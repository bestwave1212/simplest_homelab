#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="$SRC_DIR/btrbk_shire.conf"
SERVICE_SRC="$SRC_DIR/btrbk_shire.service"
TIMER_SRC="$SRC_DIR/btrbk_shire.timer"

DEST_CONF="/etc/btrbk/btrbk_shire.conf"
SYSTEMD_DIR="/etc/systemd/system"

print_usage() {
	cat <<EOF
Usage: $0 [--install]

By default the script runs in dry-run mode and prints the actions it would take.
Pass --install to perform the actions (requires sudo/root).

Actions performed with --install:
- create /etc/btrbk if needed
- copy the config to $DEST_CONF
- copy service and timer to $SYSTEMD_DIR
- reload systemd, enable and start the timer
- attempt a btrbk dry-run if `which btrbk` is available
EOF
}

DRY_RUN=true
if [[ ${1-} == "--install" ]]; then
	DRY_RUN=false
elif [[ ${1-} == "--help" || ${1-} == "-h" ]]; then
	print_usage
	exit 0
fi

for f in "$CONF_SRC" "$SERVICE_SRC" "$TIMER_SRC"; do
	if [[ ! -f "$f" ]]; then
		echo "ERROR: required source file not found: $f" >&2
		exit 2
	fi
done

run_cmd() {
	if $DRY_RUN; then
		echo "+ $*"
	else
		echo "=> $*"
		eval "$@"
	fi
}

echo "Mode: $( $DRY_RUN && echo 'dry-run' || echo 'install' )"

# Ensure target dir exists (do not create it)
if [[ ! -d /etc/btrbk ]]; then
	if $DRY_RUN; then
		echo "NOTE: /etc/btrbk does not exist; an install would create it."
	else
		echo "ERROR: target directory /etc/btrbk does not exist; please create it or run with the appropriate setup." >&2
		exit 3
	fi
fi

# Copy config
run_cmd sudo cp -v "$CONF_SRC" "$DEST_CONF"
run_cmd sudo chown root:root "$DEST_CONF"
run_cmd sudo chmod 644 "$DEST_CONF"

# Install systemd unit files
run_cmd sudo cp -v "$SERVICE_SRC" "$SYSTEMD_DIR/"
run_cmd sudo cp -v "$TIMER_SRC" "$SYSTEMD_DIR/"
run_cmd sudo chown root:root "$SYSTEMD_DIR/$(basename "$SERVICE_SRC")" "$SYSTEMD_DIR/$(basename "$TIMER_SRC")"
run_cmd sudo chmod 644 "$SYSTEMD_DIR/$(basename "$SERVICE_SRC")" "$SYSTEMD_DIR/$(basename "$TIMER_SRC")"

# Reload systemd and enable/start timer
run_cmd sudo systemctl daemon-reload
run_cmd sudo systemctl enable --now btrbk_shire.timer

# Start the service we installed (it runs btrbk dryrun per the unit file)
if command -v systemctl >/dev/null 2>&1; then
	if $DRY_RUN; then
		echo "+ sudo systemctl start btrbk_shire.service"
	else
		echo "Starting btrbk_shire.service..."
		if sudo systemctl start btrbk_shire.service 2>&1 | tee /tmp/btrbk_service_start.log; then
			echo "Service started (log: /tmp/btrbk_service_start.log)"
		else
			echo "Note: starting service returned non-zero. See /tmp/btrbk_service_start.log" >&2
		fi
	fi
else
	echo "systemctl not found; cannot start service; skipping." >&2
fi

echo "Done."
