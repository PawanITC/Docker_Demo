# Module 01 — Introduction to Docker

## Learning objectives

- Understand what Docker is and the problem it solves.
- Know the difference between containers and virtual machines — and *why* Docker was needed when VMs already existed.
- Understand what problems Docker solves that VMs cannot.
- Know who builds VM technology and who builds Docker.
- Understand Docker's competitors today.
- Understand how Kubernetes differs from Docker and why one doesn't replace the other.
- Learn the core Docker components and architecture.

---

## 1. What is Docker?

Docker is a platform for **building, shipping, and running applications inside containers**. A container packages your application together with everything it needs to run — code, runtime, libraries, and system tools — so it behaves the same on any machine.

> "It works on my machine" → With Docker, **your machine ships with the app.**

---

## 2. Containers vs Virtual Machines

| | Virtual Machine | Container |
|---|-----------------|-----------|
| Isolation | Full OS per VM | Shares host kernel |
| Size | Gigabytes | Megabytes |
| Startup | Minutes | Seconds |
| Overhead | High (hypervisor) | Low |

A VM virtualizes **hardware** and runs a full guest OS. A container virtualizes the **operating system** and shares the host's kernel, making it far lighter.

```
   VIRTUAL MACHINES                CONTAINERS
 ┌──────┐ ┌──────┐             ┌──────┐ ┌──────┐
 │ App  │ │ App  │             │ App  │ │ App  │
 │ Bins │ │ Bins │             │ Bins │ │ Bins │
 │Guest │ │Guest │             └──────┘ └──────┘
 │ OS   │ │ OS   │             ┌────────────────┐
 ├──────┴─┴──────┤             │  Docker Engine │
 │  Hypervisor   │             ├────────────────┤
 │   Host OS     │             │    Host OS     │
 └───────────────┘             └────────────────┘
```

---

### The key insight

A VM boots an **entire operating system** (its own kernel, drivers, init system, services) on top of virtualized hardware. That's why a VM is measured in gigabytes and takes minutes to boot.

A container is **just your app's processes** running in an isolated "bubble" on the host's *already-running* kernel. There is no second OS to boot — so it starts in seconds and weighs megabytes. Docker uses built-in Linux kernel features (**namespaces** for isolation and **cgroups** for resource limits) to create that bubble.

---

## 3. Why was Docker needed? (The problem it solves)

Before containers, teams already had VMs — so why invent Docker? Because VMs solve *isolation* but leave several painful problems unsolved:

### Problem 1 — "It works on my machine"
The classic nightmare: code runs on a developer's laptop but breaks in testing or production because of a different library version, OS patch, or missing dependency. VMs don't fix this by themselves — each VM image is still hand-configured and drifts over time.

**Docker's answer:** the app *and all its dependencies* are baked into a single image defined by a `Dockerfile`. The exact same image runs identically on a laptop, a CI server, and production. The environment travels *with* the app.

### Problem 2 — VMs are heavy and slow
Each VM carries a full guest OS, so:
- A server can run maybe a handful of VMs (each GBs of RAM/disk).
- Booting takes minutes.
- Patching/maintaining every guest OS is real work.

**Docker's answer:** containers share the host kernel, so a single server can run **dozens or hundreds** of containers, each starting in **seconds**, using a fraction of the resources.

### Problem 3 — Slow, inconsistent setup
Onboarding a new developer or spinning up an environment meant following a long, error-prone setup document ("install Postgres 14, this Redis, that Python...").

**Docker's answer:** `docker compose up` recreates the entire stack — database, cache, app — identically in one command, in minutes.

### Problem 4 — Inefficient scaling and deployment
Scaling a VM-based app means cloning whole machines; deployments are large and slow.

**Docker's answer:** images are small, layered, and cached, so shipping a new version means moving only the changed layers. Starting another copy of the app is nearly instant.

### VMs vs Docker — what each actually solves

