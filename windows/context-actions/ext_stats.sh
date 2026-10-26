#!/usr/bin/env bash
# Interactive per-extension file count of a folder ($1, or the current folder on background).
# mintty is not a Windows console, so msvcrt key reads need winpty in between.
root="${1:-$(pwd -W)}"
runner=()
command -v winpty >/dev/null && runner=(winpty)
if ! "${runner[@]}" python3 "$(dirname "$0")/ext_stats.py" "$root"; then
  read -p "Press Enter to close..."
fi
