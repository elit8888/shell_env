"""Tests for organize.py (move files up, move videos, rename)."""
import pytest

import organize


def touch(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("x")
    return path


def listing(d):
    return sorted(p.name for p in d.iterdir())


# --- move files one folder up ---

def test_mv_up_prefixes_names(tmp_path, monkeypatch):
    touch(tmp_path / "a" / "1.jpg")
    touch(tmp_path / "a" / "sub" / "x.txt")
    touch(tmp_path / "b" / "2.jpg")
    monkeypatch.chdir(tmp_path)
    assert organize.mv_files_one_folder_up() == 0
    assert listing(tmp_path) == ["a-1.jpg", "a-sub", "b-2.jpg"]
    assert (tmp_path / "a-sub" / "x.txt").is_file()


def test_mv_up_explicit_dir(tmp_path):
    touch(tmp_path / "a" / "1.jpg")
    touch(tmp_path / "keep" / "k.txt")
    organize.mv_files_one_folder_up([str(tmp_path / "a")])
    assert listing(tmp_path) == ["a-1.jpg", "keep"]


def test_mv_up_not_a_directory(tmp_path, capsys):
    f = touch(tmp_path / "f.txt")
    assert organize.mv_files_one_folder_up([str(f)]) == 1
    assert "Not a directory" in capsys.readouterr().out


def test_mv_up_existing_target_raises(tmp_path):
    touch(tmp_path / "a" / "1.jpg")
    touch(tmp_path / "a-1.jpg")
    with pytest.raises(FileExistsError):
        organize.mv_files_one_folder_up([str(tmp_path / "a")])
    assert (tmp_path / "a" / "1.jpg").exists()


def test_mv_up_long_named_folder(long_dir):
    touch(long_dir / "1.jpg")
    organize.mv_files_one_folder_up([str(long_dir)])
    assert listing(long_dir.parent) == [f"{long_dir.name}-1.jpg"]


def test_mv_up_long_named_folder_background(long_dir, monkeypatch):
    touch(long_dir / "1.jpg")
    monkeypatch.chdir(long_dir.parent)
    organize.mv_files_one_folder_up()
    assert listing(long_dir.parent) == [f"{long_dir.name}-1.jpg"]


# --- renumber ---

def test_renum_nested_directories_only(tmp_path, monkeypatch):
    touch(tmp_path / "a" / "b" / "c" / "test.jpg")
    monkeypatch.chdir(tmp_path)
    assert organize.mv_files_one_folder_up(renumber=True) == 0
    assert not (tmp_path / "a").exists()
    assert (tmp_path / "a-b" / "c" / "test.jpg").is_file()


def test_renum_files(tmp_path, monkeypatch):
    for n in ["1.jpg", "2.jpg", "3.png"]:
        touch(tmp_path / "a" / n)
    monkeypatch.chdir(tmp_path)
    organize.mv_files_one_folder_up(renumber=True)
    assert listing(tmp_path) == ["a-0.jpg", "a-1.jpg", "a-2.png"]


def test_renum_files_and_subfolders(tmp_path, monkeypatch):
    touch(tmp_path / "a" / "sub" / "inner.txt")
    touch(tmp_path / "a" / "1.jpg")
    touch(tmp_path / "a" / "2.jpg")
    monkeypatch.chdir(tmp_path)
    organize.mv_files_one_folder_up(renumber=True)
    assert listing(tmp_path) == ["a-0.jpg", "a-1.jpg", "a-sub"]
    assert (tmp_path / "a-sub" / "inner.txt").is_file()


def test_renum_zero_padding(tmp_path, monkeypatch):
    (tmp_path / "a" / "sub").mkdir(parents=True)
    for i in range(1, 11):
        touch(tmp_path / "a" / f"f{i}.jpg")
    monkeypatch.chdir(tmp_path)
    organize.mv_files_one_folder_up(renumber=True)
    nums = sorted(p.name for p in tmp_path.glob("a-[0-9][0-9].jpg"))
    assert nums[0] == "a-00.jpg" and nums[-1] == "a-09.jpg" and len(nums) == 10


def test_renum_long_named_folder(long_dir):
    touch(long_dir / "x.jpg")
    touch(long_dir / "y.png")
    organize.mv_files_one_folder_up([str(long_dir)], renumber=True)
    assert listing(long_dir.parent) == [f"{long_dir.name}-0.jpg", f"{long_dir.name}-1.png"]


# --- move videos ---

def test_move_videos(tmp_path, monkeypatch, capsys):
    touch(tmp_path / "a" / "b" / "d.mp4")
    touch(tmp_path / "top.MKV")
    touch(tmp_path / "x" / "video" / "already.mp4")
    touch(tmp_path / "pic.jpg")
    touch(tmp_path / "c" / "e.gif")
    touch(tmp_path / "c" / "video" / "e.gif")
    monkeypatch.chdir(tmp_path)
    assert organize.move_videos_to_subfolder() == 0
    assert (tmp_path / "a" / "b" / "video" / "d.mp4").is_file()
    assert (tmp_path / "video" / "top.MKV").is_file()
    assert (tmp_path / "x" / "video" / "already.mp4").is_file()
    assert not (tmp_path / "x" / "video" / "video").exists()
    assert (tmp_path / "pic.jpg").is_file()
    assert (tmp_path / "c" / "e.gif").is_file()
    out = capsys.readouterr().out
    assert "SKIP (exists)" in out
    assert "Done. 2 file(s) moved. 2 already in video/ (skipped)." in out


def test_move_videos_none(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert organize.move_videos_to_subfolder() == 0
    assert "No video files found." in capsys.readouterr().out


def test_move_videos_long_named_folder(long_dir, monkeypatch):
    touch(long_dir / "v.mp4")
    monkeypatch.chdir(long_dir.parent)
    organize.move_videos_to_subfolder()
    assert (long_dir / "video" / "v.mp4").is_file()


# --- rename *_large ---

def test_rename_large_ext(tmp_path, monkeypatch, capsys):
    touch(tmp_path / "a.jpg_large")
    touch(tmp_path / "sub" / "B.PNG_LARGE")
    touch(tmp_path / "c.jpg_large")
    touch(tmp_path / "c.jpg")
    monkeypatch.chdir(tmp_path)
    assert organize.rename_large_ext() == 0
    assert (tmp_path / "a.jpg").is_file()
    assert (tmp_path / "sub" / "B.PNG").is_file()
    assert (tmp_path / "c.jpg_large").exists()
    out = capsys.readouterr().out
    assert "SKIP (exists)" in out
    assert "Done. 2 file(s) renamed." in out


def test_rename_large_ext_long_named_folder(long_dir):
    touch(long_dir / "a.jpg_large")
    organize.rename_large_ext(str(long_dir))
    assert (long_dir / "a.jpg").is_file()


# --- rename special chars ---

@pytest.mark.parametrize("name,expected", [
    ("a b.txt", "a-b.txt"),
    ("x (1)!.jpg", "x-1-.jpg"),
    ("【本】、＆＋.png", "-本-.png"),
    ("a--b.txt", "a-b.txt"),
    ("plain.txt", "plain.txt"),
    ("a　b'c^d,e;f&g?h.txt", "a-b-c-d-e-f-g-h.txt"),
])
def test_special_name(name, expected):
    assert organize.special_name(name) == expected


def test_rename_special_chars_depth_first(tmp_path, monkeypatch):
    touch(tmp_path / "a b" / "c d.txt")
    touch(tmp_path / "e-f.txt")
    touch(tmp_path / "e f.txt")
    monkeypatch.chdir(tmp_path)
    assert organize.rename_special_chars() == 0
    assert (tmp_path / "a-b" / "c-d.txt").is_file()
    assert (tmp_path / "e f.txt").exists()  # target exists -> skipped


def test_rename_special_chars_long_named_folder(long_dir, monkeypatch):
    touch(long_dir / "x y.txt")
    monkeypatch.chdir(long_dir.parent)
    organize.rename_special_chars()
    renamed = organize.special_name(long_dir.name)
    assert (long_dir.parent / renamed / "x-y.txt").is_file()
