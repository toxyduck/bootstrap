#!/usr/bin/env bash
set -Eeuo pipefail

SESSION=toxy-bootstrap
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/toxy"
STAGE="$STATE/bootstrap-stage2.sh"

[[ ${EUID:-$(id -u)} -ne 0 ]] || { echo 'Run as a normal user with sudo, not root.' >&2; exit 1; }
source /etc/os-release
case "$ID" in ubuntu|debian) ;; *) echo "Ubuntu/Debian required (found: $ID)" >&2; exit 1 ;; esac

if ! command -v tmux >/dev/null 2>&1; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tmux curl ca-certificates
fi
mkdir -p "$STATE/logs"; chmod 700 "$STATE" "$STATE/logs"
if tmux has-session -t "$SESSION" 2>/dev/null; then exec tmux attach-session -t "$SESSION"; fi

cat >"$STAGE" <<'STAGE2'
#!/usr/bin/env bash
set -Eeuo pipefail
sudo -v
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git gh
gh auth status -h github.com >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
account=$(gh api user --jq .login)
[[ "$account" == toxyduck ]] || { echo "Expected toxyduck, got $account" >&2; exit 1; }
mkdir -p "$HOME/dev"
if [[ -d "$HOME/dev/.dotenv/.git" ]]; then
  branch=$(git -C "$HOME/dev/.dotenv" branch --show-current)
  if [[ "$branch" == main ]]; then
    git -C "$HOME/dev/.dotenv" pull --ff-only origin main
  else
    echo "[toxy] Using existing branch $branch; origin/main was not merged."
  fi
else
  gh repo clone toxyduck/.dotenv "$HOME/dev/.dotenv"
fi
chmod +x "$HOME/dev/.dotenv/bin/toxy" "$HOME/dev/.dotenv/vpn/start.sh"
exec "$HOME/dev/.dotenv/bin/toxy" setup
STAGE2
chmod 700 "$STAGE"

tmux new-session -d -s "$SESSION" "set -o pipefail; '$STAGE' 2>&1 | tee '$STATE/logs/bootstrap.log'; code=\${PIPESTATUS[0]}; echo; echo '[toxy] bootstrap finished with status' \$code; exit \$code"
tmux set-option -t "$SESSION" remain-on-exit on
exec tmux attach-session -t "$SESSION"
