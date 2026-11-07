"""Shared pytest fixtures for the context-actions tests."""
import subprocess
from pathlib import Path

import pytest

# 284 bytes in UTF-8 (104 UTF-16 chars): over the 255-byte NAME_MAX that broke the
# old Git Bash scripts, but a valid NTFS name.
LONG_NAME = (
    "はねっかえり (リコシェット)｜オタクの僕にも中出しさせてくれる優しいヤリマンビッチギャル／第1話 "
    "[はねっかえり (リコシェット)] オタクの僕にも中出しさせてくれる優しいヤリマンビッチギャル [中国翻訳]"
)
assert len(LONG_NAME.encode("utf-8")) > 255


def make_img(path: Path, size: int = 8, color: str = "red") -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", f"color=c={color}:s={size}x{size}",
         "-frames:v", "1", str(path)],
        check=True,
    )
    return path


def make_anim_webp(path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "testsrc=size=16x16:rate=5:duration=1",
         "-c:v", "libwebp_anim", "-loop", "0", str(path)],
        check=True,
    )
    return path


def make_gif(path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "testsrc=size=15x15:rate=5:duration=1",
         str(path)],
        check=True,
    )
    return path


def width(path: Path) -> int:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width",
         "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True,
    )
    return int(out.stdout.strip())


def is_jpg(path: Path) -> bool:
    return path.is_file() and path.read_bytes()[:3] == b"\xff\xd8\xff"


@pytest.fixture
def long_dir(tmp_path: Path) -> Path:
    d = tmp_path / LONG_NAME
    d.mkdir()
    return d


@pytest.fixture(autouse=True)
def _delete_originals(monkeypatch):
    monkeypatch.setenv("ELIT_DELETE_ORIGINAL", "true")
