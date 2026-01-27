#!/bin/bash

# Auto-update script - run this daily/hourly via cron
# Example cron: 0 */6 * * * /opt/ksaers/app/v4/auto-update.sh

cd /opt/ksaers/app/v4

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting auto-update check..."

# Pull latest changes
git pull origin main > /tmp/ksaers-update.log 2>&1

if [ $? -eq 0 ]; then
    # Check if there were changes
    if grep -q "Already up to date" /tmp/ksaers-update.log; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] No updates available"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updates found, rebuilding..."
        
        # Rebuild and restart
        docker-compose up -d --build >> /tmp/ksaers-update.log 2>&1
        
        if [ $? -eq 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Update completed successfully"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Update failed"
            cat /tmp/ksaers-update.log | mail -s "Ksaers Website Update Failed" admin@ksaers.com
        fi
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Git pull failed"
    cat /tmp/ksaers-update.log | mail -s "Ksaers Website Update Failed" admin@ksaers.com
fi
