#!/usr/bin/env bash
# Shared connection settings — edit these once, all scripts pick them up.
# To avoid committing your IP/key to git, put overrides in scripts/config.local.sh
# (that file is gitignored).  Example:
#   echo 'VM_HOST="192.168.1.50"' > scripts/config.local.sh

VM_HOST=""        # VM IP or hostname, e.g. 192.168.1.50
VM_USER="ubuntu"
SSH_KEY=""        # path to private key, e.g. ~/.ssh/id_ed25519  (blank = SSH default)
REPO_DIR="/opt/dell-firmware-mirror"

# Source local overrides if present
[[ -f "$(dirname "${BASH_SOURCE[0]}")/config.local.sh" ]] && \
  source "$(dirname "${BASH_SOURCE[0]}")/config.local.sh"

# ── internal helpers ──────────────────────────────────────────────────────────

_check_config() {
  if [[ -z "$VM_HOST" ]]; then
    echo "ERROR: VM_HOST is not set in scripts/config.sh" >&2
    exit 1
  fi
}

_ssh_opts() {
  local opts=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o BatchMode=no)
  [[ -n "$SSH_KEY" ]] && opts+=(-i "$SSH_KEY")
  echo "${opts[@]}"
}

# run_ssh [-t] <remote command>
#   -t  allocate a pseudo-TTY (needed for interactive / colour output)
run_ssh() {
  local tty_flag=()
  if [[ "$1" == "-t" ]]; then
    tty_flag=(-t)
    shift
  fi
  _check_config
  # shellcheck disable=SC2046
  ssh $(_ssh_opts) "${tty_flag[@]}" "${VM_USER}@${VM_HOST}" "$@"
}
