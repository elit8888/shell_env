#!/usr/bin/env bash
set -euo pipefail

process_dir() {
    local d="$1"
    local count=0

    echo "Processing: $d"

    shopt -s nullglob
    mapfile -t files < <(ls -- "$d" | sort)
    local total=0
    for f in "${files[@]}"; do
        [[ -f "$d/$f" ]] && total=$((total + 1))
    done
    local pad=${#total}

    for f in "${files[@]}"; do
        [[ -f "$d/$f" ]] || continue
        mv -- "$d/$f" "./$(basename "$d")-$(printf "%0${pad}d" $count).${f##*.}"
        count=$((count + 1))
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

