# Detailed Setup Guide

This guide provides step-by-step instructions for setting up vibe_in_vps, including screenshots descriptions and troubleshooting.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Hetzner Cloud Setup](#hetzner-cloud-setup)
3. [healthchecks.io Setup](#healthchecksio-setup)
4. [SSH Key Generation](#ssh-key-generation)
5. [Terraform Configuration](#terraform-configuration)
6. [GitHub Secrets Setup](#github-secrets-setup)
7. [First Deployment](#first-deployment)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- Git installed (`git --version`)
- Terraform installed (`terraform --version`)
- SSH client installed (built-in on macOS/Linux, use WSL on Windows)
- A text editor (VS Code, Sublime, nano, etc.)

### Installing Terraform

**macOS (Homebrew):**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Windows:**
Download from [terraform.io/downloads](https://www.terraform.io/downloads)

---

## Hetzner Cloud Setup

### Step 1: Create Hetzner Account

1. Go to [https://console.hetzner.cloud/](https://console.hetzner.cloud/)
2. Click "Sign Up"
3. Fill in your details
4. Verify your email address

### Step 2: Create a Project

1. After logging in, click "New Project"
2. Name it (e.g., "vibe-deployments")
3. Click "Create Project"

### Step 3: Generate API Token

1. In your project, click on the left sidebar: **Security** → **API Tokens**
2. Click "Generate API Token"
3. Give it a description (e.g., "Terraform access")
4. Permissions: Select **Read & Write**
5. Click "Generate"
6. **IMPORTANT**: Copy the token immediately - you won't see it again!
7. Save it in a secure place (password manager recommended)

**Token format**: `long-random-string-of-characters`

---

## healthchecks.io Setup

### Step 1: Create Account

1. Go to [https://healthchecks.io/](https://healthchecks.io/)
2. Click "Sign Up" (free tier is sufficient)
3. Verify your email

### Step 2: Get API Key

1. After logging in, click your email in the top right
2. Click "Settings"
3. Scroll to "API Access"
4. Click "Show API keys"
5. Copy the "Read-write key"
6. Save it securely

**API key format**: `random-hex-string`

---

## SSH Key Generation

### Check if you already have an SSH key

```bash
ls ~/.ssh/id_*.pub
```

If you see files like `id_ed25519.pub` or `id_rsa.pub`, you already have a key! Skip to "Using your existing key".

### Generate a new SSH key

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

When prompted:
- **Enter file to save the key**: Press Enter (uses default location)
- **Enter passphrase**: Press Enter twice (no passphrase for automation)

This creates:
- **Private key**: `~/.ssh/id_ed25519` (keep secret!)
- **Public key**: `~/.ssh/id_ed25519.pub` (safe to share)

### View your keys

**Public key** (for Terraform):
```bash
cat ~/.ssh/id_ed25519.pub
```

Output example:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJl3dIeudNqd0DMROQ... your-email@example.com
```

**Private key** (for GitHub Secrets):
```bash
cat ~/.ssh/id_ed25519
```

Output example:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
...
-----END OPENSSH PRIVATE KEY-----
```

**CRITICAL**: Never share or commit your private key!

---

## Terraform Configuration

### Step 1: Fork the repository

1. Go to the GitHub repository
2. Click "Fork" in the top right
3. Select your account

### Step 2: Clone your fork

```bash
git clone https://github.com/YOUR_USERNAME/vibe_in_vps.git
cd vibe_in_vps
```

### Step 3: Create terraform.tfvars

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

### Step 4: Edit terraform.tfvars

```bash
nano terraform.tfvars  # or use your preferred editor
```

Fill in your values:

```hcl
# Hetzner API token (from earlier step)
hcloud_token = "your-hetzner-api-token-here"

# healthchecks.io API key (from earlier step)
healthchecks_api_key = "your-healthchecks-api-key-here"

# Your SSH public key (output from: cat ~/.ssh/id_ed25519.pub)
ssh_public_key = "ssh-ed25519 AAAAC3NzaC... your-email@example.com"

# Your GitHub repository (format: username/repo-name)
github_repository = "yourusername/vibe_in_vps"

# Optional customizations:
# server_name = "my-production-server"
# server_type = "cx11"  # Cheaper: $3.79/mo instead of $5.50/mo
# location = "ash"      # Ashburn, VA (USA East Coast)
```

**Save and close** (Ctrl+X, then Y, then Enter in nano)

### Step 5: Validate Terraform configuration

```bash
# Still in infra/terraform directory
terraform init
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 6: Review what will be created

```bash
terraform plan
```

This shows you what Terraform will create:
- Hetzner VPS (cx22 by default)
- Firewall rules
- SSH key
- healthchecks.io monitoring check

Review carefully!

### Step 7: Apply Terraform configuration

```bash
terraform apply
```

Type `yes` when prompted.

**This will:**
- Charge your Hetzner account (~$0.01/hour, ~$5.50/month)
- Create a VPS
- Install Docker via cloud-init (takes 2-3 minutes)

**Wait for completion** (takes 3-5 minutes).

### Step 8: Save Terraform outputs

```bash
terraform output
```

You'll see:

```
app_url = "http://1.2.3.4"
github_secrets_summary = <<EOT
  Add these secrets to your GitHub repository:
  VPS_HOST: 1.2.3.4
  VPS_SSH_KEY: <your-private-ssh-key>
  VPS_USER: deploy
  HEALTHCHECK_PING_URL: https://hc-ping.com/...
EOT
healthcheck_ping_url = <sensitive>
server_ip = "1.2.3.4"
server_status = "running"
ssh_command = "ssh deploy@1.2.3.4"
```

**IMPORTANT**: Copy the `server_ip` and `healthcheck_ping_url` - you'll need them for GitHub Secrets.

To see the sensitive `healthcheck_ping_url`:
```bash
terraform output healthcheck_ping_url
```

---

## GitHub Secrets Setup

### Step 1: Navigate to repository settings

1. Go to your forked repository on GitHub
2. Click **Settings** (tab at the top)
3. In the left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add secrets

Click "New repository secret" for each of these:

#### Secret 1: VPS_HOST

- **Name**: `VPS_HOST`
- **Value**: The `server_ip` from Terraform output (e.g., `1.2.3.4`)

#### Secret 2: VPS_SSH_KEY

- **Name**: `VPS_SSH_KEY`
- **Value**: Your **entire private SSH key**

Get it with:
```bash
cat ~/.ssh/id_ed25519
```

Copy the **entire output** including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
... all the lines ...
-----END OPENSSH PRIVATE KEY-----
```

**Paste it exactly** into the GitHub secret value field.

#### Secret 3: VPS_USER

- **Name**: `VPS_USER`
- **Value**: `deploy`

#### Secret 4: HEALTHCHECK_PING_URL

- **Name**: `HEALTHCHECK_PING_URL`
- **Value**: The ping URL from Terraform (get it with `terraform output healthcheck_ping_url`)

Example format: `https://hc-ping.com/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Step 3: Verify secrets

You should now have 4 secrets:
- VPS_HOST
- VPS_SSH_KEY
- VPS_USER
- HEALTHCHECK_PING_URL

---

## First Deployment

### Step 1: Run initial setup workflow

1. Go to your GitHub repository
2. Click the **Actions** tab
3. In the left sidebar, click "Initial VPS Setup"
4. Click "Run workflow" button on the right
5. Click the green "Run workflow" button in the dropdown
6. Wait for the workflow to complete (2-3 minutes)

**What this does:**
- Waits for the VPS to be ready
- Copies deployment files to the VPS
- Runs the bootstrap script
- Pulls the Docker image
- Starts your application

### Step 2: Verify setup succeeded

Click on the workflow run to see the output. You should see:
```
✓ cloud-init complete
✓ Docker ready
✓ Docker Compose ready
✓ Services started
✓ App is running
```

### Step 3: Test your application

Open your browser and visit:
```
http://YOUR_SERVER_IP
```

You should see:
```json
{
  "message": "Hello from vibe_in_vps!",
  "timestamp": "2024-01-15T12:34:56.789Z",
  "environment": "production"
}
```

### Step 4: Test health endpoint

Visit:
```
http://YOUR_SERVER_IP/health
```

You should see:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T12:34:56.789Z",
  "uptime": 42.5
}
```

### Step 5: Check healthchecks.io

1. Go to [healthchecks.io/projects/](https://healthchecks.io/projects/)
2. You should see your check with a green "UP" status
3. Configure alert channels (email, Slack, etc.) if desired

---

## Troubleshooting

### VPS is not accessible

**Symptom**: Cannot SSH to the VPS

**Possible causes:**
1. Cloud-init still running (wait 5 minutes)
2. Wrong SSH key
3. Firewall blocking port 22

**Solutions:**

Check VPS status in Hetzner Console:
1. Go to [console.hetzner.cloud](https://console.hetzner.cloud/)
2. Select your project
3. Click on the server
4. Check status (should be "Running")
5. Click "Console" to access web-based terminal

Test SSH connection:
```bash
ssh -v deploy@YOUR_SERVER_IP
```

The `-v` flag shows verbose output to diagnose issues.

### Deployment failed in GitHub Actions

**Symptom**: Red X on GitHub Actions workflow

**Solutions:**

1. Click on the failed workflow
2. Click on the failed job
3. Read the error message
4. Common issues:
   - **SSH key permissions**: Make sure you added the **private** key, not public
   - **Docker build failed**: Test locally with `./scripts/test-local.sh`
   - **Port already in use**: SSH to VPS and run `docker compose down`

### App not responding to health checks

**Symptom**: healthchecks.io shows "DOWN"

**Solutions:**

SSH to VPS and check logs:
```bash
ssh deploy@YOUR_SERVER_IP
docker compose ps      # Check if container is running
docker compose logs app  # View application logs
```

Make sure your app:
1. Exposes port 3000
2. Responds to `GET /health` with 200 status

### Terraform errors

**Error**: "Error creating server: invalid_input"

**Solution**: Check your `terraform.tfvars`:
- Ensure `ssh_public_key` starts with `ssh-ed25519` or `ssh-rsa`
- Remove any extra whitespace or line breaks

**Error**: "401 Unauthorized"

**Solution**: Check your Hetzner API token is correct

**Error**: "Resource already exists"

**Solution**: Run `terraform destroy` first, then `terraform apply` again

### Cost concerns

**Worried about unexpected charges?**

Set up billing alerts in Hetzner:
1. Go to [console.hetzner.cloud](https://console.hetzner.cloud/)
2. Click your project
3. Go to **Billing** → **Alerts**
4. Set a monthly limit (e.g., $10)

Remember: VPS costs ~$0.01/hour, so even if you forget to destroy it, max cost is ~$5.50/month.

---

## Next Steps

Now that your app is deployed:

1. **Add your own application**: Replace the example app in `/app`
2. **Configure monitoring**: Set up email/Slack alerts in healthchecks.io
3. **Add environment variables**: Edit `/opt/app/.env` on the VPS
4. **Enable HTTPS** (coming soon): Follow TODO for Cloudflare integration

---

## Getting Help

- **GitHub Issues**: [Open an issue](https://github.com/filipegalo/vibe_in_vps/issues)
- **Hetzner Docs**: [docs.hetzner.com](https://docs.hetzner.com/)
- **Terraform Docs**: [terraform.io/docs](https://www.terraform.io/docs)

---

**Happy deploying!** 🚀
