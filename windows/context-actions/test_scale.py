"""Tests for scale.py (scale image / scale all jpg)."""
import scale
from conftest import make_img, width


def make_tree(root):
    for name in ["a.jpg", "sub/b.jpg", "sub/deep/c.jpg", "by4/old.jpg"]:
        make_img(root / name, size=16)


def test_scale_one_writes_by_folder(tmp_path):
    src = make_img(tmp_path / "x.jpg", size=16)
    assert scale.scale_one("2", str(src))
    assert width(tmp_path / "by2" / "x.jpg") == 8


def test_scale_all_non_recursive(tmp_path, monkeypatch):
    make_tree(tmp_path)
    monkeypatch.chdir(tmp_path)
    assert scale.scale_all("2") == 0
    assert width(tmp_path / "by2" / "a.jpg") == 8
    assert not (tmp_path / "by2" / "sub").exists()


def test_scale_all_recursive_keeps_structure(tmp_path, monkeypatch):
    make_tree(tmp_path)
    monkeypatch.chdir(tmp_path)
    scale.scale_all("2", recursive=True)
    for name in ["a.jpg", "sub/b.jpg", "sub/deep/c.jpg"]:
        assert width(tmp_path / "by2" / name) == 8, name
    assert not (tmp_path / "sub" / "by2").exists()
    assert not (tmp_path / "by2" / "by4").exists()
    # rerun ignores its own output
    scale.scale_all("2", recursive=True)
    assert not (tmp_path / "by2" / "by2").exists()


def test_has_subdirs_ignores_scale_output(tmp_path):
    make_img(tmp_path / "a.jpg")
    make_img(tmp_path / "by2" / "x.jpg")
    assert not scale.has_subdirs(str(tmp_path))
    (tmp_path / "sub").mkdir()
    assert scale.has_subdirs(str(tmp_path))


def test_scale_all_empty(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert scale.scale_all("2") == 1
    assert "No .jpg files found." in capsys.readouterr().out
    assert not (tmp_path / "by2").exists()


def test_scale_all_in_long_named_folder(long_dir, monkeypatch):
    make_img(long_dir / "a.jpg", size=16)
    monkeypatch.chdir(long_dir.parent)
    scale.scale_all("2", recursive=True)
    assert width(long_dir.parent / "by2" / long_dir.name / "a.jpg") == 8


def test_scale_single_in_long_named_folder(long_dir):
    src = make_img(long_dir / "a.jpg", size=16)
    scale.scale_one("1.5", str(src))
    assert (long_dir / "by1.5" / "a.jpg").is_file()


def test_scale_failure_reported(tmp_path, monkeypatch, capsys):
    (tmp_path / "bad.jpg").write_text("not a jpg")
    monkeypatch.chdir(tmp_path)
    assert scale.scale_all("2") == 1
    assert "bad.jpg" in capsys.readouterr().out
