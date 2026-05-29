#!/usr/bin/env bash
# Stream nginx access log lines from the VM.
# Press Ctrl+C to stop.

set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "Streaming nginx access log from ${VM_HOST} (Ctrl+C to stop)..."
echo "─────────────────────────────────────────────────────────────────"

# nginx:alpine symlinks /var/log/nginx/access.log → /dev/stdout, so all access
# log lines appear on the container's stdout which docker compose captures.
# We grep for the quoted HTTP method to isolate access lines from any other output.
run_ssh -t "cd ${REPO_DIR} && \
  docker compose logs -f --tail=50 2>/dev/null \
  | grep --line-buffered -E '\"(GET|POST|HEAD|PUT|DELETE|PATCH|OPTIONS) '"
