#!/usr/bin/env bash
source "$(dirname "$0")/utils.sh"

if [ -n "$1" ]; then
  cd "$1"
fi

echo "Renaming *.jpg_large and *.png_large in: $(pwd)"
rename_large_ext

read -p "Press Enter to close..."
