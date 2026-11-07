"""Folder housekeeping: move files one folder up, move videos into video/, rename files."""
import os
import re

import fsops

VIDEO_EXTS = ["mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg", "3gp", "gif"]
LARGE_EXTS = ["jpg_large", "png_large"]
SPECIAL_RE = re.compile(r"[　 ?'^+();,&＆、【】＋!\-]+")


def subdirs(root: str) -> list[str]:
    root = fsops.long_path(root)
    return sorted(os.path.join(root, n) for n in os.listdir(root)
                  if not n.startswith(".") and os.path.isdir(os.path.join(root, n)))


def move_up(d: str, renumber: bool) -> None:
    """Move d's entries into d's parent as '<d>-<name>' (files renumbered '<d>-<n>.<ext>'), then drop d."""
    d = fsops.long_path(d).rstrip("\\/")
    parent, prefix = os.path.split(d)
    print(f"Processing: {prefix}")
    names = sorted(os.listdir(d))
    files = [n for n in names if os.path.isfile(os.path.join(d, n))]
    pad = len(str(len(files)))
    moves = []
    for n in names:
        if renumber and n in files:
            new = f"{prefix}-{files.index(n):0{pad}d}{os.path.splitext(n)[1]}"
        else:
            new = f"{prefix}-{n}"
        moves.append((os.path.join(d, n), os.path.join(parent, new)))
    # Check every target first so a clash leaves the folder untouched
    for _, dest in moves:
        if os.path.exists(dest):
            raise FileExistsError(f"target already exists: {fsops.plain_path(dest)}")
    for src, dest in moves:
        os.rename(src, dest)
    os.rmdir(d)


def mv_files_one_folder_up(dirs: list[str] | None = None, renumber: bool = False, root: str = ".") -> int:
    """Given dirs, process just those; otherwise every subfolder of root."""
    if dirs is not None:
        for d in dirs:
            if not os.path.isdir(fsops.long_path(d)):
                print(f"Not a directory: {d}")
                return 1
    for d in dirs if dirs is not None else subdirs(root):
        move_up(d, renumber)
    return 0


def move_videos_to_subfolder(root: str = ".") -> int:
    """./a/b/c.mp4 -> ./a/b/video/c.mp4; files already inside a video/ folder stay put."""
    files = fsops.find_files(root, VIDEO_EXTS)
    if not files:
        print("No video files found.")
        return 0
    moved = skipped = 0
    for f in files:
        folder, name = os.path.split(f)
        if "video" in fsops.rel(folder, root).split("/"):
            skipped += 1
            continue
        dest = os.path.join(folder, "video", name)
        if os.path.exists(dest):
            print(f"SKIP (exists): {fsops.rel(dest, root)}")
            continue
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        os.rename(f, dest)
        print(f"Moved: {fsops.rel(f, root)} -> {fsops.rel(dest, root)}")
        moved += 1
    print()
    print(f"Done. {moved} file(s) moved. {skipped} already in video/ (skipped).")
    return 0


def rename_large_ext(root: str = ".") -> int:
    """x.jpg_large -> x.jpg, x.png_large -> x.png (recursive)."""
    print(f"Renaming *.jpg_large and *.png_large in: {fsops.plain_path(fsops.long_path(root))}")
    count = 0
    for f in fsops.find_files(root, LARGE_EXTS):
        new = f[:-len("_large")]
        if os.path.exists(new):
            print(f"SKIP (exists): {fsops.rel(new, root)}")
            continue
        os.rename(f, new)
        print(f"Renamed: {fsops.rel(f, root)} -> {fsops.rel(new, root)}")
        count += 1
    print()
    print(f"Done. {count} file(s) renamed.")
    return 0


def special_name(name: str) -> str:
    """Each run of special characters (spaces, brackets, punctuation, ...) becomes a single '-'."""
    return SPECIAL_RE.sub("-", name)


def rename_special_chars(root: str = ".") -> int:
    """Recursively rename files and folders; deepest first so parent paths stay valid."""
    top = fsops.long_path(root)
    for dirpath, dirnames, filenames in os.walk(top, topdown=False):
        for name in filenames + dirnames:
            new = special_name(name)
            if new == name:
                continue
            src, dest = os.path.join(dirpath, name), os.path.join(dirpath, new)
            if os.path.exists(dest):
                print(f"Warning: {fsops.rel(dest, root)} already exists, skipping {fsops.rel(src, root)}")
                continue
            print(f"Rename: {fsops.rel(src, root)} -> {fsops.rel(dest, root)}")
            os.rename(src, dest)
    return 0
