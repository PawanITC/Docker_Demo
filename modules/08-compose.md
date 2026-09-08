# Module 08 — Docker Compose

## Learning objectives

- Define a multi-container application in one YAML file.
- Start and stop an entire stack with a single command.
- Use networks, volumes, and dependencies in Compose.

---

## 1. Why Compose?

Running a real app means juggling several containers (web + database + cache) with the right ports, volumes, and networks. **Docker Compose** describes all of that declaratively in a `compose.yaml` file, so the whole stack comes up with one command.

---

## Practical 8.1 — A web + database stack

**Goal:** Run a Flask app with a Postgres database using Compose.

Create `compose.yaml`:

```yaml
services:
  api:
    build: .
    ports:
      - "5000:5000"
    environment:
      DATABASE_URL: postgres://postgres:secret@db:5432/postgres
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

**Commands:**

```bash
docker compose up -d
docker compose ps
```

**What just happened?**
Compose read `compose.yaml` and:
1. Built the `api` image from the local `Dockerfile` (`build: .`).
2. Pulled `postgres:16` for `db`.
3. Created a **dedicated network** so `api` can reach `db` by name.
4. Created the `pgdata` **named volume**.
5. Started `db` before `api` because of `depends_on`.

All with a single `up -d`.

---

## Practical 8.2 — Logs, scaling, and lifecycle

**Goal:** Operate the running stack.

**Commands:**

```bash
docker compose logs -f          # Stream logs from all services
docker compose logs api         # Just one service
docker compose up -d --scale api=3   # Run 3 copies of the api
docker compose stop             # Stop without removing
docker compose start            # Start again
```

**What just happened?**
`compose logs` aggregates output from every service (or one you name). `--scale api=3` runs three replicas of the `api` service on the shared network — handy for testing load balancing. `stop`/`start` pause and resume the whole stack.

---

## Practical 8.3 — Tear down cleanly

**Goal:** Remove the stack.

**Commands:**

```bash
docker compose down             # Stop & remove containers + network
docker compose down -v          # Also remove named volumes (deletes data!)
```

**What just happened?**
`down` removes the containers and the network Compose created, leaving images and named volumes intact. Adding `-v` **also deletes the volumes**, wiping your database data — use it only when you truly want a clean slate.

---

## Practical 8.4 — Environment files

**Goal:** Keep secrets and config out of the YAML.

Create `.env`:
```
POSTGRES_PASSWORD=secret
```

Reference it in `compose.yaml`:
```yaml
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

**What just happened?**
Compose automatically loads a `.env` file from the project directory and substitutes `${VARIABLE}` references. This keeps credentials out of version-controlled YAML (add `.env` to `.gitignore`).

---

## Key takeaways

- One `compose.yaml` describes the whole app; `up -d` starts it.
- Services reach each other by name on Compose's auto-created network.
- `down` cleans up; `down -v` also deletes data.

➡️ Next: [Module 09 — Registries & Distribution](09-registry.md)
