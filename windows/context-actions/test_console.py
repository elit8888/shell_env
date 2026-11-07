"""Tests for console.py (CJK-capable font for the conhost window)."""
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

import console

HERE = Path(__file__).resolve().parent

PROBE = """
import ctypes, json, sys
import console
console.CJK_FONT = sys.argv[2]
try:
    console.use_cjk_font()
    error = ""
except OSError as e:
    error = str(e)
k = ctypes.WinDLL("kernel32", use_last_error=True)
info = console.CONSOLE_FONT_INFOEX()
info.cbSize = ctypes.sizeof(info)
assert k.GetCurrentConsoleFontEx(k.GetStdHandle(-11), False, ctypes.byref(info))
open(sys.argv[1], "w", encoding="utf-8").write(
    json.dumps({"face": info.FaceName, "height": info.dwFontSize.Y, "error": error}))
"""


def probe_new_console(tmp_path, font: str) -> dict:
    """Run use_cjk_font() with the given font in a fresh conhost window."""
    out = tmp_path / "font.json"
    env = {k: v for k, v in os.environ.items() if k != "WT_SESSION"}
    proc = subprocess.run([sys.executable, "-c", PROBE, str(out), font], cwd=HERE, env=env, timeout=30,
                          creationflags=subprocess.CREATE_NEW_CONSOLE)
    assert proc.returncode == 0
    return json.loads(out.read_text(encoding="utf-8"))


@pytest.mark.skipif(not console.font_installed(console.CJK_FONT),
                    reason=f"{console.CJK_FONT} is not installed (e.g. GitHub runner)")
def test_sets_cjk_font_in_new_console(tmp_path):
    got = probe_new_console(tmp_path, console.CJK_FONT)
    assert got["error"] == ""
    assert got["face"] == console.CJK_FONT
    assert got["height"] > 0


def test_missing_font_raises(tmp_path):
    # conhost reports success but silently keeps its old font; that must not pass unnoticed
    got = probe_new_console(tmp_path, "NoSuchFont Mono")
    assert "NoSuchFont Mono" in got["error"]
    assert "not installed" in got["error"]


def test_font_installed():
    assert console.font_installed("Consolas")
    assert not console.font_installed("NoSuchFont Mono")


def test_no_console_is_noop(monkeypatch):
    # pytest's stdout is a pipe here, not a console window
    monkeypatch.delenv("WT_SESSION", raising=False)
    console.use_cjk_font()


def test_skipped_in_windows_terminal(monkeypatch):
    monkeypatch.setenv("WT_SESSION", "x")
    monkeypatch.setattr(console, "stdout_console", lambda: (_ for _ in ()).throw(AssertionError("touched console")))
    console.use_cjk_font()
