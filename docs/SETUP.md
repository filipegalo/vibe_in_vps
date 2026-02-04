# Complete Setup Guide

This guide walks you through deploying your first application using vibe_in_vps, from creating accounts to accessing your deployed app.

**Time to complete**: 5-10 minutes

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Interactive Setup Wizard](#interactive-setup-wizard)
3. [Step 1: Fork Repository](#step-1-fork-repository)
4. [Step 2: Create Accounts](#step-2-create-accounts)
5. [Step 3: Generate SSH Keys](#step-3-generate-ssh-keys)
6. [Step 4: Configure GitHub Secrets](#step-4-configure-github-secrets)
7. [Step 5: Run Setup Workflow](#step-5-run-setup-workflow)
8. [Step 6: Verify Deployment](#step-6-verify-deployment)
9. [Step 7: Deploy Your Own App](#step-7-deploy-your-own-app)
10. [Database Setup](#database-setup)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, you'll need:

- **A computer** with internet access
- **A web browser**
- **Terminal/Command Line** access (macOS/Linux built-in, Windows: WSL or Git Bash)
- **15 minutes** of your time

**No installation required!** Everything runs in GitHub Actions.

---

## Interactive Setup Wizard

The easiest way to set up vibe_in_vps is using the interactive setup wizard. It guides you through each step with clear instructions and handles SSH key generation and database configuration automatically.

### Running the Wizard

```bash
npm run setup-wizard
```

### Navigation Keys

The wizard uses keyboard navigation:

| Key | Action |
|-----|--------|
| `N` | Move to **N**ext step |
| `P` | Move to **P**revious step |
| `Q` | **Q**uit the wizard |

**Note**: Pressing any other key will refresh the current step display, keeping the wizard responsive.

### Step-Specific Keys

Different steps have additional commands:

**Step 3 - SSH Keys:**

| Key | Action |
|-----|--------|
| `G` | **G**enerate new SSH keys (saves to `.ssh/` directory) |
| `V` | **V**iew existing SSH keys |

When you generate or view keys, you'll see a "Press any key to continue" prompt. Any keypress returns you to the current step.

If SSH keys already exist in the project directory, pressing `G` will regenerate them (the old keys are automatically deleted first to avoid interactive prompts).

**Step 4 - Database Selection:**

| Key | Action |
|-----|--------|
| `1` | Toggle **PostgreSQL** on/off |
| `2` | Toggle **MySQL** on/off |
| `3` | Toggle **Redis** on/off |

Toggling a database automatically:
- Updates `deploy/docker-compose.yml` (uncomments/comments the service)
- Saves your selection to `.setup-config.json`
- Configures environment variables and health check dependencies

**Step 5 - SSH Access Configuration:**

| Key | Action |
|-----|--------|
| `E` | **E**nable/Disable direct SSH access from your computer |
| `I` | Set your **I**P address (only available when direct access is enabled) |

By default, SSH access is restricted to GitHub Actions only. If you need to SSH directly from your machine for troubleshooting, enable direct access and add your IP address. Your IP can be found by running `curl ifconfig.me`.

**Step 6 - GitHub Secrets:**

| Key | Action |
|-----|--------|
| `K` | View full SSH **K**eys for copying to GitHub Secrets |

### Configuration Persistence

Your selections are saved to `.setup-config.json` in the project root. This file persists between wizard sessions, so you can:
- Stop and resume the wizard later
- Re-run the wizard to change database selections or SSH access settings
- Track what databases you've enabled and your SSH configuration

### What the Wizard Does

1. **Guides you through account creation** (GitHub, Hetzner, healthchecks.io)
2. **Generates SSH keys** in the project's `.ssh/` directory
3. **Lets you select databases** (PostgreSQL, MySQL, Redis)
4. **Configures SSH access** (enable direct SSH from your machine)
5. **Auto-manages docker-compose.yml** based on your database selections
6. **Shows you exactly what secrets to add** to GitHub
7. **Walks you through running workflows** and verifying deployment

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

### Option A: Using the Setup Wizard (Recommended)

If you're using the setup wizard (`npm run setup-wizard`), SSH key generation is built-in:

1. Navigate to **Step 3: Generate SSH Keys**
2. Press `G` to **G**enerate new SSH keys
3. Keys are saved to the project's `.ssh/` directory
4. Press `V` to **V**iew your keys anytime
5. In **Step 6**, press `K` to view keys formatted for GitHub Secrets

**Benefits of wizard-generated keys:**
- Stored in project directory (not your home directory)
- Automatically shown in Step 6 for easy copying
- Can be regenerated anytime by pressing `G` (old keys are automatically deleted first)

### Option B: Manual Generation

If you prefer to generate keys manually:

### 3.1 Check for Existing Keys

Open your terminal and run:
```bash
ls ~/.ssh/id_*.pub
```

**If you see files** like `id_ed25519.pub` or `id_rsa.pub`:
- You already have SSH keys. Skip to [Step 3.3](#33-copy-your-keys)

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

**Checkpoint**: You have SSH keys at `~/.ssh/id_ed25519` (private) and `~/.ssh/id_ed25519.pub` (public).

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
- Keep your **private key** secret - NEVER share it publicly
- The **public key** is safe to share

Keep your terminal open - you'll copy these values in the next step.

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

#### Secret 4: HEALTHCHECKS_API_KEY (Optional)

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

You should see 4 secrets listed:
- `HETZNER_TOKEN`
- `HEALTHCHECKS_API_KEY`
- `SSH_PRIVATE_KEY`
- `SSH_PUBLIC_KEY`

**Note**: The SSH user is always `deploy` - this is automatically configured by cloud-init and requires no secret configuration.

**Note**: After running the setup workflow in Step 5, you'll add 2 more secrets (`VPS_HOST` and `HEALTHCHECK_PING_URL`) for automatic deployments.

✅ **Checkpoint**: Initial secrets configured!

### 4.6 Optional: Add Database Secrets

If you plan to use databases (PostgreSQL, MySQL, or Redis), add these secrets now.

#### Generate Database Passwords

Run this command to generate a secure password:
```bash
openssl rand -base64 32
```

Run it once for each database you want to use.

#### Add Database Secrets

For **PostgreSQL**:
1. Click **"New repository secret"**
2. **Name**: `POSTGRES_PASSWORD`
3. **Secret**: Paste your generated password
4. Click **"Add secret"**

For **MySQL**:
1. Click **"New repository secret"**
2. **Name**: `MYSQL_ROOT_PASSWORD`
3. **Secret**: Paste your generated password
4. Click **"Add secret"**

For **Redis**:
1. Click **"New repository secret"**
2. **Name**: `REDIS_PASSWORD`
3. **Secret**: Paste your generated password
4. Click **"Add secret"**

**Note**: The setup wizard automatically uncomments database services in `deploy/docker-compose.yml` based on your selections in Step 4. You only need to add the secrets here.

See the [Database Setup](#database-setup) section for detailed instructions.

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

**What's happening** (4-5 minutes total):

**Phase 1: Provision Infrastructure (2-3 minutes)**
- ✅ Terraform initializes
- ✅ Terraform validates configuration
- ✅ Terraform creates VPS on Hetzner
- ✅ Saves Terraform state as artifact
- ✅ Displays deployment secrets to configure

**Phase 2: Verify VPS Setup (2-3 minutes)**
- ✅ Waits for VPS to accept SSH connections
- ✅ Waits for cloud-init to install Docker (~3 min)
- ✅ Verifies Docker installation

**Note**: The app is NOT deployed yet - that happens when you push code in Step 6.

### 5.4 Check for Success

When complete, you'll see:
- ✅ Green checkmark on the workflow
- ✅ "🎉 Infrastructure Provisioned!" in the summary

Click on the **"Summary"** to see:
- **VPS IP Address**
- **SSH Command**
- **What's installed** (Docker, firewall, etc.)

✅ **Checkpoint**: Your VPS is provisioned and ready for deployment!

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

## Step 6: Deploy Your Application

Your VPS is ready! Now trigger the first deployment by pushing code.

### 6.1 Trigger First Deployment

The easiest way is to make a small change and push:

```bash
# Make a small change (or just trigger rebuild)
git commit --allow-empty -m "trigger first deployment"
git push origin main
```

This will trigger the **"Deploy to VPS"** workflow which will:
1. Build your Docker image
2. Push it to GitHub Container Registry
3. Deploy it to your VPS

### 6.2 Watch the Deployment

1. Go to **Actions** tab in GitHub
2. You'll see "Deploy to VPS" workflow running
3. Click on it to watch progress (2-3 minutes)

### 6.3 Access Your Application

Once deployment completes, open your browser:
```
http://YOUR_VPS_IP
```

**You should see**:
```json
{
  "message": "Hello from vibe_in_vps!",
  "timestamp": "2026-02-02T01:00:00.000Z",
  "environment": "production"
}
```

### 6.4 Check Health Endpoint

Visit:
```
http://YOUR_VPS_IP/health
```

**You should see**:
```json
{
  "status": "ok",
  "timestamp": "2026-02-02T01:00:00.000Z",
  "uptime": 123.45
}
```

✅ **Checkpoint**: Your app is deployed and running!

### 6.5 Check Monitoring (If Enabled)

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

> **Using an AI Coding Assistant?**
>
> Check [`app/PROMPT.md`](../app/PROMPT.md) for ready-to-use prompts you can give to Claude, Cursor, GitHub Copilot, or ChatGPT. These templates ensure your generated app includes the critical requirements:
> - Port 3000 exposed
> - `/health` endpoint returning HTTP 200
> - `HEALTHCHECK` command in Dockerfile
> - Environment variables for configuration

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
2. Verify all 4 secrets exist
3. Re-run the workflow

### Issue: Workflow Failed - "SSH connection refused"

**Cause**: VPS not ready yet, or cloud-init still running.

**Fix**:
1. Wait 5 minutes for cloud-init to complete
2. Re-run the workflow
3. Check Hetzner Console - is VPS running?

### Issue: App Not Accessible

**Symptoms**: `curl http://VPS_IP` times out.

**Diagnosis** (via GitHub Actions - see [SSH Access](#ssh-access-security) below):
```bash
# Check if container is running
docker compose ps

# Check logs
docker compose logs app
```

**Common fixes**:
- Container crashed: Check logs for errors
- Port not exposed: Verify Dockerfile has `EXPOSE 3000`
- App not listening: Verify app binds to `0.0.0.0:3000`

### SSH Access Security

**Important**: SSH access to the VPS is restricted by default to GitHub Actions IP ranges only. This is a security feature that prevents unauthorized access to your server.

**Default behavior:**
- Deployments work normally (GitHub Actions IPs are always whitelisted)
- Direct SSH from your local machine is blocked unless you add your IP
- This prevents unauthorized access even if your SSH key is compromised

**Adding your IP for direct SSH access:**

There are two ways to enable direct SSH from your machine:

#### Option 1: Use the Setup Wizard (Easiest)

1. Run `npm run setup-wizard`
2. Navigate to **Step 5: Configure SSH Access**
3. Press `E` to enable direct SSH access
4. Press `I` to enter your IP address (find it with `curl ifconfig.me`)
5. Run the **Provision Infrastructure** workflow to apply changes

The wizard saves your configuration to `.setup-config.json` for persistence.

#### Option 2: Edit terraform.tfvars Manually

1. Edit `infra/terraform/terraform.tfvars`:
   ```hcl
   # Add your IP address (find it with: curl ifconfig.me)
   additional_ssh_ips = ["YOUR.IP.ADDRESS/32"]
   ```

2. Run the **Provision Infrastructure** workflow to apply changes

**Example:**
```hcl
# Allow SSH from your home IP
additional_ssh_ips = ["203.0.113.45/32"]

# Allow SSH from multiple IPs
additional_ssh_ips = ["203.0.113.45/32", "198.51.100.10/32"]
```

**How to run commands without direct SSH:**

#### Use GitHub Actions Workflow (When SSH is disabled)

Create a workflow dispatch to run commands remotely:

1. Go to **Actions** tab in your repository
2. Create or use an existing workflow with SSH access
3. The deployment workflow already has SSH access - you can add debug steps there

Example: Add a debug step to `.github/workflows/deploy.yml`:
```yaml
- name: Debug - Check container status
  run: |
    ssh -o StrictHostKeyChecking=no deploy@${{ secrets.VPS_HOST }} << 'EOF'
      docker compose ps
      docker compose logs --tail=50 app
    EOF
```

#### Use Hetzner Cloud Console (Emergency Access)

For emergency situations when you need immediate access:

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Select your project and server
3. Click **"Console"** button (top right of server details)
4. This opens a browser-based console with direct access
5. Log in as the `deploy` user

**Note**: The console provides full access regardless of firewall rules.

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

### Issue: Setup Wizard Not Responding

**Symptoms**: Pressing keys has no effect, or wizard appears frozen.

**Fix**:
1. Press `Ctrl+C` to exit the wizard
2. Restart with `npm run setup-wizard`
3. If the issue persists, ensure your terminal supports raw mode

**Note**: The wizard is designed to stay responsive. Pressing any invalid key will simply refresh the current step display rather than doing nothing.

### Issue: SSH Key Generation Fails in Wizard

**Symptoms**: Pressing `G` shows an error about key generation.

**Possible causes**:
- `ssh-keygen` not installed (rare on macOS/Linux)
- Permission issues with the `.ssh/` directory

**Fix**:
1. Generate keys manually (see [Step 3: Generate SSH Keys](#step-3-generate-ssh-keys))
2. Or ensure `ssh-keygen` is in your PATH

### Issue: Database Toggle Not Updating docker-compose.yml

**Symptoms**: Toggling databases in Step 4 but `docker-compose.yml` unchanged.

**Possible causes**:
- Missing block markers in `docker-compose.yml`
- File permission issues

**Fix**:
1. Check that `deploy/docker-compose.yml` contains the marker comments like `# [POSTGRES_START]`
2. Verify you have write permissions to the file
3. Manually uncomment the database services as described in [Manual Method](#2-manual-method-alternative)

### Getting More Help

- **Documentation**: [README.md](../README.md)
- **Operations**: [RUNBOOK.md](RUNBOOK.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/vibe_in_vps/issues)

---

## Database Setup

vibe_in_vps supports optional PostgreSQL, MySQL, and Redis databases running in Docker containers on your VPS.

### When to Add Databases

- **During initial setup**: Use the setup wizard or add database secrets in [Step 4.6](#46-optional-add-database-secrets)
- **After deployment**: Re-run the wizard or manually edit `docker-compose.yml`

### Step-by-Step: Enable a Database

#### 1. Run Setup Wizard (Recommended)

The easiest way to enable databases is through the interactive setup wizard:

```bash
npm run setup-wizard
```

Navigate to **Step 4: Optional Database Selection** using `N` (next) key, then:

| Key | Database |
|-----|----------|
| `1` | Toggle **PostgreSQL** on/off |
| `2` | Toggle **MySQL** on/off |
| `3` | Toggle **Redis** on/off |

Press the number key to toggle a database. A checkmark indicates the database is enabled.

**What happens automatically when you toggle:**
- Database services uncommented/commented in `deploy/docker-compose.yml`
- Environment variables (DATABASE_URL, etc.) uncommented/commented
- Health check dependencies configured
- Volume persistence enabled/disabled
- Configuration saved to `.setup-config.json`

**Configuration persistence:**
Your database selections are saved to `.setup-config.json`. You can:
- Close the wizard and come back later - your selections are preserved
- Re-run the wizard anytime to change database selections
- View the file to see what's currently enabled

Then proceed to **Step 6** in the wizard, which will show you exactly which database secrets you need to add based on your selections.

#### 2. Manual Method (Alternative)

If you prefer to enable databases manually:

**Add GitHub Secrets:**

See [Step 4.6](#46-optional-add-database-secrets) for instructions.

Required secrets by database:
- **PostgreSQL**: `POSTGRES_PASSWORD`
- **MySQL**: `MYSQL_ROOT_PASSWORD`
- **Redis**: `REDIS_PASSWORD`

**Edit docker-compose.yml:**

Open `deploy/docker-compose.yml` in your repository and:

**For PostgreSQL:**
```yaml
# Uncomment the entire postgres service section
postgres:
  image: postgres:16-alpine
  container_name: postgres
  # ... rest of config
```

**For MySQL:**
```yaml
# Uncomment the entire mysql service section
mysql:
  image: mysql:8.0
  container_name: mysql
  # ... rest of config
```

**For Redis:**
```yaml
# Uncomment the entire redis service section
redis:
  image: redis:7-alpine
  container_name: redis
  # ... rest of config
```

#### 3. Enable Connection Strings

In the same file, uncomment the relevant environment variables in the `app` service:

```yaml
services:
  app:
    environment:
      # Uncomment the ones you need:
      - DATABASE_URL=postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB:-app}
      - MYSQL_URL=mysql://${MYSQL_USER:-app}:${MYSQL_PASSWORD}@mysql:3306/${MYSQL_DATABASE:-app}
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
```

#### 4. Enable Service Dependencies

Uncomment the `depends_on` section to ensure databases start before your app:

```yaml
services:
  app:
    depends_on:
      postgres:
        condition: service_healthy
      # Add others as needed
```

#### 5. Enable Volume Persistence

Uncomment the volumes at the bottom of the file:

```yaml
volumes:
  postgres-data:
  mysql-data:
  redis-data:
```

#### 6. Deploy

Commit and push your changes:

```bash
git add deploy/docker-compose.yml
git commit -m "feat: enable database support"
git push origin main
```

The deployment workflow will automatically start the database containers.

### Connecting to Databases

#### From Your Application

Use the connection string environment variables:

**PostgreSQL:**
```javascript
const DATABASE_URL = process.env.DATABASE_URL
// postgresql://app:PASSWORD@postgres:5432/app
```

**MySQL:**
```javascript
const MYSQL_URL = process.env.MYSQL_URL
// mysql://app:PASSWORD@mysql:3306/app
```

**Redis:**
```javascript
const REDIS_URL = process.env.REDIS_URL
// redis://:PASSWORD@redis:6379
```

#### From Hetzner Console (Development/Debugging)

> **Note**: Direct SSH is restricted to GitHub Actions only. Use [Hetzner Cloud Console](https://console.hetzner.cloud/) for interactive database access. See [SSH Access Security](#ssh-access-security) for details.

After connecting via Hetzner Console:
```bash
cd /opt/app
```

**PostgreSQL:**
```bash
docker compose exec postgres psql -U app -d app
```

**MySQL:**
```bash
docker compose exec mysql mysql -u app -p
```

**Redis:**
```bash
docker compose exec redis redis-cli -a YOUR_PASSWORD
```

### Database Architecture

- **Network**: All databases run on an internal Docker network (`app-network`)
- **Ports**: No external ports exposed - only accessible from your app container
- **Storage**: Persistent volumes ensure data survives container restarts
- **Health checks**: Databases must be healthy before app starts
- **Security**: Passwords passed via environment variables, never hardcoded

---

## Database Backup and Restore

vibe_in_vps includes a built-in backup script (`deploy/scripts/db-backup.sh`) that handles PostgreSQL, MySQL, and Redis backups with automatic 7-day retention.

### Running Manual Backups

To run a backup manually, use a GitHub Actions workflow or Hetzner Console.

**Via GitHub Actions** (add to your workflow):
```yaml
- name: Run database backup
  run: |
    ssh deploy@${{ secrets.VPS_HOST }} 'cd /opt/app && ./scripts/db-backup.sh'
```

**Via Hetzner Console:**
```bash
cd /opt/app && ./scripts/db-backup.sh
```

The script will:
- Back up all running database containers (PostgreSQL, MySQL, Redis)
- Create timestamped backup files in `/opt/app/backups/`
- Automatically delete backups older than 7 days
- Display a summary of all backups and disk usage

### Backup File Locations

Backups are stored in `/opt/app/backups/` with timestamped filenames:

| Database | Backup Format | Example Filename |
|----------|---------------|------------------|
| PostgreSQL | Compressed SQL | `postgres_20260204_120000.sql.gz` |
| MySQL | Compressed SQL | `mysql_20260204_120000.sql.gz` |
| Redis | RDB snapshot | `redis_20260204_120000.rdb` |

### Setting Up Automated Daily Backups

To run backups automatically every day at 2:00 AM, use Hetzner Console to set up a cron job:

1. Connect via [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Edit crontab:
   ```bash
   crontab -e
   ```
3. Add this line for daily backups at 2:00 AM:
   ```
   0 2 * * * cd /opt/app && ./scripts/db-backup.sh >> /opt/app/backups/backup.log 2>&1
   ```
4. Save and exit

The cron job will run daily and append logs to `/opt/app/backups/backup.log`.

### Viewing and Downloading Backups

**List available backups** (via GitHub Actions workflow):
```yaml
- name: List backups
  run: |
    ssh deploy@${{ secrets.VPS_HOST }} 'ls -lh /opt/app/backups/'
```

**Download backups via GitHub Actions:**
```yaml
- name: Download backups
  run: |
    scp deploy@${{ secrets.VPS_HOST }}:/opt/app/backups/*.sql.gz ./
- uses: actions/upload-artifact@v4
  with:
    name: database-backups
    path: "*.sql.gz"
```

Then download the artifact from the GitHub Actions run page.

### Backup Retention Policy

- **Retention period**: 7 days (configurable in `db-backup.sh`)
- **Automatic cleanup**: Old backups are deleted after each backup run
- **Manual cleanup**: Run `find /opt/app/backups -mtime +7 -delete` to remove old files

### Restore Procedures

> **Note**: Restore operations require Hetzner Console access for interactive commands. Connect via [Hetzner Cloud Console](https://console.hetzner.cloud/).

#### Restore PostgreSQL

```bash
# Via Hetzner Console
cd /opt/app

# Stop the app to prevent database writes during restore
docker compose stop app

# Restore from backup (replace filename with your backup)
gunzip -c backups/postgres_20260204_120000.sql.gz | docker exec -i postgres psql -U app -d app

# Restart the app
docker compose start app
```

#### Restore MySQL

```bash
# Via Hetzner Console
cd /opt/app

# Stop the app to prevent database writes during restore
docker compose stop app

# Restore from backup (replace filename and password)
gunzip -c backups/mysql_20260204_120000.sql.gz | docker exec -i mysql mysql -u root -p"YOUR_PASSWORD"

# Restart the app
docker compose start app
```

#### Restore Redis

```bash
# Via Hetzner Console
cd /opt/app

# Stop Redis
docker compose stop redis

# Copy the backup file into the Redis data volume
docker cp backups/redis_20260204_120000.rdb redis:/data/dump.rdb

# Restart Redis (it will load the dump.rdb on startup)
docker compose start redis
```

---

## Next Steps

After successful deployment:

1. **Add databases**: See [Database Setup](#database-setup) section
2. **Configure custom domain** (coming soon - Cloudflare integration)
3. **Add environment variables**: Via GitHub Secrets (recommended) or Hetzner Console - see [docs/RUNBOOK.md](RUNBOOK.md)
4. **Set up monitoring alerts**: Configure healthchecks.io channels

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
