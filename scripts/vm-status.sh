#!/usr/bin/env bash
# Show a quick health summary of the VM: Docker container, systemd services,
# disk usage on the mirror volume, and the next scheduled sync time.

set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "VM status: ${VM_USER}@${VM_HOST}"
echo "═════════════════════════════════════════════════════════════════"

run_ssh "
set -uo pipefail

echo ''
echo '── Docker container ─────────────────────────────────────────────'
cd ${REPO_DIR} && docker compose ps 2>/dev/null || echo '  (no containers running)'

echo ''
echo '── nginx service ────────────────────────────────────────────────'
systemctl status dell-firmware-mirror.service --no-pager -l | head -12

echo ''
echo '── sync timer ───────────────────────────────────────────────────'
systemctl status dellmirror-sync.timer --no-pager | head -8
echo ''
systemctl list-timers dellmirror-sync.timer --no-pager 2>/dev/null | tail -3

echo ''
echo '── mirror disk usage ────────────────────────────────────────────'
df -h ${REPO_DIR}/mirror 2>/dev/null || echo '  mirror dir not found'
echo ''
du -sh ${REPO_DIR}/mirror/* 2>/dev/null | sort -rh | head -10 \
  || echo '  (mirror directory is empty)'

echo ''
echo '── last 5 sync journal entries ──────────────────────────────────'
journalctl -u dellmirror-sync.service -n 5 --no-pager 2>/dev/null \
  || echo '  (no sync runs recorded yet)'
"
