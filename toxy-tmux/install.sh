#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${TOXY_TMUX_BASE_URL:-https://raw.githubusercontent.com/toxyduck/bootstrap/main/toxy-tmux}"
[[ -n "${PREFIX:-}" && ( -n "${TERMUX_VERSION:-}" || "$PREFIX" == *com.termux* ) ]] || {
  echo 'toxy-tmux: this installer must run inside Termux' >&2
  exit 1
}

if [[ "${TOXY_TERMUX_PACKAGES_READY:-0}" != 1 ]]; then
  pkg update -y
  # Standalone installs must also avoid a partial Termux package upgrade.
  pkg upgrade -y
fi
pkg install -y tmux openssh python termux-services

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$BASE_URL/toxy-tmux" -o "$tmp"
bash -n "$tmp"
install -m 755 "$tmp" "$PREFIX/bin/toxy-tmux"

service="$PREFIX/var/service/toxy-tmux"
log_service="$service/log"
mkdir -p "$log_service" "$PREFIX/var/log/sv/toxy-tmux" "$HOME/.termux"

run_tmp=$(mktemp)
cat >"$run_tmp" <<EOF
#!$PREFIX/bin/sh
exec 2>&1
exec $PREFIX/bin/toxy-tmux watch
EOF
install -m 755 "$run_tmp" "$service/run"

cat >"$run_tmp" <<EOF
#!$PREFIX/bin/sh
exec $PREFIX/bin/svlogger $PREFIX/var/log/sv/toxy-tmux
EOF
install -m 755 "$run_tmp" "$log_service/run"
rm -f "$run_tmp"

properties="$HOME/.termux/termux.properties"
properties_tmp=$(mktemp)
if [[ -f "$properties" ]]; then
  awk '!/^[[:space:]]*allow-external-apps[[:space:]]*=/' "$properties" >"$properties_tmp"
fi
printf '%s\n' 'allow-external-apps=true' >>"$properties_tmp"
install -m 600 "$properties_tmp" "$properties"
rm -f "$properties_tmp"
termux-reload-settings 2>/dev/null || true

rm -f "$service/down"
if command -v sv >/dev/null 2>&1 && sv up toxy-tmux >/dev/null 2>&1; then
  echo 'toxy-tmux service enabled and started'
else
  echo 'toxy-tmux installed and enabled. Fully restart Termux to start the service daemon.'
fi
echo 'Security note: installer enabled allow-external-apps=true for Termux RUN_COMMAND support.'
if ! command -v toxy >/dev/null 2>&1; then
  echo 'toxy-tmux is blocked until the toxy bootstrap is installed; no fallback inventory will be used.'
fi
