# toxy bootstrap

Minimal Ubuntu/Debian SSH client and remote server bootstrap.

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

The client stays minimal. Full Git/Codex/Docker/dotfiles setup runs only on the selected server inside `toxy-bootstrap`.
