r"""Shared filesystem helpers for the context-actions scripts.

Every path handed out is absolute with the \\?\ prefix, so neither MAX_PATH (260)
nor long folder names (> 255 UTF-8 bytes, which broke the old Git Bash scripts)
get in the way. ffmpeg and 7z accept these paths as-is.
"""
import os
import subprocess
from collections.abc import Callable, Iterable


def long_path(path: str | os.PathLike) -> str:
    r"""Absolute path with the \\?\ extended-length prefix (plain absolute path off Windows)."""
    path = os.fspath(path)
    if path.startswith("\\\\?\\"):
        return path
    path = os.path.abspath(path)
    if os.name != "nt":
        return path
    if path.startswith("\\\\"):  # UNC: \\server\share -> \\?\UNC\server\share
        return "\\\\?\\UNC\\" + path[2:]
    return "\\\\?\\" + path


def rel(path: str, root: str) -> str:
    """Display form of path relative to root, with / separators."""
    return os.path.relpath(long_path(path), long_path(root)).replace(os.sep, "/")


def has_ext(name: str, exts: Iterable[str]) -> bool:
    lower = name.lower()
    return any(lower.endswith("." + ext.lower()) for ext in exts)


def find_files(root: str, exts: Iterable[str], *, recursive: bool = True,
               prune: Callable[[str], bool] | None = None) -> list[str]:
    """Files under root whose extension (case-insensitive) is one of exts, sorted.

    prune(dir_name) -> True skips that directory and everything below it.
    """
    exts = list(exts)
    found = []
    for dirpath, dirnames, filenames in os.walk(long_path(root)):
        dirnames[:] = [] if not recursive else [d for d in dirnames if not (prune and prune(d))]
        found += [os.path.join(dirpath, f) for f in filenames if has_ext(f, exts)]
    return sorted(found, key=lambda p: rel(p, root))


def plain_path(path: str) -> str:
    r"""Drop the \\?\ prefix again, for programs that do not understand it (explorer.exe)."""
    if path.startswith("\\\\?\\UNC\\"):
        return "\\\\" + path[len("\\\\?\\UNC\\"):]
    return path.removeprefix("\\\\?\\")


def reveal(path: str) -> None:
    """Open File Explorer at the file's folder with the file selected."""
    subprocess.Popen(f'explorer /select,"{os.path.normpath(plain_path(long_path(path)))}"')


def delete_original() -> bool:
    """ELIT_DELETE_ORIGINAL=false keeps the source files after a successful conversion."""
    return os.environ.get("ELIT_DELETE_ORIGINAL", "true") == "true"
