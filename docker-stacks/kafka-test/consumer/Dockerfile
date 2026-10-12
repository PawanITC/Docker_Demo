# Kafka smoke test: consumer. Configured only through environment variables.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY consumer.py .

# Run as a non-root user.
RUN useradd --create-home --uid 1000 app
USER app

CMD ["python", "consumer.py"]
