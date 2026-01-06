# Copilot / Agent instructions for simplest_homelab ✅

Purpose: give an AI coding agent concise, actionable knowledge to be immediately productive in this ops-focused repo.

## Quick orientation 💡
- This is an infrastructure/ops repo (home lab). Primary concerns: BTRFS snapshots, btrbk-based backups, systemd timers/services, and a small set of helper scripts.
- Servers are named after Middle-earth: **Shire** (primary), **Gondor** (backup/remote), **LeBon** (baremetal/proxmox). When you see these names, treat them as host roles, not arbitrary strings.

## Fast start (what to run locally) ▶️
- Inspect and dry-run the backup installer: `./btrbk/btrbk_update.sh` (prints dry-run actions).
- To apply on a real host: `sudo ./btrbk/btrbk_update.sh --install` then check `systemctl status btrbk_shire.timer`.
- SSH key setup used by backups: see `btrbk/README.md` (uses `ssh-keygen` and `ssh-copy-id` to provision root SSH keys between hosts).

## Key files to read / edit 🔧
- `btrbk/btrbk_update.sh` — installer: copies `{btrbk_shire,gondor}.conf` and systemd units, enables timers. Important: it expects the real system to have `/etc/btrbk` (see "Gotcha").
- `btrbk/btrbk_shire.conf` and `btrbk/btrbk_gondor.conf` — the btrbk source-of-truth for snapshots and remote targets.
- `btrbk/*.service` and `btrbk/*.timer` — systemd units installed by the script (units live at `/etc/systemd/system/`).
- `btrbk/backup_gondor.sh`, `btrbk/command_gondor.sh` — helper scripts that illustrate remote push patterns.
- `README.md` — project-level documentation with many reproducible, operational commands (proxmox, TrueNAS, Nextcloud AIO examples).

## Important patterns & conventions 🔍
- Scripts are written defensively: `set -euo pipefail` is used — treat failures as significant and avoid brittle changes.
- Configs live under `btrbk/` and are meant to be the canonical templates; changes here should be tested with the dry-run before installing.
- System-wide changes require root + `systemctl daemon-reload` and enabling timers (the installer does this for you).
- Keep host-specific IPs and credentials explicit: IPs like `192.168.1.6` and `192.168.12.*` are intentionally used; verify these before editing or applying changes.

## Gotchas & checks ⚠️
- The installer prints that it *would* create `/etc/btrbk` but in `--install` mode it errors if `/etc/btrbk` is missing (so **create `/etc/btrbk` manually** before `--install` or adjust the script cautiously).
- The installer logs service start output to `/tmp/btrbk_shire_service_start.log` and `/tmp/btrbk_gondor_service_start.log` — inspect those files when troubleshooting service startup.
- Watch for secrets in examples (README shows `PBS_PASSWORD` in an example script) — do not commit real credentials.

## Integration points to be aware of 🔗
- Btrfs subvolumes and snapshots: btrbk is used to create & push snapshots (`snapshot_dir mnt/data/@snapshots`).
- SSH-based `target` endpoints (see `btrbk_gondor.conf`); ensure identity files and ssh access are valid.
- Proxmox/Proxmox Backup Server and TrueNAS/Nextcloud are referenced: changes often affect the running host and require manual validation.

## How agents should operate here (dos & don'ts) ✅ / ❌
- DO: run `./btrbk/btrbk_update.sh` locally in dry-run mode, propose minimal, testable edits, and include the exact commands to validate changes.
- DO: prefer small, reversible edits and include `--install` instructions only after dry-run validation and a remediation plan.
- DO NOT: push changes that embed secrets, or change systemd units without instructing how to reload and verify (daemon-reload + `systemctl enable --now <unit>`).
- DO: add/modify README sections with concrete commands or examples when you change operational behavior.

## Example PR checklist for this repo ✅
- Run `./btrbk/btrbk_update.sh` (dry-run) and paste its output into the PR description if you touched btrbk files.
- If modifying systemd units: include exact `systemctl` steps to reload, enable, and check status and where to look for logs (`/tmp/*` or `journalctl -u <unit>`).
- If you change IPs or hostnames: update README references and config templates, and call out any required manual SSH key changes.

---

If anything is unclear or you'd like more detail on a section (e.g., additional troubleshooting steps for `btrbk` or `systemd` unit tests), tell me which area to expand and I'll iterate. 🔁