#!/usr/bin/env bash
# Apply journal defaults to a host over SSH. See README.md (Waybar font size, pwgen).
set -euo pipefail

usage() {
    echo "usage: $0 user@host" >&2
    exit 1
}

[[ ${1-} ]] || usage
TARGET="$1"

exec ssh -t "$TARGET" bash -s <<'REMOTE'
set -euo pipefail
STYLE="${HOME}/.config/waybar/style.css"

[[ -f "$STYLE" ]] || { echo "missing: $STYLE" >&2; exit 1; }

if grep -q 'font-size: 12px;' "$STYLE"; then
  sed -i 's/font-size: 12px;/font-size: 20px;/' "$STYLE"
  echo "waybar: font-size 12px -> 20px ($STYLE)"
else
  echo "waybar: skip (no font-size: 12px; — already applied or edited?)"
fi

sudo pacman -S --needed --noconfirm pwgen
echo "pacman: pwgen installed"

pkill -SIGUSR2 waybar 2>/dev/null || pkill waybar 2>/dev/null || true
echo "waybar: reload signal sent (restart session if bar looks wrong)"
REMOTE
