# Public stack: pgAdmin + Kafka UI for anyone with a login, Postgres + Kafka for apps anywhere

```
Internet ─443──▶ Caddy (HTTPS) ─▶ pgAdmin  ─▶ Postgres
                               └▶ Kafka UI ─▶ Kafka
Internet ─5432─▶ Postgres  (TLS + password)            db.<ip-with-dashes>.sslip.io
Internet ─9094─▶ Kafka     (SASL_SSL, SCRAM-SHA-512)   broker.<ip-with-dashes>.sslip.io
```

| URL | Login | Who controls access |
|---|---|---|
| `https://pgadmin.<ip-with-dashes>.sslip.io` | pgAdmin email + password | pgAdmin users (Administrator / User) + Postgres roles |
| `https://kafka.<ip-with-dashes>.sslip.io` | AWS Cognito sign-in | Cognito groups `kafka-admins` (full) / `kafka-viewers` (read-only) |
| `db.<ip-with-dashes>.sslip.io:5432` | app name + password (`APP_USERS`) | Postgres roles `app_readwrite` / `app_readonly` |
| `broker.<ip-with-dashes>.sslip.io:9094` | app name + password (`APP_USERS`) | Kafka ACLs (readwrite = produce + consume, readonly = consume) |

Public ports: **80/443** (Caddy), **5432** (Postgres) and **9094** (Kafka). Both
data ports refuse anything without TLS and a password; the Postgres superuser
cannot log in from outside. pgAdmin and Kafka UI have no published ports.
The infrastructure (Elastic IP, Cognito, secrets) is in
`aws-docker-lab/01-ec2-docker/public-access.tf`.

## 1. Configure and apply the infra (GitHub)

Repo **Settings → Secrets and variables → Actions → Variables**:

| Variable | Example | Why |
|---|---|---|
| `EC2_INSTANCE_TYPE` | `t4g.small` | The stack needs ~1.6 GB RAM; `t4g.micro` (1 GB) is too small |
| `PGADMIN_EMAIL` | `you@gmail.com` | Initial pgAdmin Administrator |
| `KAFKA_USERS` | `{"you@gmail.com":"kafka-admins","dev@gmail.com":"kafka-viewers"}` | Kafka UI users; each gets an invite email with a temporary password |
| `PGADMIN_USERS` | `{"dev@gmail.com":"User","lead@gmail.com":"Administrator"}` | Extra pgAdmin users; passwords generated into SSM |
| `APP_USERS` | `{"orders_svc":"readwrite","reporting":"readonly","kafka_test":"readwrite"}` | Apps that connect to Postgres + Kafka from any machine; one generated password per app (same for both) |

Then **Actions → Terraform Infra Control → `01-ec2-docker` → `apply`**.
The outputs show `pgadmin_url`, `kafka_ui_url`, `postgres_jdbc_url`,
`kafka_bootstrap_servers` and how to get the passwords.

## 2. Start the containers (on EC2)

```bash
cd ~/Docker_Demo && git pull
cd docker-stacks/public
./fetch-env.sh                  # secrets from SSM → .env (never committed)
docker compose up -d --build
docker compose logs -f caddy    # wait for "certificate obtained successfully"
docker compose logs postgres-users kafka-users   # "Synced <app> (<role>)"
```

Re-run `./fetch-env.sh` and `docker compose up -d` after every `terraform apply`.

Once, install the weekly job that hands renewed certificates to Postgres and Kafka
(Caddy renews them on its own about every 60 days):
```bash
(crontab -l 2>/dev/null; echo "0 4 * * 1 $PWD/renew-tls.sh >> $PWD/renew-tls.log 2>&1") | crontab -
```

## Connect a Java / Spring Boot app (from any machine)

Get the credentials (`name:role:password;...`):
```bash
aws ssm get-parameter --with-decryption --name /docker-lab/public/APP_USERS --query Parameter.Value --output text
```

