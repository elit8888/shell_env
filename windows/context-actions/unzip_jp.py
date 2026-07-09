#!/usr/bin/env python3
"""
unzip_jp.py - 解壓縮日文檔名的 zip 檔案（自動偵測 UTF-8 / cp932 編碼）
用法：
    python unzip_jp.py <zip檔案> [輸出目錄] [-p 密碼]

若省略輸出目錄，則在 zip 檔案所在位置建立同名資料夾。
若 zip 內含加密項目，會以 -p 指定的密碼解壓；未提供則互動式詢問。
"""

import sys
import os
import getpass
import argparse
import zipfile

# 嘗試的檔名編碼順序：先 UTF-8，失敗再退回 cp932 (Shift-JIS)
FILENAME_ENCODINGS = ("utf-8", "cp932")


def open_zip(zip_path: str) -> zipfile.ZipFile:
    """以可用的編碼開啟 zip。逐一嘗試 FILENAME_ENCODINGS，直到能讀出檔名清單。"""
    last_error: Exception | None = None
    for encoding in FILENAME_ENCODINGS:
        try:
            z = zipfile.ZipFile(zip_path, "r", metadata_encoding=encoding)
            z.infolist()  # 觸發檔名解碼；編碼不符會在此丟出 UnicodeDecodeError
            print(f"檔名編碼：{encoding}")
            return z
        except UnicodeDecodeError as e:
            last_error = e
            continue
    raise RuntimeError(
        f"無法以 {FILENAME_ENCODINGS} 任一編碼解析檔名：{last_error}"
    )


def extract(zip_path: str, output_dir: str | None = None, password: str | None = None) -> None:
    zip_path = os.path.abspath(zip_path)

    if not os.path.isfile(zip_path):
        print(f"錯誤：找不到檔案 {zip_path}", file=sys.stderr)
        sys.exit(1)

    if output_dir is None:
        output_dir = os.path.splitext(zip_path)[0]

    os.makedirs(output_dir, exist_ok=True)

    with open_zip(zip_path) as z:
        entries = z.infolist()
        total = len(entries)

        # 偵測是否有加密項目（flag bit 0）
        encrypted = any(info.flag_bits & 0x1 for info in entries)
        if encrypted and password is None:
            password = getpass.getpass("此 zip 含加密項目，請輸入密碼：")

        pwd_bytes = password.encode("utf-8") if password else None

        print(f"共 {total} 個項目，解壓至：{output_dir}\n")

        for i, info in enumerate(entries, 1):
            target = os.path.join(output_dir, info.filename)

            if info.filename.endswith("/"):
                os.makedirs(target, exist_ok=True)
            else:
                os.makedirs(os.path.dirname(target), exist_ok=True)
                z.extract(info, output_dir, pwd=pwd_bytes)

            print(f"[{i:>4}/{total}] {info.filename}")

    print("\n解壓縮完成！")


if __name__ == "__main__":
    # 設定 stdout 使用 utf-8，避免 Windows 終端編碼問題
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(
        description="解壓縮日文檔名的 zip 檔案（自動偵測 UTF-8 / cp932 編碼）"
    )
    parser.add_argument("zip_file", help="要解壓的 zip 檔案")
    parser.add_argument("output_dir", nargs="?", default=None, help="輸出目錄（預設為同名資料夾）")
    parser.add_argument("-p", "--password", default=None, help="加密 zip 的密碼")

    args = parser.parse_args()
    extract(args.zip_file, args.output_dir, args.password)
