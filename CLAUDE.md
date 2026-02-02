# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Vision

**"Fork, Push, Deployed"**

This is a zero-ops deployment template that enables any developer to deploy their Dockerized application to a cheap VPS with zero manual server configuration. The developer provides only a Dockerfile in `/app`, and GitHub Actions handles building, pushing to GHCR, and deploying to a Terraform-provisioned Hetzner VPS.

**Target User**: Frontend developers, junior developers, hobbyists who want to deploy apps without learning DevOps.

**Success Metric**: Fresh fork can deploy example app in under 10 minutes.

---

## Architecture Overview

```
Developer Push (main)
    │
    ▼
GitHub Actions
    │
    ├── Build Docker image from /app
    ├── Push to ghcr.io/<user>/<repo>
    └── SSH to VPS: docker compose pull && up -d && curl healthchecks.io

    ▼
Hetzner VPS (Terraform-provisioned)
    │
    ├── Docker + Docker Compose (cloud-init installed)
    └── User App Container (exposed on port 80)
         │
         └── Monitored by healthchecks.io
```

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| VPS Provider | Hetzner | Affordable reliable EU/US provider (~$7.50/mo for CPX22) |
| Container Registry | GHCR | Free for public repos, integrated with GitHub |
| Reverse Proxy | None (for now) | Keep it simple - direct port 80 access |
| IaC Tool | Terraform | Industry standard, Hetzner provider available |
| CI/CD | GitHub Actions | Already where code lives, free for public repos |
| Deployment Method | SSH + docker compose | Simple, no agents needed, easy to debug |
| Monitoring | healthchecks.io (optional) | Free tier, Terraform provider available, optional to reduce complexity |
| Logging | docker logs | Built-in, zero config |
| SSL/Domain | None (for now) | See TODOs - Cloudflare integration planned |

---

## Constraints & Non-Goals

This project explicitly does NOT support:

- ❌ Multi-server setups
- ❌ Kubernetes
- ❌ Auto-scaling
- ❌ Blue/green deployments
- ❌ Zero-downtime deployments
- ❌ Secrets managers beyond GitHub Secrets
- ❌ Paid SaaS tooling (beyond Hetzner + GitHub)
- ❌ Vendor lock-in beyond Hetzner + GitHub

**Philosophy**: Prefer boring, proven tools. Optimize for clarity over flexibility.

---

## Known Trade-offs

### 1. Single Server = Single Point of Failure
- **Trade-off**: If VPS goes down, app goes down
- **Accepted because**: Target users don't need 99.99% uptime
- **Mitigation**: healthchecks.io alerts when app is down

### 2. No Zero-Downtime Deploys
- **Trade-off**: Brief downtime during `docker compose up -d`
- **Accepted because**: Typical deploy takes <10 seconds
- **Mitigation**: Deploy during low-traffic periods if needed

### 3. GHCR Requires GitHub Account
- **Trade-off**: Couples deployment to GitHub
- **Accepted because**: Target users already use GitHub
- **Alternative**: Could support Docker Hub, but adds complexity

### 4. Terraform in CI/CD (Not Local)
- **Decision**: Terraform runs in GitHub Actions, not locally
- **Benefit**: Users don't need Terraform CLI installed
- **Trade-off**: State stored as GitHub Actions artifact (90-day retention)
- **Mitigation**: Document how to download state for destroy operations

### 5. SSH-Based Deployment
- **Trade-off**: Requires SSH key in GitHub Secrets
- **Accepted because**: Simple to understand and debug
- **Alternative**: Pull-based deployments (Watchtower) considered but rejected for visibility

---

## Repository Structure

```
/
├── app/                       # User application code
│   ├── Dockerfile             # ONLY file required from user
│   ├── server.js              # Example: Simple Node.js app
│   └── package.json           # Example: Dependencies
│
├── infra/
│   └── terraform/             # Hetzner VPS provisioning
│       ├── main.tf            # VPS resources
│       ├── variables.tf       # Input variables
│       ├── outputs.tf         # Server IP, SSH command
│       ├── provider.tf        # Hetzner + healthchecksio providers
│       ├── cloud-init.yaml    # Server bootstrap (Docker install)
│       └── terraform.tfvars.example
│
├── deploy/
│   ├── docker-compose.yml     # Runtime services (app only)
│   ├── bootstrap.sh           # Initial VPS setup script
│   ├── update.sh              # Deployment script
│   └── .env.example           # Environment variable template
│
├── .github/workflows/
│   ├── deploy.yml             # Main CI/CD pipeline
│   └── setup.yml              # One-time bootstrap workflow
│
├── scripts/
│   ├── test-local.sh          # Test Docker build locally
│   ├── validate-terraform.sh  # Validate Terraform without apply
│   └── destroy.sh             # Clean teardown script
│
├── docs/
│   └── SETUP.md               # Detailed step-by-step guide
│
├── CLAUDE.md                  # This file - AI context
├── README.md                  # User-facing documentation
└── .gitignore                 # Prevent committing secrets
```

---

## Environment Variables Reference

### Required for Terraform (`terraform.tfvars`)
- `hcloud_token` - Hetzner Cloud API token
- `ssh_public_key` - SSH public key for server access
- `healthchecks_api_key` - healthchecks.io API key (optional - leave empty to disable monitoring)