`application.yml` (replace the host with yours and pass the password as an
environment variable, not in git):
```yaml
spring:
  datasource:
    url: jdbc:postgresql://db.65-2-137-133.sslip.io:5432/appdb?sslmode=verify-full&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory
    username: orders_svc
    password: ${APP_PASSWORD}
  kafka:
    bootstrap-servers: broker.65-2-137-133.sslip.io:9094
    properties:
      security.protocol: SASL_SSL
      sasl.mechanism: SCRAM-SHA-512
      sasl.jaas.config: org.apache.kafka.common.security.scram.ScramLoginModule required username="orders_svc" password="${APP_PASSWORD}";
```

The certificates are from Let's Encrypt, which Java trusts by default, so
you don't need a truststore. `DefaultJavaSSLFactory` makes the Postgres driver
use Java's trust store and check the hostname (`verify-full`).
`sslmode=require` also works; it encrypts but does not check the certificate.

What each role may do:

| | Postgres (`appdb`, schema `public`) | Kafka |
|---|---|---|
| `readwrite` | read/write all tables, create tables (Flyway, `ddl-auto`) | produce + consume all topics, create topics, transactions |
| `readonly` | `SELECT` only | consume all topics (any consumer group) |

Quick check from any machine with `psql`:
```bash
psql "host=db.65-2-137-133.sslip.io dbname=appdb user=reporting sslmode=require"
```

To check Kafka end to end, run the Python producer/consumer in
[`../kafka-test/`](../kafka-test/README.md) as the `kafka_test` app.

## 3. Manage access

**Apps (Postgres + Kafka):** edit `APP_USERS`, run `apply`, then on EC2
`./fetch-env.sh && docker compose up -d`. The `postgres-users` and `kafka-users`
containers create or update the logins. An app removed from the list loses its Kafka
login and its Postgres role is disabled (its tables are kept).

**Kafka UI:** add, remove or move people by editing `KAFKA_USERS` and running `apply`.
Groups and their permissions are defined in `kafka-ui/config.yml`.

**pgAdmin:** edit `PGADMIN_USERS`, run `apply`, then on EC2 `./fetch-env.sh && docker compose up -d`.
The `pgadmin-users` container creates or updates them. Their passwords:
```bash
aws ssm get-parameter --with-decryption --name /docker-lab/public/PGADMIN_EXTRA_USERS --query Parameter.Value --output text
```
You can also sign in as the Administrator → *Users* (top-right menu), or:
```bash
docker compose exec pgadmin python /pgadmin4/setup.py add-user dev@gmail.com 'StrongPass#123' --role User
```
What each person may do *inside* the database is set with Postgres roles:
```sql
CREATE ROLE dev_readonly LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE appdb TO dev_readonly;
GRANT USAGE ON SCHEMA public TO dev_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dev_readonly;
```

**Passwords:**
```bash
aws ssm get-parameter --with-decryption --name /docker-lab/public/PGADMIN_DEFAULT_PASSWORD --query Parameter.Value --output text
aws ssm get-parameter --with-decryption --name /docker-lab/public/POSTGRES_PASSWORD --query Parameter.Value --output text
```
In pgAdmin, *Servers → Local Postgres* asks for the Postgres password above.

## Troubleshooting

- **App can't connect to 5432 / 9094:** `docker compose ps` should show
  `0.0.0.0:5432->5432/tcp` and `0.0.0.0:9094->9094/tcp`. If `tls-certs` failed:
  `docker compose logs tls-certs` (Caddy must have obtained the `db.` / `broker.` certs).
- **Postgres "no pg_hba.conf entry":** the client isn't using TLS (add `sslmode=require`)
  or is logging in as `postgres` (use an `APP_USERS` app instead).
- **Kafka "Authentication failed" / "Not authorized":** wrong name/password, or a
  `readonly` app tried to produce. Check `docker compose logs kafka-users`.

- **Browser can't connect:** `docker compose ps` should show `caddy` with `0.0.0.0:443->443/tcp`.
- **Certificate errors:** `docker compose logs caddy`. Port 80 must be reachable for the Let's Encrypt challenge.
- **Kafka UI "redirect_mismatch":** the Elastic IP changed. Run `apply`, then `./fetch-env.sh` and `docker compose up -d`.
- **Out of memory / containers restarting:** `free -m`; use `t4g.small` or larger.
