# Module 03 — Working with Images

## Learning objectives

- Pull, list, inspect, and remove images.
- Understand image tags and layers.
- Search Docker Hub from the CLI.

---

## 1. What is an image?

An image is a **read-only, layered template**. Each instruction that built it added a layer. Layers are cached and shared between images, which is why the second pull of a shared base is instant.

An image reference looks like:

```
registry/repository:tag
docker.io/library/nginx:1.27-alpine
```

If you omit the registry it defaults to Docker Hub (`docker.io`), and if you omit the tag it defaults to `latest`.

---

## Practical 3.1 — Pull and list images

**Goal:** Download images and see them locally.

**Commands:**

```bash
docker pull nginx
docker pull python:3.12-slim
docker images
```

**What just happened?**
`docker pull` downloads an image (and any missing layers) from the registry. `nginx` resolved to `nginx:latest`. `docker images` then lists everything cached locally with its repository, tag, image ID, and size.

---

## Practical 3.2 — Inspect an image

**Goal:** See the low-level metadata of an image.

**Commands:**

```bash
docker inspect nginx
docker history nginx
```

**What just happened?**
`docker inspect` dumps JSON with the image's config — environment variables, exposed ports, entrypoint, and layer digests. `docker history` shows how the image was built, layer by layer, with the size each instruction added.

---

## Practical 3.3 — Search and tag

**Goal:** Find images and give one a new local name.

**Commands:**

```bash
docker search redis
docker tag nginx:latest my-nginx:v1
docker images
```

**What just happened?**
`docker search` queries Docker Hub for repositories matching "redis". `docker tag` creates a **new reference** pointing at the same image (no data is copied — notice the identical image ID). Tagging is how you prepare an image for pushing to your own repository.

---

## Practical 3.4 — Remove images

**Goal:** Free up disk space.

**Commands:**

```bash
docker rmi my-nginx:v1
docker image prune           # Remove dangling (untagged) images
docker image prune -a        # Remove all unused images
```

**What just happened?**
`docker rmi` removes a specific image (or just a tag if other tags point to it). `docker image prune` deletes **dangling** images — layers no longer referenced by any tag. Adding `-a` removes every image not used by a container.

---

## Key takeaways

- Images are immutable, layered, and cached.
- `pull`, `images`, `inspect`, `history`, `tag`, `rmi` are your daily tools.
- Tagging just adds a name; it doesn't duplicate data.

➡️ Next: [Module 04 — Working with Containers](04-containers.md)
