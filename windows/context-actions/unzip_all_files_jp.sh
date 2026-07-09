#!/usr/bin/env bash
# 解壓資料夾內所有 zip，走 unzip_jp.py 的 UTF-8 / cp932 編碼偵測；成功後刪除原檔
shopt -s nullglob
here="$(dirname "$0")"
for z in *.zip; do
    python3 "$here/unzip_jp.py" "$z" && rm "$z"
done
echo ""
read -p "Press Enter to close..."
