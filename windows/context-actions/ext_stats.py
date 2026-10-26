"""統計指定資料夾（預設目前目錄）底下各副檔名的檔案數，並可在 console 上瀏覽

用法：ext_stats.py [資料夾]
↑↓ 選擇、→ 列出該副檔名的所有檔案、← 回上一層、
檔案列表中 Enter 開啟檔案所在資料夾，副檔名表中 Enter 結束
"""
import argparse
import os
import shutil
import subprocess
import sys
import traceback
import unicodedata
from collections.abc import Sequence
from dataclasses import dataclass, replace
from pathlib import Path

NO_EXT = "(無副檔名)"

UP, DOWN, LEFT, RIGHT, ENTER = "up", "down", "left", "right", "enter"
ARROW_KEYS = {"H": UP, "P": DOWN, "K": LEFT, "M": RIGHT}

HIGHLIGHT = "\x1b[7m"
RESET = "\x1b[0m"
HEADER_LINES = 4


def long_path(path: str) -> str:
    r"""Windows 未啟用 LongPathsEnabled 時，超過 MAX_PATH (260) 的路徑會失敗；
    轉成絕對路徑並加上 \\?\ 前綴改走延伸長度路徑。非 Windows 只回傳絕對路徑。"""
    path = os.path.abspath(path)
    if os.name != "nt" or path.startswith("\\\\?\\"):
        return path
    if path.startswith("\\\\"):  # UNC：\\server\share -> \\?\UNC\server\share
        return "\\\\?\\UNC\\" + path[2:]
    return "\\\\?\\" + path


def scan_exts(root: Path) -> dict[str, list[Path]]:
    """遞迴掃描 root，依小寫副檔名分組，路徑相對於 root"""
    top = long_path(str(root))
    groups: dict[str, list[Path]] = {}
    for dirpath, _, filenames in os.walk(top):
        rel_dir = Path(dirpath[len(top):].lstrip("\\/"))
        for name in filenames:
            ext = os.path.splitext(name)[1].lower() or NO_EXT
            groups.setdefault(ext, []).append(rel_dir / name)
    return groups


def sorted_exts(groups: dict[str, list[Path]]) -> list[str]:
    return sorted(groups, key=lambda ext: (-len(groups[ext]), ext))


@dataclass(frozen=True)
class Nav:
    exts: list[str]
    counts: dict[str, int]
    level: str = "exts"
    ext_idx: int = 0
    file_idx: int = 0


def handle_key(nav: Nav, key: str) -> Nav | None:
    """回傳按鍵後的新狀態，副檔名表中 Enter 回傳 None 表示結束"""
    if key == ENTER and nav.level == "exts":
        return None

    if nav.level == "exts":
        if key == RIGHT:
            return replace(nav, level="files", file_idx=0)
        return replace(nav, ext_idx=move(nav.ext_idx, key, len(nav.exts)))

    if key == LEFT:
        return replace(nav, level="exts")
    total = nav.counts[nav.exts[nav.ext_idx]]
    return replace(nav, file_idx=move(nav.file_idx, key, total))


def move(idx: int, key: str, total: int) -> int:
    step = {UP: -1, DOWN: 1}.get(key, 0)
    return max(0, min(idx + step, total - 1))