### Optional for Terraform
- `server_name` - VPS name (default: "vibe-vps")
- `server_type` - Hetzner server type (default: "cpx22" - 2 vCPU, 4GB RAM)
- `location` - Datacenter location (default: "nbg1")
- `project_name` - Project identifier for labels (default: "vibe-in-vps")
- `allowed_ssh_ips` - IP addresses allowed to SSH (default: ["0.0.0.0/0", "::/0"])
- `allowed_http_ips` - IP addresses allowed HTTP access (default: ["0.0.0.0/0", "::/0"])
- `allowed_https_ips` - IP addresses allowed HTTPS access (default: ["0.0.0.0/0", "::/0"])

### Required for GitHub Secrets (Initial Setup)
- `HETZNER_TOKEN` - Hetzner Cloud API token
- `SSH_PUBLIC_KEY` - SSH public key for server access
- `SSH_PRIVATE_KEY` - SSH private key for deployment
- `VPS_USER` - SSH username (set to "deploy")

### Optional GitHub Secrets
- `HEALTHCHECKS_API_KEY` - healthchecks.io API key (leave empty to disable monitoring)

### Auto-Generated GitHub Secrets (by setup.yml workflow)
- `VPS_HOST` - Server IP address (from Terraform output)
- `HEALTHCHECK_PING_URL` - healthchecks.io ping URL (from Terraform output)

### Runtime (VPS `.env` file)
- `GITHUB_REPOSITORY` - Format: username/repo-name
- Application-specific variables (user-defined)

---

## Common Issues & Solutions

### Issue: Cloud-init still running when GitHub Actions SSH
**Solution**: `bootstrap.sh` waits for Docker to be ready before proceeding

### Issue: SSH permission denied
**Solution**: Check SSH key permissions (`chmod 600`) and correct user (deploy, not root)

### Issue: Docker build fails
**Solution**: Test locally first with `scripts/test-local.sh`

### Issue: Port 80 already in use
**Solution**: Check for existing services: `sudo lsof -i :80`

---

## TODOs / Open Questions

### High Priority
- [ ] **Cloudflare Integration**: Add optional Cloudflare Terraform module for custom domain + SSL
  - Use Cloudflare Tunnel or DNS + origin cert
  - Update docker-compose.yml to support HTTPS mode
  - Document DNS setup

### Medium Priority
- [ ] **Setup Wizard**: Create interactive script for optional customizations
  - Database (PostgreSQL, MySQL, Redis)
  - Environment variable configuration
  - Volume mount configuration
  - Port mapping customization

### Low Priority
- [ ] **Cost Monitoring**: Add Terraform output showing estimated monthly cost
- [ ] **Multi-app Support**: Allow multiple apps on same VPS (different ports)
- [ ] **Backup Reminder**: Document manual backup procedures

### Questions
- Should we support ARM-based Hetzner instances for lower cost?
- Should healthchecks.io integration be optional?

---

## Decision Log

### 2026-02-01: Initial Architecture Decisions
- **Decided**: Start with IP + port 80 only (no Traefik, no SSL)
- **Rationale**: Simplicity first; Cloudflare can be added later
- **Decided**: Include healthchecks.io monitoring via Terraform provider
- **Rationale**: Free tier available, automated setup, proactive alerts
- **Decided**: No built-in database support
- **Rationale**: Adds complexity; can be added via setup wizard later
- **Decided**: Use docker logs, no log aggregation
- **Rationale**: Sufficient for single-server deployments
- **Decided**: Run Terraform in GitHub Actions, not locally
- **Rationale**: True "zero-ops" - users don't need Terraform CLI
- **Implementation**: setup.yml workflow handles terraform apply/destroy
- **State Management**:
  - State stored as GitHub Actions artifact (90-day retention)
  - Automatically restored from previous workflow run before each execution
  - Saved after successful apply/destroy
  - Uses `dawidd6/action-download-artifact@v3` to fetch from previous run
  - No remote backend needed for single-user deployments
- **Decided**: Make healthchecks.io monitoring optional
- **Rationale**: Reduces required accounts from 3 to 2 (GitHub + Hetzner)
- **Implementation**: Conditional resource creation in Terraform, workflows skip ping if disabled
- **Trade-off**: No automated uptime monitoring unless user opts in
- **Decided**: Make firewall rules customizable via variables
- **Rationale**: Allow users to restrict SSH to their IP, customize access control
- **Implementation**: Variables for allowed IPs per port (SSH, HTTP, HTTPS)
- **Default**: Open to all (0.0.0.0/0) for simplicity, users can lock down as needed

---

## Implementation Status

- [x] Planning complete
- [x] Phase 1: Project Scaffolding
- [x] Phase 2: Terraform Infrastructure
- [x] Phase 3: VPS Runtime Configuration
- [x] Phase 4: GitHub Actions CI/CD
- [x] Phase 5: Example Application
- [x] Phase 6: Documentation
- [x] Phase 7: Testing & Validation

**Status**: ✅ Core implementation complete and ready for testing

---

## Documentation Standards

### Approved Documentation Files

**ONLY these markdown files should exist in the project:**

1. **README.md** - High-level overview and quick start guide
2. **CLAUDE.md** - Architecture decisions and project context (this file)
3. **docs/SETUP.md** - Complete step-by-step setup guide with troubleshooting
4. **docs/RUNBOOK.md** - Operations and maintenance reference
5. **docs/CONTRIBUTING.md** - Development workflow and contribution guidelines

**Important**: Any other `.md` files should be deleted or consolidated into the above files to maintain clean documentation structure.


<claude-mem-context>
# Recent Activity

<!-- This section is auto-generated by claude-mem. Edit content outside the tags. -->

*No recent activity*
</claude-mem-context>
