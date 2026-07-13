# toxy-tmux for Termux

`toxy-tmux` mirrors tmux sessions from the SSH machines returned by
`toxy machines list` into the standard Termux session drawer. It does not fork
Termux and does not install an Android plugin APK.

## Installation

> [!IMPORTANT]
> `toxy-tmux` requires the classic Termux app from F-Droid or the official
> Termux GitHub releases. **The Google Play Termux build is not supported:** it
> does not include `RunCommandService`, so `toxy-tmux` cannot create terminal
> sessions even if discovery and the background service are working.
>
> Back up the existing Termux home and SSH keys before changing sources.
> Android cannot install the F-Droid/GitHub APK over the Google Play build
> because they use different signing keys. Uninstall Termux and all Termux
> plugins first, then install Termux and any plugins from the same source. The
> recommended stable APK is
> [Termux 0.118.3 from F-Droid](https://f-droid.org/repo/com.termux_1002.apk).

The normal toxy bootstrap installs and enables this package automatically when
run inside Termux:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/toxyduck/bootstrap/main/install.sh)"
```

To reinstall or update only this package:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/toxyduck/bootstrap/main/toxy-tmux/install.sh)"
```

Fully close and reopen Termux after the first installation so the
`termux-services` daemon starts. The installer enables
`allow-external-apps=true` in `~/.termux/termux.properties`; this is required by
Termux `RUN_COMMAND` and allows permitted callers to execute commands in the
Termux environment.

## Usage

```bash
toxy-tmux status
toxy-tmux doctor
toxy-tmux refresh
toxy-tmux logs
```

The service polls the default tmux server of the current SSH user every five
seconds. New remote sessions become named Termux sessions such as
`toxy-main/work [$1]`. Killing a remote tmux session closes its local Termux
session. Temporary SSH failures reconnect inside the existing session.

If a generated Termux session is closed or detached manually, it stays hidden.
Run `toxy-tmux refresh` to execute `toxy machines sync`, reload the machine list,
clear hidden sessions, and recreate them.

Service controls:

```bash
sv status toxy-tmux
sv down toxy-tmux
sv up toxy-tmux
sv-disable toxy-tmux
sv-enable toxy-tmux
```

The runit log is stored at `$PREFIX/var/log/sv/toxy-tmux/current`.

## Expected error states

- **`toxy` is missing or too old:** the watcher reports `blocked` and does not
  fall back to SSH config or another inventory. Install the current toxy
  bootstrap.
- **GitHub authentication is unavailable:** run `toxy machines sync`
  interactively, then `toxy-tmux refresh`.
- **A machine is unreachable:** existing attached sessions keep running or
  reconnect; the machine appears as `unreachable` in `toxy-tmux status`.
- **Remote tmux is missing:** the machine appears as `unavailable`.
- **No tmux sessions exist:** this is a healthy zero-session state.

Only machines with `has_ssh_endpoint=true` in `toxy machines list --format=json`
are used. Profile-only entries are ignored. Version 0.1 tracks the default tmux
socket only; custom `tmux -L` and `tmux -S` sockets are not discovered.
