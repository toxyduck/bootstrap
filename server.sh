#!/usr/bin/env bash
set -Eeuo pipefail
SESSION=toxy-bootstrap
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/toxy"
PROFILE=base
VPN=""
while (($#)); do
  case "$1" in
    --profile) shift; [[ $# -gt 0 ]] || { echo 'Missing profile value' >&2; exit 1; }; PROFILE="$1";;
    --vpn) VPN=--vpn;;
    *) echo "Unknown setup argument: $1" >&2; exit 1;;
  esac
  shift
done
[[ "$PROFILE" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || { echo 'Invalid profile name' >&2; exit 1; }
[[ ${EUID:-$(id -u)} -ne 0 ]] || { echo 'Run as a normal user, not root.' >&2; exit 1; }

case "$(uname -s)" in
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
    fi
    command -v brew >/dev/null 2>&1 || { echo 'Homebrew installation failed.' >&2; exit 1; }
    command -v tmux >/dev/null 2>&1 || brew install tmux
    ;;
  Linux)
    [[ -r /etc/os-release ]] || { echo 'Ubuntu/Debian required' >&2; exit 1; }
    source /etc/os-release
    case "$ID" in ubuntu|debian) ;; *) echo 'Ubuntu/Debian required' >&2; exit 1;; esac
    if ! command -v tmux >/dev/null 2>&1; then
      sudo apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 update
      sudo DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install -y
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tmux
    fi
    ;;
  *) echo 'Supported systems: macOS, Ubuntu and Debian' >&2; exit 1;;
esac

mkdir -p "$STATE/logs"; chmod 700 "$STATE" "$STATE/logs"
if [[ -n "${SSH_AUTH_SOCK:-}" ]] && tmux list-sessions >/dev/null 2>&1; then
  tmux set-environment -g SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
fi
if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [[ $(tmux display-message -p -t "$SESSION" '#{pane_dead}') == 1 ]]; then tmux kill-session -t "$SESSION"
  else exec tmux attach-session -t "$SESSION"; fi
fi
STAGE="$STATE/server-setup.sh"
cat >"$STAGE" <<STAGE2
#!/usr/bin/env bash
set -Eeuo pipefail
exec > >(tee '$STATE/logs/setup.log') 2>&1
case "\$(uname -s)" in
  Darwin)
    if [[ -x /opt/homebrew/bin/brew ]]; then eval "\$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then eval "\$(/usr/local/bin/brew shellenv)"; fi
    brew install git gh
    root="\${TOXY_ROOT:-\$HOME/Development/.dotenv}"
    ;;
  Linux)
    sudo -v
    sudo apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 update
    sudo DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates git gh
    root="\${TOXY_ROOT:-\$HOME/dev/.dotenv}"
    ;;
esac
if ! gh auth status -h github.com >/dev/null 2>&1; then gh auth login --hostname github.com --web; fi
gh config set -h github.com git_protocol https 2>/dev/null || gh config set git_protocol https
gh auth setup-git
[[ \$(gh api user --jq .login) == toxyduck ]] || { echo 'Use GitHub account toxyduck' >&2; exit 1; }
mkdir -p "\$(dirname "\$root")"
if git -C "\$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repo_url=\$(git -C "\$root" remote get-url origin 2>/dev/null || true)
  case "\$repo_url" in
    git@github.com:toxyduck/.dotenv.git|https://github.com/toxyduck/.dotenv.git|https://github.com/toxyduck/.dotenv) ;;
    *) echo "TOXY_ROOT points to a different repository: \$root (origin: \${repo_url:-missing})" >&2; exit 1;;
  esac
  git -C "\$root" remote set-url origin https://github.com/toxyduck/.dotenv.git
  branch=\$(git -C "\$root" branch --show-current)
  [[ "\$branch" != main ]] || git -C "\$root" pull --ff-only origin main
else
  [[ ! -e "\$root" ]] || { echo "TOXY_ROOT exists but is not the dotfiles repository: \$root" >&2; exit 1; }
  gh repo clone toxyduck/.dotenv "\$root"
fi
chmod +x "\$root/bin/toxy-server" "\$root/vpn/start.sh"
exec env TOXY_ROOT="\$root" "\$root/bin/toxy-server" setup --profile "$PROFILE" $VPN
STAGE2
chmod 700 "$STAGE"
tmux new-session -d -s "$SESSION" "'$STAGE'; code=\$?; echo; echo '[toxy] setup finished with status' \$code; exit \$code"
tmux set-option -t "$SESSION" remain-on-exit on
exec tmux attach-session -t "$SESSION"
