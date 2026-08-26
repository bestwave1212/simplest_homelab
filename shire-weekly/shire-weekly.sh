#!/usr/bin/env bash
#
# shire-weekly.sh — Weekly update & health summary
# Runs locally on shire (Debian 13)
# Cron: 0 0 * * 1  (Monday 00:00)
#
set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────
EMAIL_FILE="/home/bestwave/.shire-email"
EMAIL_TO=$(cat "$EMAIL_FILE" 2>/dev/null || echo "bestwave@shire")
EMAIL_SUBJECT="Shire Weekly Report — $(date +%Y-%m-%d)"
LOG="/home/bestwave/shire-weekly.log"
LAST_RUN="/home/bestwave/.shire-weekly-last-run"

# ─── Helpers ──────────────────────────────────────────────────────────────
append_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

# ─── Pre-flight ───────────────────────────────────────────────────────────
> "$LOG"
append_log "Starting shire weekly routine"
date '+%Y-%m-%d %H:%M:%S' > "$LAST_RUN"

# ─── 1. Apt upgrades ────────────────────────────────────────────────────
append_log "Running apt update..."
APT_UPDATE=$(sudo apt update 2>&1) || true
append_log "$APT_UPDATE"

UPGRADE_OUTPUT=$(sudo apt list --upgradable 2>/dev/null || true)
UPGRADE_COUNT=$(echo "$UPGRADE_OUTPUT" | grep -c "upgradable" 2>/dev/null || echo 0)

if [ "$UPGRADE_COUNT" -gt 0 ]; then
    append_log "Upgrading $UPGRADE_COUNT packages..."
    APT_UPGRADE=$(sudo apt upgrade -y 2>&1) || true
    append_log "$APT_UPGRADE"
    RUNTIME="${UPGRADE_COUNT} packages upgraded"
else
    RUNTIME="No apt upgrades available"
fi

# ─── 2. Docker container updates ──────────────────────────────────────────
append_log "Pulling latest container images..."
CONTAINERS=$(docker ps --format "{{.Names}} {{.Image}}" --filter "status=running" 2>/dev/null || true)

RESTART_LIST=""

while IFS= read -r line; do
    [ -z "$line" ] && continue
    CONTAINER_NAME=$(echo "$line" | awk '{print $1}')
    CURRENT_IMAGE=$(echo "$line" | awk '{print $2}')

    append_log "Pulling image for $CONTAINER_NAME: $CURRENT_IMAGE"
    PULL_OUTPUT=$(docker pull "$CURRENT_IMAGE" 2>&1) || true
    append_log "$PULL_OUTPUT"

    NEW_IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' "$CURRENT_IMAGE" 2>/dev/null || true)

    if [ "$CURRENT_IMAGE" != "$NEW_IMAGE" ]; then
        RESTART_LIST="$RESTART_LIST $CONTAINER_NAME"
        append_log "Image changed for $CONTAINER_NAME — will restart"
    fi
done <<< "$CONTAINERS"

for name in $RESTART_LIST; do
    append_log "Restarting $name..."
    docker restart "$name" 2>&1 || true
done

[ -z "$RESTART_LIST" ] && DOCKER_RUNTIME="All images already up to date" || DOCKER_RUNTIME="Updated and restarted:${RESTART_LIST}"

# ─── 3. Health data ───────────────────────────────────────────────────────
append_log "Collecting health data..."

HOSTNAME_INFO=$(hostname)
UPTIME_INFO=$(uptime)
DISK_INFO=$(df -h / /boot 2>/dev/null | grep -v "tmpfs\|devtmpfs" || true)
MEM_INFO=$(free -h 2>/dev/null | grep -E "Mem:|Swap:" || true)
CPU_LOAD=$(cat /proc/loadavg 2>/dev/null || true)
CONTAINER_STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null || true)
RESTARTING=$(docker ps --filter "status=restarting" --format "{{.Names}} ({{.Image}}): {{.Status}}" 2>/dev/null || true)
INODE_INFO=$(df -i / 2>/dev/null | tail -1 || true)

# ─── 4. Build report ──────────────────────────────────────────────────────
REPORT=$(cat <<EOF
═══════════════════════════════════════════════════════
  SHIRE WEEKLY HEALTH REPORT
  $(date '+%A, %B %d, %Y')
═══════════════════════════════════════════════════════

── SYSTEM ─────────────────────────────────────────────
  Host:        $HOSTNAME_INFO
  Uptime:      $UPTIME_INFO
  Load (avg):  $CPU_LOAD

── DISK ──────────────────────────────────────────────
$DISK_INFO

  Inodes (/):  $INODE_INFO

── MEMORY ────────────────────────────────────────────
$MEM_INFO

── APT UPDATES ───────────────────────────────────────
  $RUNTIME
$(echo "$UPGRADE_OUTPUT" | grep -i "upgradable" 2>/dev/null || echo "  No upgrades needed")

── DOCKER ────────────────────────────────────────────
  $DOCKER_RUNTIME

── CONTAINER STATUS ──────────────────────────────────
$CONTAINER_STATUS

── RESTARTING CONTAINERS ─────────────────────────────
${RESTARTING:-None}

── NOTES ─────────────────────────────────────────────
  Last run: $(date '+%Y-%m-%d %H:%M:%S %Z')
  Log: $LOG

═══════════════════════════════════════════════════════
EOF
)

# ─── 5. Send report ───────────────────────────────────────────────────────
append_log "Sending report to $EMAIL_TO"
echo "$REPORT" | mail -s "$EMAIL_SUBJECT" "$EMAIL_TO"
append_log "Report sent to $EMAIL_TO"

# Print to stdout (cron will capture this)
echo "$REPORT"

exit 0
