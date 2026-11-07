"""Tests for elit.py (context-menu entry point)."""
import os
import subprocess
import sys
from pathlib import Path

import pytest

import elit
import ext_stats
from conftest import is_jpg, make_img, width

HERE = Path(__file__).resolve().parent


@pytest.fixture
def answers(monkeypatch):
    """Feed input() answers; records the prompts shown."""
    prompts = []

    def feed(*values):
        it = iter(values)

        def fake_input(prompt=""):
            prompts.append(prompt)
            return next(it)
        monkeypatch.setattr("builtins.input", fake_input)
        return prompts
    return feed


def test_convert_batch_then_pause(tmp_path, monkeypatch, answers, capsys):
    make_img(tmp_path / "a.png")
    monkeypatch.chdir(tmp_path)
    prompts = answers("")
    assert elit.main(["convert", "img2jpg"]) == 0
    assert is_jpg(tmp_path / "a.jpg")
    assert prompts == ["Press Enter to close..."]
    assert "Converting all" in capsys.readouterr().out


def test_convert_single(tmp_path, answers, capsys):
    src = make_img(tmp_path / "a.webp")
    answers("")
    assert elit.main(["convert", "img2jpg", str(src)]) == 0
    assert is_jpg(tmp_path / "a.jpg")
    assert src.exists()
    assert f"Converting single - {src}" in capsys.readouterr().out


def test_convert_folder_argument_runs_batch_there(long_dir, answers, capsys):
    (long_dir / "a.rpgmvp").write_bytes(b"\0" * 32 + b"BODY")
    answers("")
    assert elit.main(["convert", "rpgmvp2png", str(long_dir)]) == 0
    assert (long_dir / "png" / "a.png").is_file()
    assert "Converting all" in capsys.readouterr().out


def test_scale_more_prompts_factor_and_subfolders(tmp_path, monkeypatch, answers, capsys):
    make_img(tmp_path / "a.jpg", size=16)
    make_img(tmp_path / "sub" / "b.jpg", size=16)
    monkeypatch.chdir(tmp_path)
    prompts = answers("4", "y", "")
    elit.main(["scale", "more"])
    assert prompts == ["Enter scale factor (e.g. 2.5): ", "Include subfolders? [y/N]: ", "Press Enter to close..."]
    assert width(tmp_path / "by4" / "sub" / "b.jpg") == 4
    assert "Scaling all by 4 (recursive: True)" in capsys.readouterr().out


def test_scale_default_not_recursive(tmp_path, monkeypatch, answers):
    make_img(tmp_path / "a.jpg", size=16)
    make_img(tmp_path / "sub" / "b.jpg", size=16)
    monkeypatch.chdir(tmp_path)
    answers("", "")
    elit.main(["scale", "2"])
    assert (tmp_path / "by2" / "a.jpg").is_file()
    assert not (tmp_path / "by2" / "sub").exists()


def test_scale_no_subdirs_no_prompt(tmp_path, monkeypatch, answers):
    make_img(tmp_path / "a.jpg", size=16)
    monkeypatch.chdir(tmp_path)
    prompts = answers("")
    elit.main(["scale", "2"])
    assert prompts == ["Press Enter to close..."]


def test_scale_single(tmp_path, answers, capsys):
    src = make_img(tmp_path / "a.jpg", size=16)
    answers("")
    elit.main(["scale", "2", str(src)])
    assert width(tmp_path / "by2" / "a.jpg") == 8
    assert "Scaling single by 2" in capsys.readouterr().out


def test_scale_empty_factor(tmp_path, monkeypatch, answers, capsys):
    monkeypatch.chdir(tmp_path)
    answers("", "")
    assert elit.main(["scale", "more"]) == 1
    assert "No scale factor given." in capsys.readouterr().out


def test_error_prints_traceback_and_pauses(tmp_path, answers, capsys):
    (tmp_path / "a" ).mkdir()
    (tmp_path / "a" / "1.jpg").write_text("x")
    (tmp_path / "a-1.jpg").write_text("x")
    prompts = answers("")
    assert elit.main(["mv-up", str(tmp_path / "a")]) == 1
    assert "FileExistsError" in capsys.readouterr().err
    assert prompts == ["Press Enter to close..."]


@pytest.mark.parametrize("argv,func", [
    (["unzip-all"], "archive.unzip_all_recursive"),
    (["unzip-7z", "x.7z"], "archive.unzip_7z"),
    (["unzip-jp", "x.zip"], "archive.unzip_jp"),
    (["mv-up"], "organize.mv_files_one_folder_up"),
    (["mv-up-renum", "d"], "organize.mv_files_one_folder_up"),
    (["move-videos"], "organize.move_videos_to_subfolder"),
    (["rename-large", "d"], "organize.rename_large_ext"),
    (["rename-special"], "organize.rename_special_chars"),
])
def test_dispatch(monkeypatch, answers, argv, func):
    calls = []
    module, name = func.split(".")
    monkeypatch.setattr(f"{module}.{name}", lambda *a, **k: calls.append((a, k)) or 0)
    answers("")
    assert elit.main(argv) == 0
    assert len(calls) == 1


def test_mv_up_renum_args(monkeypatch, answers):
    calls = []
    monkeypatch.setattr("organize.mv_files_one_folder_up", lambda *a, **k: calls.append((a, k)) or 0)
    answers("", "")
    elit.main(["mv-up-renum", "d"])
    elit.main(["mv-up"])
    assert calls == [((["d"],), {"renumber": True}), ((None,), {"renumber": False})]


def test_external_commands_use_cwd(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    trans = elit.external_command("rpgmv-trans")
    assert trans[:2] == ["bun", "D:/Documents/unreal/tools/rpgmv-trans/src/cli.ts"]
    assert trans[-2:] == ["run", str(tmp_path)]
    render = elit.external_command("rpgview-render")
    assert render[0] == "uv" and render[-1] == str(tmp_path)


def test_external_run(tmp_path, monkeypatch, answers):
    monkeypatch.chdir(tmp_path)
    seen = []
    monkeypatch.setattr(elit, "external_command", lambda name: seen.append(name) or [sys.executable, "-c", "raise SystemExit(3)"])
    answers("")
    assert elit.main(["rpgmv-trans"]) == 3
    assert seen == ["rpgmv-trans"]


def test_ext_stats_no_pause_on_success(tmp_path, monkeypatch, answers):
    seen = []
    monkeypatch.setattr(ext_stats, "main", lambda argv: seen.append(list(argv)))
    prompts = answers()
    assert elit.main(["ext-stats", str(tmp_path)]) == 0
    assert seen == [[str(tmp_path)]]
    assert prompts == []


def test_cli_runs_as_script_in_long_named_folder(long_dir):
    """Run elit.py the way Explorer does: a native process whose cwd is the long-named folder."""
    make_img(long_dir / "a.png")
    proc = subprocess.run([sys.executable, str(HERE / "elit.py"), "convert", "img2jpg"],
                          cwd=long_dir, input="\n", capture_output=True, text=True, encoding="utf-8",
                          env={**os.environ, "ELIT_DELETE_ORIGINAL": "true"}, timeout=60)
    assert proc.returncode == 0, proc.stderr
    assert is_jpg(long_dir / "a.jpg")
    assert "a.png" in proc.stdout
