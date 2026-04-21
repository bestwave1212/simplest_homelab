#!/usr/bin/env bash
# Install Synology backup to systemd
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMD_DIR="/etc/systemd/system"
MOUNT_POINT="/mnt/synology_backup"
SMBCREDS="$SCRIPT_DIR/.smbcredentials"

print_usage() {
    cat <<EOF
Usage: $0 [--install]

By default the script runs in dry-run mode and prints the actions it would take.
Pass --install to perform the actions (requires sudo/root).

Actions performed with --install:
- create mount point $MOUNT_POINT if needed
- create SMB credentials file if needed
- copy service and timer to $SYSTEMD_DIR
- add SMB mount to /etc/fstab (optional)
- reload systemd, enable and start the timer
EOF
}

DRY_RUN=true
if [[ ${1-} == "--install" ]]; then
    DRY_RUN=false
elif [[ ${1-} == "--help" || ${1-} == "-h" ]]; then
    print_usage
    exit 0
fi

run_cmd() {
    if $DRY_RUN; then
        echo "+ $*"
    else
        echo "=> $*"
        eval "$@"
    fi
}

echo "Mode: $( $DRY_RUN && echo 'dry-run' || echo 'install' )"

# Create mount point
run_cmd sudo mkdir -p "$MOUNT_POINT"

# Check/create SMB credentials
if [[ ! -f "$SMBCREDS" ]]; then
    if $DRY_RUN; then
        echo "+ sudo tee '$SMBCREDS' <<'EOF'"
        echo "+ (prompt for username/password)"
    else
        echo "WARNING: $SMBCREDS does not exist. Create it with:"
        echo "  sudo tee '$SMBCREDS' <<'EOF'"
        echo "  username=your_username"
        echo "  password=your_password"
        echo "  EOF"
        echo "  sudo chmod 600 $SMBCREDS"
    fi
fi

# Copy systemd files
run_cmd sudo cp -v "$SCRIPT_DIR/btrbk_stationMir.service" "$SYSTEMD_DIR/"
run_cmd sudo cp -v "$SCRIPT_DIR/btrbk_stationMir.timer" "$SYSTEMD_DIR/"
run_cmd sudo chown root:root "$SYSTEMD_DIR/btrbk_stationMir.service" "$SYSTEMD_DIR/btrbk_stationMir.timer"
run_cmd sudo chmod 644 "$SYSTEMD_DIR/btrbk_stationMir.service" "$SYSTEMD_DIR/btrbk_stationMir.timer"

# Make backup script executable
run_cmd sudo chmod +x "$SCRIPT_DIR/backup_stationMir.sh"

# Reload systemd and enable timer
run_cmd sudo systemctl daemon-reload
run_cmd sudo systemctl enable --now btrbk_stationMir.timer

# Show status
if ! $DRY_RUN; then
    echo ""
    echo "Installation complete. Timer status:"
    sudo systemctl status btrbk_stationMir.timer --no-pager
fi

echo "Done."