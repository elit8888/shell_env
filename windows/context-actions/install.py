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


def store_key(file_type: str) -> str:
    """HKCR-relative key holding the verbs for a file type.

    The verbs live outside the shell\\elit_actions key because SubCommands-style
    cascading menus are capped at 16 items by the shell; ExtendedSubCommandsKey
    has no such cap.
    """
    ident = file_type.replace(".", "").replace("\\", "_").lower()
    return f"elit_actions.{ident}"


def store_base(store: str) -> str:
    return rf"HKEY_CURRENT_USER\Software\Classes\{store}"


def is_single(file_type: str) -> bool:
    return file_type != "Directory\\Background"


def build_command(action: dict, mintty: str, bash_dir: str, single: bool) -> str:
    # Pass the path as bash's $1 rather than splicing it into the -c string,
    # so quotes or $ in the path are never parsed as shell syntax.
    arg = ' \\"$1\\"' if single else ""
    if "bash" in action:
        inner = f"D={bash_dir}; {action['bash']}{arg}"
    else:
        inner = f"{bash_dir}/{action['script']}{arg}"
    raw = f'"{mintty}" --exec "/usr/bin/bash" -lc "{inner}"'
    if single:
        raw += ' _ "%1"'
    return escape_reg(raw)


def emit_actions(lines: list, store: str, entries: list, mintty: str, bash_dir: str, single: bool) -> None:
    base = store_base(store)
    for action in entries:
        action_id = make_id(action["label"])
        node = f"{base}\\shell\\{action_id}"
        if "children" in action:
            # Nested store lives under the parent store so one delete cleans it up.
            sub = f"{store}\\sub\\{action_id}"
            lines += [
                f"[{node}]",
                f'"MUIVerb"="{escape_reg(action["label"])}"',
                f'"ExtendedSubCommandsKey"="{escape_reg(sub)}"',
                "",
            ]
            emit_actions(lines, sub, action["children"], mintty, bash_dir, single)
        else:
            cmd = build_command(action, mintty, bash_dir, single)
            lines += [
                f"[{node}]",
                f'"MUIVerb"="{escape_reg(action["label"])}"',
                f"[{node}\\command]",
                f'@="{cmd}"',
                "",
            ]


# The shell renders at most this many commands per cascading menu; the rest are
# silently dropped (they sort last, so the tail of the menu just disappears).
MENU_ITEM_LIMIT = 16


def count_leaves(entries: list) -> int:
    return sum(
        count_leaves(a["children"]) if "children" in a else 1
        for a in entries
    )


def check_limits(data: dict) -> None:
    for file_type, entries in data["file_types"].items():
        n = count_leaves(entries)
        if n > MENU_ITEM_LIMIT:
            raise SystemExit(
                f"ERROR: {file_type} has {n} commands, over the shell's "
                f"{MENU_ITEM_LIMIT}-item cascading menu limit. "
                f"The last {n - MENU_ITEM_LIMIT} would never show up. "
                f"Trim actions.json."
            )
        print(f"{file_type}: {n}/{MENU_ITEM_LIMIT} commands")


def generate_reg(mintty: str, bash_dir: str, data: dict) -> str:
    lines = ["Windows Registry Editor Version 5.00", ""]

    # Wipe first: reg import merges, so stale values (e.g. SubCommands) would survive.
    lines += ["; === clean up previous install ==="]
    for file_type in data["file_types"]:
        lines.append(f"[-{reg_base(file_type)}]")
        lines.append(f"[-{store_base(store_key(file_type))}]")
    lines.append("")

    for file_type, entries in data["file_types"].items():
        store = store_key(file_type)
        lines += [
            f"; === {file_type} ===",
            f"[{reg_base(file_type)}]",
            '"MUIVerb"="elit_actions"',
            f'"ExtendedSubCommandsKey"="{escape_reg(store)}"',
            "",
        ]

        emit_actions(lines, store, entries, mintty, bash_dir, is_single(file_type))

    return "\r\n".join(lines)


def generate_uninstall_reg(data: dict) -> str:
    lines = ["Windows Registry Editor Version 5.00", ""]
    for file_type in data["file_types"]:
        lines += [
            f"; === {file_type} ===",
            f"[-{reg_base(file_type)}]",
            f"[-{store_base(store_key(file_type))}]",
            "",
        ]
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

    check_limits(data)
    print()

    reg_content = generate_reg(mintty, bash_dir, data)

    # Keep the uninstall file in sync with whatever we just registered.
    with open(os.path.join(script_dir, "actions_uninstall.reg"), "w", encoding="ascii", newline="") as f:
        f.write(generate_uninstall_reg(data))

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
