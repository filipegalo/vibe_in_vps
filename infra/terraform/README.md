# Terraform Configuration

## File Structure

```
infra/terraform/
├── terraform.tfvars          # Non-sensitive config (SAFE TO COMMIT)
├── terraform.tfvars.example  # Template for terraform.tfvars
└── *.tf                      # Terraform resources
```

## How Variables Work

This project uses a **hybrid approach** to keep secrets safe while allowing configuration to be version-controlled:

### 🔒 Sensitive Values (GitHub Secrets)

These are **NEVER** in terraform.tfvars:

| Variable | Set in GitHub Secrets as | Passed to Terraform as |
|----------|--------------------------|------------------------|
| Hetzner API Token | `HETZNER_TOKEN` | `TF_VAR_hcloud_token` |
| Healthchecks API Key | `HEALTHCHECKS_API_KEY` | `TF_VAR_healthchecks_api_key` |
| Cloudflare API Token | `CLOUDFLARE_API_TOKEN` | `TF_VAR_cloudflare_api_token` |
| Cloudflare Account ID | `CLOUDFLARE_ACCOUNT_ID` | `TF_VAR_cloudflare_account_id` |
| SSH Public Key | `SSH_PUBLIC_KEY` | `TF_VAR_ssh_public_key` |

**How it works:**
- Stored in GitHub: Settings → Secrets and variables → Actions
- GitHub Actions sets `TF_VAR_*` environment variables
- Terraform reads from environment automatically

### ✅ Non-Sensitive Configuration (terraform.tfvars)

These are **SAFE TO COMMIT**:

| Variable | Example | Why it's safe |
|----------|---------|---------------|
| `additional_ssh_ips` | `["1.2.3.4/32"]` | Your IP whitelist (you choose) |
| `domain_name` | `"app.example.com"` | Public domain name |
| `cloudflare_zone_id` | `"abc123..."` | Just an identifier, not a secret |
| `server_name` | `"my-vps"` | Public server name |
| `server_type` | `"cpx22"` | Server size (public info) |
| `location` | `"nbg1"` | Datacenter location |
| `allowed_http_ips` | `["0.0.0.0/0"]` | Public access rules |

**How it works:**
- Edit `terraform.tfvars` in your repo
- Commit and push to git
- GitHub Actions reads this file during deployment
- Terraform merges with environment variables

## Setup Instructions

### 1. Create terraform.tfvars

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Non-Sensitive Values

Edit `terraform.tfvars` with your configuration:

```hcl
# Your IP for SSH access (optional)
additional_ssh_ips = ["1.2.3.4/32"]

# Custom domain configuration (optional)
domain_name        = "app.example.com"
cloudflare_zone_id = "your-zone-id"

# Server customization (optional)
# server_name = "my-app"
# server_type = "cpx11"  # Cheaper option
```

### 3. Commit and Push

```bash
git add terraform.tfvars
git commit -m "Configure VPS settings"
git push origin main
```

**This is safe!** No secrets in this file.

### 4. Add Secrets to GitHub

Go to your repo → Settings → Secrets and variables → Actions → New repository secret:

**Required:**
- `HETZNER_TOKEN` = Your Hetzner API token
- `SSH_PUBLIC_KEY` = Your SSH public key
- `SSH_PRIVATE_KEY` = Your SSH private key

**Optional:**
- `HEALTHCHECKS_API_KEY` = healthchecks.io API key (or leave empty)
- `CLOUDFLARE_API_TOKEN` = Cloudflare API token (if using custom domain)
- `CLOUDFLARE_ACCOUNT_ID` = Cloudflare Account ID (if using custom domain - find in dashboard)

### 5. Run Infrastructure Workflow

Actions → "Provision Infrastructure" → Run workflow

## Security Benefits

✅ **No secrets in git history**
- API tokens, SSH keys never committed
- Can safely make repo public

✅ **Team-friendly**
- Each team member adds their own GitHub Secrets
- Configuration (IPs, domains) shared via git

✅ **Audit trail**
- Git history shows configuration changes
- GitHub audit log shows who changed secrets

✅ **Easy rotation**
- Rotate secrets in GitHub Secrets UI
- No need to update git history

## Local Development

If you want to run Terraform locally:

```bash
# Set environment variables
export TF_VAR_hcloud_token="your-token"
export TF_VAR_cloudflare_api_token="your-token"
export TF_VAR_healthchecks_api_key="your-key"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_github_repository="username/repo"

# Run Terraform (terraform.tfvars will be read automatically)
cd infra/terraform
terraform init
terraform plan
terraform apply
```

Or add to your `~/.bashrc`:

```bash
# vibe_in_vps Terraform
export TF_VAR_hcloud_token="xxxxx"
export TF_VAR_cloudflare_api_token="xxxxx"
export TF_VAR_healthchecks_api_key="xxxxx"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_github_repository="username/repo"
```

## What Gets Read From Where

```
Terraform reads:
├── Environment variables (TF_VAR_*)  ← Secrets from GitHub
└── terraform.tfvars                  ← Non-sensitive config from git

Final merged configuration used for provisioning
```

## Troubleshooting

**Q: Terraform says variable not set**
- Check GitHub Secrets are configured correctly
- Variable names must match: `HETZNER_TOKEN` → `TF_VAR_hcloud_token`

**Q: Can I commit terraform.tfvars?**
- Yes! It's designed to be committed (only non-sensitive values)
- DO NOT put API tokens or SSH keys in this file

**Q: How do I change my IP whitelist?**
- Edit `additional_ssh_ips` in `terraform.tfvars`
- Commit and push
- Re-run "Provision Infrastructure" workflow

**Q: How do I rotate API tokens?**
- Update in GitHub Secrets
- Re-run "Provision Infrastructure" workflow
- Old token can be revoked
