#!/usr/bin/env bash
# 遞迴解壓當前資料夾（含子資料夾）內所有 zip / rar / 7z，各自解到同名資料夾。
# 解出來的壓縮檔也會繼續解；失敗的跳過，全部處理完後列出失敗清單，問使用者是否在 File Explorer 開啟。
source "$(dirname "$0")/utils.sh"
unzip_all_recursive
echo
read -p "Press Enter to close..."
