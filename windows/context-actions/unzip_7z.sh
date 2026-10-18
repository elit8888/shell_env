#!/usr/bin/env bash
# 解壓單一 .7z 或分卷 7z 的第一卷（x.7z.001，7z 自動接續後續分卷）到同名資料夾，保留原檔
source "$(dirname "$0")/utils.sh"
f="$1"
if [[ "${f,,}" == *.001 && "${f,,}" != *.7z.001 ]]; then
    echo "ERROR: only multi-volume 7z (.7z.001) is supported: $f"
else
    7z x -y -o"$(archive_out_dir "$f")" "$f"
fi
echo ""
read -p "Press Enter to close..."
