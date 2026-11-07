"""Tests for console.py (CJK-capable font for the conhost window)."""
import json
import os
import subprocess
import sys
from pathlib import Path

import console

HERE = Path(__file__).resolve().parent

PROBE = """
import ctypes, json, sys
import console
console.use_cjk_font()
k = ctypes.WinDLL("kernel32", use_last_error=True)
info = console.CONSOLE_FONT_INFOEX()
info.cbSize = ctypes.sizeof(info)
assert k.GetCurrentConsoleFontEx(k.GetStdHandle(-11), False, ctypes.byref(info))
open(sys.argv[1], "w", encoding="utf-8").write(json.dumps({"face": info.FaceName, "height": info.dwFontSize.Y}))
"""


def test_sets_cjk_font_in_new_console(tmp_path):
    out = tmp_path / "font.json"
    env = {k: v for k, v in os.environ.items() if k != "WT_SESSION"}
    proc = subprocess.run([sys.executable, "-c", PROBE, str(out)], cwd=HERE, env=env, timeout=30,
                          creationflags=subprocess.CREATE_NEW_CONSOLE)
    assert proc.returncode == 0
    got = json.loads(out.read_text(encoding="utf-8"))
    assert got["face"] == console.CJK_FONT
    assert got["height"] > 0


def test_no_console_is_noop(monkeypatch):
    # pytest's stdout is a pipe here, not a console window
    monkeypatch.delenv("WT_SESSION", raising=False)
    console.use_cjk_font()


def test_skipped_in_windows_terminal(monkeypatch):
    monkeypatch.setenv("WT_SESSION", "x")
    monkeypatch.setattr(console, "stdout_console", lambda: (_ for _ in ()).throw(AssertionError("touched console")))
    console.use_cjk_font()