| Problem | VMs | Docker |
|---------|-----|--------|
| Isolate workloads on one machine | ✅ | ✅ |
| Guaranteed consistent app environment everywhere | ❌ (drifts) | ✅ (image is immutable) |
| Lightweight / high density per server | ❌ | ✅ |
| Start in seconds | ❌ | ✅ |
| Package app + dependencies as one shippable unit | ❌ | ✅ |
| Run a *different* OS kernel (e.g. Windows on Linux) | ✅ | ❌ (shares host kernel) |

> **They're complementary, not enemies.** In the cloud today, containers usually run *inside* VMs: the VM provides strong hardware-level isolation and the OS, while Docker provides fast, portable, consistent app packaging on top.

---

## 4. Who provides VMs and who provides Docker?

### Virtualization (VM) providers
Virtualization is a mature field with many vendors:

- **VMware** — vSphere / ESXi (enterprise standard).
- **Microsoft** — Hyper-V (built into Windows).
- **Oracle** — VirtualBox (free, popular for desktops).
- **KVM/QEMU** — the open-source Linux hypervisor that powers most clouds.
- **Citrix** — XenServer.
- **Cloud VMs** — AWS EC2, Azure Virtual Machines, Google Compute Engine (VMs as a service).

### Docker
- **Docker** is developed by **Docker, Inc.** It was created by Solomon Hykes and launched publicly in **2013**.
- The underlying container standards are now open and governed by the **Open Container Initiative (OCI)**, and the low-level runtime (**containerd**, originally from Docker) is a **CNCF** (Cloud Native Computing Foundation) project.
- **Docker Desktop** (the GUI app for Windows/macOS) is a Docker, Inc. product; the core engine is open source.

---

## 5. Docker's competitors today

Docker popularized containers, but it's no longer the only tool. Common alternatives:

- **Podman** (by Red Hat) — a daemonless, rootless container engine with a Docker-compatible CLI. Often used as a drop-in replacement (`alias docker=podman`).
- **containerd** — the lightweight core runtime (extracted from Docker) that many platforms, including Kubernetes, use directly.
- **CRI-O** — a minimal runtime built specifically for Kubernetes.
- **Buildah** — focused purely on *building* OCI images (no daemon).
- **LXC/LXD** — system containers (closer to lightweight VMs) rather than app containers.
- **rkt** — an early competitor from CoreOS (now discontinued).

> Note: because of the **OCI** standard, images built by Docker, Podman, or Buildah are interchangeable — they all produce the same kind of image.

---

## 6. How is Kubernetes different from Docker? Why not use Docker instead of Kubernetes?

This is the most common point of confusion, so read carefully: **Docker and Kubernetes are not competitors — they operate at different layers.**

### Docker = build and run *a container*
Docker's job is to **package** an app into an image and **run containers**, typically on **one machine**. It answers: *"How do I turn my app into a container and run it here?"*

### Kubernetes (K8s) = orchestrate *many containers across many machines*
Kubernetes is a **container orchestrator**. It manages large numbers of containers across a **cluster of many servers** and answers the operational questions Docker alone doesn't:

- **Scheduling** — which server should run each container?
- **Scaling** — automatically add/remove copies based on load.
- **Self-healing** — restart or reschedule containers that crash or whose host dies.
- **Load balancing & service discovery** — route traffic across many replicas.
- **Rolling updates & rollbacks** — deploy new versions with zero downtime.
- **Config & secret management** across the whole cluster.

```
        DOCKER                              KUBERNETES
  ┌──────────────────┐          ┌──────────────────────────────────┐
  │   One machine    │          │        Cluster of machines        │
  │ ┌────┐ ┌────┐    │          │  ┌──Node1──┐ ┌──Node2──┐ ┌─Node3─┐│
  │ │cont│ │cont│    │          │  │cont cont│ │cont cont│ │  cont │ │
  │ └────┘ └────┘    │          │  └─────────┘ └─────────┘ └───────┘ │
  │  build + run     │          │  schedules, scales, heals, routes  │
  └──────────────────┘          └──────────────────────────────────┘
```

