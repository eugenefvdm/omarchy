# Runs on the Intel host via: ssh user@host bash -s < this-file
# Do not run this file directly on the Mac.
set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "error: jq not found — install as root, then re-run apply:" >&2
  echo "  pacman -S --needed jq" >&2
  exit 1
fi

STYLE="${HOME}/.config/waybar/style.css"

[[ -f "$STYLE" ]] || { echo "missing: $STYLE" >&2; exit 1; }

if grep -q 'font-size: 12px;' "$STYLE"; then
  sed -i 's/font-size: 12px;/font-size: 20px;/' "$STYLE"
  echo "waybar: font-size 12px -> 20px ($STYLE)"
else
  echo "waybar: skip (no font-size: 12px; — already applied or edited?)"
fi

WBCONFIG="${HOME}/.config/waybar/config.jsonc"
MARKER="${HOME}/.config/waybar/.omarchy-tray-expand-removed"

if [[ -f "$WBCONFIG" ]]; then
  ICON_BEFORE=$(jq -r '.tray["icon-size"] // 12' "$WBCONFIG")
  IDX=$(jq -r '.["modules-right"] | index("group/tray-expander")' "$WBCONFIG")

  jq '
    .["modules-right"] |= map(if . == "group/tray-expander" then "tray" else . end) |
    if .tray != null then .tray["icon-size"] = 20 else . end
  ' "$WBCONFIG" > "${WBCONFIG}.tmp"
  mv "${WBCONFIG}.tmp" "$WBCONFIG"

  if [[ -n "$IDX" && "$IDX" != "null" ]]; then
    EXP_IDX=$IDX
  else
    EXP_IDX=-1
  fi
  printf '%s\n%s\n' "$EXP_IDX" "$ICON_BEFORE" > "$MARKER"
  echo "waybar: config.jsonc — tray expander removed if present; tray icon-size -> 20 (was $ICON_BEFORE); marker $MARKER"
else
  echo "waybar: skip config (missing $WBCONFIG)"
fi

pkill -SIGUSR2 waybar 2>/dev/null || pkill waybar 2>/dev/null || true
echo "waybar: reload signal sent (restart session if bar looks wrong)"

cat <<'EOF'

--- Next: root on this Intel host ---
Log on, elevate to root, and install packages this journal uses (skip any you already have):

  pacman -S --needed --noconfirm jq pwgen
EOF
