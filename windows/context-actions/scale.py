"""Downscale jpg images into a by<factor>/ folder via ffmpeg."""
import os
import re

import fsops
from convert import ffmpeg

# Previous scale output folders (by2/, by1.5/, ...) are never treated as input
SCALE_OUT_RE = re.compile(r"by[0-9.]+")


def is_scale_out(dir_name: str) -> bool:
    return SCALE_OUT_RE.fullmatch(dir_name) is not None


def ffmpeg_scale(fac: str, src: str, out: str) -> bool:
    os.makedirs(os.path.dirname(out), exist_ok=True)
    ok, msg = ffmpeg("-y", "-v", "error", "-i", src, "-vf", f"scale=iw/{fac}:ih/{fac}", out)
    if msg:
        print(msg)
    return ok


def scale_one(fac: str, src: str) -> bool:
    """<dir>/x.jpg -> <dir>/by<fac>/x.jpg"""
    src = fsops.long_path(src)
    return ffmpeg_scale(fac, src, os.path.join(os.path.dirname(src), f"by{fac}", os.path.basename(src)))


def has_subdirs(root: str = ".") -> bool:
    with os.scandir(fsops.long_path(root)) as it:
        return any(e.is_dir() and not is_scale_out(e.name) for e in it)


def scale_all(fac: str, recursive: bool = False, root: str = ".") -> int:
    """Scale every *.jpg into <root>/by<fac>/; recursive keeps the subfolder structure there."""
    files = fsops.find_files(root, ["jpg"], recursive=recursive, prune=is_scale_out)
    if not files:
        print("No .jpg files found.")
        return 1
    out_root = os.path.join(fsops.long_path(root), f"by{fac}")
    failed = 0
    for f in files:
        print(fsops.rel(f, root))
        out = os.path.join(out_root, os.path.relpath(f, fsops.long_path(root)))
        failed += not ffmpeg_scale(fac, f, out)
    return 1 if failed else 0
