#!/usr/bin/env bash
set -Eeuo pipefail
SESSION=toxy-bootstrap
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/toxy"
VPN="${1:-}"
[[ ${EUID:-$(id -u)} -ne 0 ]] || { echo 'Run as a normal user, not root.' >&2; exit 1; }
source /etc/os-release
case "$ID" in ubuntu|debian) ;; *) echo 'Ubuntu/Debian required' >&2; exit 1;; esac
if ! command -v tmux >/dev/null 2>&1; then
  sudo apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 update
  sudo DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tmux
fi
mkdir -p "$STATE/logs"; chmod 700 "$STATE" "$STATE/logs"
if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [[ $(tmux display-message -p -t "$SESSION" '#{pane_dead}') == 1 ]]; then
    tmux kill-session -t "$SESSION"
  else
    exec tmux attach-session -t "$SESSION"
  fi
fi
STAGE="$STATE/server-setup.sh"
cat >"$STAGE" <<STAGE2
#!/usr/bin/env bash
set -Eeuo pipefail
sudo -v
sudo apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 update
sudo DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates git gh
if ! gh auth status -h github.com >/dev/null 2>&1; then
  gh auth login --hostname github.com --web
fi
gh config set -h github.com git_protocol https 2>/dev/null || gh config set git_protocol https
gh auth setup-git
[[ \$(gh api user --jq .login) == toxyduck ]] || { echo 'Use GitHub account toxyduck' >&2; exit 1; }
mkdir -p "\$HOME/dev"
if [[ -d "\$HOME/dev/.dotenv/.git" ]]; then
  branch=\$(git -C "\$HOME/dev/.dotenv" branch --show-current)
  [[ "\$branch" != main ]] || git -C "\$HOME/dev/.dotenv" pull --ff-only origin main
else
  gh repo clone toxyduck/.dotenv "\$HOME/dev/.dotenv"
fi
chmod +x "\$HOME/dev/.dotenv/bin/toxy-server" "\$HOME/dev/.dotenv/vpn/start.sh"
exec "\$HOME/dev/.dotenv/bin/toxy-server" setup "$VPN"
STAGE2
chmod 700 "$STAGE"
tmux new-session -d -s "$SESSION" "set -o pipefail; '$STAGE' 2>&1 | tee '$STATE/logs/setup.log'; code=\${PIPESTATUS[0]}; echo '[toxy] setup finished with status' \$code; exit \$code"
tmux set-option -t "$SESSION" remain-on-exit on
exec tmux attach-session -t "$SESSION"
