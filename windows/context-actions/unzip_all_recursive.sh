#!/usr/bin/env bash
# 遞迴解壓當前資料夾（含子資料夾）內所有 zip / rar，各自解到同名資料夾。
# 遇到解壓失敗就停下來，讓使用者看得到是哪個檔案出問題。
source "$(dirname "$0")/utils.sh"
unzip_all_recursive
echo
read -p "Press Enter to close..."
