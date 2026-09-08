# Module 01 — Introduction to Docker

## Learning objectives

- Understand what Docker is and the problem it solves.
- Know the difference between containers and virtual machines.
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

## 3. Core concepts

- **Image** — a read-only template with instructions for creating a container (e.g. `nginx`, `python:3.12`).
- **Container** — a running (or stopped) instance of an image.
- **Dockerfile** — a text file with instructions to build an image.
- **Registry** — a store for images (e.g. Docker Hub).
- **Docker Engine** — the background service (daemon) that builds and runs containers.

---

## 4. Docker architecture

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

## Key takeaways

- Docker packages apps into portable, lightweight containers.
- Containers share the host kernel; VMs don't.
- The CLI talks to the daemon, which manages images and containers.

➡️ Next: [Module 02 — Installation & Setup](02-installation.md)
