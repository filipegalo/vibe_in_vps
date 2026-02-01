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
| VPS Provider | Hetzner | Cheapest reliable EU/US provider (~$4.50/mo for CX22) |
| Container Registry | GHCR | Free for public repos, integrated with GitHub |
| Reverse Proxy | None (for now) | Keep it simple - direct port 80 access |
| IaC Tool | Terraform | Industry standard, Hetzner provider available |
| CI/CD | GitHub Actions | Already where code lives, free for public repos |
| Deployment Method | SSH + docker compose | Simple, no agents needed, easy to debug |
| Monitoring | healthchecks.io | Free tier, Terraform provider available |
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

### 4. Manual Terraform Apply
- **Trade-off**: User must run Terraform locally once
- **Accepted because**: Infrastructure changes are rare
- **Why not automate**: Managing Terraform state in CI is complex

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
- `healthchecks_api_key` - healthchecks.io API key

### Optional for Terraform
- `server_name` - VPS name (default: "vibe-vps")
- `server_type` - Hetzner server type (default: "cx22")
- `location` - Datacenter location (default: "nbg1")

### Required for GitHub Secrets
- `VPS_HOST` - Server IP address (from Terraform output)
- `VPS_SSH_KEY` - Private SSH key
- `VPS_USER` - SSH username (default: "deploy")
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


<claude-mem-context>
# Recent Activity

<!-- This section is auto-generated by claude-mem. Edit content outside the tags. -->

*No recent activity*
</claude-mem-context>
