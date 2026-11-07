"""Tests for install.py command generation.

The end-to-end tests expand %1 like Explorer and run the generated registry
command line through CreateProcess with the real uv, so they exercise the same
Windows command-line parsing Explorer triggers.
"""
import json
import subprocess
from pathlib import Path

import pytest

import elit
import install
from conftest import LONG_NAME

HERE = Path(__file__).resolve().parent

PATHS = [
    r"D:\plain\dir",
    r"D:\with space\dir",
    r"D:\SteamLibrary\Marie's Adventure\pictures - Copy",
    r"D:\a $HOME `x` & (b)\c",
    "D:\\" + LONG_NAME + "\\a.png",
]

ECHO_SCRIPT = """\
import json, os, sys
with open(os.environ["ELIT_TEST_OUT"], "w", encoding="utf-8") as f:
    json.dump({"argv": sys.argv[1:], "cwd": os.getcwd()}, f)
"""


def unescape_reg(s: str) -> str:
    return s.replace('\\"', '"').replace("\\\\", "\\")


@pytest.fixture(scope="module")
def uv() -> str:
    return install.find_uv()


def run_as_explorer(tmp_path, monkeypatch, cmd: str, target: str | None, cwd: Path) -> dict:
    (tmp_path / "elit.py").write_text(ECHO_SCRIPT, encoding="utf-8")
    out = tmp_path / "out.json"
    monkeypatch.setenv("ELIT_TEST_OUT", str(out))
    cmdline = unescape_reg(cmd)
    if target is not None:
        cmdline = cmdline.replace("%1", target)
    subprocess.run(cmdline, cwd=cwd, check=True, timeout=60)
    return json.loads(out.read_text(encoding="utf-8"))


@pytest.mark.parametrize("target", PATHS)
def test_single_action_receives_path_verbatim(tmp_path, monkeypatch, uv, target):
    cmd = install.build_command({"args": ["convert", "img2jpg"]}, uv, str(tmp_path), single=True)
    got = run_as_explorer(tmp_path, monkeypatch, cmd, target, tmp_path)
    assert got["argv"] == ["convert", "img2jpg", target]


def test_background_runs_in_long_named_cwd(tmp_path, monkeypatch, uv):
    cwd = tmp_path / LONG_NAME
    cwd.mkdir()
    cmd = install.build_command({"args": ["scale", "1.5"]}, uv, str(tmp_path), single=False)
    got = run_as_explorer(tmp_path, monkeypatch, cmd, None, cwd)
    assert got["argv"] == ["scale", "1.5"]
    assert got["cwd"] == str(cwd)


def test_background_command_has_no_path_arg():
    cmd = unescape_reg(install.build_command({"args": ["unzip-all"]}, r"C:\u v\uv.exe", r"D:\s", single=False))
    assert cmd == r'"C:\u v\uv.exe" run --script "D:\s\elit.py" unzip-all'


def test_single_command_format():
    cmd = unescape_reg(install.build_command({"args": ["scale", "1.5"]}, r"C:\uv.exe", r"D:\s", single=True))
    assert cmd == r'"C:\uv.exe" run --script "D:\s\elit.py" scale 1.5 "%1"'


def iter_leaves(entries):
    for a in entries:
        if "children" in a:
            yield from iter_leaves(a["children"])
        else:
            yield a


def test_actions_json_args_parse():
    data = json.loads((HERE / "actions.json").read_text(encoding="utf-8"))
    parser = elit.build_parser()
    for file_type, entries in data["file_types"].items():
        for action in iter_leaves(entries):
            argv = list(action["args"])
            if install.is_single(file_type):
                argv.append("X:\\target")
            parser.parse_args(argv)  # SystemExit on an unknown command


def test_check_limits_rejects_over_16(capsys):
    install.check_limits({"file_types": {".x": [{"args": ["unzip-all"]}] * 16}})
    with pytest.raises(SystemExit):
        install.check_limits({"file_types": {".x": [{"args": ["unzip-all"]}] * 17}})


def test_generate_reg_wipes_then_registers(tmp_path):
    data = {"file_types": {
        ".png": [{"label": "convert to jpg", "args": ["convert", "img2jpg"]}],
        "Directory\\Background": [{"label": "scale all jpg", "children": [
            {"label": "by 2", "args": ["scale", "2"]}]}],
    }}
    reg = install.generate_reg(r"C:\uv.exe", r"D:\s", data)
    assert reg.index("[-HKEY_CURRENT_USER\\Software\\Classes\\SystemFileAssociations\\.png\\shell\\elit_actions]") \
        < reg.index("[HKEY_CURRENT_USER\\Software\\Classes\\SystemFileAssociations\\.png\\shell\\elit_actions]")
    assert "elit_actions.directory_background\\\\sub\\\\scale_all_jpg" in reg
    assert '\\"%1\\"' in reg
    assert reg.count('\\"%1\\"') == 1
    uninstall = install.generate_uninstall_reg(data)
    assert "[-HKEY_CURRENT_USER\\Software\\Classes\\Directory\\Background\\shell\\elit_actions]" in uninstall


def test_find_uv_missing(monkeypatch):
    monkeypatch.setattr(install, "which", lambda _name: None)
    with pytest.raises(RuntimeError):
        install.find_uv()
