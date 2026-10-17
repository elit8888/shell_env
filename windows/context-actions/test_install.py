"""Tests for install.py command generation.

The end-to-end tests run the generated registry command line through the real
Git-for-Windows bash (swapped in for mintty), so they exercise the same Windows
command-line parsing Explorer triggers.
"""
import os
import subprocess

import pytest

import install

PATHS = [
    r"D:\plain\dir",
    r"D:\with space\dir",
    r"D:\SteamLibrary\Marie's Adventure\pictures - Copy",
    r"D:\a $HOME `x` & (b)\c",
]


def unescape_reg(s: str) -> str:
    return s.replace('\\"', '"').replace("\\\\", "\\")


@pytest.fixture(scope="module")
def bash_exe() -> str:
    exe = os.path.join(os.path.dirname(install.find_mintty()), "bash.exe")
    assert os.path.isfile(exe), exe
    return exe


def run_as_explorer(cmd: str, mintty: str, bash_exe: str, target: str) -> None:
    """Expand %1 like Explorer does and run with bash in place of mintty."""
    prefix = f'"{mintty}" --exec "/usr/bin/bash"'
    raw = unescape_reg(cmd)
    assert raw.startswith(prefix)
    cmdline = f'"{bash_exe}"' + raw[len(prefix):].replace("%1", target)
    subprocess.run(cmdline, check=True, timeout=30)


@pytest.mark.parametrize("target", PATHS)
def test_script_action_receives_path_verbatim(tmp_path, bash_exe, target):
    out = tmp_path / "out.txt"
    (tmp_path / "echo.sh").write_text(f'printf %s "$1" > {install.to_bash_path(str(out))}\n')
    mintty = install.find_mintty()
    cmd = install.build_command({"script": "echo.sh"}, mintty, install.to_bash_path(str(tmp_path)), single=True)
    run_as_explorer(cmd, mintty, bash_exe, target)
    assert out.read_text() == target


@pytest.mark.parametrize("target", PATHS)
def test_bash_action_receives_path_verbatim(tmp_path, bash_exe, target):
    out = tmp_path / "out.txt"
    (tmp_path / "utils.sh").write_text(f'show() {{ printf %s "$1" > {install.to_bash_path(str(out))}; }}\n')
    mintty = install.find_mintty()
    action = {"bash": "source $D/utils.sh; show"}
    cmd = install.build_command(action, mintty, install.to_bash_path(str(tmp_path)), single=True)
    run_as_explorer(cmd, mintty, bash_exe, target)
    assert out.read_text() == target


def test_background_command_has_no_path_arg():
    cmd = unescape_reg(install.build_command({"script": "x.sh"}, "C:\\m.exe", "/d/s", single=False))
    assert "%1" not in cmd
    assert cmd == '"C:\\m.exe" --exec "/usr/bin/bash" -lc "/d/s/x.sh"'
