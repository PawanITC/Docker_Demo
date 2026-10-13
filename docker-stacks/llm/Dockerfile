# Ollama LLM server that downloads its model(s) on first start.
FROM ollama/ollama:0.40.3

# Space-separated list of models to pull (see https://ollama.com/library).
# Override it in docker-compose.yml without rebuilding. Options:
#   General chat:
#     qwen2.5:0.5b           ~0.4 GB download, ~1 GB RAM
#     llama3.2:1b            ~1.3 GB, ~2 GB RAM   (default)
#     llama3.2:3b            ~2 GB,   ~4 GB RAM
#     llama3.1:8b            ~4.7 GB, ~8 GB RAM
#   Programming / debugging:
#     qwen2.5-coder:1.5b     ~1 GB,   ~2-3 GB RAM  (t4g.medium)
#     qwen2.5-coder:3b       ~1.9 GB, ~4 GB RAM    (t4g.large)
#     qwen2.5-coder:7b       ~4.7 GB, ~8 GB RAM    (t4g.xlarge)
#     devstral-small-2:24b   ~15 GB,  ~20 GB RAM   (t4g.2xlarge)
#     qwen3-coder:30b        ~19 GB,  ~24 GB RAM   (t4g.2xlarge) best local coder
#     qwen3-coder-next       ~52 GB,  ~64 GB RAM   (r7g.2xlarge)
# Example: OLLAMA_MODELS_TO_PULL="llama3.2:1b qwen2.5-coder:7b"
ENV OLLAMA_MODELS_TO_PULL="llama3.2:1b" \
    OLLAMA_HOST=0.0.0.0:11434 \
    OLLAMA_KEEP_ALIVE=10m

COPY entrypoint.sh /entrypoint.sh
# Strip Windows CRLF line endings (git autocrlf) so the script runs in Linux.
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Downloaded model weights live here.
VOLUME /root/.ollama

EXPOSE 11434

ENTRYPOINT ["/entrypoint.sh"]
