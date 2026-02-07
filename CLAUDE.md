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

## Secrets Flow Architecture

GitHub Secrets are the single source of truth for sensitive configuration. They flow to application containers through a 6-step pipeline:

```
GitHub Secrets                     deploy.yml                      VPS Server
+---------------+    reads via     +---------------+    SSH with    +---------------+
| POSTGRES_PASS | --------------> | ${{ secrets   | ------------> | export VAR=   |
| API_KEY       |   ${{ secrets}} |   .VAR }}     |   env vars    | "value"       |
| REDIS_PASS    |                 |               |               |               |
+---------------+                 +-------+-------+               +-------+-------+
                                          |                               |
                                          |                               v
                                          |                       +---------------+
                                          |                       | update.sh     |
                                          |                       | writes to     |
                                          |                       | /opt/app/.env |
                                          |                       +-------+-------+
                                          |                               |
                                          v                               v
+---------------+                 +---------------+               +---------------+
| Application   | <-------------- | docker-compose| <------------ | .env file     |
| Container     |   env vars      | reads ${VAR}  |   loads       | VAR=value     |
| process.env   |                 | from .env     |               |               |
+---------------+                 +---------------+               +---------------+
```

### Key Files in the Pipeline

| File | Path | Role |
|------|------|------|
| GitHub Secrets | Repository Settings | Source of truth for sensitive values |
| `deploy.yml` | `.github/workflows/deploy.yml` | Reads secrets, exports via SSH (lines 136-140) |
| `update.sh` | `deploy/update.sh` | Writes secrets to `.env` file (lines 14-25) |
| `docker-compose.yml` | `deploy/docker-compose.yml` | Substitutes `${VAR}` from `.env` |
| `.env` | `/opt/app/.env` | Auto-generated runtime config |

### Adding New Secrets

To add a new secret, update these 4 locations:

1. **GitHub Secrets**: Add the secret value
2. **deploy.yml**: Add to `env:` block AND export in SSH heredoc
3. **update.sh**: Add to the `cat > .env <<EOF` block
4. **docker-compose.yml**: Add to service's `environment:` section

### Important Behaviors

- **`.env` is auto-generated**: Overwritten on every deployment by `update.sh`
- **Variables must flow through all 4 files**: Missing any step results in undefined values
- **Default values**: Use `${VAR:-default}` syntax in `update.sh` and `docker-compose.yml`
- **Security**: Secrets are never logged; `.env` has restricted permissions

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| VPS Provider | Hetzner | Affordable reliable EU/US provider (€7.37/mo for CPX22) |
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
│   ├── update.sh              # Deployment script
│   └── .env.example           # Environment variable template
│
├── .github/workflows/
│   ├── deploy.yml             # Main CI/CD pipeline
│   └── infrastructure.yml              # One-time bootstrap workflow
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
- `additional_ssh_ips` - Additional IPs allowed SSH access beyond GitHub Actions (default: [])
- `allowed_http_ips` - IP addresses allowed HTTP access (default: ["0.0.0.0/0", "::/0"])
- `allowed_https_ips` - IP addresses allowed HTTPS access (default: ["0.0.0.0/0", "::/0"])
- `cloudflare_api_token` - Cloudflare API token (optional - leave empty to disable custom domain)
- `cloudflare_zone_id` - Cloudflare Zone ID for your domain (optional)
- `domain_name` - Custom domain name (e.g., app.example.com) (optional)

**Note**: SSH access automatically includes GitHub Actions IP ranges (fetched from `https://api.github.com/meta`). Use `additional_ssh_ips` to add your own IP for direct SSH access.

### Required for GitHub Secrets (Initial Setup)
- `HETZNER_TOKEN` - Hetzner Cloud API token
- `SSH_PUBLIC_KEY` - SSH public key for server access
- `SSH_PRIVATE_KEY` - SSH private key for deployment

**Note**: The SSH user is hardcoded to `deploy` in the workflows - no secret configuration needed.

### Optional GitHub Secrets
- `HEALTHCHECKS_API_KEY` - healthchecks.io API key (leave empty to disable monitoring)
- `CLOUDFLARE_API_TOKEN` - Cloudflare API token (required if using custom domain)
- `CLOUDFLARE_ZONE_ID` - Cloudflare Zone ID (required if using custom domain)
- `DOMAIN_NAME` - Custom domain name (required if using custom domain)

### Auto-Extracted from Terraform State (No Manual Configuration Needed)

The deploy workflow automatically downloads the Terraform state artifact and extracts:
- `VPS_HOST` - Server IP address
- `HEALTHCHECK_PING_URL` - healthchecks.io ping URL (if enabled)
- `CLOUDFLARE_TUNNEL_TOKEN` - Cloudflare Tunnel token (if enabled)
- `CUSTOM_DOMAIN_URL` - Custom domain HTTPS URL (if enabled)

**No manual secret copying required!** After running the infrastructure workflow once, all subsequent deployments automatically discover these values.

