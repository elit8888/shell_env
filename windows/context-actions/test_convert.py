"""Tests for convert.py (gif -> mp4/webm, png/webp/jpeg -> jpg, rpgmvp -> png)."""
import subprocess

import pytest

import convert
from conftest import is_jpg, make_anim_webp, make_gif, make_img

HEADER = "=== Warnings / errors ==="


@pytest.mark.parametrize("ext", ["png", "webp", "jpeg"])
def test_img2jpg_single(tmp_path, ext):
    src = make_img(tmp_path / f"one.{ext}")
    ok, _ = convert.img2jpg(str(src))
    assert ok
    assert is_jpg(tmp_path / "one.jpg")


def test_img2jpg_batch_recursive_case_insensitive(tmp_path, monkeypatch):
    for name in ["a.png", "b.webp", "sub/c.jpeg", "D.PNG", "keep.gif"]:
        make_img(tmp_path / name)
    monkeypatch.chdir(tmp_path)
    assert convert.batch("img2jpg") == 0
    for name in ["a.jpg", "b.jpg", "sub/c.jpg", "D.jpg"]:
        assert is_jpg(tmp_path / name), name
    for name in ["a.png", "b.webp", "sub/c.jpeg", "keep.jpg"]:
        assert not (tmp_path / name).exists(), name
    assert (tmp_path / "keep.gif").exists()


def test_img2jpg_batch_keeps_originals(tmp_path, monkeypatch):
    make_img(tmp_path / "k.webp")
    monkeypatch.setenv("ELIT_DELETE_ORIGINAL", "false")
    monkeypatch.chdir(tmp_path)
    convert.batch("img2jpg")
    assert is_jpg(tmp_path / "k.jpg")
    assert (tmp_path / "k.webp").exists()


def test_batch_no_files(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert convert.batch("img2jpg") == 1
    assert "No .png/.webp/.jpeg files found." in capsys.readouterr().out


def test_img2jpg_skips_animated_webp(tmp_path):
    src = make_anim_webp(tmp_path / "one.webp")
    ok, msg = convert.img2jpg(str(src))
    assert not ok
    assert msg == "skip animated"
    assert not (tmp_path / "one.jpg").exists()


def test_is_animated_webp_tiny_file(tmp_path):
    (tmp_path / "tiny.png").write_bytes(b"x")
    assert convert.is_animated_webp(str(tmp_path / "tiny.png")) is False
    assert convert.is_animated_webp(str(make_img(tmp_path / "still.webp"))) is False


def test_batch_animated_kept_static_converted(tmp_path, monkeypatch):
    make_anim_webp(tmp_path / "moving.webp")
    make_img(tmp_path / "still.webp")
    monkeypatch.chdir(tmp_path)
    convert.batch("img2jpg")
    assert not (tmp_path / "moving.jpg").exists()
    assert (tmp_path / "moving.webp").exists()
    assert is_jpg(tmp_path / "still.jpg")
    assert not (tmp_path / "still.webp").exists()


def test_batch_messages_deferred_to_end(tmp_path, monkeypatch, capsys):
    make_anim_webp(tmp_path / "moving.webp")
    (tmp_path / "bad.png").write_text("not an image")
    make_img(tmp_path / "a.png")
    make_img(tmp_path / "b.png")
    monkeypatch.chdir(tmp_path)
    convert.batch("img2jpg")
    out = capsys.readouterr().out
    assert HEADER in out
    before, after = out.split(HEADER)
    assert "skip animated" not in before
    assert "Invalid data" not in before
    assert "[moving.webp]\nskip animated" in after
    assert "[bad.png]" in after and "Invalid data" in after
    assert "[a.png]" not in after
    assert (tmp_path / "bad.png").exists()
    assert is_jpg(tmp_path / "a.jpg")


def test_clean_batch_has_no_summary(tmp_path, monkeypatch, capsys):
    make_img(tmp_path / "a.png")
    monkeypatch.chdir(tmp_path)
    convert.batch("img2jpg")
    assert HEADER not in capsys.readouterr().out


def test_img2jpg_transparency_becomes_dark_gray(tmp_path):
    src = tmp_path / "t.png"
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "color=c=red@0.0:s=8x8,format=rgba",
                    "-frames:v", "1", str(src)], check=True)
    assert convert.img2jpg(str(src))[0]
    px = subprocess.run(["ffmpeg", "-v", "error", "-i", str(tmp_path / "t.jpg"), "-f", "rawvideo",
                         "-pix_fmt", "rgb24", "-frames:v", "1", "-"], check=True, capture_output=True).stdout[:3]
    assert all(28 <= c <= 36 for c in px), px


