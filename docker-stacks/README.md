# Docker Stacks

Ready-to-run Dockerfiles for common tools. Every service stores its data on a
**named volume**, so `docker compose down` + `up` never loses data.

Each folder runs **on its own**, or you can run **everything at once** with
the `docker-compose.yml` in this folder.

To share **pgAdmin and Kafka UI publicly from EC2** (HTTPS, logins, Cognito
roles), use [`public/`](public/README.md). To check that its Kafka works, run the
Python producer/consumer in [`kafka-test/`](kafka-test/README.md).

| Folder | Service(s) | URL / Port | Login | Volume |
|---|---|---|---|---|
| `postgres-pgadmin/` | PostgreSQL 16 | `localhost:5432` | `postgres` / `postgres`, db `appdb` | `stack_postgres-data` |
| | pgAdmin 4 | http://localhost:5050 | no login (desktop mode); server password `postgres` | `stack_pgadmin-data` |
| `jenkins/` | Jenkins LTS | http://localhost:8080 | see *initial password* below | `stack_jenkins-home` |
| `kafka/` | Confluent Kafka 7.7 (KRaft) | `localhost:9092` | — | `stack_kafka-data` |
| | Kafka UI | http://localhost:8085 | — | — |
| `python-app/` | Flask API | http://localhost:5000 | — | `stack_python-data` |
| `java-app/` | Java 21 HTTP API | http://localhost:8081 | — | `stack_java-data` |
| `grafana/` | Grafana OSS | http://localhost:3000 | `admin` / `admin` | `stack_grafana-data` |
| `redis/` | Redis 7.4 | `localhost:6379` | password `redis` | `stack_redis-data` |
| `llm/` | Ollama (LLM server, `llama3.2:1b`) | http://localhost:11434 | — | `stack_ollama-data` |
| | Open WebUI (chat) | http://localhost:3001 | create admin on first visit | `stack_open-webui-data` |

> Credentials are lab defaults baked into the Dockerfiles as `ENV`. Override
> them with `environment:` in compose for anything beyond local practice.

## Run one service

```bash
cd redis
docker compose up -d --build
docker compose ps
docker compose logs -f
docker compose down          # stops; data stays in the volume
```

## Run everything

```bash
docker compose up -d --build                         # all services
docker compose up -d --build postgres pgadmin grafana # or pick some
docker compose --profile llm up -d --build           # everything + the LLM
docker compose ps
docker compose down          # keep data
docker compose down -v       # delete data too
```

> Running everything needs roughly **4–6 GB RAM** (Jenkins and Kafka are the heaviest).
> The LLM is behind the `llm` profile because it downloads a model (~1.3 GB) and
> needs about 2 GB more RAM. See [`llm/`](llm/README.md).
> The per-folder and all-in-one files use the **same ports**. Stop one before starting the other.

## Handy commands

```bash
# Jenkins initial admin password
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Postgres shell
docker compose exec postgres psql -U postgres -d appdb -c "SELECT * FROM customers;"

# Redis
docker compose exec redis redis-cli -a redis set hello world
docker compose exec redis redis-cli -a redis get hello

# Kafka: create, produce, consume
docker compose exec kafka kafka-topics --bootstrap-server localhost:9092 --create --topic demo
docker compose exec kafka kafka-console-producer --bootstrap-server localhost:9092 --topic demo
docker compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic demo --from-beginning

# Prove the volumes work: counter keeps going after the container is recreated
curl localhost:5000
docker compose up -d --force-recreate python-app
curl localhost:5000

# List / inspect volumes
docker volume ls --filter name=stack_
docker volume inspect stack_postgres-data
```

## How the services talk to each other

In the all-in-one stack, all services share one network and reach each other
by **service name**: pgAdmin → `postgres:5432`, Grafana → `postgres:5432`,
Kafka UI → `kafka:29092`. From your host, use `localhost` and the published port.
