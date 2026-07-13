#!/usr/bin/env bash
set -Eeuo pipefail
TOXY_URL="${TOXY_URL:-https://raw.githubusercontent.com/toxyduck/bootstrap/main/toxy}"

if [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == *com.termux* ]]; then
  pkg update -y
  pkg install -y ca-certificates curl git gh openssh python
  INSTALL_DIR="$PREFIX/bin"
elif [[ "$(uname -s)" == Darwin ]]; then
  [[ ${EUID:-$(id -u)} -ne 0 ]] || { echo 'Run as a normal user, not root.' >&2; exit 1; }
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  command -v brew >/dev/null 2>&1 || { echo 'Homebrew installation failed.' >&2; exit 1; }
  brew install git gh python
  INSTALL_DIR="$HOME/.local/bin"
else
  [[ ${EUID:-$(id -u)} -ne 0 ]] || { echo 'Run as a normal user, not root.' >&2; exit 1; }
  [[ -r /etc/os-release ]] || { echo 'Supported clients: macOS, Termux, Ubuntu and Debian.' >&2; exit 1; }
  source /etc/os-release
  case "$ID" in ubuntu|debian) ;; *) echo 'Supported clients: macOS, Termux, Ubuntu and Debian.' >&2; exit 1;; esac
  sudo apt-get update
  INSTALL_DIR="$HOME/.local/bin"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git gh openssh-client python3
fi
if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
  export PATH="$INSTALL_DIR:$PATH"
  if [[ "$(uname -s)" == Darwin ]]; then
    case "${SHELL:-}" in */zsh) profile="$HOME/.zprofile";; */bash) profile="$HOME/.bash_profile";; *) profile="$HOME/.profile";; esac
  else
    profile="$HOME/.profile"
  fi
  path_line='export PATH="$HOME/.local/bin:$PATH"'
  touch "$profile"
  grep -Fqx "$path_line" "$profile" || printf '%s\n' "$path_line" >> "$profile"
fi
mkdir -p "$INSTALL_DIR"
curl -fsSL "$TOXY_URL" -o "$INSTALL_DIR/toxy"
chmod 755 "$INSTALL_DIR/toxy"
"$INSTALL_DIR/toxy" machines sync
echo 'Client ready. Run: toxy help'
