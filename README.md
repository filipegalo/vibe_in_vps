# vibe_in_vps

> Zero-ops deployment template: Fork, add secrets, click run. ✨

Deploy your Dockerized app to a cheap VPS with **zero manual setup**. No Terraform CLI, no SSH, no server configuration. Just fork this repo, add GitHub secrets, click "Run workflow", and your app is live.

## What is this?

This is a deployment template that handles the entire DevOps pipeline for you:

- **Infrastructure**: Terraform (runs in GitHub Actions) provisions a Hetzner VPS (~$5/month)
- **CI/CD**: GitHub Actions builds and deploys on every push
- **Monitoring**: healthchecks.io alerts you if your app goes down
- **Runtime**: Docker + Docker Compose (no Kubernetes complexity)

**Target Time**: Fresh fork to deployed app in **under 5 minutes**.

## Who is this for?

- Frontend developers who want to deploy a side project
- Junior developers learning deployment
- Hobbyists who want cheap hosting without the DevOps headache
- Anyone who just needs a simple app running on a server

## What you need

- [ ] GitHub account (free)
- [ ] Hetzner Cloud account ([sign up](https://console.hetzner.cloud/), free tier available)
- [ ] healthchecks.io account ([sign up](https://healthchecks.io/), free tier: 20 checks)
- [ ] SSH key pair (or generate one: `ssh-keygen -t ed25519`)

**You do NOT need:**
- ❌ Terraform installed locally
- ❌ SSH access to configure servers
- ❌ Docker installed locally
- ❌ Any DevOps experience

## Quick Start (5 minutes)

### Step 1: Fork this repository

Click the "Fork" button at the top of this page.

### Step 2: Get your API tokens

**Hetzner API Token:**
1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create a new project (or use existing)
3. Go to **Security** → **API Tokens** → **Generate API Token**
4. Give it "Read & Write" permissions
5. Copy the token

**healthchecks.io API Key:**
1. Go to [healthchecks.io](https://healthchecks.io/)
2. Sign up for free account
3. Go to **Settings** → **API Access**
4. Copy your API key

### Step 3: Generate SSH keys (if you don't have them)

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Press Enter for all prompts (no passphrase needed for automation).

**View your keys:**
```bash
# Public key (for GitHub secret SSH_PUBLIC_KEY)
cat ~/.ssh/id_ed25519.pub

# Private key (for GitHub secret SSH_PRIVATE_KEY)
cat ~/.ssh/id_ed25519
```

### Step 4: Add GitHub Secrets

Go to your forked repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these **5 secrets**:

| Secret Name | Value | How to get it |
|-------------|-------|---------------|
| `HETZNER_TOKEN` | Your Hetzner API token | From Step 2 |
| `HEALTHCHECKS_API_KEY` | Your healthchecks.io API key | From Step 2 |
| `SSH_PUBLIC_KEY` | Your SSH **public** key | `cat ~/.ssh/id_ed25519.pub` |
| `SSH_PRIVATE_KEY` | Your SSH **private** key (entire file) | `cat ~/.ssh/id_ed25519` |
| `VPS_USER` | `deploy` | Just type: `deploy` |

### Step 5: Run the setup workflow

1. Go to **Actions** tab in your repo
2. Click **"Initial VPS Setup"** in the left sidebar
3. Click **"Run workflow"** button (top right)
4. Click the green **"Run workflow"** button

**What happens next:**
- ✅ Terraform provisions a Hetzner VPS (~2 minutes)
- ✅ Cloud-init installs Docker (~3 minutes)
- ✅ Bootstrap script deploys your app (~1 minute)
- ✅ GitHub secrets are automatically configured
- ✅ healthchecks.io monitoring is activated

**Total time: ~6 minutes**

### Step 6: Access your app

When the workflow completes, check the **Summary** tab for your app URL:

```
http://YOUR_VPS_IP
```

You should see:
```json
{
  "message": "Hello from vibe_in_vps!",
  "timestamp": "2024-01-15T12:34:56.789Z",
  "environment": "production"
}
```

**That's it!** Your app is live.

## How deployments work

```
You push to main
      │
      ▼
GitHub Actions builds Docker image
      │
      ▼
Pushes to ghcr.io (GitHub Container Registry)
      │
      ▼
SSH to VPS → docker compose pull && up -d
      │
      ▼
Pings healthchecks.io ✓
```

## How updates work

Just push to `main`. That's it.

```bash
# Make changes to your app
vim app/server.js

# Commit and push
git add .
git commit -m "Update server"
git push origin main
```

GitHub Actions automatically:
- Builds new image
- Deploys to VPS
- Verifies health check

## Adding your own app

### Replace the example app

1. Delete everything in `/app` except `.gitkeep`
2. Add your application code
3. Add a `Dockerfile` that:
   - Exposes port 3000
   - Includes a `/health` endpoint (for health checks)
4. Push to main

### Example Dockerfile requirements

```dockerfile
FROM node:20-alpine

# Your build steps here
COPY . .
RUN npm install

# Must expose port 3000
EXPOSE 3000

# Must include health check
HEALTHCHECK --interval=30s CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["npm", "start"]
```

### Health endpoint

Your app must respond to `GET /health` with a 200 status code:

```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

## Environment variables

### Adding app-specific environment variables

SSH to the VPS and edit `/opt/app/.env`:

```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
nano .env  # Add your variables
```

Then restart:
```bash
docker compose restart app
```

## Persistent storage

### Adding volumes

Edit `deploy/docker-compose.yml`:

```yaml
services:
  app:
    volumes:
      - app-data:/app/data  # Your app's data directory

volumes:
  app-data:  # This persists across deployments
```

## How to destroy everything

### Option 1: Via GitHub Actions (Recommended)

1. Go to **Actions** → **Initial VPS Setup**
2. Click **Run workflow**
3. Check the **"Destroy infrastructure"** checkbox
4. Click **Run workflow**

This will:
- Destroy the Hetzner VPS
- Delete the healthchecks.io check
- Clean up all resources

### Option 2: Manual cleanup

Manually delete:
1. VPS from [Hetzner Console](https://console.hetzner.cloud/)
2. Docker images from [GitHub Packages](https://github.com/settings/packages)
3. healthchecks.io check from [dashboard](https://healthchecks.io/projects/)

## Common pitfalls

### "Terraform state not found" when destroying

**Problem**: Terraform state is stored as a GitHub Actions artifact

**Solution**: Download the state first:
1. Go to **Actions** → find your setup workflow run
2. Download "terraform-state" artifact
3. Extract to `infra/terraform/terraform.tfstate`
4. Run destroy workflow

### "Permission denied (publickey)"

**Problem**: SSH key not configured correctly

**Solution**: Make sure you added the **entire private key** to `SSH_PRIVATE_KEY` secret:

```bash
# Copy this ENTIRE output (including BEGIN/END lines)
cat ~/.ssh/id_ed25519
```

### "Port 80 already in use"

**Problem**: Another service is using port 80

**Solution**: SSH to the VPS and check:

```bash
ssh deploy@YOUR_VPS_IP
sudo lsof -i :80
docker compose ps
```

### "healthchecks.io shows 'DOWN'"

**Problem**: App is not responding to health checks

**Solution**: Check if the app is running:

```bash
ssh deploy@YOUR_VPS_IP
docker compose ps
docker compose logs app
```

Make sure your app has a `/health` endpoint.

## Cost estimate

| Service | Cost | Notes |
|---------|------|-------|
| Hetzner CX22 VPS | ~$5.50/mo | 2 vCPU, 4GB RAM, 40GB SSD |
| GitHub Actions | Free | 2,000 minutes/month (public repos) |
| GitHub Container Registry | Free | Public repos |
| healthchecks.io | Free | Up to 20 checks |
| **Total** | **~$5.50/mo** | |

### Cheaper options

- **CX11** ($3.79/mo): 1 vCPU, 2GB RAM - Good for low-traffic apps
- **ARM instances**: Even cheaper, but requires ARM-compatible Docker images

## Monitoring & logs

### Check app status

```bash
ssh deploy@YOUR_VPS_IP 'docker compose ps'
```

### View logs

```bash
ssh deploy@YOUR_VPS_IP 'docker compose logs -f app'
```

### healthchecks.io dashboard

Visit [healthchecks.io/projects/](https://healthchecks.io/projects/) to see uptime status and configure alerts (email, Slack, etc.)

## Advanced: Terraform state management

**Important**: Terraform state is stored as a GitHub Actions artifact (90-day retention).

### Download state

1. Go to **Actions** → find your setup workflow run
2. Download "terraform-state" artifact
3. Extract `terraform.tfstate` to `infra/terraform/`

### Best practices for production

For production deployments, use a remote backend:

- **Terraform Cloud** (free tier available)
- **AWS S3 + DynamoDB** (with state locking)
- **Azure Blob Storage**
- **Google Cloud Storage**

See `infra/terraform/backend.tf.example` for configuration examples.

## Roadmap / TODOs

- [ ] Cloudflare integration for custom domains + SSL
- [ ] Setup wizard for optional database (PostgreSQL, MySQL, Redis)
- [ ] Cost monitoring in Terraform outputs
- [ ] Multi-app support (multiple apps on same VPS)

## Contributing

Contributions are welcome! Please open an issue or PR.

### Guidelines

- Keep it simple (this is for beginners)
- Avoid adding complexity that requires DevOps knowledge
- Prefer boring, proven tools
- Update documentation for all changes

## License

MIT License - feel free to use this for your projects!

## Need help?

- Open an issue on GitHub
- Check [docs/SETUP.md](docs/SETUP.md) for detailed setup instructions
- See [CLAUDE.md](CLAUDE.md) for architecture decisions

---

**Built with** ❤️ **for developers who just want to deploy their apps without the DevOps headache.**
