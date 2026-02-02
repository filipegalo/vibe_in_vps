# Complete Setup Guide

This guide walks you through deploying your first application using vibe_in_vps, from creating accounts to accessing your deployed app.

**Time to complete**: 5-10 minutes

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Fork Repository](#step-1-fork-repository)
3. [Step 2: Create Accounts](#step-2-create-accounts)
4. [Step 3: Generate SSH Keys](#step-3-generate-ssh-keys)
5. [Step 4: Configure GitHub Secrets](#step-4-configure-github-secrets)
6. [Step 5: Run Setup Workflow](#step-5-run-setup-workflow)
7. [Step 6: Verify Deployment](#step-6-verify-deployment)
8. [Step 7: Deploy Your Own App](#step-7-deploy-your-own-app)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, you'll need:

- **A computer** with internet access
- **A web browser**
- **Terminal/Command Line** access (macOS/Linux built-in, Windows: WSL or Git Bash)
- **15 minutes** of your time

**No installation required!** Everything runs in GitHub Actions.

---

## Step 1: Fork Repository

### 1.1 Fork on GitHub

1. Go to the vibe_in_vps repository on GitHub
2. Click the **"Fork"** button in the top-right corner
3. Select your account as the destination
4. Wait for the fork to complete (~5 seconds)

### 1.2 Verify Fork

You should now see the repository at:
```
https://github.com/YOUR_USERNAME/vibe_in_vps
```

**Note**: You may see a failed "Deploy to VPS" workflow run - this is expected! The deployment workflow requires initial setup to be completed first. Just continue with the setup steps below.

✅ **Checkpoint**: You have your own copy of the repository.

---

## Step 2: Create Accounts

You need 2-3 accounts depending on whether you want monitoring.

### 2.1 GitHub Account (Required)

If you don't have one:
1. Go to [github.com/signup](https://github.com/signup)
2. Follow the signup process
3. Verify your email

✅ **You already have this** if you forked the repo.

### 2.2 Hetzner Cloud Account (Required)

**What it's for**: VPS hosting (~$5.50/month)

**Steps**:
1. Go to [console.hetzner.cloud](https://console.hetzner.cloud/)
2. Click **"Sign up"**
3. Fill in your details:
   - Email address
   - Password
   - Accept terms
4. Click **"Sign up"**
5. **Verify your email** - check your inbox for verification link
6. **Add payment method** - Required even for free tier
   - Click your name → Billing
   - Add credit card or PayPal
   - No charge until you create resources

**Create a Project**:
1. Click **"New Project"**
2. Name it: `vibe-deployments` (or anything you like)
3. Click **"Create Project"**

✅ **Checkpoint**: You're logged into Hetzner Console with a project.

### 2.3 healthchecks.io Account (Optional)

**What it's for**: Uptime monitoring and alerts (Free for 20 checks)

**Steps**:
1. Go to [healthchecks.io](https://healthchecks.io/)
2. Click **"Sign Up"**
3. Enter your email
4. Verify your email
5. Log in

**Skip this step if**:
- You don't need automated monitoring
- You want the simplest possible setup

✅ **Checkpoint**: You have 2 (or 3) accounts ready.

---

## Step 3: Generate SSH Keys

SSH keys are used to securely access your VPS.

### 3.1 Check for Existing Keys

Open your terminal and run:
```bash
ls ~/.ssh/id_*.pub
```

**If you see files** like `id_ed25519.pub` or `id_rsa.pub`:
- ✅ You already have SSH keys! Skip to [Step 3.3](#33-copy-your-keys)

**If you see "No such file or directory"**:
- Continue to Step 3.2 to generate new keys

### 3.2 Generate New SSH Keys

Run this command in your terminal:
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Replace `your-email@example.com` with your actual email.

**When prompted**:

1. **"Enter file in which to save the key"**:
   - Press **Enter** (uses default location: `~/.ssh/id_ed25519`)

2. **"Enter passphrase"**:
   - Press **Enter** (no passphrase for automation)

3. **"Enter same passphrase again"**:
   - Press **Enter** again

**Output should look like**:
```
Your identification has been saved in /Users/you/.ssh/id_ed25519
Your public key has been saved in /Users/you/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:xxx your-email@example.com
```

✅ **Checkpoint**: You have SSH keys at `~/.ssh/id_ed25519` (private) and `~/.ssh/id_ed25519.pub` (public).

### 3.3 Copy Your Keys

You'll need both keys in the next step.

**View your PUBLIC key**:
```bash
cat ~/.ssh/id_ed25519.pub
```

Example output:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJl3dIeudNqd0DMROQ4fGdb7Y3ex your-email@example.com
```

**View your PRIVATE key**:
```bash
cat ~/.ssh/id_ed25519
```

Example output:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACCZd3SHrnTandAzETkOHxnW+2N3sQm7YH8vN9H5ZPmD2wAAAJhJVbfXSVW3
...many more lines...
-----END OPENSSH PRIVATE KEY-----
```

**Important**:
- ✅ Keep your **private key** secret - NEVER share it publicly
- ✅ The **public key** is safe to share

📋 **Keep your terminal open** - you'll copy these values in the next step.

---

## Step 4: Configure GitHub Secrets

GitHub Secrets store sensitive data (API tokens, SSH keys) securely.

### 4.1 Navigate to Secrets Settings

1. Go to your forked repository on GitHub
2. Click **"Settings"** tab (top of page)
3. In the left sidebar, click **"Secrets and variables"** → **"Actions"**
4. You should see the "Actions secrets" page

### 4.2 Get Your Hetzner API Token

**In a new tab**, go to [console.hetzner.cloud](https://console.hetzner.cloud/):

1. Select your project
2. In the left sidebar, click **"Security"** → **"API Tokens"**
3. Click **"Generate API Token"**
4. Fill in:
   - **Description**: `vibe_in_vps terraform`
   - **Permissions**: Select **"Read & Write"**
5. Click **"Generate"**
6. **IMPORTANT**: Copy the token immediately - you won't see it again!

The token looks like: `aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890`

📋 **Keep this tab open** or save the token temporarily.

### 4.3 Get Your healthchecks.io API Key (Optional)

**If you want monitoring**, in a new tab go to [healthchecks.io](https://healthchecks.io/):

1. Click your email → **"Settings"**
2. Scroll to **"API Access"**
3. Click **"Show API keys"**
4. Copy the **"Read-write key"**

The key looks like: `a1b2c3d4e5f6g7h8i9j0`

**If you're skipping monitoring**: You'll leave this secret empty.

### 4.4 Add Secrets to GitHub

Back in the GitHub Secrets page, add these secrets one by one:

#### Secret 1: HETZNER_TOKEN

1. Click **"New repository secret"**
2. **Name**: `HETZNER_TOKEN`
3. **Secret**: Paste your Hetzner API token
4. Click **"Add secret"**

#### Secret 2: SSH_PUBLIC_KEY

1. Click **"New repository secret"**
2. **Name**: `SSH_PUBLIC_KEY`
3. **Secret**: Paste the output from `cat ~/.ssh/id_ed25519.pub`
   - Should start with `ssh-ed25519 AAAA...`
   - Should be ONE line
4. Click **"Add secret"**

#### Secret 3: SSH_PRIVATE_KEY

1. Click **"New repository secret"**
2. **Name**: `SSH_PRIVATE_KEY`
3. **Secret**: Paste the ENTIRE output from `cat ~/.ssh/id_ed25519`
   - Should start with `-----BEGIN OPENSSH PRIVATE KEY-----`
   - Should end with `-----END OPENSSH PRIVATE KEY-----`
   - Should be MULTIPLE lines
4. Click **"Add secret"**

#### Secret 4: VPS_USER

1. Click **"New repository secret"**
2. **Name**: `VPS_USER`
3. **Secret**: Type exactly: `deploy`
4. Click **"Add secret"**

#### Secret 5: HEALTHCHECKS_API_KEY (Optional)

**If you want monitoring**:
1. Click **"New repository secret"**
2. **Name**: `HEALTHCHECKS_API_KEY`
3. **Secret**: Paste your healthchecks.io API key
4. Click **"Add secret"**

**If you're skipping monitoring**:
1. Click **"New repository secret"**
2. **Name**: `HEALTHCHECKS_API_KEY`
3. **Secret**: Leave it empty (just blank)
4. Click **"Add secret"**

### 4.5 Verify Secrets

You should see 5 secrets listed:
- `HETZNER_TOKEN`
- `HEALTHCHECKS_API_KEY`
- `SSH_PRIVATE_KEY`
- `SSH_PUBLIC_KEY`
- `VPS_USER`

**Note**: After running the setup workflow in Step 5, you'll add 2 more secrets (`VPS_HOST` and `HEALTHCHECK_PING_URL`) for automatic deployments.

✅ **Checkpoint**: Initial secrets configured!

---

## Step 5: Run Setup Workflow

Now the magic happens - GitHub Actions will provision your VPS and deploy the app.

### 5.1 Navigate to Actions

1. In your GitHub repository, click the **"Actions"** tab
2. You'll see a list of workflows

### 5.2 Run Provision Infrastructure

1. In the left sidebar, click **"Provision Infrastructure"**
2. On the right side, click the **"Run workflow"** dropdown button
3. Keep "Branch: main" selected
4. Leave "Destroy infrastructure" **UNCHECKED**
5. Click the green **"Run workflow"** button

### 5.3 Watch the Progress

The workflow will start running. Click on the workflow run to see details.

**What's happening** (6-8 minutes total):

**Phase 1: Provision Infrastructure (2-3 minutes)**
- ✅ Terraform initializes
- ✅ Terraform validates configuration
- ✅ Terraform creates VPS on Hetzner
- ✅ Saves Terraform state as artifact
- ✅ Displays deployment secrets to configure

**Phase 2: Bootstrap VPS (4-5 minutes)**
- ✅ Waits for VPS to accept SSH connections
- ✅ Waits for cloud-init to install Docker (~3 min)
- ✅ Copies deployment files to VPS
- ✅ Runs bootstrap script
- ✅ Pulls Docker image and starts app
- ✅ Verifies deployment

### 5.4 Check for Success

When complete, you'll see:
- ✅ Green checkmark on the workflow
- ✅ "🎉 Setup Complete!" in the summary

Click on the **"Summary"** to see:
- **VPS IP Address**
- **SSH Command**
- **App URL**

✅ **Checkpoint**: Your VPS is provisioned and app is deployed!

### 5.5 Configure Deployment Secrets

The workflow summary will show you two secrets that need to be added for automatic deployments:

1. **Go to Settings** → **Secrets and variables** → **Actions**

2. **Add VPS_HOST secret:**
   - Click **"New repository secret"**
   - **Name**: `VPS_HOST`
   - **Secret**: Copy the IP address from the workflow summary
   - Click **"Add secret"**

3. **Add HEALTHCHECK_PING_URL secret (if you configured healthchecks.io):**
   - Click **"New repository secret"**
   - **Name**: `HEALTHCHECK_PING_URL`
   - **Secret**: Copy the ping URL from the workflow summary
   - Click **"Add secret"**

   **If you didn't configure healthchecks.io**: Skip this secret or leave it empty.

✅ **Checkpoint**: Deployment secrets configured - automatic deployments will now work!

---

## Step 6: Verify Deployment

### 6.1 Access Your Application

From the workflow Summary, copy the **App URL** (or VPS IP).

Open your browser and go to:
```
http://YOUR_VPS_IP
```

**You should see**:
```json
{
  "message": "Hello from vibe_in_vps!",
  "timestamp": "2026-02-01T23:45:00.000Z",
  "environment": "production"
}
```

### 6.2 Check Health Endpoint

Visit:
```
http://YOUR_VPS_IP/health
```

**You should see**:
```json
{
  "status": "ok",
  "timestamp": "2026-02-01T23:45:00.000Z",
  "uptime": 123.45
}
```

### 6.3 Verify in Hetzner Console

1. Go to [console.hetzner.cloud](https://console.hetzner.cloud/)
2. Click your project
3. You should see a server named `vibe-vps` (or your custom name)
4. Status: **Running** (green)

### 6.4 Check Monitoring (If Enabled)

If you enabled healthchecks.io:

1. Go to [healthchecks.io/projects/](https://healthchecks.io/projects/)
2. You should see a check named `vibe-vps`
3. Status: **UP** (green checkmark)
4. Click to configure alert channels (email, Slack, etc.)

### 6.5 Check GitHub Deployments

1. In your GitHub repository, click **"Environments"** (below Code tab)
2. You should see **"production"** environment
3. Click it to see deployment history

✅ **Checkpoint**: Everything is working!

---

## Step 7: Deploy Your Own App

Now let's replace the example app with your own application.

### 7.1 Clone Your Repository Locally

```bash
git clone https://github.com/YOUR_USERNAME/vibe_in_vps.git
cd vibe_in_vps
```

### 7.2 Replace Example App

1. **Delete example app**:
   ```bash
   rm -rf app/*
   ```

2. **Add your application code** to the `app/` directory:
   ```bash
   # Copy your application files
   cp -r /path/to/your/app/* app/
   ```

### 7.3 Create a Dockerfile

Your `app/Dockerfile` must:
- Expose port 3000
- Include a `/health` endpoint

**Example for Node.js**:
```dockerfile
FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy app code
COPY . .

# Expose port 3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

# Run app
CMD ["npm", "start"]
```

**Example for Python/Flask**:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy app code
COPY . .

# Expose port 3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s CMD curl -f http://localhost:3000/health || exit 1

# Run app
CMD ["python", "app.py"]
```

### 7.4 Add Health Endpoint

Your app must respond to `GET /health` with status 200.

**Example (Express/Node.js)**:
```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

**Example (Flask/Python)**:
```python
@app.route('/health')
def health():
    return {'status': 'ok'}, 200
```

### 7.5 Test Locally (Optional)

Before deploying, test your Docker build:

```bash
# Build image
docker build -t myapp ./app

# Run container
docker run -p 3000:3000 myapp

# In another terminal, test
curl http://localhost:3000/health
```

### 7.6 Deploy to Production

```bash
git add .
git commit -m "feat: replace example app with my application"
git push origin main
```

### 7.7 Watch Deployment

1. Go to **Actions** tab in GitHub
2. Watch the **"Deploy to VPS"** workflow run
3. Wait for completion (~3-5 minutes)

### 7.8 Access Your App

Visit `http://YOUR_VPS_IP` to see your app live!

✅ **Checkpoint**: Your own app is now deployed!

---

## Troubleshooting

### Issue: Workflow Failed - "terraform.tfvars not found"

**Cause**: GitHub secrets not configured correctly.

**Fix**:
1. Go to Settings → Secrets → Actions
2. Verify all 5 secrets exist
3. Re-run the workflow

### Issue: Workflow Failed - "SSH connection refused"

**Cause**: VPS not ready yet, or cloud-init still running.

**Fix**:
1. Wait 5 minutes for cloud-init to complete
2. Re-run the workflow
3. Check Hetzner Console - is VPS running?

### Issue: App Not Accessible

**Symptoms**: `curl http://VPS_IP` times out.

**Diagnosis**:
```bash
# SSH to VPS
ssh deploy@YOUR_VPS_IP

# Check if container is running
docker compose ps

# Check logs
docker compose logs app
```

**Common fixes**:
- Container crashed: Check logs for errors
- Port not exposed: Verify Dockerfile has `EXPOSE 3000`
- App not listening: Verify app binds to `0.0.0.0:3000`

### Issue: "Port 3000 already in use"

**Fix**:
Change the port in your app, or update `deploy/docker-compose.yml`:
```yaml
ports:
  - "80:YOUR_APP_PORT"  # Change YOUR_APP_PORT to match your app
```

### Issue: Docker Build Failed

**Fix**:
1. Test locally: `docker build -t test ./app`
2. Check Dockerfile syntax
3. Verify all files are in `app/` directory
4. Check GitHub Actions logs for specific error

### Issue: Health Check Failing

**Symptoms**: Container keeps restarting.

**Fix**:
1. Verify `/health` endpoint exists and returns 200
2. Test locally: `curl http://localhost:3000/health`
3. Check app logs for errors

### Issue: Out of Money / Unexpected Charges

**Prevention**:
Set up billing alerts in Hetzner:
1. Hetzner Console → Billing → Alerts
2. Set monthly limit (e.g., $10)

**Destroy infrastructure**:
1. Go to Actions → Provision Infrastructure
2. Run workflow
3. Check "Destroy infrastructure"
4. Click Run workflow

### Getting More Help

- **Documentation**: [README.md](../README.md)
- **Operations**: [RUNBOOK.md](RUNBOOK.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/vibe_in_vps/issues)

---

## Next Steps

After successful deployment:

1. **Configure custom domain** (coming soon - Cloudflare integration)
2. **Add environment variables**: SSH to VPS, edit `/opt/app/.env`
3. **Set up monitoring alerts**: Configure healthchecks.io channels
4. **Add database** (coming soon - setup wizard)

---

## Cost Breakdown

**Monthly costs**:
- Hetzner CPX22 VPS: ~$7.50/month
- GitHub Actions: Free (2,000 minutes/month for public repos)
- healthchecks.io: Free (up to 20 checks)

**Total**: ~$5.50/month

**Cheaper option**:
- Hetzner CX11: $3.79/month (1 vCPU, 2GB RAM)
- Change `server_type = "cx11"` in Terraform variables

---

## Summary

Congratulations! You've successfully:

✅ Forked the repository
✅ Created necessary accounts
✅ Configured GitHub secrets
✅ Provisioned a VPS with Terraform (via GitHub Actions)
✅ Deployed an application
✅ Set up automated deployments
✅ (Optional) Configured monitoring

**From now on**: Just `git push` to deploy!

Your deployment pipeline is fully automated. 🚀
