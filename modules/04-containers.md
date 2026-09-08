# Module 04 — Working with Containers

## Learning objectives

- Run containers in the foreground and background.
- Manage the container lifecycle (start, stop, restart, remove).
- Read logs and execute commands inside a running container.

---

## 1. The container lifecycle

```
created ──run──► running ──stop──► stopped ──start──► running
                    │                  │
                    └──────rm──────────┴──► removed
```

---

## Practical 4.1 — Run a container in the background

**Goal:** Start an nginx web server detached.

**Commands:**

```bash
docker run -d --name web -p 8080:80 nginx
docker ps
```

Open http://localhost:8080 in your browser.

**What just happened?**
- `-d` runs the container **detached** (in the background).
- `--name web` gives it a friendly name instead of a random one.
- `-p 8080:80` maps **host port 8080** to **container port 80**.

`docker ps` confirms it's running, and the browser shows the nginx welcome page served from inside the container.

---

## Practical 4.2 — View logs

**Goal:** See the web server's output.

**Commands:**

```bash
docker logs web
docker logs -f web       # Follow (stream) new logs; Ctrl+C to stop
```

**What just happened?**
`docker logs` prints whatever the container wrote to stdout/stderr. `-f` follows the stream live — refresh the browser and watch new access log lines appear.

---

## Practical 4.3 — Execute a command inside a container

**Goal:** Get a shell inside the running container.

**Commands:**

```bash
docker exec -it web bash
# Now inside the container:
ls /usr/share/nginx/html
cat /etc/nginx/nginx.conf
exit
```

**What just happened?**
`docker exec` runs a new process inside an already-running container. `-it` gives you an **i**nteractive **t**erminal. You're now exploring the container's filesystem. Typing `exit` leaves the shell but the container keeps running.

---

## Practical 4.4 — Stop, start, and remove

**Goal:** Control the container lifecycle.

**Commands:**

```bash
docker stop web
docker ps -a            # Shows it as "Exited"
docker start web
docker restart web
docker rm -f web        # Force-remove (stops first if running)
```

**What just happened?**
`stop` sends SIGTERM (graceful shutdown), `start` boots a stopped container back up, and `restart` does both. `rm` deletes the container; `-f` forces it even while running. After `rm`, the container is gone — but the **image remains**.

---

## Practical 4.5 — Run an interactive one-off container

**Goal:** Experiment inside a throwaway container.

**Commands:**

```bash
docker run -it --rm ubuntu bash
# Inside:
apt-get update && apt-get install -y cowsay
/usr/games/cowsay "Hello from a container"
exit
```

**What just happened?**
`-it` gives an interactive shell; `--rm` **automatically deletes** the container when you exit. This is perfect for quick experiments — nothing is left behind.

---

## Key takeaways

- `-d` detaches, `-p` publishes ports, `--name` names, `--rm` auto-cleans.
- `logs`, `exec -it`, `stop/start/restart`, `rm` manage running containers.
- Removing a container never removes its image.

➡️ Next: [Module 05 — Writing Dockerfiles](05-dockerfiles.md)
