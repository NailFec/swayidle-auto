#!/bin/bash
# Install the idle lock/sleep policy for the user who runs this script.
# sudo is only used to install swayidle and hyprlock when they are missing.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
USER_ID=$(id -u)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:${HOME}/.local/bin${PATH:+:$PATH}"
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$USER_ID}

if [[ $USER_ID -eq 0 ]]; then
  echo "Run this as your desktop user, not as root." >&2
  exit 1
fi

if command -v pacman >/dev/null 2>&1; then
  need_pkgs=()
  for pkg in swayidle hyprlock; do
    pacman -Q "$pkg" >/dev/null 2>&1 || need_pkgs+=("$pkg")
  done
  if ((${#need_pkgs[@]})); then
    echo "Installing: ${need_pkgs[*]}"
    if [[ -t 0 ]]; then
      sudo pacman -S --needed --noconfirm "${need_pkgs[@]}" || pkg_install_failed=1
    else
      sudo -n pacman -S --needed --noconfirm "${need_pkgs[@]}" || pkg_install_failed=1
    fi
    if [[ ${pkg_install_failed:-0} -eq 1 ]]; then
      echo "Could not install ${need_pkgs[*]}. Install them later with: sudo pacman -S ${need_pkgs[*]}" >&2
    fi
  fi
else
  echo "pacman was not found. Install swayidle and hyprlock with your package manager if they are missing." >&2
fi

if ! command -v hyprlock >/dev/null 2>&1; then
  echo "hyprlock is not on PATH. The screen cannot be locked until it is installed." >&2
  exit 1
fi
if ! command -v swayidle >/dev/null 2>&1; then
  echo "swayidle is not on PATH. On battery, idle lock and suspend will not run until it is installed." >&2
fi

install -d -m 755 "$HOME/.local/bin" "$HOME/.config/systemd/user"
install -m 755 "$ROOT/bin/swayidle-auto" "$HOME/.local/bin/swayidle-auto"
install -m 644 "$ROOT/systemd/user/swayidle-auto.service" "$HOME/.config/systemd/user/swayidle-auto.service"

# Drop the earlier one-shot run, if this session started the script by hand.
systemctl --user stop swayidle-auto.service >/dev/null 2>&1 || true
systemctl --user daemon-reload
systemctl --user enable --now swayidle-auto.service

niri_cfg=${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl
if [[ -f $niri_cfg ]] && grep -q 'swayidle/auto\.sh' "$niri_cfg"; then
  echo "Remove the swayidle/auto.sh spawn-at-startup line from $niri_cfg." >&2
  echo "The swayidle-auto user service starts the policy." >&2
fi

echo
echo "Installed. Plugged in, or a desktop with no system battery: no lock and no sleep."
echo "On battery: hyprlock after 5 minutes, suspend after 10 minutes."
echo "Change LOCK_SEC and SUSPEND_SEC in bin/swayidle-auto, then run ./install.sh again."
