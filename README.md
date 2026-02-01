# vibe_in_vps

> Zero-ops deployment template: Fork, push, deployed. ✨

Deploy your Dockerized app to a cheap VPS with **zero manual server setup**. Just fork this repo, add your Dockerfile, push to GitHub, and your app auto-deploys to a Hetzner VPS.

## What is this?

This is a deployment template that handles the entire DevOps pipeline for you:

- **Infrastructure**: Terraform provisions a Hetzner VPS (~$5/month)
- **CI/CD**: GitHub Actions builds and deploys on every push
- **Monitoring**: healthchecks.io alerts you if your app goes down
- **Runtime**: Docker + Docker Compose (no Kubernetes complexity)

**Target Time**: Fresh fork to deployed app in under 10 minutes.

## Who is this for?

- Frontend developers who want to deploy a side project
- Junior developers learning deployment
- Hobbyists who want cheap hosting without the DevOps headache
- Anyone who just needs a simple app running on a server

## What you need

- [ ] GitHub account (free)
- [ ] Hetzner Cloud account ([sign up](https://console.hetzner.cloud/), free tier available)
- [ ] healthchecks.io account ([sign up](https://healthchecks.io/), free tier: 20 checks)
- [ ] A Dockerfile for your application
- [ ] Terraform installed locally ([download](https://www.terraform.io/downloads))
- [ ] SSH key pair (or generate one: `ssh-keygen -t ed25519`)

## Quick Start (10 minutes)

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

### Step 3: Configure Terraform

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and fill in your values:

```hcl
hcloud_token         = "your-hetzner-api-token"
healthchecks_api_key = "your-healthchecks-api-key"
ssh_public_key       = "ssh-ed25519 AAAA... your-email@example.com"
github_repository    = "yourusername/vibe_in_vps"
```

### Step 4: Provision the VPS

```bash
terraform init
terraform plan   # Review what will be created
terraform apply  # Type 'yes' to confirm
```

Terraform will output important values. **Save these!**

```
server_ip = "1.2.3.4"
ssh_command = "ssh deploy@1.2.3.4"
healthcheck_ping_url = "https://hc-ping.com/..."
```

### Step 5: Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `VPS_HOST` | The `server_ip` from Terraform output |
| `VPS_SSH_KEY` | Your **private** SSH key (from `~/.ssh/id_ed25519`) |
| `VPS_USER` | `deploy` |
| `HEALTHCHECK_PING_URL` | The `healthcheck_ping_url` from Terraform output |

### Step 6: Run initial setup

Go to **Actions** → **Initial VPS Setup** → **Run workflow**

This runs once to bootstrap the VPS.

### Step 7: Deploy your app

Push to the `main` branch:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will:
1. Build your Docker image
2. Push to GitHub Container Registry
3. Deploy to your VPS
4. Ping healthchecks.io

### Step 8: Access your app

Visit `http://<your-server-ip>` in your browser.

You should see: `{"message":"Hello from vibe_in_vps!"}`

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

Edit `deploy/.env.example` and add your variables:

```bash
GITHUB_REPOSITORY=yourusername/vibe_in_vps
DATABASE_URL=postgres://...
API_KEY=your-api-key
```

SSH to the VPS and create `/opt/app/.env`:

```bash
ssh deploy@<your-server-ip>
cd /opt/app
nano .env  # Add your variables
```

Restart the app:

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

### WARNING: This deletes your VPS and all data!

```bash
cd infra/terraform
terraform destroy
```

Then manually delete:
1. Docker images from [GitHub Packages](https://github.com/settings/packages)
2. healthchecks.io check from [dashboard](https://healthchecks.io/projects/)

## Common pitfalls

### "Permission denied (publickey)"

**Problem**: SSH key not configured correctly

**Solution**: Make sure you added the **private** key to GitHub Secrets, not the public key.

```bash
# This is your PRIVATE key (add to GitHub Secrets)
cat ~/.ssh/id_ed25519

# This is your PUBLIC key (add to terraform.tfvars)
cat ~/.ssh/id_ed25519.pub
```

### "Port 80 already in use"

**Problem**: Another service is using port 80

**Solution**: SSH to the VPS and check what's running:

```bash
ssh deploy@<your-server-ip>
sudo lsof -i :80
docker compose ps
```

### "Docker build fails in GitHub Actions"

**Problem**: Dockerfile has errors

**Solution**: Test locally first:

```bash
./scripts/test-local.sh
```

### "healthchecks.io shows 'DOWN'"

**Problem**: App is not responding to health checks

**Solution**: Check if the app is running:

```bash
ssh deploy@<your-server-ip>
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
ssh deploy@<your-server-ip> 'docker compose ps'
```

### View logs

```bash
ssh deploy@<your-server-ip> 'docker compose logs -f app'
```

### healthchecks.io dashboard

Visit [healthchecks.io/projects/](https://healthchecks.io/projects/) to see uptime status and configure alerts (email, Slack, etc.)

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
