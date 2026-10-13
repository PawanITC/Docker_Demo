# LLM (Ollama + Open WebUI)

Runs a local LLM in Docker. On its first start, **Ollama** downloads the model
to a named volume, so later starts are quick. **Open WebUI** gives you a
ChatGPT-style chat page that uses it.

| Service | URL / Port | Volume |
|---|---|---|
| Ollama API | http://localhost:11434 | `stack_ollama-data` (model weights) |
| Open WebUI | http://localhost:3001 | `stack_open-webui-data` (users, chats) |

## Run

```bash
docker compose up -d --build
docker compose logs -f ollama      # wait for "Ready. Models on disk:"
```

Open http://localhost:3001. The first account you create becomes the admin.
Then pick `llama3.2:1b` and start chatting.

## Use the API

```bash
# One-shot completion
curl localhost:11434/api/generate -d '{"model":"llama3.2:1b","prompt":"Why is the sky blue?","stream":false}'

# OpenAI-compatible endpoint (works with the openai SDKs)
curl localhost:11434/v1/chat/completions -H "Content-Type: application/json" \
  -d '{"model":"llama3.2:1b","messages":[{"role":"user","content":"Hello"}]}'

# Chat in the terminal
docker compose exec ollama ollama run llama3.2:1b
```

## Open it from EC2 (SSH tunnel)

When the stack runs on the EC2 host, forward its ports to your laptop through
AWS SSM. You don't need to open any ports in the security group.

1. **Start the stack on EC2** (Docker context `aws-docker` points at the instance):

   ```bash
   docker context use aws-docker
   cd docker-stacks/llm
   docker compose up -d --build
   docker compose logs -f ollama      # wait for "Ready. Models on disk:"
   ```

2. **Open the tunnel** from your terminal and leave it running (Ctrl+C closes it):

   ```bash
   ssh -N -L 3001:localhost:3001 -L 11434:localhost:11434 <instance-id>
   ```

   This uses the `Host i-...` entry in `~/.ssh/config`, which connects through
   `aws ssm start-session`.

3. **Open http://localhost:3001** on your laptop. `curl localhost:11434/api/tags`
   also works locally while the tunnel is up.

Without SSH, you can forward one port through SSM directly:

```bash
aws ssm start-session --target <instance-id> --region ap-south-1   --document-name AWS-StartPortForwardingSession   --parameters '{"portNumber":["3001"],"localPortNumber":["3001"]}'
```

**Keep the instance ID in sync.** The `Host` line in `~/.ssh/config` and the
`aws-docker` Docker context must use the ID of the current instance. Look it up,
then fix whichever one is stale:

```bash
aws ec2 describe-instances --region ap-south-1 --filters Name=instance-state-name,Values=running   --query "Reservations[].Instances[].[InstanceId,Tags[?Key=='Name']|[0].Value]" --output table

docker context rm aws-docker
docker context create aws-docker --docker "host=ssh://<instance-id>"
```

> **Size the instance first.** The lab's default `t4g.micro` has only 1 GB RAM,
> which is not enough for any model plus Open WebUI. Set `instance_type` in
> `aws-docker-lab/01-ec2-docker/terraform.tfvars` to fit the model (see
> the table below), and stop the instance when idle because larger types cost more.

## Models for programming and debugging

These are coding-tuned models from the Ollama library. Bigger models are
better at multi-file reasoning and finding bugs. All of them run on CPU, but
a GPU makes them much faster.

| Model | Download | RAM needed | EC2 (ARM, CPU) | EC2 cost (ap-south-1) | Notes |
|---|---|---|---|---|---|
| `qwen2.5-coder:1.5b` | ~1 GB | ~2–3 GB | `t4g.small` (2 GB) is tight; `t4g.medium` (4 GB) | $0.0112/hr (~$8/mo); $0.0224/hr (~$16/mo) | Autocomplete, small snippets |
| `qwen2.5-coder:3b` | ~1.9 GB | ~4 GB | `t4g.medium` (4 GB) is tight; `t4g.large` (8 GB) | $0.0224/hr (~$16/mo); $0.0448/hr (~$33/mo) | Smallest that's useful for explaining and fixing code |
| `qwen2.5-coder:7b` | ~4.7 GB | ~8 GB | `t4g.xlarge` (16 GB) | $0.0896/hr (~$65/mo) | Good balance; the best choice under 16 GB |
| `devstral-small-2:24b` | ~15 GB | ~20 GB | `t4g.2xlarge` (32 GB) | $0.1792/hr (~$131/mo) | Built for agentic coding (editing and fixing whole repos) |
| `qwen3-coder:30b` | ~19 GB | ~24 GB | `t4g.2xlarge` (32 GB) | $0.1792/hr (~$131/mo) | **Best local coder here.** It's MoE (only ~3B active), so it's fast for its size |
| `qwen3-coder-next` | ~52 GB | ~64 GB | `r7g.2xlarge` (64 GB) or a GPU box | $0.3003/hr (~$219/mo) | Strongest option; needs a big machine |

> Costs are On-Demand Linux prices in ap-south-1 (Mumbai), from the AWS Pricing
> API in October 2026. The monthly figure assumes it runs 24x7 (730 hours).
> Stopped instances cost nothing for compute, so running 2–3 hours a day costs
> about a tenth of that. Spot (`02-ec2-spot-docker`) is often 60–70% cheaper.
> EBS storage is billed separately: gp3 is ~$0.09/GB-month in Mumbai, so 30 GB
> for model files costs ~$2.7/mo.

Try one by setting it in `docker-compose.yml`, then run `docker compose up -d`:

```yaml
    environment:
      OLLAMA_MODELS_TO_PULL: "qwen2.5-coder:7b"
```

## Change or add models

Set `OLLAMA_MODELS_TO_PULL` in `docker-compose.yml` to a space-separated list
from https://ollama.com/library and run `docker compose up -d`:

| Model | Download | RAM (CPU) |
|---|---|---|
| `qwen2.5:0.5b` | ~0.4 GB | ~1 GB |
| `llama3.2:1b` (default) | ~1.3 GB | ~2 GB |
| `llama3.2:3b` | ~2 GB | ~4 GB |
| `llama3.1:8b` | ~4.7 GB | ~8 GB |

You can also pull models on demand:

```bash
docker compose exec ollama ollama pull qwen2.5:0.5b
docker compose exec ollama ollama list
docker compose exec ollama ollama rm llama3.2:1b
```

## GPU

The stack runs on CPU by default. On a machine with an NVIDIA GPU and the
NVIDIA Container Toolkit (on Windows, Docker Desktop with WSL2), uncomment the
`deploy:` block in `docker-compose.yml`.

## Stop / clean up

```bash
docker compose down        # keep models and chats
docker compose down -v     # delete them too (models must be downloaded again)
```
