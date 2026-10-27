#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"  # zipfile metadata_encoding
# ///
"""
unzip_jp.py - 解壓縮日文檔名的 zip 檔案（自動偵測 UTF-8 / cp932 / cp949 編碼）
用法：
    uv run --script unzip_jp.py <zip檔案> [輸出目錄] [-p 密碼]

若省略輸出目錄，則在 zip 檔案所在位置建立同名資料夾。
若 zip 內含加密項目，會以 -p 指定的密碼解壓；未提供則互動式詢問。
"""

import sys
import os
import getpass
import argparse
import zipfile

# 嘗試的檔名編碼：UTF-8 能解就直接用；否則在 cp932 (Shift-JIS) / cp949 (韓文) 中挑較合理者
FILENAME_ENCODINGS = ("utf-8", "cp932", "cp949")

# zipfile 能解的壓縮方式
SUPPORTED_METHODS = {zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED, zipfile.ZIP_BZIP2, zipfile.ZIP_LZMA}


def suspicious_chars(name: str) -> int:
    """計算「看起來是用錯編碼解出來」的字元數。
    韓文 cp949 位元組被 cp932 解碼時多半變成半形片假名；日文 cp932 位元組被 cp949 解碼時
    多半落在 KS X 1001 以外的 UHC 擴充韓文字。兩者都視為可疑。"""
    count = 0
    for ch in name:
        if "\uff61" <= ch <= "\uff9f":  # 半形片假名
            count += 1
        elif "\uac00" <= ch <= "\ud7a3":  # 韓文音節：不在 EUC-KR (KS X 1001) 常用字內即可疑
            try:
                ch.encode("euc_kr")
            except UnicodeEncodeError:
                count += 1
    return count


def open_zip(zip_path: str) -> zipfile.ZipFile:
    """以可用的編碼開啟 zip。UTF-8 能解就用；否則在其餘能解的編碼中挑可疑字元最少者（同分取先列者）。"""
    best: tuple[int, str] | None = None
    last_error: Exception | None = None
    for encoding in FILENAME_ENCODINGS:
        try:
            with zipfile.ZipFile(zip_path, "r", metadata_encoding=encoding) as z:
                names = z.namelist()  # 編碼不符會在此丟出 UnicodeDecodeError
        except UnicodeDecodeError as e:
            last_error = e
            continue
        if encoding == "utf-8":
            best = (0, encoding)
            break
        score = sum(suspicious_chars(n) for n in names)
        if best is None or score < best[0]:
            best = (score, encoding)
    if best is None:
        raise RuntimeError(
            f"無法以 {FILENAME_ENCODINGS} 任一編碼解析檔名：{last_error}"
        )
    encoding = best[1]
    print(f"檔名編碼：{encoding}")
    return zipfile.ZipFile(zip_path, "r", metadata_encoding=encoding)


def long_path(path: str) -> str:
    r"""Windows 未啟用 LongPathsEnabled 時，超過 MAX_PATH (260) 的路徑會失敗；
    轉成絕對路徑並加上 \\?\ 前綴改走延伸長度路徑。非 Windows 只回傳絕對路徑。"""
    path = os.path.abspath(path)
    if os.name != "nt" or path.startswith("\\\\?\\"):
        return path
    if path.startswith("\\\\"):  # UNC：\\server\share -> \\?\UNC\server\share
        return "\\\\?\\UNC\\" + path[2:]
    return "\\\\?\\" + path


def extract(zip_path: str, output_dir: str | None = None, password: str | None = None) -> None:
    zip_path = os.path.abspath(zip_path)

    if not os.path.isfile(zip_path):
        print(f"錯誤：找不到檔案 {zip_path}", file=sys.stderr)
        sys.exit(1)

    if output_dir is None:
        output_dir = os.path.splitext(zip_path)[0]

    display_dir = output_dir
    output_dir = long_path(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    with open_zip(zip_path) as z:
        entries = z.infolist()
        total = len(entries)

        # zipfile 不支援 AES 加密（method 99）、Deflate64（method 9）等；問密碼前先擋下，交給呼叫端改用 7z
        unsupported = {info.compress_type for info in entries} - SUPPORTED_METHODS
        if unsupported:
            print(f"錯誤：不支援的壓縮方式 {sorted(unsupported)}", file=sys.stderr)
            sys.exit(1)

        # 偵測是否有加密項目（flag bit 0）
        encrypted = any(info.flag_bits & 0x1 for info in entries)
        if encrypted and password is None:
            password = getpass.getpass("此 zip 含加密項目，請輸入密碼：")

        pwd_bytes = password.encode("utf-8") if password else None

        print(f"共 {total} 個項目，解壓至：{display_dir}\n")

        for i, info in enumerate(entries, 1):
            # \\?\ 路徑不會自動轉換 "/"，須拆開後以系統分隔符組合
            target = os.path.join(output_dir, *info.filename.split("/"))

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
        description="解壓縮日文檔名的 zip 檔案（自動偵測 UTF-8 / cp932 / cp949 編碼）"
    )
    parser.add_argument("zip_file", help="要解壓的 zip 檔案")
    parser.add_argument("output_dir", nargs="?", default=None, help="輸出目錄（預設為同名資料夾）")
    parser.add_argument("-p", "--password", default=None, help="加密 zip 的密碼")

    args = parser.parse_args()
    extract(args.zip_file, args.output_dir, args.password)
