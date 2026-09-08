# Module 09 — Registries & Distribution

## Learning objectives

- Push and pull images to/from Docker Hub.
- Understand tagging for registries.
- Run a private local registry.

---

## 1. What is a registry?

A registry stores and distributes images. **Docker Hub** is the default public registry. Companies often run **private registries** (Docker Hub private repos, GitHub Container Registry, AWS ECR, Harbor, or the open-source `registry` image).

An image destined for a registry must be tagged as:
```
<registry-host>/<namespace>/<repository>:<tag>
yourname/my-flask-app:1.0          # Docker Hub (host omitted)
ghcr.io/yourname/my-flask-app:1.0  # GitHub Container Registry
```

---

## Practical 9.1 — Push to Docker Hub

**Goal:** Share your image publicly.

**Commands:**

```bash
docker login                       # Enter your Docker Hub username & token

# Tag the image with your username as namespace
docker tag my-flask-app:1.0 YOURNAME/my-flask-app:1.0

docker push YOURNAME/my-flask-app:1.0
```

**What just happened?**
`docker login` authenticates your CLI with Docker Hub. Retagging with `YOURNAME/` sets the destination namespace. `docker push` uploads each layer that isn't already on the registry. Anyone can now `docker pull YOURNAME/my-flask-app:1.0`.

> Use an **access token** (Account Settings → Security), not your password.

---

## Practical 9.2 — Pull on another machine

**Goal:** Retrieve and run your published image anywhere.

**Commands:**

```bash
docker pull YOURNAME/my-flask-app:1.0
docker run -d -p 5000:5000 YOURNAME/my-flask-app:1.0
```

**What just happened?**
Docker downloaded the image from Docker Hub and ran it — the same artifact you built, now portable to any machine with Docker.

---

## Practical 9.3 — Run a private local registry

**Goal:** Host your own registry on localhost.

**Commands:**

```bash
# Start a registry container on port 5000
docker run -d -p 5000:5000 --name registry registry:2

# Tag and push to it
docker tag my-flask-app:1.0 localhost:5000/my-flask-app:1.0
docker push localhost:5000/my-flask-app:1.0

# Pull it back
docker pull localhost:5000/my-flask-app:1.0
```

**What just happened?**
The `registry:2` image runs a fully functional registry. By tagging with the `localhost:5000/` prefix, Docker knows to push there instead of Docker Hub. This is the basis of on-premise or air-gapped image distribution.

---

## Practical 9.4 — Digests for immutability

**Goal:** Pin an image by content, not tag.

**Commands:**

```bash
docker inspect --format='{{index .RepoDigests 0}}' nginx
docker pull nginx@sha256:<digest-from-above>
```

**What just happened?**
Tags can move (today's `latest` isn't tomorrow's). A **digest** (`@sha256:...`) is a cryptographic hash of the exact image content, guaranteeing you get precisely the same bytes every time — important for reproducible production deployments.

---

## Key takeaways

- Tag as `namespace/repo:tag`, then `login` and `push`.
- Anyone can `pull` a public image; private registries keep it internal.
- Pin by digest for reproducible deployments.

➡️ Next: [Module 10 — Best Practices & Production](10-best-practices.md)
