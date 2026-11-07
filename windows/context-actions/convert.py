"""Batch / single-file converters: gif -> mp4/webm, png/webp/jpeg -> jpg, rpgmvp/png_ -> png."""
import os
import subprocess
from collections.abc import Callable

import fsops

Result = tuple[bool, str]  # (succeeded, message shown in the summary)

PNG_HEADER = bytes.fromhex("89504E470D0A1A0A0000000D49484452")
RPGMVP_HEADER_LEN = 32
GRAY_BG = "[0:v]split[fg][bg];[bg]lutrgb=r=32:g=32:b=32,format=rgb24[gray];[gray][fg]overlay=format=auto"


def ffmpeg(*args: str) -> Result:
    proc = subprocess.run(["ffmpeg", "-nostdin", *args], capture_output=True, text=True,
                          encoding="utf-8", errors="replace")
    return proc.returncode == 0, (proc.stdout + proc.stderr).strip()


def swap_ext(path: str, ext: str) -> str:
    return os.path.splitext(path)[0] + "." + ext


def gif2mp4(src: str) -> Result:
    return ffmpeg("-y", "-v", "warning", "-i", src, "-vf", "scale=ceil(iw/2)*2:ceil(ih/2)*2,fps=30",
                  "-c:v", "libx264", "-pix_fmt", "yuv420p", swap_ext(src, "mp4"))


def gif2webm(src: str) -> Result:
    return ffmpeg("-y", "-v", "warning", "-i", src, "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "32",
                  "-pix_fmt", "yuv420p", swap_ext(src, "webm"))


def is_animated_webp(path: str) -> bool:
    """RIFF....WEBPVP8X with the animation flag (0x02) set in the VP8X flags byte."""
    with open(fsops.long_path(path), "rb") as f:
        hdr = f.read(21)
    return len(hdr) == 21 and hdr[12:16] == b"VP8X" and bool(hdr[20] & 0x02)


def img2jpg(src: str) -> Result:
    """png / webp / jpeg -> jpg; transparent areas become dark gray (32,32,32).

    Animated webp and an existing target jpg are skipped and reported as failure
    so the original is kept.
    """
    out = swap_ext(src, "jpg")
    if is_animated_webp(src):
        return False, "skip animated"
    if os.path.exists(fsops.long_path(out)):
        return False, f"skip exists: {os.path.basename(out)}"
    return ffmpeg("-n", "-v", "error", "-i", src, "-filter_complex", GRAY_BG, "-frames:v", "1", out)


def rpgmvp2png(src: str, out: str | None = None) -> Result:
    """RPG Maker MV encrypted image: drop the 32-byte header and restore the PNG signature + IHDR."""
    out = fsops.long_path(out or swap_ext(src, "png"))
    with open(fsops.long_path(src), "rb") as f:
        f.seek(RPGMVP_HEADER_LEN)
        body = f.read()
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "wb") as f:
        f.write(PNG_HEADER + body)
    return True, ""


def rpgmvp_out(src: str, root: str) -> str:
    """Batch output for rpgmvp: <root>/png/<same relative path>.png"""
    root = fsops.long_path(root)
    return os.path.join(root, "png", swap_ext(os.path.relpath(fsops.long_path(src), root), "png"))


# name -> (converter, source extensions, batch output path or None for "next to the source")
CONVERTERS: dict[str, tuple[Callable[..., Result], list[str], Callable[[str, str], str] | None]] = {
    "gif2mp4": (gif2mp4, ["gif"], None),
    "gif2webm": (gif2webm, ["gif"], None),
    "img2jpg": (img2jpg, ["png", "webp", "jpeg"], None),
    "rpgmvp2png": (rpgmvp2png, ["rpgmvp", "png_"], rpgmvp_out),
}


def single(name: str, src: str) -> int:
    """Convert one file next to itself; the original is always kept."""
    converter, _, _ = CONVERTERS[name]
    ok, msg = converter(src)
    if msg:
        print(msg)
    return 0 if ok else 1


def batch(name: str, root: str = ".") -> int:
    """Convert every matching file under root; converter output is printed after the progress list."""
    converter, exts, out_path = CONVERTERS[name]
    files = fsops.find_files(root, exts)
    if not files:
        print(f"No {'/'.join('.' + e for e in exts)} files found.")
        return 1

    msgs = []
    for f in files:
        shown = fsops.rel(f, root)
        if out_path:
            print(f"{shown} -> {fsops.rel(out_path(f, root), root)}")
            ok, msg = converter(f, out_path(f, root))
        else:
            print(shown)
            ok, msg = converter(f)
        if ok and fsops.delete_original():
            os.remove(f)
        if msg:
            msgs.append(f"[{shown}]\n{msg}")

    if msgs:
        print()
        print("=== Warnings / errors ===")
        print("\n\n".join(msgs))
    return 0
