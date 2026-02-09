#!/usr/bin/env bash
set -euo pipefail

for d in */; do
    echo "$d"
    cd "$d"
    count=0
    mapfile -t files < <(ls -rt)
    for f in "${files[@]}"; do
        mv -- "$f" "../${d%/}-${count}.${f##*.}" || exit 1
        (( count++ ))
    done
    cd .. && rm -r -- "$d"
done

read -p "Press Enter to close..."
