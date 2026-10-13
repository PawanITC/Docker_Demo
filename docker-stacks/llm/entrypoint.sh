#!/bin/sh
# Start the Ollama server, then pull every model in $OLLAMA_MODELS_TO_PULL.
# Models already on the volume are only re-checked, not re-downloaded.
set -e

ollama serve &
SERVER_PID=$!

until ollama list >/dev/null 2>&1; do sleep 1; done

for model in $OLLAMA_MODELS_TO_PULL; do
  echo "Pulling model: $model"
  ollama pull "$model" || echo "WARNING: could not pull $model (offline?)"
done

echo "Ready. Models on disk:"
ollama list

wait "$SERVER_PID"
