#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"  # zipfile metadata_encoding (unzip_jp.py)
# ///
"""Entry point of every Windows context-menu action (registered by install.py).

Explorer starts `uv run --script elit.py <command> [args] ["%1"]` directly in a
console window, with the clicked folder as the working directory. Everything is
native Windows Python, so folder names past Git Bash's 255-byte limit work.

Usage: elit.py <command> [args]  (see --help)
"""
import argparse
import os
import subprocess
import sys
import traceback
from collections.abc import Sequence

import archive
import console
import convert
import ext_stats
import fsops
import organize
import scale

PAUSE_PROMPT = "Press Enter to close..."
EXTERNAL = {
    "rpgmv-trans": lambda cwd: ["bun", "D:/Documents/unreal/tools/rpgmv-trans/src/cli.ts", "run", cwd],
    "rpgview-render": lambda cwd: ["uv", "run", "--project", "D:/Projects/rpg-view", "python",
                                   "D:/Projects/rpg-view/render_interactive.py", cwd],
}


def external_command(name: str) -> list[str]:
    return EXTERNAL[name](os.getcwd())


def cmd_convert(args) -> int:
    """No path or a folder (Directory verb): batch under it; a file: just that file."""
    if args.file and not os.path.isdir(fsops.long_path(args.file)):
        print(f"Converting single - {args.file}")
        return convert.single(args.name, args.file)
    print("Converting all")
    return convert.batch(args.name, args.file or ".")


def cmd_scale(args) -> int:
    fac = args.factor
    if fac == "more":
        fac = input("Enter scale factor (e.g. 2.5): ").strip()
    if not fac:
        print("No scale factor given.")
        return 1
    if args.file:
        print(f"Scaling single by {fac} - {args.file}")
        return 0 if scale.scale_one(fac, args.file) else 1
    recursive = scale.has_subdirs() and input("Include subfolders? [y/N]: ").strip().lower().startswith("y")
    print(f"Scaling all by {fac} (recursive: {recursive})")
    return scale.scale_all(fac, recursive)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="elit.py", description="Windows context-menu actions")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("convert", help="convert one file, or every matching file under the current folder")
    p.add_argument("name", choices=sorted(convert.CONVERTERS))
    p.add_argument("file", nargs="?")
    p.set_defaults(run=cmd_convert)

    p = sub.add_parser("scale", help="downscale jpg into by<factor>/")
    p.add_argument("factor", help="e.g. 2, 1.5, or 'more' to ask")
    p.add_argument("file", nargs="?")
    p.set_defaults(run=cmd_scale)

    p = sub.add_parser("unzip-all", help="extract every zip/rar/7z recursively")
    p.set_defaults(run=lambda a: archive.unzip_all_recursive())

    p = sub.add_parser("unzip-7z", help="extract one .7z / .7z.001")
    p.add_argument("file")
    p.set_defaults(run=lambda a: archive.unzip_7z(a.file))

    p = sub.add_parser("unzip-jp", help="extract one zip with Japanese filenames")
    p.add_argument("file")
    p.set_defaults(run=lambda a: archive.unzip_jp(a.file))

    for name, renumber in (("mv-up", False), ("mv-up-renum", True)):
        p = sub.add_parser(name, help="move a subfolder's files one folder up"
                           + (", renumbered" if renumber else ""))
        p.add_argument("dir", nargs="?")
        p.set_defaults(run=lambda a, r=renumber: organize.mv_files_one_folder_up(
            [a.dir] if a.dir else None, renumber=r))

    p = sub.add_parser("move-videos", help="move videos into a video/ subfolder")
    p.set_defaults(run=lambda a: organize.move_videos_to_subfolder())

    p = sub.add_parser("rename-large", help="x.jpg_large -> x.jpg")
    p.add_argument("dir", nargs="?", default=".")
    p.set_defaults(run=lambda a: organize.rename_large_ext(a.dir))

    p = sub.add_parser("rename-special", help="replace special characters in names with -")
    p.set_defaults(run=lambda a: organize.rename_special_chars())

    for name in EXTERNAL:
        p = sub.add_parser(name, help=f"run {name} on the current folder")
        p.set_defaults(run=lambda a, n=name: subprocess.run(external_command(n)).returncode)

    p = sub.add_parser("ext-stats", help="browse file counts by extension")
    p.add_argument("dir", nargs="?", default=".")
    p.set_defaults(run=lambda a: ext_stats.main([a.dir]) or 0, interactive=True)

    return parser


def main(argv: Sequence[str]) -> int:
    args = build_parser().parse_args(argv)
    try:
        rc = args.run(args)
    except Exception:
        traceback.print_exc()
        rc = 1
    # ext-stats is a full-screen browser that the user leaves on purpose: pause only on error
    if rc != 0 or not getattr(args, "interactive", False):
        print()
        input(PAUSE_PROMPT)
    return rc


if __name__ == "__main__":
    # line_buffering keeps our lines in order with the output of ffmpeg / 7z / unzip_jp.py
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8", line_buffering=True)
    console.use_cjk_font()
    raise SystemExit(main(sys.argv[1:]))
