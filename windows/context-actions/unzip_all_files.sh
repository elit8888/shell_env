#!/usr/bin/env bash
# 解壓資料夾內所有 zip / 7z / 分卷 7z（x.7z.001）到同名資料夾；成功後刪除原檔（含所有分卷）
source "$(dirname "$0")/utils.sh"
shopt -s nullglob nocaseglob
for z in *.zip *.7z *.7z.001; do
    7z x "$z" -o"$(archive_out_dir "$z")" && archive_rm "$z"
done
read -p "Press Enter to close..."
