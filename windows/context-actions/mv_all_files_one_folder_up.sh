#!/usr/bin/env bash
set -euo pipefail

for d in */; do
    echo "$d"
    cd "$d"
    for f in *; do
        mv -- "$f" "../${d%/}-$f" || exit 1
    done
    cd .. && rm -r -- "$d"
done

read -p "Press Enter to close..."
