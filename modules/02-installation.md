# Module 02 — Installation & Setup

## Learning objectives

- Install Docker on your operating system.
- Verify the installation.
- Understand Docker Desktop vs Docker Engine.

---

## 1. Which Docker do I need?

- **Docker Desktop** — the easiest option for **Windows and macOS**. Includes the engine, CLI, Compose, and a GUI.
- **Docker Engine** — the core engine for **Linux servers** (no GUI).

---

## 2. Installation

### Windows / macOS

1. Download **Docker Desktop** from https://www.docker.com/products/docker-desktop
2. Run the installer and follow the prompts.
3. On Windows, enable **WSL 2** when asked (recommended backend).
4. Launch Docker Desktop and wait for the whale icon to say "Docker Desktop is running".

### Linux (Ubuntu/Debian) — install Docker Engine

**Commands:**

```bash
# Remove any old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install using the official convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# (Optional) Run docker without sudo
sudo usermod -aG docker $USER
newgrp docker
```

**What just happened?**
The convenience script adds Docker's official package repository and installs the engine, CLI, and containerd. Adding your user to the `docker` group lets you run `docker` commands without `sudo`.

---

## Practical 2.1 — Verify the installation

**Goal:** Make sure Docker is installed and running.

**Commands:**

```bash
docker --version
docker compose version
docker run hello-world
```

**What just happened?**
- `docker --version` prints the installed engine version.
- `docker compose version` confirms Compose (v2, built into the CLI) is available.
- `docker run hello-world` does a full end-to-end test: pull an image and run a container.

---

## Practical 2.2 — Explore system state

**Goal:** Learn the commands that show what Docker is doing.

**Commands:**

```bash
docker info            # System-wide info
docker ps              # Running containers
docker ps -a           # All containers (including stopped)
docker images          # Local images
```

**What just happened?**
`docker info` summarizes the engine's configuration and resource usage. `docker ps` lists only **running** containers; adding `-a` includes **stopped** ones. `docker images` lists images cached locally.

---

## Practical 2.3 — Configure resources (Docker Desktop)

**Goal:** Adjust CPU/memory limits so builds don't starve your machine.

**Steps:**
1. Open Docker Desktop → **Settings** → **Resources**.
2. Set CPUs and Memory to sensible values (e.g. 4 CPUs, 4 GB).
3. Click **Apply & Restart**.

**What just happened?**
Docker Desktop runs a lightweight Linux VM. These sliders control how much of your host's resources that VM — and therefore your containers — may use.

---

## Key takeaways

- Desktop for Windows/macOS; Engine for Linux servers.
- `docker run hello-world` is the definitive "is it working?" test.
- Know `docker info`, `ps`, `ps -a`, and `images` cold.

➡️ Next: [Module 03 — Working with Images](03-images.md)