def test_img2jpg_existing_jpg_skipped(tmp_path, monkeypatch, capsys):
    make_img(tmp_path / "a.png")
    make_img(tmp_path / "a.webp")
    monkeypatch.chdir(tmp_path)
    convert.batch("img2jpg")
    assert is_jpg(tmp_path / "a.jpg")
    assert (tmp_path / "a.png").exists() or (tmp_path / "a.webp").exists()
    assert "skip exists: a.jpg" in capsys.readouterr().out


def test_img2jpg_batch_in_long_named_folder(long_dir, monkeypatch):
    make_img(long_dir / "a.png")
    make_img(long_dir / "sub" / "b.webp")
    monkeypatch.chdir(long_dir.parent)
    assert convert.batch("img2jpg") == 0
    assert is_jpg(long_dir / "a.jpg")
    assert is_jpg(long_dir / "sub" / "b.jpg")
    assert not (long_dir / "a.png").exists()


def test_batch_from_inside_long_named_folder(long_dir, monkeypatch):
    make_img(long_dir / "a.png")
    monkeypatch.chdir(long_dir)
    assert convert.batch("img2jpg") == 0
    assert is_jpg(long_dir / "a.jpg")


@pytest.mark.parametrize("name,out_ext", [("gif2mp4", "mp4"), ("gif2webm", "webm")])
def test_gif_batch(long_dir, monkeypatch, name, out_ext):
    make_gif(long_dir / "a.gif")
    monkeypatch.chdir(long_dir.parent)
    assert convert.batch(name) == 0
    assert (long_dir / f"a.{out_ext}").stat().st_size > 0
    assert not (long_dir / "a.gif").exists()


def test_single_keeps_original(tmp_path, capsys):
    src = make_img(tmp_path / "a.png")
    assert convert.single("img2jpg", str(src)) == 0
    assert is_jpg(tmp_path / "a.jpg")
    assert src.exists()


def test_single_failure_reports(tmp_path, capsys):
    src = make_anim_webp(tmp_path / "m.webp")
    assert convert.single("img2jpg", str(src)) == 1
    assert "skip animated" in capsys.readouterr().out


# --- rpgmvp ---

def fake_rpgmvp(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"\0" * 32 + b"FAKEPNGBODYDATA")
    return path


def test_rpgmvp2png_single(tmp_path):
    src = fake_rpgmvp(tmp_path / "test.rpgmvp")
    convert.rpgmvp2png(str(src))
    data = (tmp_path / "test.png").read_bytes()
    assert data[:8] == bytes.fromhex("89504e470d0a1a0a")
    assert data[8:16] == bytes.fromhex("0000000d49484452")
    assert data[16:] == b"FAKEPNGBODYDATA"


def test_rpgmvp2png_custom_out_and_png_(tmp_path):
    convert.rpgmvp2png(str(fake_rpgmvp(tmp_path / "t.rpgmvp")), str(tmp_path / "custom" / "out.png"))
    assert (tmp_path / "custom" / "out.png").is_file()
    convert.rpgmvp2png(str(fake_rpgmvp(tmp_path / "t3.png_")))
    assert (tmp_path / "t3.png").is_file()


def test_rpgmvp_batch_keeps_structure(tmp_path, monkeypatch):
    for name in ["root.rpgmvp", "a/mid.rpgmvp", "a/b/deep.png_"]:
        fake_rpgmvp(tmp_path / name)
    monkeypatch.setenv("ELIT_DELETE_ORIGINAL", "false")
    monkeypatch.chdir(tmp_path)
    assert convert.batch("rpgmvp2png") == 0
    for name in ["png/root.png", "png/a/mid.png", "png/a/b/deep.png"]:
        assert (tmp_path / name).is_file(), name
    assert (tmp_path / "root.rpgmvp").exists()


def test_rpgmvp_batch_delete_in_long_folder(long_dir, monkeypatch):
    fake_rpgmvp(long_dir / "del.rpgmvp")
    monkeypatch.chdir(long_dir.parent)
    convert.batch("rpgmvp2png")
    assert (long_dir.parent / "png" / long_dir.name / "del.png").is_file()
    assert not (long_dir / "del.rpgmvp").exists()


def test_rpgmvp_single_via_dispatch(tmp_path):
    src = fake_rpgmvp(tmp_path / "s.rpgmvp")
    assert convert.single("rpgmvp2png", str(src)) == 0
    assert (tmp_path / "s.png").is_file()
    assert src.exists()


def test_unknown_converter():
    with pytest.raises(KeyError):
        convert.batch("nope")
