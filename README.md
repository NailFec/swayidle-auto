# swayidle-auto

Keep a Wayland session awake while it is plugged in, or while the computer has no system battery. On battery, lock with hyprlock and then suspend.

A mouse or keyboard battery does not count. UPower's OnBattery flag is the check: false on AC power (charging, full, or held at a charge limit) and false on a desktop.

## Behavior

| Power | Idle lock | Sleep |
| --- | --- | --- |
| Laptop on AC, or a desktop | No | No. Lid close and `systemctl suspend` are refused too |
| Laptop on battery | hyprlock after 5 minutes | Suspend after 10 minutes |

A manual lock key still works. This does not change that shortcut.

The battery timers are `LOCK_SEC` and `SUSPEND_SEC` at the top of `bin/swayidle-auto`. Edit them and run `./install.sh` again.

## Requirements

- A systemd user session with a running graphical session
- `swayidle` and `hyprlock`
- UPower (`busctl` can read `org.freedesktop.UPower`)

On Arch and CachyOS, `install.sh` installs the two packages with pacman when they are missing. That step asks for sudo. Everything else is installed in your home directory.

## Install

```bash
git clone <your repo url>
cd swayidle-auto
./install.sh
```

The installer copies:

| Source | Installed to |
| --- | --- |
| `bin/swayidle-auto` | `~/.local/bin/swayidle-auto` |
| `systemd/user/swayidle-auto.service` | `~/.config/systemd/user/swayidle-auto.service` |

The service is enabled for `graphical-session.target` and started immediately. It does not edit the compositor config. If niri still has a `spawn-at-startup` line for `swayidle/auto.sh`, remove that line. The service replaces it.

## Uninstall

```bash
./uninstall.sh
```

This stops the service and deletes the two installed files. Packages are left installed.
