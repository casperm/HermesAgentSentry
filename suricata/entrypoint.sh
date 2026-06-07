#!/bin/sh
# Suricata container entrypoint
# ==============================
# 1. Installs a cron job for daily logrotate (7-day retention)
# 2. Starts crond in the background
# 3. Execs Suricata in AF_PACKET mode on eth0
#
# This script is bind-mounted at /entrypoint.sh in the suricata container.

set -e

# Ensure log directory exists and is writable
mkdir -p /var/log/suricata
chmod 755 /var/log/suricata

# Install logrotate cron job (run daily at 02:00)
CRON_ENTRY="0 2 * * * /usr/sbin/logrotate /etc/logrotate.d/suricata --state /var/log/suricata/logrotate.state"

# Write crontab
echo "$CRON_ENTRY" | crontab -

# Start crond in the background (busybox crond or system crond)
if command -v crond >/dev/null 2>&1; then
    crond
elif command -v cron >/dev/null 2>&1; then
    cron
fi

echo "[entrypoint] Suricata starting with AF_PACKET on eth0"
echo "[entrypoint] Log rotation: daily, 7-day retention"
echo "[entrypoint] Logs: /var/log/suricata/"

# Exec Suricata — replace this shell process
exec suricata \
    -c /etc/suricata/suricata.yaml \
    --af-packet \
    --pidfile /var/run/suricata.pid \
    -v
