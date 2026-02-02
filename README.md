# vibe_in_vps

> **Zero-ops deployment**: Fork → Configure → Deploy. No DevOps knowledge required. ✨

Deploy your Dockerized app to a cheap VPS in under 10 minutes. Just add GitHub secrets, click "Run workflow", and your app goes live on a Hetzner VPS with automated deployments.

---

## What is This?

A deployment template that automates the entire infrastructure and deployment pipeline:

- **Infrastructure**: Terraform provisions Hetzner VPS (~$5/month) via GitHub Actions
- **CI/CD**: Automatic builds and deployments on every git push
- **Monitoring**: Optional healthchecks.io integration for uptime alerts
- **Runtime**: Docker + Docker Compose (no Kubernetes complexity)

**Core Philosophy**: Boring, proven tools. Simple enough for frontend developers. Powerful enough for production.

---

## Why Use This?

✅ **No local tools** - Everything runs in GitHub Actions (no Terraform CLI, Docker, or SSH setup)
✅ **No manual server config** - Cloud-init handles all VPS setup automatically
✅ **No vendor lock-in** - Uses open standards (Docker, Terraform, GitHub Actions)
✅ **Cost effective** - ~$7.50/month for VPS, everything else is free
✅ **Production ready** - Health checks, monitoring, deployment tracking

---

## Quick Start

**Setup time**: 5-10 minutes

### Requirements

