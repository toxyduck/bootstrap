# toxy bootstrap

Minimal macOS/Termux/Ubuntu/Debian SSH client (Git is installed only as a GitHub CLI runtime dependency) and remote server bootstrap.

On Termux the bootstrap also installs the `toxy-tmux` service. It discovers SSH
machines through `toxy machines list` and mirrors their remote tmux sessions into
the standard Termux session drawer. Fully restart Termux after the first install
so the `termux-services` daemon starts.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/toxyduck/bootstrap/main/install.sh)"
```

Daily commands:

```bash
toxy machines sync
toxy machines list
toxy machines connect <alias>
toxy setup [alias|user@ip] [--vpn]
toxy setup --local <alias> [--vpn]
toxy-tmux status
toxy-tmux refresh
toxy-tmux doctor
```

Remote SSH sessions default to `TERM=xterm-256color` for compatibility with servers that do not have Ghostty terminfo; override with `TOXY_REMOTE_TERM` when needed.

The client stays minimal. Git, Codex, Claude and dotfiles are installed on the selected machine inside `toxy-bootstrap`. Local setup takes an alias from the private inventory and uses its profile without SSH. Docker, Docker Compose and VPN are installed only when setup is run with `--vpn` on Linux.

`toxy machines list --format=json` is the stable machine-readable inventory
contract. The human-readable default remains unchanged. See
[`toxy-tmux/README.md`](toxy-tmux/README.md) for service controls, standalone
updates and troubleshooting.
