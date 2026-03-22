#!/usr/bin/env python3
"""
unzip_jp.py - 以 cp932 (Shift-JIS) 編碼解壓縮 zip 檔案
用法：
    python unzip_jp.py <zip檔案> [輸出目錄]

若省略輸出目錄，則在 zip 檔案所在位置建立同名資料夾。
"""

import sys
import os
import zipfile


def extract(zip_path: str, output_dir: str | None = None) -> None:
    zip_path = os.path.abspath(zip_path)

    if not os.path.isfile(zip_path):
        print(f"錯誤：找不到檔案 {zip_path}", file=sys.stderr)
        sys.exit(1)

    if output_dir is None:
        base = os.path.splitext(zip_path)[0]
        output_dir = base

    os.makedirs(output_dir, exist_ok=True)

    with zipfile.ZipFile(zip_path, "r", metadata_encoding="cp932") as z:
        entries = z.infolist()
        total = len(entries)
        print(f"共 {total} 個項目，解壓至：{output_dir}\n")

        for i, info in enumerate(entries, 1):
            target = os.path.join(output_dir, info.filename)

            if info.filename.endswith("/"):
                os.makedirs(target, exist_ok=True)
            else:
                os.makedirs(os.path.dirname(target), exist_ok=True)
                z.extract(info, output_dir)

            print(f"[{i:>4}/{total}] {info.filename}")

    print("\n解壓縮完成！")


if __name__ == "__main__":
    # 設定 stdout 使用 utf-8，避免 Windows 終端編碼問題
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    zip_arg = sys.argv[1]
    out_arg = sys.argv[2] if len(sys.argv) >= 3 else None

    extract(zip_arg, out_arg)
