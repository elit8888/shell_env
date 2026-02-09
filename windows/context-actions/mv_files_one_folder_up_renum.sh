#!/usr/bin/env bash
set -euo pipefail

process_dir() {
    local d="$1"
    local count=0

    echo "Processing: $d"

    shopt -s nullglob
    # Sort by modification time (oldest first)
    mapfile -t files < <(ls -rt -- "$d")
    for f in "${files[@]}"; do
        [[ -f "$d/$f" ]] || continue
        mv -- "$d/$f" "./$(basename "$d")-$count.${f##*.}"
        ((count++))
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

read -p "Press Enter to close..." || true

