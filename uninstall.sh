#!/bin/bash
# Stop the idle policy and remove the files install.sh copied into the home directory.
set -euo pipefail

USER_ID=$(id -u)

if [[ $USER_ID -eq 0 ]]; then
  echo "Run this as your desktop user, not as root." >&2
  exit 1
fi

export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$USER_ID}

systemctl --user disable --now swayidle-auto.service >/dev/null 2>&1 || true
rm -f "$HOME/.local/bin/swayidle-auto" "$HOME/.config/systemd/user/swayidle-auto.service"
systemctl --user daemon-reload || true

echo "Removed the swayidle-auto service and script."
echo "swayidle and hyprlock were left installed."
