#!/usr/bin/env bash
set -Eeuo pipefail
TOXY_URL="${TOXY_URL:-https://raw.githubusercontent.com/toxyduck/bootstrap/main/toxy}"

if [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == *com.termux* ]]; then
  pkg update -y
  pkg install -y ca-certificates curl git gh openssh python
  INSTALL_DIR="$PREFIX/bin"
else
  [[ ${EUID:-$(id -u)} -ne 0 ]] || { echo 'Run as a normal user, not root.' >&2; exit 1; }
  [[ -r /etc/os-release ]] || { echo 'Supported clients: Termux, Ubuntu and Debian.' >&2; exit 1; }
  source /etc/os-release
  case "$ID" in ubuntu|debian) ;; *) echo 'Supported clients: Termux, Ubuntu and Debian.' >&2; exit 1;; esac
  sudo apt-get update
  INSTALL_DIR="$HOME/.local/bin"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git gh openssh-client python3
fi
mkdir -p "$INSTALL_DIR"
curl -fsSL "$TOXY_URL" -o "$INSTALL_DIR/toxy"
chmod 755 "$INSTALL_DIR/toxy"
gh auth status -h github.com >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
"$INSTALL_DIR/toxy" machines sync
echo 'Client ready. Run: toxy help'
