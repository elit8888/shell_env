"""Tests for fsops.py (shared path helpers)."""
import os

import fsops


def test_long_path_prefixes_absolute(tmp_path):
    p = fsops.long_path(str(tmp_path))
    assert p.startswith("\\\\?\\")
    assert p.endswith(os.path.abspath(str(tmp_path))[2:])
    assert fsops.long_path(p) == p


def test_long_path_unc():
    assert fsops.long_path(r"\\server\share\x") == r"\\?\UNC\server\share\x"


def test_find_files_case_insensitive_recursive_sorted(tmp_path):
    for name in ["b.png", "A.PNG", "sub/c.webp", "skip.gif"]:
        (tmp_path / name).parent.mkdir(parents=True, exist_ok=True)
        (tmp_path / name).write_text("")
    found = fsops.find_files(str(tmp_path), ["png", "webp"])
    assert [fsops.rel(f, str(tmp_path)) for f in found] == ["A.PNG", "b.png", "sub/c.webp"]
    assert all(f.startswith("\\\\?\\") for f in found)


def test_find_files_multi_dot_ext(tmp_path):
    (tmp_path / "v.7z.001").write_text("")
    (tmp_path / "v.7z.002").write_text("")
    found = fsops.find_files(str(tmp_path), ["7z.001"])
    assert [fsops.rel(f, str(tmp_path)) for f in found] == ["v.7z.001"]


def test_find_files_non_recursive_and_prune(tmp_path):
    for name in ["a.jpg", "sub/b.jpg", "by2/c.jpg", "sub/by1.5/d.jpg"]:
        (tmp_path / name).parent.mkdir(parents=True, exist_ok=True)
        (tmp_path / name).write_text("")
    top = fsops.find_files(str(tmp_path), ["jpg"], recursive=False)
    assert [fsops.rel(f, str(tmp_path)) for f in top] == ["a.jpg"]
    pruned = fsops.find_files(str(tmp_path), ["jpg"], prune=lambda name: name.startswith("by"))
    assert [fsops.rel(f, str(tmp_path)) for f in pruned] == ["a.jpg", "sub/b.jpg"]


def test_find_files_in_long_named_folder(long_dir):
    (long_dir / "x.png").write_text("")
    found = fsops.find_files(str(long_dir.parent), ["png"])
    assert len(found) == 1
    assert os.path.isfile(found[0])
    assert fsops.rel(found[0], str(long_dir.parent)) == f"{long_dir.name}/x.png"


def test_delete_original_env(monkeypatch):
    monkeypatch.setenv("ELIT_DELETE_ORIGINAL", "false")
    assert fsops.delete_original() is False
    monkeypatch.setenv("ELIT_DELETE_ORIGINAL", "true")
    assert fsops.delete_original() is True
    monkeypatch.delenv("ELIT_DELETE_ORIGINAL")
    assert fsops.delete_original() is True


def test_plain_path_round_trip(tmp_path):
    assert fsops.plain_path(fsops.long_path(str(tmp_path))) == str(tmp_path)
    assert fsops.plain_path("\\\\?\\UNC\\server\\share") == "\\\\server\\share"
    assert fsops.long_path(tmp_path) == fsops.long_path(str(tmp_path))


def test_reveal_runs_explorer_with_plain_path(tmp_path, monkeypatch):
    calls = []
    monkeypatch.setattr(fsops.subprocess, "Popen", calls.append)
    fsops.reveal(fsops.long_path(str(tmp_path / "a b.txt")))
    assert calls == [f'explorer /select,"{tmp_path / "a b.txt"}"']
