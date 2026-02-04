# Operations Runbook

Quick reference for common operational tasks.

## Deployments

### Normal Deployment

**Trigger**: Push to `main` branch

**Process**:
1. GitHub Actions builds Docker image
2. Pushes to GHCR
3. SSH to VPS and pulls new image
4. Restarts app container
5. Pings healthchecks.io (if configured)
6. Creates GitHub Deployment

**Duration**: 3-5 minutes

### Manual Deployment

1. Go to Actions → Deploy to VPS
2. Click "Run workflow"
3. Select branch
4. Click Run

## Monitoring

### Check App Health

```bash
# Via HTTP
curl http://YOUR_VPS_IP/health

# Via SSH
ssh deploy@YOUR_VPS_IP 'docker compose ps'
```

### View Logs

> **Note**: Direct SSH access is restricted to GitHub Actions only. See [Troubleshooting Access](#troubleshooting-access) for how to run commands.

**Via GitHub Actions workflow:**
```yaml
# Add to your workflow to view logs
- name: View app logs
  run: |
    ssh deploy@${{ secrets.VPS_HOST }} 'docker compose logs --tail=100 app'
```

**Via Hetzner Console** (for emergency access):
```bash
# After connecting via Hetzner Cloud Console
cd /opt/app
docker compose logs -f app
```

### GitHub Deployments

View deployment history: `Code → Environments → production`

### healthchecks.io (if enabled)

Dashboard: https://healthchecks.io/projects/

## Database Operations

> **Note**: All database commands must be run via GitHub Actions workflow or Hetzner Cloud Console. See [Troubleshooting Access](#troubleshooting-access) for how to access the VPS.

### View Database Status

```bash
# Run on VPS (via GitHub Actions or Hetzner Console)
docker compose ps postgres mysql redis
```

### Connect to Databases

#### PostgreSQL
```bash
# After connecting via Hetzner Console or GitHub Actions
cd /opt/app
docker compose exec postgres psql -U app -d app
```

Common commands:
- `\dt` - List tables
- `\d table_name` - Describe table
- `\q` - Quit

#### MySQL
```bash
# After connecting via Hetzner Console or GitHub Actions
cd /opt/app
docker compose exec mysql mysql -u app -p
```

Common commands:
- `SHOW TABLES;` - List tables
- `DESCRIBE table_name;` - Describe table
- `EXIT;` - Quit

#### Redis
```bash
# After connecting via Hetzner Console or GitHub Actions
cd /opt/app
docker compose exec redis redis-cli -a YOUR_PASSWORD
```

Common commands:
- `KEYS *` - List all keys
- `GET key` - Get value
- `EXIT` - Quit

### Database Logs

```bash
# Run on VPS (via GitHub Actions or Hetzner Console)
# PostgreSQL logs
docker compose logs postgres

# MySQL logs
docker compose logs mysql

# Redis logs
docker compose logs redis
```

### Database Restart

```bash
# Run on VPS (via GitHub Actions or Hetzner Console)
# Restart PostgreSQL
docker compose restart postgres

# Restart MySQL
docker compose restart mysql

# Restart Redis
docker compose restart redis
```

### Storage Space

Check database volume usage:
```bash
# Run on VPS (via GitHub Actions or Hetzner Console)
docker system df -v
```

### Database Backups

The backup script at `/opt/app/scripts/db-backup.sh` handles automated backups for all database types with 7-day retention.

#### Run Manual Backup

Via GitHub Actions workflow:
```yaml
- name: Run database backup
  run: |
    ssh deploy@${{ secrets.VPS_HOST }} 'cd /opt/app && ./scripts/db-backup.sh'
```

Or via Hetzner Console:
```bash
cd /opt/app && ./scripts/db-backup.sh
```

#### View Available Backups

Via GitHub Actions workflow:
```yaml
- name: List backups
  run: |
    ssh deploy@${{ secrets.VPS_HOST }} 'ls -lh /opt/app/backups/'
```

#### Download Backups

Backups must be downloaded via GitHub Actions. Add a workflow step:
```yaml
- name: Download backup
  run: |
    scp deploy@${{ secrets.VPS_HOST }}:/opt/app/backups/postgres_*.sql.gz ./
- uses: actions/upload-artifact@v4
  with:
    name: database-backup
    path: "*.sql.gz"
```

#### Set Up Automated Daily Backups

Via Hetzner Console, edit crontab:
```bash
crontab -e

# Add this line for daily 2 AM backups
0 2 * * * cd /opt/app && ./scripts/db-backup.sh >> /opt/app/backups/backup.log 2>&1
```

#### Restore Procedures

> **Note**: Restore operations require Hetzner Console access for interactive commands.

**PostgreSQL:**
```bash
# Via Hetzner Console
cd /opt/app
docker compose stop app
gunzip -c backups/postgres_TIMESTAMP.sql.gz | docker exec -i postgres psql -U app -d app
docker compose start app
```

**MySQL:**
```bash
# Via Hetzner Console
cd /opt/app
docker compose stop app
gunzip -c backups/mysql_TIMESTAMP.sql.gz | docker exec -i mysql mysql -u root -p"PASSWORD"
docker compose start app
```

**Redis:**
```bash
# Via Hetzner Console
cd /opt/app
docker compose stop redis
docker cp backups/redis_TIMESTAMP.rdb redis:/data/dump.rdb
docker compose start redis
```

## Application Management

### Managing Environment Variables

Your application can access environment variables defined in the `.env` file on the VPS.

#### How Secrets Flow to Containers

GitHub Secrets are automatically deployed to your application through a 6-step pipeline. Understanding this flow helps with debugging configuration issues.

```
+---------------------------+
|     GITHUB SECRETS        |  1. User adds secrets in GitHub UI
+-------------+-------------+
              |
              v
+---------------------------+
|      deploy.yml           |  2. Workflow reads via ${{ secrets.VAR }}
+-------------+-------------+
              |
              v
+---------------------------+
|   SSH to VPS              |  3. Variables exported to shell
+-------------+-------------+
              |
              v
+---------------------------+
|      update.sh            |  4. Script writes to /opt/app/.env
+-------------+-------------+
              |
              v
+---------------------------+
|   docker-compose.yml      |  5. Compose reads ${VAR} from .env
+-------------+-------------+
              |
              v
+---------------------------+
|   Application Container   |  6. App accesses process.env.VAR
+---------------------------+
```

#### Pipeline Files Reference

| Step | File | Location | What It Does |
|------|------|----------|--------------|
| 1 | GitHub Secrets | Repository Settings | Secure storage for sensitive values |
| 2-3 | `deploy.yml` | `.github/workflows/deploy.yml` | Reads secrets, SSHs to VPS, exports variables |
| 4 | `update.sh` | `/opt/app/update.sh` | Writes variables to `.env` file |
| 5 | `docker-compose.yml` | `/opt/app/docker-compose.yml` | Substitutes `${VAR}` and passes to container |
| 6 | `.env` | `/opt/app/.env` | Runtime config file (auto-generated) |

#### Code Flow Example

Tracing `POSTGRES_PASSWORD` through the pipeline:

**deploy.yml (reads and exports):**
```yaml
env:
  POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}

run: |
  ssh deploy@${{ secrets.VPS_HOST }} << 'EOF'
    export POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
    ./update.sh
  EOF
```

**update.sh (writes to .env):**
```bash
cat > .env <<EOF
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}
EOF
```

**docker-compose.yml (reads from .env):**
```yaml
environment:
  - DATABASE_URL=postgresql://app:${POSTGRES_PASSWORD}@postgres:5432/app
```

**Your application:**
```javascript
const dbUrl = process.env.DATABASE_URL
// Result: "postgresql://app:actualPassword@postgres:5432/app"
```

#### The .env File is Auto-Generated

**Critical**: The `.env` file at `/opt/app/.env` is **overwritten on every deployment** by the `update.sh` script.

- Manual edits to this file will be lost on next `git push`
- To add persistent variables, update the deployment pipeline (see [SETUP.md](SETUP.md#47-how-secrets-flow-to-your-application))
- The file is created with restricted permissions for security

#### When to Use Each Method

| Method | Use For | Persists Across Deploys |
|--------|---------|-------------------------|
| GitHub Secrets | API keys, passwords, tokens | Yes (recommended) |
| Direct `.env` edit | Quick testing, debugging | No |
| Hetzner Console edit | Emergency fixes | No |

#### Two Methods to Configure Environment Variables

#### Method 1: Via GitHub Secrets (Recommended for Secrets)

This is the recommended approach for sensitive values like API keys, database credentials, and tokens.

1. **Add the secret in GitHub**:
   - Go to your repository on GitHub
   - Navigate to `Settings` > `Secrets and variables` > `Actions`
   - Click `New repository secret`
   - Enter the name (e.g., `API_KEY`) and value

2. **Update the deployment workflow** to pass the secret to the VPS:

   Edit `.github/workflows/deploy.yml` and add your variable to the SSH deployment step:
   ```yaml
   - name: Deploy to VPS
     run: |
       ssh deploy@${{ secrets.VPS_HOST }} << 'EOF'
         cd /opt/app
         echo "API_KEY=${{ secrets.API_KEY }}" >> .env
         docker compose pull app
         docker compose up -d app
       EOF
   ```

3. **Reference the variable in docker-compose.yml**:
   ```yaml
   services:
     app:
       environment:
         - API_KEY=${API_KEY}
   ```

4. **Push changes** - the variable will be available on next deployment.

#### Method 2: Direct Editing via Hetzner Console (For Non-Sensitive Values)

For non-sensitive configuration values, you can edit the `.env` file directly on the VPS using Hetzner Cloud Console.

> **Note**: Direct SSH is restricted to GitHub Actions only. Use [Hetzner Cloud Console](https://console.hetzner.cloud/) for interactive access.

```bash
# After connecting via Hetzner Console
cd /opt/app
nano .env

# Add your variables
# Example contents:
# NODE_ENV=production
# LOG_LEVEL=info
# MAX_CONNECTIONS=100

# Save and exit (Ctrl+X, Y, Enter in nano)

# Restart the app to pick up changes
docker compose restart app
```

#### Environment Block Structure

The `docker-compose.yml` environment section defines which variables are passed to your container:

```yaml
services:
  app:
    image: ghcr.io/${GITHUB_REPOSITORY}:latest
    environment:
      - NODE_ENV=production
      # Add your custom variables here:
      - API_KEY=${API_KEY}
      - DATABASE_URL=${DATABASE_URL}
      - LOG_LEVEL=${LOG_LEVEL:-info}  # Default to 'info' if not set
```

#### Examples

**Adding a DATABASE_URL**:
```bash
# In GitHub Secrets, add:
# Name: DATABASE_URL
# Value: postgresql://user:password@host:5432/dbname

# In docker-compose.yml:
environment:
  - DATABASE_URL=${DATABASE_URL}
```

**Adding multiple variables**:
```bash
# In .env on VPS:
NODE_ENV=production
LOG_LEVEL=info
MAX_FILE_SIZE=10485760
CACHE_TTL=3600
```

#### Best Practices

- **Never commit secrets** to git (`.env` is in `.gitignore`)
- **Use GitHub Secrets** for API keys, passwords, tokens, and credentials
- **Use direct SSH editing** for non-sensitive runtime configuration
- **Document required variables** in `.env.example` for other developers
- **Use defaults** with `${VAR:-default}` syntax for optional variables

### Customizing Application Configuration

> **Before You Start Customizing**
>
> If you're building a new app or making significant changes, check [`app/PROMPT.md`](../app/PROMPT.md) for AI coding assistant prompts. These templates help you generate compatible code with the correct port (3000), health endpoint (`/health`), and Docker configuration.

#### Changing the Health Endpoint

The health check endpoint is used by Docker to verify your application is running correctly.

**Default configuration** (in `app/Dockerfile`):
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
```

**To change the endpoint** (e.g., to `/api/health` or `/status`):

1. Edit `app/Dockerfile`:
   ```dockerfile
   # Change /health to your endpoint
   HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
     CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
   ```

2. Update `deploy/docker-compose.yml` health check:
   ```yaml
   healthcheck:
     test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/api/health"]
     interval: 30s
     timeout: 10s
     retries: 3
     start_period: 40s
   ```

3. Commit and push to deploy the changes.

**Note**: Your application must respond with HTTP 200 on the health endpoint for the check to pass.

#### Changing the Exposed Port

**Default configuration**:
- Container port: `3000` (defined in `app/Dockerfile`)
- Host port: `80` (defined in `deploy/docker-compose.yml`)
- External access: `http://YOUR_VPS_IP` (port 80)

**To change the container port** (e.g., to 8080):

1. Edit `app/Dockerfile`:
   ```dockerfile
   # Change the exposed port
   EXPOSE 8080

   # Update the health check URL
   HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
     CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
   ```

2. Edit `deploy/docker-compose.yml`:
   ```yaml
   services:
     app:
       ports:
         - "80:8080"  # Host:Container
       healthcheck:
         test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
   ```

3. Commit and push to deploy.

**To change the host port** (e.g., to expose on port 8080 instead of 80):

1. Edit `deploy/docker-compose.yml`:
   ```yaml
   services:
     app:
       ports:
         - "8080:3000"  # Now accessible at http://YOUR_VPS_IP:8080
   ```

2. Update Terraform firewall rules in `infra/terraform/main.tf`:
   ```hcl
   rule {
     direction  = "in"
     protocol   = "tcp"
     port       = "8080"
     source_ips = var.allowed_http_ips
   }
   ```

3. Run the infrastructure workflow to update firewall rules.

4. Commit and push to deploy.

**Warning**: Changing the host port from 80 requires updating Hetzner firewall rules via Terraform, otherwise the port will be blocked.

#### Environment-specific Configuration

Use environment variables to configure application behavior for different environments:

```bash
# Production settings (in .env on VPS)
NODE_ENV=production
LOG_LEVEL=warn
DEBUG=false
CACHE_ENABLED=true

# Or via docker-compose.yml environment section
environment:
  - NODE_ENV=production
  - LOG_LEVEL=${LOG_LEVEL:-warn}
  - DEBUG=${DEBUG:-false}
  - CACHE_ENABLED=${CACHE_ENABLED:-true}
```

**Common environment variables**:

| Variable | Purpose | Example Values |
|----------|---------|----------------|
| `NODE_ENV` | Runtime environment | `production`, `development` |
| `LOG_LEVEL` | Logging verbosity | `error`, `warn`, `info`, `debug` |
| `DEBUG` | Enable debug mode | `true`, `false` |
| `PORT` | Application port | `3000`, `8080` |
| `TIMEOUT` | Request timeout (ms) | `30000` |

## Troubleshooting Access

### Why Direct SSH May Not Work

By default, SSH access to the VPS is restricted to GitHub Actions IP ranges only. This is a **security feature**, not a limitation. However, you can easily add your own IP for direct access.

**Benefits of restricted access:**
- Prevents unauthorized access even if SSH keys are compromised
- Reduces attack surface - server only accepts connections from known sources
- Enforces infrastructure-as-code practices for server management

### Enabling Direct SSH Access

#### Method 1: Use Setup Wizard (Easiest)

1. Run `npm run setup-wizard`
2. Navigate to **Step 5: Configure SSH Access**
3. Press `E` to enable direct SSH access
4. Press `I` to set your IP address (find it with `curl ifconfig.me`)
5. Run the **Provision Infrastructure** workflow to apply changes

#### Method 2: Edit terraform.tfvars

Add your IP address to `infra/terraform/terraform.tfvars`:

```hcl
# Add your IP for direct SSH access
additional_ssh_ips = ["YOUR.IP.ADDRESS/32"]
```

Example:
```hcl
# Single IP
additional_ssh_ips = ["203.0.113.45/32"]

# Multiple IPs (home and office)
additional_ssh_ips = ["203.0.113.45/32", "198.51.100.10/32"]
```

Then run the **Provision Infrastructure** workflow to apply changes.

**Note**: GitHub Actions IPs are always included automatically - you only need to add your own IP if you want direct SSH access.

### Running Commands Without Direct SSH

If you prefer to keep SSH restricted to GitHub Actions only, here are your options:

#### Method 1: GitHub Actions Workflow (Recommended)

Add a workflow dispatch for running ad-hoc commands:

```yaml
# .github/workflows/debug.yml
name: Debug VPS
on:
  workflow_dispatch:
    inputs:
      command:
        description: 'Command to run'
        required: true
        default: 'docker compose ps'

jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
      - name: Run command on VPS
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        run: |
          mkdir -p ~/.ssh
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh -o StrictHostKeyChecking=no deploy@${{ secrets.VPS_HOST }} "${{ github.event.inputs.command }}"
```

Then go to **Actions > Debug VPS > Run workflow** and enter your command.

#### Method 2: Hetzner Cloud Console (Emergency Access)

For emergencies when you need immediate interactive access:

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Navigate to your project and select the server
3. Click the **"Console"** button (top-right of server details page)
4. A browser-based terminal opens with direct server access
5. Log in as `deploy` user (or `root` if needed)

**Note**: Console access bypasses all firewall rules - use for emergencies only.

## Common Issues

### Deployment Failed

**Check**:
1. GitHub Actions logs
2. VPS logs (via GitHub Actions or Hetzner Console - see [Troubleshooting Access](#troubleshooting-access))
3. Container status: `docker compose ps`

### App Not Accessible

> **Note**: Run these commands via GitHub Actions workflow or Hetzner Console. See [Troubleshooting Access](#troubleshooting-access).

```bash
# Check if container is running
docker compose ps

# Check if app is listening
netstat -tlnp | grep 80

# Check firewall
sudo ufw status
```

### Out of Disk Space

> **Note**: Run these commands via GitHub Actions workflow or Hetzner Console. See [Troubleshooting Access](#troubleshooting-access).

```bash
# Clean up old images
docker image prune -a -f

# Clean up system
docker system prune -a -f
```

## Rollback Procedures

### Method 1: Via GitHub (Recommended)

1. Go to `Code → Deployments`
2. Find last successful deployment
3. Click commit SHA
4. Re-run workflow

### Method 2: Manual (via Hetzner Console)

```bash
# After connecting via Hetzner Console
cd /opt/app
# Edit docker-compose.yml to use previous image tag
docker compose pull app
docker compose up -d app
```

## Maintenance Tasks

### Weekly
- Check healthchecks.io dashboard
- Review deployment history

### Monthly
- Clean up Docker images on VPS
- Review cost in Hetzner Console

## Emergency Procedures

### Complete Outage

1. Check VPS status in Hetzner Console
2. If frozen: Reboot via console
3. If unrecoverable: Run destroy workflow, then setup workflow

### Destroy Everything

1. Go to Actions → Provision Infrastructure
2. Run workflow
3. Check "Destroy infrastructure"
4. Click Run workflow

This will:
- Destroy Hetzner VPS
- Delete healthchecks.io check (if configured)
- Clean up resources

## Cost Monitoring

**Monthly estimate**: ~$7.50 (Hetzner CPX22)

**Set up alerts**:
1. Hetzner Console → Billing → Alerts
2. Set monthly limit (e.g., $10)

## Support

- **Detailed Setup**: [SETUP.md](SETUP.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Issues**: GitHub Issues
