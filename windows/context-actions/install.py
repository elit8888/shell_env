#!/usr/bin/env python3
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from shutil import which


def find_mintty() -> str:
    m = which("mintty")
    if m:
        return m

    git = which("git")
    if git:
        for levels_up in (1, 2):
            root = git
            for _ in range(levels_up):
                root = os.path.dirname(root)
            c = os.path.join(root, "usr", "bin", "mintty.exe")
            if os.path.isfile(c):
                return c

    for loc in [
        os.path.join(os.environ.get("ProgramFiles", ""), "Git", "usr", "bin", "mintty.exe"),
        os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs", "Git", "usr", "bin", "mintty.exe"),
        os.path.join(os.environ.get("USERPROFILE", ""), "scoop", "apps", "git", "current", "usr", "bin", "mintty.exe"),
    ]:
        if os.path.isfile(loc):
            return loc

    raise RuntimeError("Cannot find mintty.exe. Ensure Git for Windows is installed and 'git' is in PATH.")


def to_bash_path(path: str) -> str:
    m = re.match(r"^([A-Za-z]):\\?(.*)$", path)
    if m:
        return "/" + m.group(1).lower() + "/" + m.group(2).replace("\\", "/")
    return path.replace("\\", "/")


def escape_reg(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def make_id(label: str) -> str:
    s = label.lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")


def reg_base(file_type: str) -> str:
    if file_type.startswith("."):
        return rf"HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\{file_type}\shell\elit_actions"
    if file_type == "Directory":
        return r"HKEY_CURRENT_USER\Software\Classes\Directory\shell\elit_actions"
    if file_type == "Directory\\Background":
        return r"HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions"
    raise ValueError(f"Unknown file_type: {file_type!r}")


def is_single(file_type: str) -> bool:
    return file_type != "Directory\\Background"


def build_command(action: dict, mintty: str, bash_dir: str, single: bool) -> str:
    arg = " '%1'" if single else ""
    if "bash" in action:
        inner = f"D={bash_dir}; {action['bash']}{arg}"
    else:
        inner = f"{bash_dir}/{action['script']}{arg}"
    raw = f'"{mintty}" --exec "/usr/bin/bash" -lc "{inner}"'
    return escape_reg(raw)


def emit_actions(lines: list, base: str, entries: list, mintty: str, bash_dir: str, single: bool) -> None:
    for action in entries:
        node = f"{base}\\shell\\{make_id(action['label'])}"
        if "children" in action:
            lines += [
                f"[{node}]",
                f'"MUIVerb"="{escape_reg(action["label"])}"',
                '"SubCommands"=""',
                "",
            ]
            emit_actions(lines, node, action["children"], mintty, bash_dir, single)
        else:
            cmd = build_command(action, mintty, bash_dir, single)
            lines += [
                f"[{node}]",
                f'@="{escape_reg(action["label"])}"',
                f"[{node}\\command]",
                f'@="{cmd}"',
                "",
            ]


def generate_reg(mintty: str, bash_dir: str, data: dict) -> str:
    lines = ["Windows Registry Editor Version 5.00", ""]

    for file_type, entries in data["file_types"].items():
        base = reg_base(file_type)
        single = is_single(file_type)

        lines += [
            f"; === {file_type} ===",
            f"[{base}]",
            '"MUIVerb"="elit_actions"',
            '"SubCommands"=""',
            "",
        ]

        emit_actions(lines, base, entries, mintty, bash_dir, single)

    return "\r\n".join(lines)


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    mintty = find_mintty()
    bash_dir = to_bash_path(script_dir)

    print(f"mintty : {mintty}")
    print(f"scripts: {bash_dir}")
    print()

    with open(os.path.join(script_dir, "actions.json"), encoding="utf-8") as f:
        data = json.load(f)

    reg_content = generate_reg(mintty, bash_dir, data)

    fd, tmp = tempfile.mkstemp(suffix=".reg")
    try:
        with os.fdopen(fd, "w", encoding="utf-16") as f:
            f.write(reg_content)
        print("Importing registry entries...")
        subprocess.run(["reg", "import", tmp], check=True)
    finally:
        Path(tmp).unlink(missing_ok=True)

    print("Done! Context menu entries registered.")


if __name__ == "__main__":
    main()
