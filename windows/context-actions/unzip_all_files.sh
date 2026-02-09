#!/usr/bin/env bash
shopt -s nullglob
for z in *.zip; do
    7z x "$z" -o"${z%.zip}" && rm "$z"
done
read -p "Press Enter to close..."
