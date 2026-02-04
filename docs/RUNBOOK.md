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

```bash
# Real-time logs
ssh deploy@YOUR_VPS_IP 'docker compose logs -f app'

# Recent logs
ssh deploy@YOUR_VPS_IP 'docker compose logs --tail=100 app'
```

### GitHub Deployments

View deployment history: `Code → Environments → production`

### healthchecks.io (if enabled)

Dashboard: https://healthchecks.io/projects/

## Database Operations

### View Database Status

```bash
ssh deploy@YOUR_VPS_IP 'docker compose ps postgres mysql redis'
```

### Connect to Databases

#### PostgreSQL
```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
docker compose exec postgres psql -U app -d app
```

Common commands:
- `\dt` - List tables
- `\d table_name` - Describe table
- `\q` - Quit

#### MySQL
```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
docker compose exec mysql mysql -u app -p
```

Common commands:
- `SHOW TABLES;` - List tables
- `DESCRIBE table_name;` - Describe table
- `EXIT;` - Quit

#### Redis
```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
docker compose exec redis redis-cli -a YOUR_PASSWORD
```

Common commands:
- `KEYS *` - List all keys
- `GET key` - Get value
- `EXIT` - Quit

### Database Logs

```bash
# PostgreSQL logs
ssh deploy@YOUR_VPS_IP 'docker compose logs postgres'

# MySQL logs
ssh deploy@YOUR_VPS_IP 'docker compose logs mysql'

# Redis logs
ssh deploy@YOUR_VPS_IP 'docker compose logs redis'
```

### Database Restart

```bash
# Restart PostgreSQL
ssh deploy@YOUR_VPS_IP 'docker compose restart postgres'

# Restart MySQL
ssh deploy@YOUR_VPS_IP 'docker compose restart mysql'

# Restart Redis
ssh deploy@YOUR_VPS_IP 'docker compose restart redis'
```

### Storage Space

Check database volume usage:
```bash
ssh deploy@YOUR_VPS_IP 'docker system df -v'
```

### Database Backups

The backup script at `/opt/app/scripts/db-backup.sh` handles automated backups for all database types with 7-day retention.

#### Run Manual Backup

```bash
ssh deploy@YOUR_VPS_IP 'cd /opt/app && ./scripts/db-backup.sh'
```

#### View Available Backups

```bash
ssh deploy@YOUR_VPS_IP 'ls -lh /opt/app/backups/'
```

#### Download Backups

```bash
# Download specific backup
scp deploy@YOUR_VPS_IP:/opt/app/backups/postgres_20260204_120000.sql.gz ./

# Download all backups
scp -r deploy@YOUR_VPS_IP:/opt/app/backups/ ./local-backups/
```

#### Set Up Automated Daily Backups

```bash
# SSH to VPS and edit crontab
ssh deploy@YOUR_VPS_IP
crontab -e

# Add this line for daily 2 AM backups
0 2 * * * cd /opt/app && ./scripts/db-backup.sh >> /opt/app/backups/backup.log 2>&1
```

#### Restore Procedures

**PostgreSQL:**
```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
docker compose stop app
gunzip -c backups/postgres_TIMESTAMP.sql.gz | docker exec -i postgres psql -U app -d app
docker compose start app
```

**MySQL:**
```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
docker compose stop app
gunzip -c backups/mysql_TIMESTAMP.sql.gz | docker exec -i mysql mysql -u root -p"PASSWORD"
docker compose start app
```

**Redis:**
```bash
ssh deploy@YOUR_VPS_IP
cd /opt/app
docker compose stop redis
docker cp backups/redis_TIMESTAMP.rdb redis:/data/dump.rdb
docker compose start redis
```

## Application Management

### Managing Environment Variables

Your application can access environment variables defined in the `.env` file on the VPS. There are two methods to configure them:

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

#### Method 2: Direct SSH Editing (For Non-Sensitive Values)

For non-sensitive configuration values, you can edit the `.env` file directly on the VPS.

```bash
# SSH to the VPS
ssh deploy@YOUR_VPS_IP

# Edit the environment file
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

## Common Issues

### Deployment Failed

**Check**:
1. GitHub Actions logs
2. VPS logs: `ssh deploy@VPS_IP 'docker compose logs app'`
3. Container status: `ssh deploy@VPS_IP 'docker compose ps'`

### App Not Accessible

```bash
# Check if container is running
ssh deploy@YOUR_VPS_IP 'docker compose ps'

# Check if app is listening
ssh deploy@YOUR_VPS_IP 'netstat -tlnp | grep 80'

# Check firewall
ssh deploy@YOUR_VPS_IP 'sudo ufw status'
```

### Out of Disk Space

```bash
# Clean up old images
ssh deploy@YOUR_VPS_IP 'docker image prune -a -f'

# Clean up system
ssh deploy@YOUR_VPS_IP 'docker system prune -a -f'
```

## Rollback Procedures

### Method 1: Via GitHub (Recommended)

1. Go to `Code → Deployments`
2. Find last successful deployment
3. Click commit SHA
4. Re-run workflow

### Method 2: Manual

```bash
ssh deploy@YOUR_VPS_IP
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
