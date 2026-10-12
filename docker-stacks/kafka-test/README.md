# Kafka smoke test: Python producer + consumer

Two small images that prove the Kafka from [`public/`](../public/README.md) works:

| Folder | Image | What it does |
|---|---|---|
| `producer/` | `stack/kafka-test-producer:1.0` | connects, **creates the topic if missing**, sends `MESSAGE_COUNT` JSON messages and waits until the broker confirms each one |
| `consumer/` | `stack/kafka-test-consumer:1.0` | connects, waits for the topic, prints every message from the beginning |

Nothing is hard-coded: the broker address, the login and the topic all come
from environment variables. Both use [`confluent-kafka`](https://github.com/confluentinc/confluent-kafka-python)
and check the broker's TLS certificate against the public CAs (Let's Encrypt).

## 1. Get the login

The test uses the `kafka_test` app from `APP_USERS` (role `readwrite`: it may
create topics, produce and consume). Its password is in SSM (`name:role:password;...`):
```bash
aws ssm get-parameter --region ap-south-1 --with-decryption \
  --name /docker-lab/public/APP_USERS --query Parameter.Value --output text
```
> In Git Bash on Windows, prefix the command with `MSYS_NO_PATHCONV=1`, otherwise
> the `/docker-lab/...` name is turned into a Windows path and you get `ParameterNotFound`.

The broker address is the Terraform output `kafka_bootstrap_servers`
(`broker.<ip-with-dashes>.sslip.io:9094`).

## 2. Run it (on EC2 or any machine with Docker)

```bash
cd docker-stacks/kafka-test
cp .env.example .env            # set KAFKA_BOOTSTRAP, KAFKA_USERNAME, KAFKA_PASSWORD
docker compose build
docker compose run --rm producer
docker compose run --rm consumer   # Ctrl+C to stop
```

Expected output:
```
producer  Connected: 1 broker(s), cluster ...
          Created topic 'test-topic'
          delivered key=1 to test-topic [partition 2] @ offset 0
          ...
          Done: 10 delivered, 0 failed, 0 not confirmed
consumer  Topic 'test-topic' has 3 partition(s)
          received key=1 from [partition 2] @ offset 0: {"id": 1, "sent_at": "...", ...}
```
The producer exits with code `0` only if every message was confirmed, so it
also works in scripts: `docker compose run --rm producer && echo KAFKA OK`.

Without a `.env` file, pass the values directly:
```bash
docker run --rm -e KAFKA_BOOTSTRAP=broker.13-200-55-154.sslip.io:9094 \
  -e KAFKA_USERNAME=kafka_test -e KAFKA_PASSWORD='...' stack/kafka-test-producer:1.0
```

Leave the consumer running in one terminal and run the producer in another
(e.g. with `MESSAGE_COUNT=0` to send until stopped) to watch messages arrive live.

### Test from inside Docker (no TLS, no login)

On the EC2, the containers of the public stack share the network `public_default`,
where Kafka listens on `kafka:29092` without TLS or a login. If this works but
the public test doesn't, Kafka is fine and the problem is the port, the
certificate or the password.
```bash
docker run --rm --network public_default \
  -e KAFKA_BOOTSTRAP=kafka:29092 -e KAFKA_SECURITY_PROTOCOL=PLAINTEXT \
  stack/kafka-test-producer:1.0
docker run --rm --network public_default \
  -e KAFKA_BOOTSTRAP=kafka:29092 -e KAFKA_SECURITY_PROTOCOL=PLAINTEXT \
  -e IDLE_TIMEOUT_SEC=10 stack/kafka-test-consumer:1.0
```

## Settings

| Variable | Default | Used by | Notes |
|---|---|---|---|
| `KAFKA_BOOTSTRAP` | **required** | both | `host:port` |
| `KAFKA_USERNAME` / `KAFKA_PASSWORD` | **required for SASL** | both | an `APP_USERS` app |
| `KAFKA_SECURITY_PROTOCOL` | `SASL_SSL` | both | `PLAINTEXT`, `SSL`, `SASL_PLAINTEXT`, `SASL_SSL` |
| `KAFKA_SASL_MECHANISM` | `SCRAM-SHA-512` | both | |
| `KAFKA_TOPIC` | `test-topic` | both | |
| `TOPIC_PARTITIONS` / `TOPIC_REPLICATION` | `3` / `1` | producer | only used when the topic is created |
| `MESSAGE_COUNT` | `10` | producer | `0` = send until stopped |
| `MESSAGE_INTERVAL_SEC` | `1` | producer | pause between messages |
| `GROUP_ID` | `kafka-test` | consumer | a group reads each message once; use a new one to read everything again |
| `IDLE_TIMEOUT_SEC` | `0` | consumer | stop after this many seconds without a message; `0` = never |

## Optional: push the images to ECR

The stack has a private ECR repo (Terraform output `ecr_repository_url`). The
EC2 can pull from it with its instance role and no `docker login`, but can't
push, so push from your laptop. Build for both architectures (the EC2 is arm64):
```bash
REPO=<ecr_repository_url>       # e.g. 670578096006.dkr.ecr.ap-south-1.amazonaws.com/docker-lab
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin "${REPO%%/*}"
docker buildx create --use 2>/dev/null || true
for app in producer consumer; do
  docker buildx build --platform linux/amd64,linux/arm64 \
    -t "$REPO:kafka-test-$app-1.0" --push ./$app
done
```
On the EC2:
```bash
docker run --rm --env-file .env <ecr_repository_url>:kafka-test-producer-1.0
```

## Troubleshooting

- **`cannot reach Kafka` / `Connection refused` / timeout:** wrong host or port,
  or the public stack isn't running (`docker compose ps` in `public/` should show
  `0.0.0.0:9094->9094/tcp`).
- **`Authentication failed`:** wrong username or password, or the app is not in
  `APP_USERS` yet. On the EC2: `docker compose logs kafka-users` in `public/`
  should show `Synced kafka_test (readwrite)`.
- **`TOPIC_AUTHORIZATION_FAILED` / `Not authorized`:** the app is `readonly`; it
  can consume but can't create topics or produce.
- **`certificate verify failed`:** use the `broker.` hostname, not the IP (the
  certificate is for the name). If it's expired, run `public/renew-tls.sh`.
- **Consumer prints nothing:** the group `kafka-test` already read those messages.
  Send new ones or use another `GROUP_ID`.
