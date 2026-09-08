# Module 07 — Networking

## Learning objectives

- Understand Docker's network drivers.
- Connect containers so they can talk to each other by name.
- Publish ports to the host.

---

## 1. Network drivers

- **bridge** (default) — private internal network on a single host. Containers on the same bridge can reach each other.
- **host** — the container shares the host's network stack directly (no isolation, no port mapping).
- **none** — no networking at all.

---

## Practical 7.1 — List and inspect networks

**Goal:** See what networks exist.

**Commands:**

```bash
docker network ls
docker network inspect bridge
```

**What just happened?**
`network ls` shows the default networks (`bridge`, `host`, `none`). `inspect bridge` reveals the subnet, gateway, and which containers are attached.

---

## Practical 7.2 — Create a user-defined network for name resolution

**Goal:** Let two containers communicate by name.

**Commands:**

```bash
docker network create app-net

# Start a Redis container on the network
docker run -d --name redis --network app-net redis:7

# Start a temporary client on the same network and ping Redis by name
docker run -it --rm --network app-net redis:7 redis-cli -h redis ping
```

Expected output: `PONG`

**What just happened?**
On a **user-defined** network, Docker provides automatic **DNS resolution** — the client reached the Redis container using its name `redis` instead of an IP address. (The default `bridge` network does *not* provide name resolution; user-defined networks do.)

---

## Practical 7.3 — Two-tier app on one network

**Goal:** Connect an app container to a database container.

**Commands:**

```bash
docker network create tier

docker run -d --name db --network tier \
  -e POSTGRES_PASSWORD=secret postgres:16

docker run -d --name api --network tier \
  -e DATABASE_URL=postgres://postgres:secret@db:5432/postgres \
  my-flask-app:1.0
```

**What just happened?**
Both containers share the `tier` network, so the API reaches the database at the hostname `db` (its container name). No IP addresses, no host ports needed for internal traffic — only the parts you explicitly publish are reachable from outside.

---

## Practical 7.4 — Publishing ports

**Goal:** Understand `-p host:container`.

**Commands:**

```bash
docker run -d --name web -p 8080:80 nginx        # host 8080 -> container 80
docker run -d --name web2 -p 127.0.0.1:9090:80 nginx  # bind to localhost only
docker port web
```

**What just happened?**
`-p 8080:80` exposes the container's port 80 on the host's port 8080. Prefixing with `127.0.0.1:` binds it to localhost only, so it's not reachable from other machines. `docker port` lists the active mappings.

---

## Key takeaways

- User-defined bridge networks give free DNS by container name.
- Containers on the same network talk directly; publish ports only for external access.
- `network create/ls/inspect` and `-p` / `--network` are the core tools.

➡️ Next: [Module 08 — Docker Compose](08-compose.md)