### Runtime (VPS `.env` file)

The `.env` file on the VPS is **automatically generated** by `scripts/generate-env.sh` (called from deploy workflow) and copied to the VPS.

**Current variables:**
- `GITHUB_REPOSITORY` - Repository name (e.g., user/repo)
- `GITHUB_TOKEN` - Temporary token for GHCR access
- `GITHUB_ACTOR` - User who triggered deployment
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` - PostgreSQL credentials
- `MYSQL_ROOT_PASSWORD`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE` - MySQL credentials
- `REDIS_PASSWORD` - Redis password
- `CLOUDFLARE_TUNNEL_TOKEN` - Cloudflare tunnel token

**Adding new variables (requires editing 2 files):**

1. Edit `scripts/generate-env.sh` → Add to .env template:
```bash
cat > "${OUTPUT_FILE}" << 'EOF'
# ... existing variables ...
MY_NEW_VARIABLE=${MY_NEW_VARIABLE:-}
EOF
```

2. Edit `.github/workflows/deploy.yml` → Add to env: section:
```yaml
- name: Generate environment configuration
  run: ./scripts/generate-env.sh
  env:
    # ... existing env vars ...
    MY_NEW_VARIABLE: ${{ secrets.MY_NEW_VARIABLE }}
```

The variable will automatically be available in docker-compose.yml as `${MY_NEW_VARIABLE}`.

---

## Common Issues & Solutions

### Issue: Cloud-init still running when deployment starts
**Solution**: Setup workflow waits for cloud-init completion marker (`/opt/app/.cloud-init-complete`) before finishing

### Issue: SSH permission denied / connection refused
**Solution**: SSH is restricted to GitHub Actions IP ranges by default. To enable direct SSH:
1. Use setup wizard Step 5 to add your IP, OR
2. Edit `terraform.tfvars`: `additional_ssh_ips = ["YOUR.IP/32"]`
3. Re-run the Provision Infrastructure workflow
Alternatively, use GitHub Actions workflows or Hetzner Cloud Console. See docs/RUNBOOK.md for details.

### Issue: Docker build fails
**Solution**: Test locally first with `scripts/test-local.sh`

### Issue: Port 80 already in use
**Solution**: Check for existing services: `sudo lsof -i :80`

---

## TODOs / Open Questions

### High Priority
- [x] **Cloudflare Integration**: Add optional Cloudflare Terraform module for custom domain + SSL
  - [x] Use Cloudflare Tunnel (implemented 2026-02-05)
  - [x] Update docker-compose.yml to support HTTPS mode
  - [x] Document DNS setup

### Medium Priority
- [x] **Setup Wizard**: Create interactive script for optional customizations
  - [x] Database (PostgreSQL, MySQL, Redis)
  - [x] Environment variable configuration
  - [ ] Volume mount configuration
  - [ ] Port mapping customization

### Low Priority
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
- **Implementation**: infrastructure.yml workflow handles terraform apply/destroy
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

### 2026-02-02: Optional Database Support
- **Decided**: Implement database support via commented docker-compose services
- **Rationale**: Users can opt-in by uncommenting, follows existing pattern (like volumes)
- **Implementation**:
  - Interactive setup wizard with database toggle (Step 4)
  - Configuration persistence in `.setup-config.json`
  - Complete docker-compose.yml sections for PostgreSQL 16, MySQL 8.0, Redis 7
  - Database credentials passed via GitHub Secrets → SSH → `.env` file
  - Databases run on internal Docker network only (no external ports)
  - Health checks ensure databases start before app
- **Trade-offs**:
  - Rejected dynamic generation (too complex)
  - Rejected Terraform-managed databases (cost increase $15+/month per DB)
  - Chose manual uncomment over automatic (explicit is better than implicit)
- **Documentation**: Complete sections in SETUP.md and RUNBOOK.md for operations
- **Migration**: Existing users can adopt without changes, backward compatible

### 2026-02-04: SSH Access - GitHub Actions + Optional User IPs
- **Decided**: SSH access restricted to GitHub Actions IPs by default, with option to add user IPs
- **Rationale**: Balance security with developer convenience
- **Implementation**:
  - Terraform fetches GitHub Actions IP ranges from `https://api.github.com/meta` (always included)
  - `additional_ssh_ips` variable allows users to add their own IPs
  - Setup wizard Step 5 provides easy configuration (E to toggle, I to set IP)
  - Configuration persisted in `.setup-config.json`
  - HTTP/HTTPS remain open to all (public web access)
- **Default behavior**:
  - GitHub Actions always have SSH access (for deployments)
  - Direct SSH from developer machines blocked unless IP is added
- **How to enable direct SSH**:
  - Option 1: Setup wizard Step 5 (easiest)
  - Option 2: Edit `terraform.tfvars`: `additional_ssh_ips = ["YOUR.IP/32"]`
  - Then re-run Provision Infrastructure workflow
- **Trade-offs**:
  - Slightly more complex setup for direct SSH
  - Accepted because: Security by default, easy opt-in for convenience
