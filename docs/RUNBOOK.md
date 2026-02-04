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
