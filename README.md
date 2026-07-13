# toxy bootstrap

Minimal macOS/Termux/Ubuntu/Debian SSH client (Git is installed only as a GitHub CLI runtime dependency) and remote server bootstrap.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/toxyduck/bootstrap/main/install.sh)"
```

Daily commands:

```bash
toxy machines sync
toxy machines list
toxy machines connect <alias>
toxy setup [alias|user@ip] [--vpn]
toxy setup --local [--vpn]
```

Remote SSH sessions default to `TERM=xterm-256color` for compatibility with servers that do not have Ghostty terminfo; override with `TOXY_REMOTE_TERM` when needed.

The client stays minimal. Git, Codex and dotfiles are installed on the selected server inside `toxy-bootstrap`. Docker, Docker Compose and VPN are installed only when setup is run with `--vpn`.
