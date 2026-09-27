#!/usr/bin/env bash
# Render an interactive map viewer HTML for the RPG Maker game in the current folder.
uv run --project D:/Projects/rpg-view python D:/Projects/rpg-view/render_interactive.py "$(pwd -W)"
read -p "Press Enter to close..."
