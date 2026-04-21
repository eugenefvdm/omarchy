#!/usr/bin/env bash
# Undo apply-omarchy-customizations.sh on the Intel host over SSH (see README.md).
# Mac: out of scope — same premise as apply script.
set -euo pipefail

usage() {
    echo "usage: $0 user@host" >&2
    exit 1
}

[[ ${1-} ]] || usage
TARGET="$1"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_BODY="${DIR}/remote/revert-intel.sh"

[[ -f "$REMOTE_BODY" ]] || { echo "missing: $REMOTE_BODY" >&2; exit 1; }

exec ssh "$TARGET" bash -s <"$REMOTE_BODY"
