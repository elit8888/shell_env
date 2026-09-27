#!/usr/bin/env bash
# Translate an RPG Maker MV game in the current folder from Japanese to Chinese.
bun D:/Documents/unreal/tools/rpgmv-trans/src/cli.ts run "$(pwd -W)"
read -p "Press Enter to close..."
