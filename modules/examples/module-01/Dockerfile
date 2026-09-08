# ─────────────────────────────────────────────────────────────────────────────
# Dockerfile — instructions Docker follows to BUILD an image of our app.
# Build it with:   docker build -t hello-docker:1.0 .
# Each line below becomes a cached "layer"; ordering them least- to most-changed
# keeps rebuilds fast.
# ─────────────────────────────────────────────────────────────────────────────

# 1) Base image: start from an official, small Python image pinned to a version.
#    "-slim" is a trimmed-down variant → smaller, faster to pull.
FROM python:3.12-slim

# 2) Set the working directory inside the image. Every following command runs
#    from /app, and it's created automatically if it doesn't exist.
WORKDIR /app

# 3) Copy ONLY the dependency list first. Because this rarely changes, Docker can
#    reuse the cached "pip install" layer on future builds when only code changes.
COPY requirements.txt .

# 4) Install dependencies at BUILD time. --no-cache-dir keeps the image smaller.
RUN pip install --no-cache-dir -r requirements.txt

# 5) Now copy the rest of the application source code into the image.
COPY . .

# 6) Document the port the app listens on (informational; publishing is done at run time).
EXPOSE 5000

# 7) The default command to run when a container starts from this image.
CMD ["python", "app.py"]