### Why isn't Docker used *instead of* Kubernetes?
Because Docker **can't do what Kubernetes does**:

- Docker runs containers on **one host**. It has no built-in way to spread work across a fleet of servers.
- If a container (or its whole machine) dies at 3 a.m., Docker won't automatically move it to a healthy server — Kubernetes will.
- Docker can't automatically scale replicas up and down based on traffic across a cluster.
- Docker has no cluster-wide load balancing, rolling deployments, or self-healing.

Docker Compose *can* run multi-container apps, but only on a **single machine** and without auto-recovery or cluster scaling — fine for development, not for large-scale production.

### And why isn't Kubernetes used *instead of* Docker?
Because Kubernetes doesn't *build* images and doesn't run containers by itself — it **delegates** the actual container execution to a runtime (**containerd**, **CRI-O**, etc.). In fact:

- You typically use **Docker (or Podman/Buildah) to build the image**.
- You push it to a registry.
- **Kubernetes then pulls and runs it** across the cluster using a container runtime under the hood.

> **The relationship:** Docker builds and packages the container; Kubernetes runs many of those containers reliably at scale. They work **together** — Docker for the "inner loop" (build/run locally), Kubernetes for the "outer loop" (operate at scale in production).

---

## 7. Core concepts

- **Image** — a read-only template with instructions for creating a container (e.g. `nginx`, `python:3.12`).
- **Container** — a running (or stopped) instance of an image.
- **Dockerfile** — a text file with instructions to build an image.
- **Registry** — a store for images (e.g. Docker Hub).
- **Docker Engine** — the background service (daemon) that builds and runs containers.

---

## 8. Docker architecture

```
  docker CLI  ──REST API──►  Docker Daemon (dockerd)
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
                 Images      Containers      Registry
```

- **Client** — the `docker` command you type.
- **Daemon** — does the actual work of building/running/managing.
- **Registry** — where images are stored and shared.

---

## Practical 1.1 — Verify Docker is talking to the daemon

**Goal:** Confirm the client and daemon are connected.

**Commands:**

```bash
docker version
docker info
```

**What just happened?**
`docker version` shows both the **Client** and **Server (daemon)** versions. If you only see the client, the daemon isn't running. `docker info` reports system-wide details — number of containers, images, storage driver, and kernel version — proving your client successfully reached the daemon.

---

## Practical 1.2 — Run your first container

**Goal:** Run the classic hello-world container.

**Commands:**

```bash
docker run hello-world
```

**What just happened?**
1. Docker looked for the `hello-world` image locally and didn't find it.
2. It **pulled** the image from Docker Hub.
3. It **created a container** from that image and ran it.
4. The container printed a message and exited.

This single command demonstrates the entire pull → create → run lifecycle.

---

## 9. Installing Docker (CLI & Desktop)

You need Docker installed to run the examples below. Pick your platform:

| Platform | What to install | Download link |
|----------|-----------------|---------------|
| Windows | Docker Desktop (includes CLI + Compose + GUI) | https://docs.docker.com/desktop/install/windows-install/ |
| macOS | Docker Desktop | https://docs.docker.com/desktop/install/mac-install/ |
| Linux (desktop) | Docker Desktop | https://docs.docker.com/desktop/install/linux/ |
| Linux (server, CLI only) | Docker Engine + CLI | https://docs.docker.com/engine/install/ |

**Docker Desktop (Windows / macOS) — quick steps**
1. Download the installer from the link above.
2. Run it. On **Windows**, enable the **WSL 2** backend when prompted (recommended).
3. Launch Docker Desktop and wait for the whale icon to show "running".
4. Verify in a terminal:
   ```bash
   docker --version
   docker compose version
   docker run hello-world
   ```

