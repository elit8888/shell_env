"""Archive extraction: recursive zip/rar/7z, single 7z, single Japanese-filename zip."""
import os
import re
import subprocess
import sys
from collections.abc import Callable
from shutil import which

import fsops

HERE = os.path.dirname(os.path.abspath(__file__))
UNZIP_JP = os.path.join(HERE, "unzip_jp.py")
ARCHIVE_EXTS = ["zip", "rar", "7z", "7z.001"]

RAR_PART_RE = re.compile(r"^(.*)\.part(\d+)\.rar$", re.IGNORECASE)
PART_SUFFIX_RE = re.compile(r"\.part\d+$", re.IGNORECASE)
SEVEN_VOL_RE = re.compile(r"\.7z\.\d{3}$", re.IGNORECASE)


def is_7z_volume_start(f: str) -> bool:
    return f.lower().endswith(".7z.001")


def archive_out_dir(f: str) -> str:
    """Destination folder: drop the extension; x.7z.001 -> x, x.partN.rar -> x."""
    out = os.path.splitext(f)[0]
    if is_7z_volume_start(f):
        out = os.path.splitext(out)[0]
    return PART_SUFFIX_RE.sub("", out)


def is_trailing_rar_part(f: str) -> bool:
    """x.part2.rar, x.part3.rar ... (7z picks those up from the first part)."""
    m = RAR_PART_RE.match(os.path.basename(f))
    return m is not None and int(m.group(2)) != 1


def archive_rm(f: str) -> None:
    """Delete an archive; x.7z.001 takes every x.7z.NNN with it, x.partN.rar every x.partN.rar."""
    f = fsops.long_path(f)
    folder, name = os.path.split(f)
    if is_7z_volume_start(name):
        base = name[:-len(".001")].lower()
        doomed = [n for n in os.listdir(folder)
                  if n.lower().startswith(base) and re.fullmatch(r"\.\d{3}", n[len(base):])]
    elif m := RAR_PART_RE.match(name):
        base = m.group(1).lower()
        doomed = [n for n in os.listdir(folder)
                  if (p := RAR_PART_RE.match(n)) and p.group(1).lower() == base]
    else:
        doomed = [name]
    for n in doomed:
        os.remove(os.path.join(folder, n))


def seven_x(f: str, out: str) -> bool:
    if which("7z") is None:
        print("ERROR: 7z not found in PATH.")
        return False
    return subprocess.run(["7z", "x", "-y", f"-o{out}", f]).returncode == 0


def run_unzip_jp(f: str, out: str | None = None) -> bool:
    return subprocess.run([sys.executable, UNZIP_JP, f, *([out] if out else [])]).returncode == 0


def unzip_one(f: str, out: str) -> bool:
    """zip goes through unzip_jp.py (UTF-8 / cp932 names, password prompt) and falls back to 7z
    for what zipfile cannot handle (AES, Deflate64, ...); rar / 7z go straight to 7z."""
    if f.lower().endswith(".zip"):
        if run_unzip_jp(f, out):
            return True
        print(f"unzip_jp.py failed, retrying with 7z: {f}")
    return seven_x(f, out)


def unzip_all_recursive(root: str = ".", ask: Callable[[str], str] = input,
                        reveal: Callable[[str], None] = fsops.reveal) -> int:
    """Extract every archive under root into a same-name folder, then whatever came out of those,
    until nothing new turns up. Failures are skipped and listed at the end."""
    seen: set[str] = set()
    failed: list[str] = []
    count = 0
    while new := [f for f in fsops.find_files(root, ARCHIVE_EXTS) if f not in seen]:
        for f in new:
            seen.add(f)
            shown = fsops.rel(f, root)
            if is_trailing_rar_part(f):
                print(f"SKIP (multi-volume part): {shown}")
                continue
            out = archive_out_dir(f)
            print(f"Extracting: {shown} -> {fsops.rel(out, root)}/")
            if unzip_one(f, out):
                if fsops.delete_original():
                    archive_rm(f)
                count += 1
            else:
                print(f"ERROR: failed to extract: {shown}")
                failed.append(f)

    if not seen:
        print("No .zip, .rar or .7z files found.")
        return 0

    print()
    print(f"Done. {count} archive(s) extracted, {len(failed)} failed.")
    if not failed:
        return 0
    print("Failed:")
    for f in failed:
        print(f"  {fsops.rel(f, root)}")
    if ask("Open failed archive(s) in File Explorer? [y/N] ").strip().lower().startswith("y"):
        for f in failed:
            reveal(f)
    return 1


def unzip_7z(f: str) -> int:
    """Single .7z, or the first volume x.7z.001, into a same-name folder; originals kept."""
    if f.lower().endswith(".001") and not is_7z_volume_start(f):
        print(f"ERROR: only multi-volume 7z (.7z.001) is supported: {f}")
        return 1
    f = fsops.long_path(f)
    return 0 if seven_x(f, archive_out_dir(f)) else 1


def unzip_jp(f: str) -> int:
    """Single zip with Japanese filenames into a same-name folder; original kept."""
    return 0 if run_unzip_jp(fsops.long_path(f)) else 1
