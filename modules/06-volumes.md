# Module 06 — Data & Volumes

## Learning objectives

- Understand why container filesystems are ephemeral.
- Persist data with named volumes and bind mounts.
- Know when to use each.

---

## 1. Why data disappears

A container's writable layer is deleted when the container is removed. To **keep** data — databases, uploads, logs — you must store it outside the container using:

- **Named volumes** — managed by Docker, ideal for databases.
- **Bind mounts** — map a host folder into the container, ideal for development.
- **tmpfs** — in-memory, for sensitive/temporary data.

---

## Practical 6.1 — Prove data is ephemeral

**Goal:** See data vanish when a container is removed.

**Commands:**

```bash
docker run -it --name temp ubuntu bash
# inside:
echo "important" > /data.txt
cat /data.txt
exit

docker rm temp
# The file is gone forever — it lived only in the container's writable layer.
```

**What just happened?**
The file existed only in the container's writable layer. Removing the container removed the layer and the data with it.

---

## Practical 6.2 — Named volume with a database

**Goal:** Persist PostgreSQL data across container restarts.

**Commands:**

```bash
docker volume create pgdata
docker run -d --name db \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

# Stop and remove the container, then recreate it:
docker rm -f db
docker run -d --name db \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16
```

**What just happened?**
`-v pgdata:/var/lib/postgresql/data` mounts the named volume `pgdata` at Postgres's data directory. Even after you **destroy and recreate** the container, the volume — and all your data — survives, because volumes have an independent lifecycle.

---

## Practical 6.3 — Bind mount for live development

**Goal:** Edit files on your host and see changes instantly in the container.

**Commands:**

```bash
# From a folder containing an index.html file:
docker run -d --name site \
  -p 8080:80 \
  -v "$(pwd)":/usr/share/nginx/html \
  nginx
```

Edit `index.html` on your host, refresh http://localhost:8080 — changes appear immediately.

**What just happened?**
A bind mount maps your **current host directory** (`$(pwd)`) directly into the container. There's no copy — the container reads your live files, so edits show up without rebuilding. This is the classic development workflow.

> On Windows PowerShell use `${PWD}`; in Git Bash `$(pwd)` works.

---

## Practical 6.4 — Inspect and clean up volumes

**Goal:** Manage volumes.

**Commands:**

```bash
docker volume ls
docker volume inspect pgdata
docker volume rm pgdata          # Fails if a container is using it
docker volume prune              # Remove all unused volumes
```

**What just happened?**
`ls` lists volumes, `inspect` shows the mountpoint on the host, and `rm`/`prune` clean them up. Docker protects you: it won't delete a volume that a container still references.

---

## Named volumes vs bind mounts

| | Named volume | Bind mount |
|---|--------------|------------|
| Managed by Docker | ✅ | ❌ (you pick the path) |
| Best for | Databases, production data | Local development |
| Portable | ✅ | ❌ (host-path dependent) |

---

## Key takeaways

- Container filesystems are ephemeral — use volumes to persist data.
- Named volumes for databases/production; bind mounts for dev.
- `docker volume ls/inspect/prune` manage them.

➡️ Next: [Module 07 — Networking](07-networking.md)
