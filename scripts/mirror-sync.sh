#!/usr/bin/env bash
# Run the Dell firmware mirror sync on the VM and stream its output live.
# Passes any extra arguments through to dellmirror.py, e.g.:
#   ./mirror-sync.sh --onlyfirmware
#   ./mirror-sync.sh --server "R840,R940" --threads 16

set -euo pipefail
source "$(dirname "$0")/config.sh"

EXTRA_ARGS="${*}"

echo "Starting Dell firmware mirror sync on ${VM_HOST}..."
echo "─────────────────────────────────────────────────────────────────"

# -t allocates a PTY so dellmirror.py's per-thread colour output is preserved.
run_ssh -t "cd ${REPO_DIR} && \
  python3 dellmirror.py \
    --server 'R830,R720,R720xd,R740,R740xd2' \
    --destination ${REPO_DIR}/mirror \
    --remove-catalog-location \
    ${EXTRA_ARGS}"

echo "─────────────────────────────────────────────────────────────────"
echo "Sync complete."
