#!/usr/bin/env bash
# Apply journal defaults to a fresh Intel Omarchy host over SSH (see README.md).
# Mac / ARM64 experimentation: document in the journal; do not run this script there.
set -euo pipefail

usage() {
    echo "usage: $0 user@host" >&2
    exit 1
}

[[ ${1-} ]] || usage
TARGET="$1"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_BODY="${DIR}/remote/apply-intel.sh"

[[ -f "$REMOTE_BODY" ]] || { echo "missing: $REMOTE_BODY" >&2; exit 1; }

# No -t: a TTY + fish as login shell can consume stdin; non-interactive ssh runs bash -s only.
exec ssh "$TARGET" bash -s <"$REMOTE_BODY"
