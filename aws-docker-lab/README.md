# AWS Docker Lab — Terraform + CI/CD

Run Docker in AWS, controlled from your local machine, with **every stack
created and destroyed through a GitHub Actions pipeline** (no local Terraform
needed after the one-time bootstrap, and no long-lived AWS keys — auth is via
GitHub OIDC).

Companion to `presentations/module-02-installation.html` → **Cloud Deep Dive**.

## Stacks (cheapest cost noted in each `main.tf` header)

| Dir | What it is | Docker daemon you control? | Cheapest ~cost |
|-----|------------|----------------------------|----------------|
| `01-ec2-docker` | EC2 + Docker Engine (SSH/`docker context`) | ✅ Yes | ~$6/mo 24×7 · **pennies if stopped when idle** |
| `02-ec2-spot-docker` | Same as 01 but **Spot** capacity | ✅ Yes | **Lowest compute** — up to ~90% off (can be interrupted) |
| `03-lightsail-vm` | Managed Ubuntu VM + Docker | ✅ Yes | **~$3.50/mo flat** (nano, IP + egress included) |
| `04-lightsail-container` | "Just run my image", no VM | ❌ No | ~$7/mo flat (nano); destroy when idle |
| `05-ecs-fargate` | AWS-native serverless containers | ❌ No | ~$9/mo 24×7 (256/512, no ALB); destroy when idle |

> **Cheapest for a throwaway lab:** `02-ec2-spot-docker`.
> **Cheapest predictable bill:** `03-lightsail-vm` (nano, ~$3.50/mo flat).
> **Cheapest if always-on tiny:** stop an `01` EC2 when idle (per-second billing).

State backend is **S3 with native locking** (`use_lockfile=true`) — no DynamoDB,
so **no lock-table cost**.

## One-time bootstrap (run locally, once)

Creates the S3 state bucket + the GitHub OIDC role the pipeline assumes.

```bash
cd aws-docker-lab/bootstrap
cp terraform.tfvars.example terraform.tfvars   # edit: unique bucket name, repo
aws configure                                   # or use an existing profile
terraform init
terraform apply
terraform output                                # copy the values it prints
```

Then in GitHub → **Settings → Secrets and variables → Actions → Variables**, add:

| Variable | Value |
|----------|-------|
| `AWS_ROLE_ARN` | `gha_role_arn` output |
| `TF_STATE_BUCKET` | `state_bucket` output |
| `AWS_REGION` | e.g. `ap-south-1` |
| `SSH_CIDR` | `your.public.ip/32` (SSH + app ingress — **never** `0.0.0.0/0`) |
| `EC2_KEY_NAME` | *(optional)* existing EC2 key pair; leave unset for SSM-only access |

## Run / destroy infra from CI/CD

**Actions tab → “Terraform Infra Control” → Run workflow:**

- **stack** — which of the five to act on
- **action** — `plan`, `apply`, or `destroy`
- **confirm_destroy** — for `destroy`, type the exact stack name (safety guard)

`apply` prints the stack outputs (public IP, SSH/SSM command, app URL, ECR URL).
Because state is in S3, you can `destroy` a stack in a later run — the pipeline
reuses the same state.

> Tip: add a GitHub **Environment** with required reviewers and reference it in
> `.github/workflows/infra.yml` to require manual approval before `apply`/`destroy`.

## Control the remote Docker Engine from Windows (stacks 01–03)

After `apply`, use the `docker_context_command` output, e.g.:

```powershell
docker context create aws-docker --docker "host=ssh://ubuntu@<PUBLIC_IP>"
docker context use aws-docker
docker ps                                   # now runs against the EC2 daemon
docker run -d --name nginx -p 8080:80 nginx # container runs on AWS, not locally
# open http://<PUBLIC_IP>:8080
```

Never expose Docker's TCP port 2375 to the Internet — use SSH, as above.

## Deploy your own image (stacks 04 / 05)

Build locally, push to ECR (created by stack 05) or via the Lightsail plugin
(stack 04), then set `container_image` and re-run `apply`. For Fargate, after
pushing a new `:latest`, force a redeploy with the `force_new_deployment`
command from the outputs.

## Notes / gotchas

- **OIDC `Not authorized to perform sts:AssumeRoleWithWebIdentity`:** if your org
  customizes the OIDC *subject claim* to embed immutable IDs, the token's `sub`
  is `repo:<owner>@<owner_id>/<repo>@<repo_id>:ref:...`, not `repo:<owner>/<repo>:...`.
  Set `github_repo` in the bootstrap to the ID-augmented form (e.g.
  `PawanITC@239576472/Docker_Demo@1361482141`) so the trust `sub` pattern matches.
- `t4g` is **ARM64** — your images must support ARM64, or switch `instance_type`
  to `t3.micro` (x86).
- No **NAT Gateway** anywhere (it would add cost); tasks/instances sit in a
  public subnet with an Internet Gateway.
- `terraform.tfvars` and all state files are gitignored; only `*.tfvars.example`
  is committed.
```
