<h1 align="center">vibe_in_vps</h1>

<p align="center">
  <strong>Zero-ops deployment for the rest of us</strong>
</p>

<p align="center">
  Deploy your Dockerized app to a cheap VPS in under 10 minutes.<br />
  No DevOps knowledge required. No complex setup. Just push and ship.
</p>

<p align="center">
  <a href="https://github.com/filipegalo/vibe_in_vps/actions/workflows/deploy.yml">
    <img src="https://github.com/filipegalo/vibe_in_vps/actions/workflows/deploy.yml/badge.svg" alt="Deploy Status" />
  </a>
  <a href="https://github.com/filipegalo/vibe_in_vps/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT" />
  </a>
  <a href="https://github.com/filipegalo/vibe_in_vps/stargazers">
    <img src="https://img.shields.io/github/stars/filipegalo/vibe_in_vps?style=social" alt="GitHub Stars" />
  </a>
</p>

<br />

<p align="center">
  <a href="#-quick-start"><strong>Quick Start</strong></a> ·
  <a href="docs/SETUP.md"><strong>Setup Guide</strong></a> ·
  <a href="docs/RUNBOOK.md"><strong>Runbook</strong></a> ·
  <a href="#-roadmap"><strong>Roadmap</strong></a> ·
  <a href="docs/CONTRIBUTING.md"><strong>Contributing</strong></a>
</p>

<br />

---

<br />

## Why vibe_in_vps?

> **The Problem**: You built something cool. Now you need to deploy it. Suddenly you're neck-deep in Kubernetes, AWS consoles, and YAML files. You just wanted to ship your app.

> **The Solution**: Fork this repo, add 4 secrets, run a workflow. Done. Your app is live.

<br />

| | |
|:---:|:---|
| **No Local Tools** | Everything runs in GitHub Actions - no CLI installs needed |
| **No Manual Config** | Cloud-init handles all VPS setup automatically |
| **No Vendor Lock-in** | Standard Docker, Terraform, GitHub Actions |
| **Cost Effective** | €7.37/month total (or ~€4.50 for small apps) |
| **Production Ready** | Health checks, monitoring, deployment tracking |

<br />

## 🎯 See It In Action