**Docker Engine / CLI only (Linux server)**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER   # run docker without sudo (log out/in after)
```
Official install docs: https://docs.docker.com/engine/install/

> **Docker registry (Docker Hub):** https://hub.docker.com — the default public registry where images like `python`, `redis`, and `nginx` live. Browse the official images used in this course: [python](https://hub.docker.com/_/python), [redis](https://hub.docker.com/_/redis), [nginx](https://hub.docker.com/_/nginx). Create a free account to push your own images (covered in [Module 09](09-registry.md)).

---

## 10. A complete, downloadable example (Dockerfile + Compose)

A ready-to-run mini app lives in **[`examples/module-01/`](examples/module-01/)**. It's a tiny Python (Flask) web page that counts visits using Redis — enough to show both a **Dockerfile** (build one image) and a **Compose file** (run multiple containers together).

**Download / get the files** — either clone the whole course repo:
```bash
git clone https://github.com/PawanITC/Docker_Demo.git
cd Docker_Demo/modules/examples/module-01
```
…or grab the individual files from [`modules/examples/module-01/`](examples/module-01/): `app.py`, `requirements.txt`, `Dockerfile`, `docker-compose.yml`, `.dockerignore`.

### The Dockerfile (with inline explanation)

```dockerfile
# Base image: official, small, version-pinned Python.
FROM python:3.12-slim

# Everything below runs inside /app.
WORKDIR /app

# Copy the dependency list FIRST so the pip layer is cached when only code changes.
COPY requirements.txt .

# Install dependencies at build time; --no-cache-dir keeps the image small.
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the rest of the source code.
COPY . .

# Document the port the app listens on.
EXPOSE 5000

# Default command when a container starts.
CMD ["python", "app.py"]
```

### The Compose file (with inline explanation)

```yaml
services:
  web:                       # our Python web app
    build: .                 # build the image from the Dockerfile in this folder
    ports:
      - "5000:5000"          # host port 5000 -> container port 5000
    environment:
      REDIS_HOST: redis      # where the app finds Redis (the service name below)
    depends_on:
      - redis                # start redis before web

  redis:                     # counter storage
    image: "redis:7-alpine"  # official image, no build needed
    volumes:
      - redisdata:/data      # persist data across restarts

volumes:
  redisdata:                 # Docker-managed named volume
```

### Practical 1.3 — Build and run the example

**Goal:** Bring the whole app up with one command.

**Commands:**
```bash
# From inside modules/examples/module-01/
docker compose up
```
Then open http://localhost:5000 and refresh a few times — the counter goes up.

**Stop and clean up:**
```bash
docker compose down          # stop & remove containers + network
docker compose down -v       # also delete the redisdata volume
```

**What just happened?**
`docker compose up` read `docker-compose.yml` and: (1) **built** the `web` image from the `Dockerfile`, (2) **pulled** `redis:7-alpine`, (3) created a private **network** so `web` reaches `redis` by name, (4) created the `redisdata` **volume**, and (5) started `redis` before `web` (`depends_on`). Each refresh calls Redis to increment the counter — proving the two containers are talking to each other. This is the entire Docker workflow (build → network → run) in one command.

---

## Key takeaways

- Docker packages apps into portable, lightweight containers.
- Containers share the host kernel; VMs boot a full OS — that's why containers are smaller and faster.
- Docker was needed to solve what VMs don't: consistent "ships-with-the-app" environments, high density, fast startup, and one-command setup.
- VMs and Docker are **complementary** — containers commonly run inside VMs.
- VMs come from VMware, Microsoft (Hyper-V), Oracle (VirtualBox), KVM, etc.; Docker comes from **Docker, Inc.**, with standards under OCI/CNCF.
- Today's alternatives to Docker include **Podman, containerd, CRI-O, and Buildah**.
- **Docker ≠ Kubernetes.** Docker builds and runs containers on one machine; Kubernetes orchestrates many containers across a cluster. They work **together** — you can't cleanly swap one for the other.
- The CLI talks to the daemon, which manages images and containers.

➡️ Next: [Module 02 — Installation & Setup](02-installation.md)
