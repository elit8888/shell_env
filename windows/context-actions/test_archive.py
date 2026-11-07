"""Tests for archive.py (unzip all recursively / single 7z / single JP zip)."""
import os
import subprocess
import zipfile

import pytest

import archive
import fsops


def seven(*args):
    subprocess.run(["7z", *args], check=True, capture_output=True)


def make_zip(path, member, data="hello"):
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w") as z:
        z.writestr(member, data)
    return path


def make_7z(path, tmp_path, member="seven.txt", vol=None, size=None):
    stage = tmp_path / "_stage"
    stage.mkdir(exist_ok=True)
    f = stage / member
    f.write_bytes(os.urandom(size) if size else b"hello")
    path.parent.mkdir(parents=True, exist_ok=True)
    seven("a", "-t7z", *([f"-v{vol}"] if vol else []), str(path), str(f))
    f.unlink()
    return path


def make_cp932_zip(path):
    """Member name as raw cp932 bytes without the UTF-8 flag (what Japanese Windows tools write)."""
    raw = "テスト.txt".encode("cp932")
    placeholder = "A" * (len(raw) - 4) + ".txt"
    with zipfile.ZipFile(path, "w") as z:
        z.writestr(placeholder, "hello")
    path.write_bytes(path.read_bytes().replace(placeholder.encode("ascii"), raw))


@pytest.fixture
def run_all(monkeypatch):
    def run(root, answer="n"):
        monkeypatch.chdir(root)
        opened = []
        rc = archive.unzip_all_recursive(ask=lambda _p: answer, reveal=opened.append)
        return rc, opened
    return run


def test_archive_out_dir():
    assert archive.archive_out_dir("a/x.zip") == "a/x"
    assert archive.archive_out_dir("a/x.7z.001") == "a/x"
    assert archive.archive_out_dir("a/X.7Z.001") == "a/X"
    assert archive.archive_out_dir("a/movie.part1.rar") == "a/movie"
    assert archive.archive_out_dir("a/movie.PART01.rar") == "a/movie"


def test_is_trailing_rar_part():
    assert archive.is_trailing_rar_part("m.part2.rar")
    assert archive.is_trailing_rar_part("m.PART10.RAR")
    assert not archive.is_trailing_rar_part("m.part1.rar")
    assert not archive.is_trailing_rar_part("m.part01.rar")
    assert not archive.is_trailing_rar_part("m.rar")


def test_recursive_extraction(tmp_path, run_all):
    make_zip(tmp_path / "root.zip", "root.txt")
    make_zip(tmp_path / "sub" / "mid.zip", "mid.txt")
    make_zip(tmp_path / "sub" / "deep" / "deep.zip", "deep.txt")
    rc, _ = run_all(tmp_path)
    assert rc == 0
    assert (tmp_path / "root" / "root.txt").is_file()
    assert (tmp_path / "sub" / "mid" / "mid.txt").is_file()
    assert (tmp_path / "sub" / "deep" / "deep" / "deep.txt").is_file()
    assert not (tmp_path / "root.zip").exists()


def test_continue_on_error(tmp_path, run_all, capsys):
    (tmp_path / "a_broken.rar").write_text("not an archive at all")
    (tmp_path / "b_broken.zip").write_text("not a zip either")
    make_zip(tmp_path / "z_good.zip", "good.txt")
    rc, opened = run_all(tmp_path)
    out = capsys.readouterr().out
    assert rc == 1
    assert (tmp_path / "z_good" / "good.txt").is_file()
    assert not (tmp_path / "z_good.zip").exists()
    assert (tmp_path / "a_broken.rar").exists() and (tmp_path / "b_broken.zip").exists()
    assert "Done. 1 archive(s) extracted, 2 failed." in out
    summary = out.split("Failed:")[-1]
    assert "a_broken.rar" in summary and "b_broken.zip" in summary
    assert opened == []


