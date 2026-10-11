# Public stack: pgAdmin + Kafka UI for anyone with a login

```
Internet ─443─▶ Caddy (HTTPS) ─▶ pgAdmin  ─▶ Postgres   (internal)
                              └▶ Kafka UI ─▶ Kafka      (internal)
```

| URL | Login | Who controls access |
|---|---|---|
| `https://pgadmin.<ip-with-dashes>.sslip.io` | pgAdmin email + password | pgAdmin users (Administrator / User) + Postgres roles |
| `https://kafka.<ip-with-dashes>.sslip.io` | AWS Cognito sign-in | Cognito groups `kafka-admins` (full) / `kafka-viewers` (read-only) |

Only ports **80/443** are public. Postgres, Kafka, pgAdmin and Kafka UI have no
published ports. The infrastructure (Elastic IP, Cognito, secrets) is in
`aws-docker-lab/01-ec2-docker/public-access.tf`.

## 1. Configure and apply the infra (GitHub)

Repo **Settings → Secrets and variables → Actions → Variables**:

| Variable | Example | Why |
|---|---|---|
| `EC2_INSTANCE_TYPE` | `t4g.small` | The stack needs ~1.6 GB RAM; `t4g.micro` (1 GB) is too small |
| `PGADMIN_EMAIL` | `you@gmail.com` | Initial pgAdmin Administrator |
| `KAFKA_USERS` | `{"you@gmail.com":"kafka-admins","dev@gmail.com":"kafka-viewers"}` | Kafka UI users; each gets an invite email with a temporary password |
| `PGADMIN_USERS` | `{"dev@gmail.com":"User","lead@gmail.com":"Administrator"}` | Extra pgAdmin users; passwords generated into SSM |

Then **Actions → Terraform Infra Control → `01-ec2-docker` → `apply`**.
The outputs show `pgadmin_url`, `kafka_ui_url` and how to get the pgAdmin password.

## 2. Start the containers (on EC2)

```bash
cd ~/Docker_Demo && git pull
cd docker-stacks/public
./fetch-env.sh                  # secrets from SSM → .env (never committed)
docker compose up -d --build
docker compose logs -f caddy    # wait for "certificate obtained successfully"
```

Re-run `./fetch-env.sh` and `docker compose up -d` after every `terraform apply`.

## 3. Manage access

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

- **Browser can't connect:** `docker compose ps` should show `caddy` with `0.0.0.0:443->443/tcp`.
- **Certificate errors:** `docker compose logs caddy`. Port 80 must be reachable for the Let's Encrypt challenge.
- **Kafka UI "redirect_mismatch":** the Elastic IP changed. Run `apply`, then `./fetch-env.sh` and `docker compose up -d`.
- **Out of memory / containers restarting:** `free -m`; use `t4g.small` or larger.
