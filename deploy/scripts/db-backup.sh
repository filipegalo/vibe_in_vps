#!/bin/bash
# Database Backup Script for vibe_in_vps
# Backs up PostgreSQL, MySQL, and Redis databases
# Keeps 7 days of backups with automatic rotation

set -euo pipefail

BACKUP_DIR="/opt/app/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting database backups at $(date)"

# PostgreSQL Backup
if docker ps | grep -q postgres; then
    echo "Backing up PostgreSQL..."
    docker exec postgres pg_dumpall -U "${POSTGRES_USER:-app}" | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"
    echo "✓ PostgreSQL backup complete: postgres_$DATE.sql.gz"
else
    echo "⊘ PostgreSQL container not running, skipping..."
fi

# MySQL Backup
if docker ps | grep -q mysql; then
    echo "Backing up MySQL..."
    docker exec mysql mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" --all-databases | gzip > "$BACKUP_DIR/mysql_$DATE.sql.gz"
    echo "✓ MySQL backup complete: mysql_$DATE.sql.gz"
else
    echo "⊘ MySQL container not running, skipping..."
fi

# Redis Backup
if docker ps | grep -q redis; then
    echo "Backing up Redis..."
    docker exec redis redis-cli --raw SAVE
    docker cp redis:/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"
    echo "✓ Redis backup complete: redis_$DATE.rdb"
else
    echo "⊘ Redis container not running, skipping..."
fi

# Cleanup old backups (older than RETENTION_DAYS)
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.rdb" -mtime +$RETENTION_DAYS -delete

# Show backup status
echo ""
echo "Backup Summary:"
echo "---------------"
ls -lh "$BACKUP_DIR" | tail -n +2 | awk '{printf "%-50s %10s\n", $9, $5}'
echo ""
echo "Total backups: $(ls -1 "$BACKUP_DIR" | wc -l)"
echo "Disk usage: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo ""
echo "Backup completed at $(date)"