def test_no_archives(tmp_path, run_all, capsys):
    (tmp_path / "plain.txt").write_text("x")
    rc, _ = run_all(tmp_path)
    assert rc == 0
    assert "No .zip, .rar or .7z files found." in capsys.readouterr().out


def test_keep_originals(tmp_path, run_all, monkeypatch):
    make_zip(tmp_path / "keep.zip", "keep.txt")
    monkeypatch.setenv("ELIT_DELETE_ORIGINAL", "false")
    run_all(tmp_path)
    assert (tmp_path / "keep" / "keep.txt").is_file()
    assert (tmp_path / "keep.zip").exists()


def test_trailing_rar_parts_skipped(tmp_path, run_all, capsys):
    (tmp_path / "movie.part2.rar").write_text("junk")
    (tmp_path / "movie.part3.rar").write_text("junk")
    rc, _ = run_all(tmp_path)
    assert rc == 0
    assert "SKIP" in capsys.readouterr().out


def test_cp932_zip(tmp_path, run_all, capfd):
    (tmp_path / "nested").mkdir()
    make_cp932_zip(tmp_path / "nested" / "jp.zip")
    rc, _ = run_all(tmp_path)
    assert rc == 0
    assert "cp932" in capfd.readouterr().out
    assert (tmp_path / "nested" / "jp" / "テスト.txt").is_file()


def test_long_member_path(tmp_path, run_all):
    member = "a" * 120 + "/" + "b" * 120 + "/long.txt"
    make_zip(tmp_path / "long.zip", member)
    rc, _ = run_all(tmp_path)
    assert rc == 0
    # over MAX_PATH: only reachable through the \\?\ prefix
    assert os.path.isfile(fsops.long_path((tmp_path / "long").joinpath(*member.split("/"))))


def test_7z(tmp_path, run_all):
    make_7z(tmp_path / "sub" / "seven.7z", tmp_path)
    rc, _ = run_all(tmp_path / "sub")
    assert rc == 0
    assert (tmp_path / "sub" / "seven" / "seven.txt").is_file()
    assert not (tmp_path / "sub" / "seven.7z").exists()


def test_multi_volume_7z(tmp_path, run_all):
    make_7z(tmp_path / "sub" / "vol.7z", tmp_path, member="big.bin", vol="100k", size=300000)
    assert (tmp_path / "sub" / "vol.7z.003").exists()
    rc, _ = run_all(tmp_path / "sub")
    assert rc == 0
    assert (tmp_path / "sub" / "vol" / "big.bin").is_file()
    assert not (tmp_path / "sub" / "vol.7z.001").exists()
    assert not (tmp_path / "sub" / "vol.7z.003").exists()


def test_archive_rm_rar_parts(tmp_path):
    sub = tmp_path / "sub"
    sub.mkdir()
    for n in ["movie.part01.rar", "movie.part02.rar", "movie.PART10.rar", "movie.part1x.rar", "other.part02.rar"]:
        (sub / n).write_text("x")
    archive.archive_rm(str(sub / "movie.part01.rar"))
    assert sorted(p.name for p in sub.iterdir()) == ["movie.part1x.rar", "other.part02.rar"]


def test_archive_rm_7z_volumes(tmp_path):
    for n in ["v.7z.001", "v.7z.002", "v.7z.010", "v.7z", "w.7z.001"]:
        (tmp_path / n).write_text("x")
    archive.archive_rm(str(tmp_path / "v.7z.001"))
    assert sorted(p.name for p in tmp_path.iterdir()) == ["v.7z", "w.7z.001"]


def test_open_explorer_on_failure_yes(tmp_path, monkeypatch):
    (tmp_path / "sub").mkdir()
    (tmp_path / "sub" / "broken.rar").write_text("not an archive at all")
    (tmp_path / "sub" / "broken2.7z").write_text("not an archive at all")
    prompts, opened = [], []

    def ask(p):
        prompts.append(p)
        return "y"

    monkeypatch.chdir(tmp_path)
    rc = archive.unzip_all_recursive(ask=ask, reveal=opened.append)
    assert rc == 1
    assert prompts == ["Open failed archive(s) in File Explorer? [y/N] "]
    assert [fsops.rel(p, str(tmp_path)) for p in opened] == ["sub/broken.rar", "sub/broken2.7z"]


