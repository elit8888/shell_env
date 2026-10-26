#!/usr/bin/env bash
if command -v uv > /dev/null 2>&1; then
    uv run --script "$(dirname "$0")/unzip_jp.py" "$1"
else
    echo "ERROR: uv not found in PATH."
fi
echo ""
read -p "Press Enter to close..."
