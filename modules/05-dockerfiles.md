# Module 05 — Writing Dockerfiles

## Learning objectives

- Understand every common Dockerfile instruction.
- Build your own image from a Dockerfile.
- Grasp the layer cache and how to use `.dockerignore`.

---

## 1. Dockerfile instructions

| Instruction | Purpose |
|-------------|---------|
| `FROM` | Base image to build on |
| `WORKDIR` | Set the working directory |
| `COPY` / `ADD` | Copy files into the image |
| `RUN` | Execute a command at **build** time |
| `ENV` | Set environment variables |
| `EXPOSE` | Document the port the app listens on |
| `CMD` | Default command at **run** time |
| `ENTRYPOINT` | Fixed executable at **run** time |

> **CMD vs RUN:** `RUN` executes while building the image; `CMD` defines what runs when the container starts.

---

## Practical 5.1 — Build a Python web app image

**Goal:** Containerize a small Flask app.

**Step 1 — create the app files** in an empty folder:

`app.py`
```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Docker! 🐳"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

`requirements.txt`
```
flask==3.0.3
```

`Dockerfile`
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

**Step 2 — build and run:**

```bash
docker build -t my-flask-app:1.0 .
docker run -d --name flask -p 5000:5000 my-flask-app:1.0
```

Open http://localhost:5000

**What just happened?**
`docker build -t my-flask-app:1.0 .` reads the `Dockerfile` in the current directory (`.`) and executes each instruction as a layer: start from Python, set the workdir, copy requirements, install them, copy the code, and set the default command. The result is a tagged image you then run as a container.

---

## Practical 5.2 — Observe the layer cache

**Goal:** See why copying `requirements.txt` before the code matters.

**Commands:**

```bash
# Change app.py (edit the message), then rebuild:
docker build -t my-flask-app:1.1 .
```

**What just happened?**
Docker caches each layer. Because `requirements.txt` didn't change, the expensive `pip install` layer is reused from cache — only the `COPY . .` layer and below rebuild. **Ordering instructions from least- to most-frequently-changed** keeps builds fast.

---

## Practical 5.3 — Add a .dockerignore

**Goal:** Keep junk out of the build context.

Create `.dockerignore`:
```
__pycache__/
*.pyc
.git
.env
venv/
```

**What just happened?**
Before building, Docker sends the "build context" (your folder) to the daemon. `.dockerignore` excludes files you don't want copied or transferred — speeding builds and avoiding leaking secrets like `.env`.

---

## Practical 5.4 — Multi-stage build (smaller images)

**Goal:** Produce a lean final image by discarding build tools.

`Dockerfile`
```dockerfile
# Stage 1: build
FROM node:20 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: runtime (only the built output)
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

```bash
docker build -t my-frontend:1.0 .
docker images my-frontend
```

**What just happened?**
The first stage installs dependencies and builds the app. The second stage starts fresh from a tiny nginx image and copies **only the build output** with `--from=build`. All the heavy build tooling is left behind, so the final image is dramatically smaller.

---

## Key takeaways

- `docker build -t name:tag .` turns a Dockerfile into an image.
- Order layers least- to most-changed to maximize cache hits.
- `.dockerignore` trims the build context; multi-stage builds trim the image.

➡️ Next: [Module 06 — Data & Volumes](06-volumes.md)
