# Runs on the Intel host via: ssh user@host bash -s < this-file
set -euo pipefail
STYLE="${HOME}/.config/waybar/style.css"

[[ -f "$STYLE" ]] || { echo "missing: $STYLE" >&2; exit 1; }

if grep -q 'font-size: 20px;' "$STYLE"; then
  sed -i '0,/font-size: 20px/{s/font-size: 20px;/font-size: 12px;/;}' "$STYLE"
  echo "waybar: first font-size: 20px -> 12px ($STYLE)"
else
  echo "waybar: skip (no font-size: 20px; to revert)"
fi

MARKER="${HOME}/.config/waybar/.omarchy-tray-expand-removed"
WBCONFIG="${HOME}/.config/waybar/config.jsonc"

if [[ -f "$MARKER" && -f "$WBCONFIG" ]]; then
  LINE1=$(sed -n '1p' "$MARKER")
  LINE2=$(sed -n '2p' "$MARKER")
  if [[ -z "$LINE2" ]]; then
    LINE2=12
  fi

  if [[ "$LINE1" =~ ^[0-9]+$ ]]; then
    jq --argjson i "$LINE1" '.["modules-right"][$i] |= if . == "tray" then "group/tray-expander" else . end' "$WBCONFIG" > "${WBCONFIG}.tmp"
    mv "${WBCONFIG}.tmp" "$WBCONFIG"
    echo "waybar: modules-right[$LINE1] tray -> group/tray-expander"
  elif [[ "$LINE1" == "-1" ]]; then
    echo "waybar: skip expander revert (apply had no group/tray-expander)"
  else
    echo "waybar: skip expander revert (invalid marker line 1: $LINE1)"
  fi

  jq --argjson s "$LINE2" '.tray["icon-size"] = $s' "$WBCONFIG" > "${WBCONFIG}.tmp"
  mv "${WBCONFIG}.tmp" "$WBCONFIG"
  echo "waybar: tray icon-size -> $LINE2 (restored)"

  rm -f "$MARKER"
  echo "waybar: marker removed ($MARKER)"
else
  echo "waybar: skip config revert (no marker or missing $WBCONFIG — run apply first)"
fi

pkill -SIGUSR2 waybar 2>/dev/null || pkill waybar 2>/dev/null || true
echo "waybar: reload signal sent (restart session if bar looks wrong)"

cat <<'EOF'

--- Next: root on this Intel host (optional) ---
If you installed pwgen only for this journal workflow, remove it as root:

  pacman -Rs --noconfirm pwgen
EOF
