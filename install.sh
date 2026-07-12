#!/usr/bin/env bash
set -Eeuo pipefail
TOXY_URL="${TOXY_URL:-https://raw.githubusercontent.com/toxyduck/bootstrap/main/toxy}"

if [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == *com.termux* ]]; then
  pkg update -y
  pkg install -y ca-certificates curl git gh openssh python
else
  [[ ${EUID:-$(id -u)} -ne 0 ]] || { echo 'Run as a normal user, not root.' >&2; exit 1; }
  [[ -r /etc/os-release ]] || { echo 'Supported clients: Termux, Ubuntu and Debian.' >&2; exit 1; }
  source /etc/os-release
  case "$ID" in ubuntu|debian) ;; *) echo 'Supported clients: Termux, Ubuntu and Debian.' >&2; exit 1;; esac
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git gh openssh-client python3
fi
mkdir -p "$HOME/.local/bin"
curl -fsSL "$TOXY_URL" -o "$HOME/.local/bin/toxy"
chmod 755 "$HOME/.local/bin/toxy"
gh auth status -h github.com >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
"$HOME/.local/bin/toxy" machines sync
echo 'Client ready. Run: toxy help'