- GitHub account
- Hetzner Cloud account ([sign up](https://console.hetzner.cloud/))
- SSH key pair (or generate one)
- **Optional**: healthchecks.io account for monitoring

### Setup Process

1. **Fork this repository**
2. **Add 5 GitHub secrets** (API tokens, SSH keys)
3. **Run the setup workflow** in GitHub Actions
4. **Add 2 deployment secrets** from workflow output
5. **Access your deployed app** at the provided IP

👉 **[Complete Setup Guide →](docs/SETUP.md)**

The setup guide walks you through every step with screenshots and troubleshooting.

**Note**: After forking, the deploy workflow may run and fail - this is expected! It needs the initial setup to be completed first. Just follow the setup guide and it will work on subsequent pushes.

---

## How It Works

```
┌─────────────────┐
│  You push code  │
│   to GitHub     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│    GitHub Actions Workflow      │
│  ┌───────────────────────────┐  │
│  │ 1. Build Docker image     │  │
│  │ 2. Push to GHCR           │  │
│  │ 3. SSH to VPS             │  │
│  │ 4. Pull & restart app     │  │
│  │ 5. Ping healthchecks.io   │  │
│  │ 6. Create deployment      │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│      Hetzner VPS (Running)      │
│  ┌───────────────────────────┐  │
│  │  Docker + Your App        │  │
│  │  Exposed on port 80       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**First-time setup**: Terraform provisions the VPS, cloud-init installs Docker. Push code to trigger first deployment.

**Subsequent deploys**: Just `git push` → automatic deployment in 2-3 minutes.

---

## Project Structure

```
vibe_in_vps/
├── app/                    # Your application
│   ├── Dockerfile          # Required: exposes port 3000, has /health endpoint
│   └── ...                 # Your app code
│
├── infra/terraform/        # Infrastructure as Code
│   ├── main.tf            # VPS, firewall, monitoring
│   ├── variables.tf       # Configuration options
│   └── ...
│
├── deploy/                 # Deployment configuration
│   ├── docker-compose.yml # Container orchestration
│   └── update.sh          # Deployment script
│
└── .github/workflows/      # CI/CD pipelines
    ├── setup.yml          # Provision infrastructure
    └── deploy.yml         # Deploy application
```

---

## Documentation

- **[Complete Setup Guide](docs/SETUP.md)** - Step-by-step walkthrough (start here!)
- **[Operations Runbook](docs/RUNBOOK.md)** - Deployments, monitoring, troubleshooting
- **[Contributing Guide](docs/CONTRIBUTING.md)** - Development workflow and standards
- **[Architecture Decisions](CLAUDE.md)** - Technical context and trade-offs

---

## Features

### Automated Infrastructure

- **Terraform** provisions Hetzner VPS via GitHub Actions
- **Cloud-init** installs Docker and sets up firewall automatically
- **Deployment secrets** displayed in workflow summary for easy configuration
- **State management** via GitHub Actions artifacts

### Continuous Deployment

- **Build** Docker images on every push to main
- **Push** to GitHub Container Registry (GHCR)
- **Deploy** to VPS automatically via SSH
- **Track** deployments in GitHub UI
- **Monitor** with optional healthchecks.io integration

### Developer Experience

- **No local tools required** - Everything in GitHub Actions
- **One-command setup** - Just click "Run workflow"
- **One-command destroy** - Clean teardown via workflow
- **Real-time logs** - Watch deployments in GitHub Actions
- **Deployment history** - See all deployments in GitHub UI

---

## Requirements for Your App

Your application must:

1. **Have a Dockerfile** that:
   - Exposes port 3000
   - Includes a health check
   - Builds successfully

2. **Include a `/health` endpoint** that:
   - Responds with HTTP 200
   - Returns JSON: `{"status": "ok"}`

**Example** (Node.js/Express):
```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

👉 See [docs/SETUP.md#step-7-deploy-your-own-app](docs/SETUP.md#step-7-deploy-your-own-app) for full examples.

---

## Cost Breakdown

| Service | Monthly Cost | Notes |
|---------|--------------|-------|
| **Hetzner CPX22 VPS** | ~$7.50 | 2 vCPU, 4GB RAM, 80GB SSD |
| GitHub Actions | Free | 2,000 minutes/month (public repos) |
| GitHub Container Registry | Free | Public repos |
| healthchecks.io | Free (optional) | Up to 20 checks |
| **Total** | **~$7.50** | |

**Cheaper option**: Hetzner CPX11 (~$4.50/month) - 2 vCPU, 2GB RAM - good for low-traffic apps.

---

## Common Operations

### Deploy Your Own App

1. Replace contents of `/app` directory
2. Ensure Dockerfile exposes port 3000 and has health endpoint
3. `git push origin main`
4. Watch deployment in GitHub Actions

### Add Environment Variables

```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
nano .env
docker compose restart app
```

### View Logs

```bash
ssh deploy@YOUR_VPS_IP
docker compose logs -f app
```

### Rollback Deployment

See [docs/RUNBOOK.md#rollback-procedures](docs/RUNBOOK.md#rollback-procedures)

### Destroy Infrastructure

1. Go to Actions → Provision Infrastructure
2. Run workflow with "Destroy infrastructure" checked

---

## Troubleshooting

### App Not Accessible

```bash
ssh deploy@YOUR_VPS_IP
docker compose ps        # Check if running
docker compose logs app  # Check logs
```

### Deployment Failed

1. Check GitHub Actions logs
2. Verify all secrets configured correctly
3. Test Docker build locally: `docker build -t test ./app`

### More Help

See [docs/SETUP.md#troubleshooting](docs/SETUP.md#troubleshooting) for detailed solutions.

---

## Roadmap

- [ ] Cloudflare integration for custom domains + SSL
- [ ] Setup wizard for optional database (PostgreSQL, MySQL, Redis)
- [ ] Cost monitoring in Terraform outputs
- [ ] Multi-app support (multiple apps on same VPS)

---

## Architecture Decisions

Key trade-offs made for simplicity:

- **Single server** → No auto-scaling, single point of failure
- **No zero-downtime deploys** → Brief (~10s) downtime during updates
- **SSH-based deployment** → Simple to understand and debug
- **Terraform in CI** → No local tools needed, state in GitHub artifacts
- **Artifact-based state** → Automatically restored between workflow runs (90-day retention)

See [CLAUDE.md](CLAUDE.md) for full rationale.

## Terraform State Management

State is automatically managed via GitHub Actions artifacts:

- **Saved**: After every successful `terraform apply` or `terraform destroy`
- **Restored**: Before every workflow run from the most recent artifact
- **Retention**: 90 days (configurable in `.github/workflows/setup.yml`)
- **Location**: Actions → Workflow run → Artifacts → `terraform-state`

**No manual state management needed!** The workflow handles everything automatically.

---

## Contributing

Contributions welcome! Please:

1. Keep it simple (target audience: beginners)
2. Avoid adding DevOps complexity
3. Update documentation for all changes
4. Test end-to-end before submitting PR

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

---

## License

MIT License - use freely for your projects!

---

## Support

- **Setup help**: [docs/SETUP.md](docs/SETUP.md)
- **Operations**: [docs/RUNBOOK.md](docs/RUNBOOK.md)
- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/vibe_in_vps/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/vibe_in_vps/discussions)

---

**Built for developers who just want to deploy their apps without the DevOps headache.** 🚀
