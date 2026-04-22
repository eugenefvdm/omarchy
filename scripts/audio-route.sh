#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
usage: scripts/audio-route.sh [soundcore|jabra] [--restart-audio]

Examples:
  scripts/audio-route.sh soundcore
  scripts/audio-route.sh jabra
  scripts/audio-route.sh soundcore --restart-audio
EOF
    exit 1
}

[[ ${1-} ]] || usage

TARGET="$1"
RESTART_AUDIO=0
if [[ "${2-}" == "--restart-audio" ]]; then
    RESTART_AUDIO=1
fi

case "$TARGET" in
    soundcore)
        SINK_NAME="Soundcore Mini 3 Pro"
        # Override with SOUNDCORE_BLUETOOTH_MAC env var if needed.
        BLUETOOTH_MAC="${SOUNDCORE_BLUETOOTH_MAC:-3C:39:E7:B7:54:84}"
        ;;
    jabra)
        SINK_NAME="Jabra EVOLVE 20 Mono"
        BLUETOOTH_MAC=""
        ;;
    *)
        usage
        ;;
esac

if (( RESTART_AUDIO == 1 )); then
    echo "Restarting user audio services..."
    systemctl --user restart wireplumber pipewire pipewire-pulse
fi

find_sink_id() {
    local name="$1"
    wpctl status | awk -v sink_name="$name" '
        /├─ Sinks:/ { in_sinks=1; next }
        /├─ Sources:/ { in_sinks=0 }
        in_sinks && index($0, sink_name) {
            if (match($0, /[0-9]+\./)) {
                sink_id = substr($0, RSTART, RLENGTH)
                sub(/\.$/, "", sink_id)
                print sink_id
                exit
            }
        }
    '
}

SINK_ID="$(find_sink_id "$SINK_NAME")"

if [[ -z "$SINK_ID" && -n "$BLUETOOTH_MAC" ]]; then
    echo "Sink \"$SINK_NAME\" not found. Attempting bluetooth reconnect..."
    bluetoothctl connect "$BLUETOOTH_MAC" >/dev/null || true
    sleep 2
    SINK_ID="$(find_sink_id "$SINK_NAME")"
fi

if [[ -z "$SINK_ID" ]]; then
    echo "Could not find sink: $SINK_NAME" >&2
    echo "Run: wpctl status" >&2
    exit 2
fi

echo "Routing audio to: $SINK_NAME (sink $SINK_ID)"
wpctl set-default "$SINK_ID"
wpctl set-mute "$SINK_ID" 0
wpctl set-volume "$SINK_ID" 1.0

STREAM_IDS="$(pactl list short sink-inputs | awk '{print $1}')"

if [[ -z "$STREAM_IDS" ]]; then
    echo "No active sink-input streams to move."
else
    while IFS= read -r stream_id; do
        [[ -n "$stream_id" ]] || continue
        pactl move-sink-input "$stream_id" "$SINK_ID"
        pactl set-sink-input-mute "$stream_id" 0
        pactl set-sink-input-volume "$stream_id" 100%
    done <<<"$STREAM_IDS"
fi

echo "Done. Current audio summary:"
wpctl status
