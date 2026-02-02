<p align="center">
  <h1 align="center">vibe_in_vps</h1>
  <p align="center">
    <strong>Zero-ops deployment for the rest of us</strong>
  </p>
  <p align="center">
    Fork. Configure. Deploy. No DevOps knowledge required.
  </p>
</p>

<br />

Deploy your Dockerized app to a cheap VPS in under 10 minutes. Add GitHub secrets, click "Run workflow", and your app goes live on a Hetzner VPS with automated deployments on every push.

<br />

## Why vibe_in_vps?

| | |
|---|---|
| **No local tools** | Everything runs in GitHub Actions |
| **No manual server config** | Cloud-init handles all VPS setup |
| **No vendor lock-in** | Docker, Terraform, GitHub Actions |
| **Cost effective** | ~$7.50/month total |
| **Production ready** | Health checks, monitoring, deployment tracking |

<br />

## Quick Start

> **Setup time**: 5-10 minutes

### Prerequisites

- GitHub account
- [Hetzner Cloud account](https://console.hetzner.cloud/)
- SSH key pair (or generate one)
- Optional: [healthchecks.io](https://healthchecks.io) account for monitoring

### Setup Options

**Option 1: Interactive Wizard** (Recommended)

```bash
npm run setup-wizard
```

Step-by-step guided setup with navigation and progress tracking.

**Option 2: [Complete Setup Guide](docs/SETUP.md)**

Traditional documentation with screenshots and detailed explanations.

### Quick Steps

1. **Fork** this repository
2. **Add** 5 GitHub secrets (API tokens, SSH keys)
3. **Run** the setup workflow in GitHub Actions
4. **Add** 2 deployment secrets from workflow output
5. **Access** your deployed app at the provided IP

> **Note**: After forking, the deploy workflow may run and fail - this is expected. Complete the setup first.

<br />

## How It Works

```
You push code to GitHub
         |
         v
+----------------------------------+
|     GitHub Actions Workflow      |
|                                  |
|  1. Build Docker image           |
|  2. Push to GHCR                 |
|  3. SSH to VPS                   |
|  4. Pull & restart app           |
|  5. Ping healthchecks.io         |
|  6. Create deployment            |
+----------------------------------+
         |
         v
+----------------------------------+
|     Hetzner VPS (Running)        |
|                                  |
|     Docker + Your App            |
|     Exposed on port 80           |
+----------------------------------+
```

- **First-time setup**: Terraform provisions the VPS, cloud-init installs Docker
- **Subsequent deploys**: Just `git push` for automatic deployment in 2-3 minutes

<br />

## Project Structure

```
vibe_in_vps/
├── app/                          # Your application
│   ├── Dockerfile                # Required: port 3000, /health endpoint
│   └── ...
│
├── infra/terraform/              # Infrastructure as Code
│   ├── main.tf                   # VPS, firewall, monitoring
│   ├── variables.tf              # Configuration options
│   └── ...
│
├── deploy/                       # Deployment configuration
│   ├── docker-compose.yml        # Container orchestration
│   └── update.sh                 # Deployment script
│
└── .github/workflows/            # CI/CD pipelines
    ├── infrastructure.yml        # Provision infrastructure
    └── deploy.yml                # Deploy application
```

<br />

## Features

### Infrastructure

- Terraform provisions Hetzner VPS via GitHub Actions
- Cloud-init installs Docker and configures firewall
- Deployment secrets displayed in workflow summary
- State management via GitHub Actions artifacts

### Continuous Deployment

- Build Docker images on every push to main
- Push to GitHub Container Registry (GHCR)
- Deploy to VPS automatically via SSH
- Track deployments in GitHub UI
- Optional healthchecks.io integration

### Developer Experience

- No local tools required
- One-click setup and teardown
- Real-time logs in GitHub Actions
- Full deployment history

<br />

## App Requirements

Your application must have:

**1. A Dockerfile** that exposes port 3000 and includes a health check

**2. A `/health` endpoint** returning HTTP 200 with JSON:

```javascript
// Example: Node.js/Express
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

See [SETUP.md - Deploy Your Own App](docs/SETUP.md#step-7-deploy-your-own-app) for full examples.

<br />

## Cost Breakdown

| Service | Monthly Cost | Notes |
|---------|-------------:|-------|
| Hetzner CPX22 VPS | ~$7.50 | 2 vCPU, 4GB RAM, 80GB SSD |
| GitHub Actions | Free | 2,000 min/month (public repos) |
| GitHub Container Registry | Free | Public repos |
| healthchecks.io | Free | Up to 20 checks |
| **Total** | **~$7.50** | |

> **Budget option**: Hetzner CPX11 (~$4.50/month) with 2 vCPU, 2GB RAM works well for low-traffic apps.

<br />

## Common Operations

### Deploy Your App

```bash
# Replace /app contents, ensure Dockerfile + health endpoint
git push origin main
# Watch deployment in GitHub Actions
```

### Environment Variables

```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app && nano .env
docker compose restart app
```

### View Logs

```bash
ssh deploy@YOUR_VPS_IP
docker compose logs -f app
```

### Destroy Infrastructure

Go to **Actions** > **Provision Infrastructure** > Run workflow with "Destroy infrastructure" checked

<br />

## Troubleshooting

<details>
<summary><strong>App not accessible</strong></summary>

```bash
ssh deploy@YOUR_VPS_IP
docker compose ps        # Check if running
docker compose logs app  # Check logs
```
</details>

<details>
<summary><strong>Deployment failed</strong></summary>

1. Check GitHub Actions logs
2. Verify all secrets configured correctly
3. Test Docker build locally: `docker build -t test ./app`
</details>

<details>
<summary><strong>More help</strong></summary>

See [SETUP.md - Troubleshooting](docs/SETUP.md#troubleshooting) for detailed solutions.
</details>

<br />

## Architecture Decisions

Trade-offs made for simplicity:

| Decision | Trade-off |
|----------|-----------|
| Single server | No auto-scaling, single point of failure |
| SSH-based deployment | Simple to understand and debug |
| No zero-downtime deploys | Brief (~10s) downtime during updates |
| Terraform in CI | No local tools, state in GitHub artifacts |
| Artifact-based state | Auto-restored between runs (90-day retention) |

<br />

## Roadmap

- [ ] Cloudflare integration for custom domains + SSL
- [ ] Setup wizard for optional database (PostgreSQL, MySQL, Redis)
- [ ] Cost monitoring in Terraform outputs
- [ ] Multi-app support (multiple apps on same VPS)

<br />

## Documentation

| Document | Description |
|----------|-------------|
| [Setup Guide](docs/SETUP.md) | Step-by-step walkthrough |
| [Operations Runbook](docs/RUNBOOK.md) | Deployments, monitoring, troubleshooting |
| [Contributing Guide](docs/CONTRIBUTING.md) | Development workflow and standards |
| [Architecture](CLAUDE.md) | Technical context and trade-offs |

<br />

## Contributing

Contributions welcome! Please keep it simple (target audience: beginners), avoid DevOps complexity, and update documentation for all changes.

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

<br />

## License

MIT License - use freely for your projects.

<br />

## Support

- [Setup Guide](docs/SETUP.md) - Getting started help
- [Runbook](docs/RUNBOOK.md) - Operations reference
- [GitHub Issues](https://github.com/YOUR_USERNAME/vibe_in_vps/issues) - Bug reports
- [GitHub Discussions](https://github.com/YOUR_USERNAME/vibe_in_vps/discussions) - Questions

<br />

---

<p align="center">
  <strong>Built for developers who just want to deploy their apps without the DevOps headache.</strong>
</p>
