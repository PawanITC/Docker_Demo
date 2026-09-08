# Docker End-to-End Course

A complete, practical Docker course that takes you from zero to deploying containerized applications in production. Every module includes **commands to run** and **explanations for the practicals**.

## How to use this course

1. Work through the modules **in order** — each one builds on the previous.
2. Run every command yourself. Docker is learned by doing, not by reading.
3. Each practical has a **Goal**, the **Commands**, and a **What just happened?** explanation.

## Prerequisites

- A machine running Windows, macOS, or Linux.
- Basic command-line comfort (navigating directories, running commands).
- ~10 GB of free disk space for images and containers.

## Course Modules

| #  | Module | What you'll learn |
|----|--------|-------------------|
| 01 | [Introduction to Docker](modules/01-introduction.md) | Containers vs VMs, core concepts, architecture |
| 02 | [Installation & Setup](modules/02-installation.md) | Installing Docker, verifying, first container |
| 03 | [Working with Images](modules/03-images.md) | Pulling, listing, inspecting, tagging images |
| 04 | [Working with Containers](modules/04-containers.md) | Running, stopping, logs, exec, lifecycle |
| 05 | [Writing Dockerfiles](modules/05-dockerfiles.md) | Building custom images, instructions, layers |
| 06 | [Data & Volumes](modules/06-volumes.md) | Persisting data, bind mounts, named volumes |
| 07 | [Networking](modules/07-networking.md) | Bridge, host networks, container communication |
| 08 | [Docker Compose](modules/08-compose.md) | Multi-container apps, YAML, one-command stacks |
| 09 | [Registries & Distribution](modules/09-registry.md) | Docker Hub, pushing, pulling, private registries |
| 10 | [Best Practices & Production](modules/10-best-practices.md) | Image optimization, security, healthchecks |

## Quick reference

```bash
docker --version          # Check installed version
docker info               # Show system-wide information
docker ps                 # List running containers
docker images             # List local images
docker system prune       # Clean up unused data
```

---

Happy shipping! 🐳
