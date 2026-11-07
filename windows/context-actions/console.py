"""Console window setup for the context-menu actions.

Explorer opens the actions in a classic conhost window, whose default font has no
Japanese / Chinese glyphs and which does no font fallback, so CJK file names show
up as boxes. Switching the window to a monospace font that covers kana plus
simplified and traditional Han fixes that. Windows Terminal falls back on its own.
"""
import ctypes
import os
import re
from ctypes import wintypes

# Monospace, covers kana, traditional and simplified Han and full-width forms in conhost
# (NSimSun and MS Gothic also do; BIZ UDGothic / Yu Gothic / VL Gothic miss simplified Han)
CJK_FONT = "MingLiU"
STD_OUTPUT_HANDLE = -11


class CONSOLE_FONT_INFOEX(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.ULONG),
        ("nFont", wintypes.DWORD),
        ("dwFontSize", wintypes._COORD),
        ("FontFamily", wintypes.UINT),
        ("FontWeight", wintypes.UINT),
        ("FaceName", wintypes.WCHAR * 32),
    ]


def kernel32() -> ctypes.WinDLL:
    return ctypes.WinDLL("kernel32", use_last_error=True)


def stdout_console() -> int | None:
    """Handle of the console window behind stdout, or None when stdout is a pipe / file."""
    k = kernel32()
    handle = k.GetStdHandle(STD_OUTPUT_HANDLE)
    mode = wintypes.DWORD()
    return handle if k.GetConsoleMode(handle, ctypes.byref(mode)) else None


def font_installed(face: str) -> bool:
    """Whether a font family is registered, e.g. "MingLiU" from "MingLiU & PMingLiU & ... (TrueType)"."""
    import winreg
    key_path = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    for hive in (winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER):
        try:
            key = winreg.OpenKey(hive, key_path)
        except FileNotFoundError:
            continue
        with key:
            for i in range(winreg.QueryInfoKey(key)[1]):
                entry = re.sub(r"\s*\([^)]*\)$", "", winreg.EnumValue(key, i)[0])
                if face.lower() in (name.strip().lower() for name in entry.split("&")):
                    return True
    return False


def current_font(k: ctypes.WinDLL, handle: int) -> CONSOLE_FONT_INFOEX:
    info = CONSOLE_FONT_INFOEX()
    info.cbSize = ctypes.sizeof(info)
    if not k.GetCurrentConsoleFontEx(handle, False, ctypes.byref(info)):
        raise ctypes.WinError(ctypes.get_last_error())
    return info


def use_cjk_font() -> None:
    if os.name != "nt" or "WT_SESSION" in os.environ:
        return
    handle = stdout_console()
    if handle is None:
        return
    k = kernel32()
    info = current_font(k, handle)
    info.nFont = 0
    info.dwFontSize.X = 0  # let the font pick its width for the current height
    info.FontWeight = 400
    info.FaceName = CJK_FONT
    if not k.SetCurrentConsoleFontEx(handle, False, ctypes.byref(info)):
        raise ctypes.WinError(ctypes.get_last_error())
    # A missing font is not an error to conhost: it reports success and keeps the old font
    applied = current_font(k, handle).FaceName
    if applied != CJK_FONT:
        state = "is installed" if font_installed(CJK_FONT) else "is not installed"
        raise OSError(f"console font {CJK_FONT!r} not applied (still {applied!r}); the font {state}")