- **Mitigations**:
  - Setup wizard makes adding IP easy
  - Hetzner Cloud Console provides emergency access
  - GitHub Actions workflows can run any command via SSH
- **Documentation**: Updated SETUP.md, RUNBOOK.md, and terraform.tfvars.example

### 2026-02-05: Optional Cloudflare Integration for Custom Domains + HTTPS
- **Decided**: Use Cloudflare Tunnel over traditional SSL/reverse proxy approaches
- **Rationale**:
  - Zero SSL configuration (automatic certificates, no certbot/Let's Encrypt complexity)
  - No reverse proxy needed (cloudflared handles all routing, eliminates nginx/Traefik/Caddy setup)
  - Outbound-only connections (more secure - no inbound tunnel ports beyond 80/443)
  - Perfect for target users (frontend devs, junior devs, hobbyists)
  - Free tier sufficient for hobby projects
  - Cloudflare CDN and DDoS protection included
- **Implementation**: Follows healthchecks.io optional pattern exactly
  - Conditional resource creation via `count` in Terraform (`cloudflare_enabled = length(var.cloudflare_api_token) > 0`)
  - Empty string API token = disabled (no resources created)
  - Commented service in docker-compose.yml (user uncomments to enable)
  - Setup wizard Step 6 provides easy configuration (E to toggle, C to configure domain/token/zone)
  - Configuration persisted in `.setup-config.json`
  - Automatic writing to `terraform.tfvars` when configured via wizard
  - Three new variables: `cloudflare_api_token`, `cloudflare_zone_id`, `domain_name`
  - Two new outputs: `cloudflare_tunnel_token` (sensitive), `custom_domain_url`
  - GitHub Actions workflow displays tunnel token + custom domain URL in summary
  - Deploy workflow conditionally uses HTTPS URL when custom domain configured
- **User Experience**:
  - Optional at every step (app works on IP:80 without Cloudflare)
  - Wizard guides through Cloudflare account/API token/Zone ID setup
  - One-click enable/disable in wizard
  - Clear documentation in SETUP.md and RUNBOOK.md
- **Security**:
  - Cloudflare API token stored as GitHub Secret (never committed)
  - Tunnel token generated by Terraform (rotatable)
  - Outbound-only connections from VPS (no inbound tunnel ports)
  - Cloudflare handles SSL termination (automatic certificates)
- **Trade-offs**:
  - Requires Cloudflare account (free tier works)
  - Adds one external dependency (Cloudflare)
  - Accepted because: Professional HTTPS URLs are highly desired feature, free tier is sufficient, setup is optional
- **Alternative Approaches Considered**:
  - **Option B**: Traditional SSL with Let's Encrypt + Traefik
    - ❌ Requires certbot automation complexity
    - ❌ Needs reverse proxy configuration
    - ❌ Port 443 management complexity
    - ❌ Certificate renewal scripting
    - ✅ No external dependencies
  - **Option C**: Cloudflare Origin Certificates
    - ❌ Still requires reverse proxy (nginx/Traefik)
    - ❌ More configuration steps
    - ❌ Manual certificate installation
    - ✅ Tighter Cloudflare integration
  - **Verdict**: Cloudflare Tunnel (Option A) best fits project philosophy of "boring, proven tools" optimized for simplicity
- **Migration**: Existing users unaffected, purely additive feature (backward compatible)
- **Documentation**: Complete guide in SETUP.md, operations guide in RUNBOOK.md, architecture decisions in CLAUDE.md

### 2026-02-05: Extract .env Generation to Dedicated Script
- **Decided**: Extract .env generation logic from deploy.yml to `scripts/generate-env.sh`
- **Rationale**:
  - Cleaner deploy.yml workflow (removed 30+ lines of inline bash)
  - Testable .env generation logic (can be run locally)
  - Reusable script (could be used for local development testing)
  - Better separation of concerns (deployment orchestration vs config generation)
  - Clearer documentation (script has inline comments explaining each variable)
- **Implementation**:
  - Created `scripts/generate-env.sh` with all .env template logic
  - Script accepts environment variables via shell environment
  - Outputs summary without exposing secrets (shows `<set>` or `<empty>`)
  - deploy.yml now calls `./scripts/generate-env.sh` with env: block
  - All environment variables passed via env: section (GitHub Actions expands `${{ ... }}`)
- **Trade-offs**:
  - Adding new variables now requires editing 2 files instead of 1 (script + deploy.yml)
  - Accepted because: Script is clearer, testable, and 99% of users won't add variables often
- **Benefits**:
  - deploy.yml reduced from 30 lines to 15 lines for .env generation
  - Script can be tested locally: `POSTGRES_PASSWORD=test ./scripts/generate-env.sh && cat .env`
  - Better error messages (script validates and reports issues)
  - Easier to understand for new contributors
- **Documentation**: Updated SETUP.md, RUNBOOK.md, and CLAUDE.md to reflect two-file approach

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