> **Live Demo**: [vibe-in-vps.com](https://vibe-in-vps.com)
> **Demo Repository**: [filipegalo/vibe_in_vps_demo](https://github.com/filipegalo/vibe_in_vps_demo)

This is a real deployment using this template. Browse the demo repository to see:
- Complete workflow history and deployment logs
- Terraform infrastructure setup
- GitHub Actions configuration in production
- Actual deployment times and process

<br />

## How It Works

```
                          You push code to GitHub
                                    |
                                    v
                    +-------------------------------+
                    |    GitHub Actions Workflow    |
                    |                               |
                    |   1. Build Docker image       |
                    |   2. Push to GHCR             |
                    |   3. SSH to VPS               |
                    |   4. Pull & restart app       |
                    |   5. Ping healthchecks.io     |
                    |   6. Create deployment        |
                    +-------------------------------+
                                    |
                                    v
                    +-------------------------------+
                    |    Hetzner VPS (Running)      |
                    |                               |
                    |      Docker + Your App        |
                    |      Exposed on port 80       |
                    +-------------------------------+
```

- **First-time setup**: Terraform provisions the VPS, cloud-init installs Docker
- **Subsequent deploys**: Just `git push` for automatic deployment in 2-3 minutes

<br />

---

<br />

## Quick Start

> **Setup time**: 5-10 minutes

<br />

### Prerequisites

- GitHub account
- [Hetzner Cloud account](https://hetzner.cloud/?ref=IyoJUUeCm9RA) (€7.37/month) — [Use this referral](https://hetzner.cloud/?ref=IyoJUUeCm9RA) to get €20 credit when signing up
- SSH key pair (or generate one)
- Optional: [healthchecks.io](https://healthchecks.io) account for monitoring

<br />

### Get Started

<table>
<tr>
<td width="50%">

#### Option 1: Interactive Wizard

```bash
npm run setup-wizard
```

Step-by-step guided setup with navigation and progress tracking.

</td>
<td width="50%">

#### Option 2: Manual Setup

Follow the [Complete Setup Guide](docs/SETUP.md) with screenshots and detailed explanations.

</td>
</tr>
</table>

<br />

### Quick Steps

```
1. Fork this repository
        |
2. Add 4 GitHub secrets (API tokens, SSH keys)
        |
3. Run the setup workflow in GitHub Actions
        |
4. Add 2 deployment secrets from workflow output
        |
5. Access your deployed app at the provided IP
```

> **Note**: After forking, the deploy workflow may run and fail - this is expected. Complete the setup first.

<br />

---

<br />

## Features

### Infrastructure

- **Terraform Provisioning** - VPS created via GitHub Actions, no local tools
- **Automatic Setup** - Cloud-init installs Docker and configures firewall
- **Secret Management** - Deployment secrets displayed in workflow summary
- **State Persistence** - Terraform state managed via GitHub Actions artifacts

### Continuous Deployment

- **Auto Build** - Docker images built on every push to main
- **Container Registry** - Push to GitHub Container Registry (GHCR)
- **Auto Deploy** - Deploy to VPS automatically via SSH
- **Deployment Tracking** - Full history visible in GitHub UI
- **Health Monitoring** - Optional healthchecks.io integration

### Developer Experience

- **Zero Local Setup** - No CLI tools or dependencies required
- **One-Click Operations** - Setup and teardown via GitHub Actions
- **Real-Time Logs** - Stream logs directly from GitHub Actions
- **Full History** - Complete deployment audit trail

### Optional Databases

- **PostgreSQL** - Production-ready relational database
- **MySQL** - Alternative relational database
- **Redis** - In-memory cache and message broker
- **Interactive Setup** - Toggle databases on/off in setup wizard
- **Auto-Configuration** - Automatically updates docker-compose.yml
- **Secure by Default** - Internal network only, no external ports
- **Automated Backups** - Built-in backup scripts with 7-day retention

<br />

---

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

---

<br />

## App Requirements

Your application must have:

> **Building a new app?** Check [`app/PROMPT.md`](app/PROMPT.md) for ready-to-use AI coding assistant prompts that ensure your app meets all deployment requirements.

<details open>
<summary><strong>1. A Dockerfile</strong> that exposes port 3000</summary>

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

</details>

<details open>
<summary><strong>2. A <code>/health</code> endpoint</strong> returning HTTP 200 with JSON</summary>

```javascript
// Example: Node.js/Express
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

</details>

See [SETUP.md - Deploy Your Own App](docs/SETUP.md#step-7-deploy-your-own-app) for full examples in multiple languages.

<br />

---

<br />

## Cost Breakdown

| Service | Monthly Cost | Notes |
|---------|-------------:|-------|
| Hetzner CPX22 VPS | €7.37 | 2 vCPU, 4GB RAM, 80GB SSD — [referral link](https://hetzner.cloud/?ref=IyoJUUeCm9RA) gives €20 credit |
| GitHub Actions | Free | 2,000 min/month (public repos) |
| GitHub Container Registry | Free | Public repos |
| healthchecks.io | Free | Up to 20 checks |
| **Total** | **€7.37** | |

> **Budget option**: Hetzner CPX11 (~€4.50/month) with 2 vCPU, 2GB RAM works well for low-traffic apps.

<br />

---

<br />

## Common Operations

<details>
<summary><strong>Deploy Your App</strong></summary>

```bash
# Replace /app contents, ensure Dockerfile + health endpoint
git push origin main
# Watch deployment in GitHub Actions
```

</details>

<details>
<summary><strong>Set Environment Variables</strong></summary>

Direct SSH requires adding your IP first (see [SSH Access](#ssh-access) below).

```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app && nano .env
docker compose restart app
```

Or use Hetzner Cloud Console for browser-based access.

</details>

<details>
<summary><strong>View Logs</strong></summary>

Direct SSH requires adding your IP first (see [SSH Access](#ssh-access) below).

```bash
ssh deploy@YOUR_VPS_IP
docker compose logs -f app
```

Or add a debug step to your GitHub Actions workflow.

</details>

<details>
<summary><strong>Destroy Infrastructure</strong></summary>

Go to **Actions** > **Provision Infrastructure** > Run workflow with "Destroy infrastructure" checked

</details>

<br />

---

<br />

## Troubleshooting

<details>
<summary><strong>SSH connection refused</strong></summary>

SSH is restricted to GitHub Actions IPs by default. To enable direct SSH:

1. Run `npm run setup-wizard` and go to Step 5, OR
2. Edit `terraform.tfvars`: `additional_ssh_ips = ["YOUR.IP/32"]`
3. Run the **Provision Infrastructure** workflow

Alternative: Use [Hetzner Cloud Console](https://console.hetzner.cloud/) for browser-based access.

</details>

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

---

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

---

<br />

## Built With

<p align="center">
  <a href="https://www.terraform.io/"><img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform" /></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" /></a>
  <a href="https://github.com/features/actions"><img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white" alt="GitHub Actions" /></a>
  <a href="https://www.hetzner.com/cloud"><img src="https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white" alt="Hetzner" /></a>
</p>

<br />

---

<br />

## Roadmap

- [ ] Cloudflare integration for custom domains + SSL
- [x] Setup wizard for optional database (PostgreSQL, MySQL, Redis)
- [ ] Cost monitoring in Terraform outputs
- [ ] Multi-app support (multiple apps on same VPS)

See the [open issues](https://github.com/filipegalo/vibe_in_vps/issues) for a full list of proposed features and known issues.

<br />

---

<br />

## Documentation

| Document | Description |
|----------|-------------|
| [Setup Guide](docs/SETUP.md) | Step-by-step walkthrough |
| [Operations Runbook](docs/RUNBOOK.md) | Deployments, monitoring, troubleshooting |
| [Contributing Guide](docs/CONTRIBUTING.md) | Development workflow and standards |
| [Architecture](CLAUDE.md) | Technical context and trade-offs |

<br />

---

<br />

## Contributing

Contributions are welcome! This project aims to stay simple and beginner-friendly.

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

**Quick contribution guide:**
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

<br />

---

<br />

## Support

- [Setup Guide](docs/SETUP.md) - Getting started help
- [Runbook](docs/RUNBOOK.md) - Operations reference
- [GitHub Issues](https://github.com/filipegalo/vibe_in_vps/issues) - Bug reports

<br />

---

<br />

## Show Your Support

If this project helped you deploy your app without the DevOps headache, consider:

- Giving it a star on GitHub
- Sharing it with others who might find it useful
- [Contributing](#contributing) improvements or documentation

<br />

---

<br />

## License

Distributed under the MIT License. See `LICENSE` for more information.

<br />

---

<p align="center">
  <strong>Built for developers who just want to deploy their apps without the DevOps headache.</strong>
</p>

<p align="center">
  <sub>Fork. Configure. Deploy. Ship your ideas, not YAML files.</sub>
</p>
