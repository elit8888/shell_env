#!/usr/bin/env bash
set -euo pipefail

process_dir() {
    local d="$1"

    echo "Processing: $d"

    shopt -s nullglob
    for f in "$d"/*; do
        mv -- "$f" "./$(basename "$d")-$(basename "$f")"
    done
    shopt -u nullglob

    rmdir -- "$d"
}

if [[ $# -ge 1 ]]; then
    # Process specified directories only
    for d in "$@"; do
        [[ -d "$d" ]] || { echo "Not a directory: $d"; exit 1; }
        process_dir "${d%/}"
    done
else
    # Process all subdirectories
    for d in */; do
        process_dir "${d%/}"
    done
fi

read -p "Press Enter to close..."