def test_nested_archives(tmp_path, run_all, capsys):
    stage = tmp_path / "stage"
    make_zip(stage / "inner.zip", "inner.txt")
    seven("a", "-t7z", str(stage / "middle.7z"), str(stage / "inner.zip"))
    work = tmp_path / "work"
    work.mkdir()
    seven("a", "-tzip", str(work / "outer.zip"), str(stage / "middle.7z"))
    rc, _ = run_all(work)
    assert rc == 0
    assert (work / "outer" / "middle" / "inner" / "inner.txt").is_file()
    assert not (work / "outer" / "middle.7z").exists()
    assert "Done. 3 archive(s) extracted, 0 failed." in capsys.readouterr().out


def test_nested_keep_originals_extracted_once(tmp_path, run_all, monkeypatch, capsys):
    stage = tmp_path / "stage"
    make_zip(stage / "inner.zip", "inner.txt")
    work = tmp_path / "work"
    work.mkdir()
    seven("a", "-tzip", str(work / "outer.zip"), str(stage / "inner.zip"))
    monkeypatch.setenv("ELIT_DELETE_ORIGINAL", "false")
    run_all(work)
    assert (work / "outer" / "inner" / "inner.txt").is_file()
    assert "Done. 2 archive(s) extracted, 0 failed." in capsys.readouterr().out


def test_deflate64_falls_back_to_7z(tmp_path, run_all, capsys):
    stage = tmp_path / "stage"
    stage.mkdir()
    (stage / "d64.txt").write_bytes(b"\0" * 5000)
    work = tmp_path / "work"
    work.mkdir()
    seven("a", "-tzip", "-mm=Deflate64", str(work / "d64.zip"), str(stage / "d64.txt"))
    rc, _ = run_all(work)
    assert rc == 0
    assert "retrying with 7z" in capsys.readouterr().out
    assert (work / "d64" / "d64.txt").is_file()
    assert not (work / "d64.zip").exists()


def test_unzip_all_in_long_named_folder(long_dir, run_all):
    make_zip(long_dir / "a.zip", "a.txt")
    make_7z(long_dir / "b.7z", long_dir.parent)
    rc, _ = run_all(long_dir.parent)
    assert rc == 0
    assert (long_dir / "a" / "a.txt").is_file()
    assert (long_dir / "b" / "seven.txt").is_file()
    assert not (long_dir / "a.zip").exists()


def test_unzip_7z_single_keeps_original(long_dir):
    src = make_7z(long_dir / "my archive.7z", long_dir.parent, member="a.txt")
    assert archive.unzip_7z(str(src)) == 0
    assert (long_dir / "my archive" / "a.txt").is_file()
    assert src.exists()


def test_unzip_7z_volumes(tmp_path):
    make_7z(tmp_path / "vol.7z", tmp_path, member="big.bin", vol="100k", size=300000)
    assert archive.unzip_7z(str(tmp_path / "vol.7z.001")) == 0
    assert (tmp_path / "vol" / "big.bin").is_file()
    assert (tmp_path / "vol.7z.002").exists()


def test_unzip_7z_rejects_non_7z_001(tmp_path, capsys):
    make_zip(tmp_path / "other.zip", "o.txt").rename(tmp_path / "other.zip.001")
    assert archive.unzip_7z(str(tmp_path / "other.zip.001")) == 1
    assert "ERROR" in capsys.readouterr().out
    assert not (tmp_path / "other.zip").exists()


def test_unzip_jp_single_in_long_named_folder(long_dir, capfd):
    make_cp932_zip(long_dir / "jp.zip")
    assert archive.unzip_jp(str(long_dir / "jp.zip")) == 0
    assert (long_dir / "jp" / "テスト.txt").is_file()
    assert (long_dir / "jp.zip").exists()
