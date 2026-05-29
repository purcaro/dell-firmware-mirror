#!/usr/bin/env bash
# Stream nginx error/warning log lines from the VM.
# Press Ctrl+C to stop.

set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "Streaming nginx error log from ${VM_HOST} (Ctrl+C to stop)..."
echo "─────────────────────────────────────────────────────────────────"

# nginx:alpine sends errors to /dev/stderr → docker compose stderr.
# We match on nginx severity tags to isolate error lines.
run_ssh -t "cd ${REPO_DIR} && \
  docker compose logs -f --tail=50 \
  | grep --line-buffered -E '\[(error|warn|crit|alert|emerg)\]'"