def window(idx: int, total: int, rows: int) -> int:
    """回傳可視範圍的起點，讓 idx 盡量置中"""
    return max(0, min(idx - rows // 2, total - rows))


def char_width(ch: str) -> int:
    return 2 if unicodedata.east_asian_width(ch) in "WF" else 1


def display_width(text: str) -> int:
    return sum(map(char_width, text))


def pad(text: str, width: int) -> str:
    return text + " " * (width - display_width(text))


def fit_width(text: str, width: int) -> str:
    """超出顯示寬度時保留尾端（檔名），前面以 … 取代"""
    if display_width(text) <= width:
        return text
    kept, used = [], 1
    for ch in reversed(text):
        used += char_width(ch)
        if used > width:
            break
        kept.append(ch)
    return "…" + "".join(reversed(kept))


def render_lines(lines: list[str], selected: int, cols: int, rows: int) -> list[str]:
    start = window(selected, len(lines), rows)
    out = []
    for i in range(start, min(start + rows, len(lines))):
        line = fit_width(lines[i], cols - 3)
        out.append(f"{HIGHLIGHT}> {line}{RESET}" if i == selected else f"  {line}")
    return out


def render(nav: Nav, groups: dict[str, list[Path]], root: Path) -> str:
    cols, lines = shutil.get_terminal_size()
    rows = max(1, lines - HEADER_LINES - 1)

    if nav.level == "exts":
        ext_width = max(display_width("副檔名"), *(display_width(ext) for ext in nav.exts))
        total = sum(nav.counts.values())
        header = [
            f"{root}  共 {total} 個檔案、{len(nav.exts)} 種副檔名",
            "↑↓ 選擇  → 列出檔案  Enter 結束",
            "",
            f"  {pad('副檔名', ext_width)}  {'數量':>6}",
        ]
        body = [f"{pad(ext, ext_width)}  {nav.counts[ext]:>8}" for ext in nav.exts]
        selected = nav.ext_idx
    else:
        ext = nav.exts[nav.ext_idx]
        header = [
            f"{ext}  共 {nav.counts[ext]} 個檔案（{nav.file_idx + 1}/{nav.counts[ext]}）",
            "↑↓ 選擇  ← 返回  Enter 開啟所在資料夾",
            "",
            "",
        ]
        body = [path.as_posix() for path in groups[ext]]
        selected = nav.file_idx

    return "\n".join(header + render_lines(body, selected, cols, rows))


def read_key() -> str | None:
    import msvcrt
    ch = msvcrt.getwch()
    if ch in ("\x00", "\xe0"):
        return ARROW_KEYS.get(msvcrt.getwch())
    if ch == "\r":
        return ENTER
    return None


def enable_ansi() -> None:
    """讓 conhost 支援 ANSI escape（Windows Terminal 預設已支援）"""
    if os.name != "nt":
        return
    import ctypes
    kernel32 = ctypes.windll.kernel32
    handle = kernel32.GetStdHandle(-11)
    mode = ctypes.c_uint()
    if not kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
        raise OSError("無法取得 console mode，請在 console 中執行")
    kernel32.SetConsoleMode(handle, mode.value | 0x0004)


def reveal(path: Path) -> None:
    """在檔案總管開啟檔案所在資料夾並選取該檔案"""
    subprocess.Popen(f'explorer /select,"{os.path.normpath(path)}"')


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="統計資料夾底下各副檔名的檔案數")
    parser.add_argument("root", nargs="?", default=".",
                        help="要掃描的資料夾，相對路徑以目前目錄為準（預設目前目錄）")
    return parser.parse_args(argv)


def main(argv: Sequence[str] = ()) -> None:
    root = Path(parse_args(argv).root).resolve()
    if not root.is_dir():
        raise FileNotFoundError(f"找不到資料夾: {root}")

    groups = scan_exts(root)
    if not groups:
        print(f"{root} 底下沒有檔案")
        return

    exts = sorted_exts(groups)
    nav: Nav | None = Nav(exts=exts, counts={ext: len(groups[ext]) for ext in exts})

    enable_ansi()
    while nav is not None:
        sys.stdout.write("\x1b[H\x1b[J" + render(nav, groups, root))
        sys.stdout.flush()
        key = read_key()
        if key == ENTER and nav.level == "files":
            reveal(root / groups[nav.exts[nav.ext_idx]][nav.file_idx])
        if key is not None:
            nav = handle_key(nav, key)
    print()


if __name__ == "__main__":
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    try:
        main(sys.argv[1:])
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
