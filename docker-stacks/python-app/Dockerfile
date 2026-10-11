# Small Flask API that stores a visit counter on a volume.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DATA_DIR=/data

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Run as a non-root user. /data is created and owned by that user BEFORE the
# VOLUME line, so a new named volume inherits the correct ownership.
RUN useradd --create-home --uid 1000 app \
 && mkdir -p /data && chown app:app /data
USER app

VOLUME /data

EXPOSE 5000

HEALTHCHECK --interval=15s --timeout=3s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
