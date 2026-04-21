#!/usr/bin/env bash
set -euo pipefail

# Backup integrity checker for btrbk
# Checks local snapshots, remote snapshots (gondor), and service status

HOST=192.168.1.6
SHIRE_CONF="/etc/btrbk/btrbk_shire.conf"
GONDOR_CONF="/etc/btrbk/btrbk_gondor.conf"
SNAPSHOT_DIR="/mnt/data/@snapshots"
DOCKER_SNAPSHOT_DIR="/@snapshots/docker"
GONDOR_BACKUP="/mnt/backup/shire"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

pass() { echo -e "  ${GREEN}[OK]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((ERRORS++)); }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)); }
header() { echo -e "\n${NC}=== $1 ===${NC}"; }

# --- Systemd services ---
header "Systemd services"

for svc in btrbk_shire btrbk_gondor; do
    if systemctl is-enabled --quiet "${svc}.timer" 2>/dev/null; then
        pass "${svc}.timer is enabled"
    else
        fail "${svc}.timer is not enabled"
    fi

    status=$(systemctl is-active "${svc}.service" 2>/dev/null || true)
    if [[ "$status" == "inactive" ]]; then
        pass "${svc}.service is idle (last run completed)"
    elif [[ "$status" == "active" ]]; then
        warn "${svc}.service is currently running"
    elif [[ "$status" == "failed" ]]; then
        fail "${svc}.service has failed"
    else
        warn "${svc}.service status: $status"
    fi
done

# --- Config files ---
header "Configuration files"

for conf in "$SHIRE_CONF" "$GONDOR_CONF"; do
    if [[ -f "$conf" ]]; then
        pass "$(basename "$conf") exists"
    else
        fail "$(basename "$conf") not found"
    fi
done

# --- Local snapshots (media subvolumes) ---
header "Local snapshots (mnt/data/@snapshots)"

if [[ -d "$SNAPSHOT_DIR" ]]; then
    pass "Snapshot directory exists: $SNAPSHOT_DIR"
    snapshot_count=$(ls -1 "$SNAPSHOT_DIR" 2>/dev/null | wc -l)
    echo "     Found $snapshot_count snapshots"

    # Check age of most recent snapshot
    latest=$(ls -1t "$SNAPSHOT_DIR" 2>/dev/null | head -1)
    if [[ -n "$latest" ]]; then
        latest_path="$SNAPSHOT_DIR/$latest"
        age_days=$(( ($(date +%s) - $(stat -c %Y "$latest_path")) / 86400 ))
        if [[ $age_days -le 1 ]]; then
            pass "Latest snapshot: $latest (${age_days}d ago)"
        elif [[ $age_days -le 7 ]]; then
            warn "Latest snapshot: $latest (${age_days}d ago)"
        else
            fail "Latest snapshot: $latest (${age_days}d ago) - too old"
        fi
    else
        fail "No snapshots found in $SNAPSHOT_DIR"
    fi

    # Check each expected subvolume has recent snapshots
    expected_subvols=(internal immich cloud movies tv books audiobooks audio)
    for subvol in "${expected_subvols[@]}"; do
        count=$(ls -1 "$SNAPSHOT_DIR" 2>/dev/null | grep -c "^${subvol}\." || true)
        if [[ $count -gt 0 ]]; then
            latest_snap=$(ls -1t "$SNAPSHOT_DIR/${subvol}."* 2>/dev/null | head -1)
            if [[ -n "$latest_snap" ]]; then
                age_days=$(( ($(date +%s) - $(stat -c %Y "$latest_snap")) / 86400 ))
                if [[ $age_days -le 2 ]]; then
                    pass "$subvol: $count snapshots (latest ${age_days}d ago)"
                else
                    warn "$subvol: $count snapshots (latest ${age_days}d ago)"
                fi
            fi
        else
            fail "$subvol: no snapshots found"
        fi
    done
else
    fail "Snapshot directory not found: $SNAPSHOT_DIR"
fi

# --- Docker volume snapshots ---
header "Docker volume snapshots (/@snapshots/docker)"

if [[ -d "$DOCKER_SNAPSHOT_DIR" ]]; then
    pass "Docker snapshot directory exists"
    docker_count=$(ls -1 "$DOCKER_SNAPSHOT_DIR" 2>/dev/null | wc -l)
    echo "     Found $docker_count docker snapshots"

    latest_docker=$(ls -1t "$DOCKER_SNAPSHOT_DIR" 2>/dev/null | head -1)
    if [[ -n "$latest_docker" ]]; then
        age_days=$(( ($(date +%s) - $(stat -c %Y "$DOCKER_SNAPSHOT_DIR/$latest_docker")) / 86400 ))
        if [[ $age_days -le 1 ]]; then
            pass "Latest docker snapshot: $latest_docker (${age_days}d ago)"
        elif [[ $age_days -le 7 ]]; then
            warn "Latest docker snapshot: $latest_docker (${age_days}d ago)"
        else
            fail "Latest docker snapshot: $latest_docker (${age_days}d ago) - too old"
        fi
    else
        fail "No docker snapshots found"
    fi

    # Check docker volumes subvolume
    if sudo btrfs subvolume show /var/lib/docker/volumes &>/dev/null; then
        pass "/var/lib/docker/volumes is a btrfs subvolume"
    else
        fail "/var/lib/docker/volumes is not a btrfs subvolume"
    fi
else
    fail "Docker snapshot directory not found: $DOCKER_SNAPSHOT_DIR"
fi

# --- Btrfs subvolume integrity ---
header "Btrfs subvolume integrity"

check_subvol() {
    local path="$1"
    local name
    name=$(basename "$path")
    if sudo btrfs subvolume show "$path" &>/dev/null; then
        pass "$name is a valid btrfs subvolume"
    else
        fail "$name is not a valid btrfs subvolume or not found"
    fi
}

# Check media subvolumes (on /mnt/data)
media_subvols=(
    "/mnt/data/backup/internal"
    "/mnt/data/immich"
    "/mnt/data/cloud"
    "/mnt/data/servarr/media/movies"
    "/mnt/data/servarr/media/tv"
    "/mnt/data/servarr/media/books"
    "/mnt/data/servarr/media/audiobooks"
    "/mnt/data/servarr/media/audio"
)

for subvol in "${media_subvols[@]}"; do
    check_subvol "$subvol"
done

# Check docker volumes subvolume (on root)
check_subvol "/var/lib/docker/volumes"

# --- Remote gondor (optional) ---
header "Remote backup (gondor)"

if ping -c1 -W2 "$HOST" &>/dev/null; then
    pass "Gondor ($HOST) is reachable"

    remote_count=$(ssh -o ConnectTimeout=5 root@"$HOST" "ls -1 '$GONDOR_BACKUP' 2>/dev/null | wc -l" 2>/dev/null || echo "0")
    if [[ "$remote_count" -gt 0 ]]; then
        pass "Gondor backup directory has $remote_count entries"

        # Check if docker volumes exist on gondor
        remote_docker=$(ssh -o ConnectTimeout=5 root@"$HOST" "ls -1 '$GONDOR_BACKUP' 2>/dev/null | grep -c 'volumes' || true" 2>/dev/null || echo "0")
        if [[ "$remote_docker" -gt 0 ]]; then
            pass "Docker volumes backed up on gondor ($remote_docker entries)"
        else
            warn "No docker volume backups found on gondor"
        fi

        # Check age of latest remote snapshot
        remote_latest=$(ssh -o ConnectTimeout=5 root@"$HOST" "ls -1t '$GONDOR_BACKUP' 2>/dev/null | head -1" 2>/dev/null || echo "")
        if [[ -n "$remote_latest" ]]; then
            echo "     Latest remote snapshot: $remote_latest"
        fi
    else
        fail "Gondor backup directory is empty or unreachable"
    fi
else
    warn "Gondor ($HOST) is not reachable (skipping remote check)"
fi

# --- Summary ---
header "Summary"

if [[ $ERRORS -gt 0 ]]; then
    echo -e "  ${RED}$ERRORS error(s) found${NC}"
fi
if [[ $WARNINGS -gt 0 ]]; then
    echo -e "  ${YELLOW}$WARNINGS warning(s)${NC}"
fi
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "  ${GREEN}All checks passed${NC}"
fi

echo ""
exit $ERRORS
