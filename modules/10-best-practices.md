# Module 10 — Best Practices & Production

## Learning objectives

- Build small, secure, and reliable images.
- Add healthchecks and resource limits.
- Clean up and monitor a Docker host.

---

## 1. Image best practices

- **Use small base images** — prefer `-slim` or `-alpine` variants.
- **Pin versions** — `python:3.12-slim`, not `python:latest`.
- **One process per container** — keep containers focused.
- **Leverage the layer cache** — copy dependency manifests before source.
- **Use `.dockerignore`** — keep the build context lean and secrets out.
- **Run as a non-root user** — reduce the blast radius of a compromise.

---

## Practical 10.1 — Run as a non-root user

**Goal:** Drop root privileges inside the container.

`Dockerfile`
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# Create and switch to an unprivileged user
RUN useradd --create-home appuser
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
```

```bash
docker build -t my-flask-app:secure .
docker run -d -p 5000:5000 my-flask-app:secure
docker exec <container-id> whoami   # -> appuser
```

**What just happened?**
By default containers run as `root`. Creating `appuser` and switching with `USER` means the app — and anyone who breaks into it — runs unprivileged. `whoami` confirms the process is no longer root.

---

## Practical 10.2 — Add a healthcheck

**Goal:** Let Docker know if your app is actually healthy.

Add to your `Dockerfile`:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:5000/ || exit 1
```

```bash
docker build -t my-flask-app:health .
docker run -d --name flask my-flask-app:health
docker ps        # STATUS column shows (health: starting -> healthy)
```

**What just happened?**
Docker periodically runs the `HEALTHCHECK` command inside the container. If it fails repeatedly, the container is marked **unhealthy** — orchestrators (Compose, Swarm, Kubernetes) can then restart or replace it automatically.

---

## Practical 10.3 — Set resource limits

**Goal:** Prevent a container from hogging the host.

**Commands:**

```bash
docker run -d --name web \
  --memory=256m --cpus=0.5 \
  -p 8080:80 nginx

docker stats web        # Live CPU/memory usage; Ctrl+C to exit
```

**What just happened?**
`--memory` and `--cpus` cap the resources the container may use. `docker stats` streams live usage so you can verify the container stays within its limits — essential on shared hosts.

---

## Practical 10.4 — Clean up the host

**Goal:** Reclaim disk space safely.

**Commands:**

```bash
docker system df          # Show disk usage by images/containers/volumes
docker container prune    # Remove all stopped containers
docker image prune -a     # Remove all unused images
docker system prune -a --volumes   # Aggressive full cleanup
```

**What just happened?**
`system df` shows where space is going. The `prune` commands remove unused objects. `system prune -a --volumes` is the nuclear option — it removes all unused images, networks, build cache, **and volumes**, so run it deliberately.

---

## Practical 10.5 — Production readiness checklist

- [ ] Images pinned to specific versions and scanned for vulnerabilities (`docker scout cves <image>`).
- [ ] Containers run as non-root.
- [ ] Healthchecks defined.
- [ ] Resource limits set.
- [ ] Secrets injected via environment/secret managers, **never baked into images**.
- [ ] Logs shipped to a central location.
- [ ] Restart policy set (`--restart unless-stopped`).
- [ ] Multi-stage builds keep images small.

---

## Key takeaways

- Small, pinned, non-root images with healthchecks and limits are production-grade.
- `docker scout` scans for CVEs; `system prune` reclaims space.
- Never bake secrets into images.

🎉 **You've completed the Docker End-to-End Course!** Revisit [the course index](../README.md) any time.
