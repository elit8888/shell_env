"""Tests for ext_stats.py scanning and navigation (the key loop needs a console)."""
from pathlib import Path

import ext_stats
from ext_stats import DOWN, ENTER, LEFT, RIGHT, UP, Nav


def test_scan_exts_groups_by_lowercase_ext(tmp_path):
    (tmp_path / "sub").mkdir()
    for name in ["a.JPG", "b.jpg", "sub/c.png", "README"]:
        (tmp_path / name).write_text("")
    groups = ext_stats.scan_exts(tmp_path)
    assert sorted(groups[".jpg"]) == [Path("a.JPG"), Path("b.jpg")]
    assert groups[".png"] == [Path("sub/c.png")]
    assert groups[ext_stats.NO_EXT] == [Path("README")]
    assert ext_stats.sorted_exts(groups) == [".jpg", ext_stats.NO_EXT, ".png"]


def test_handle_key_navigation():
    nav = Nav(exts=[".jpg", ".png"], counts={".jpg": 3, ".png": 1})
    nav = ext_stats.handle_key(nav, UP)
    assert nav.ext_idx == 0
    nav = ext_stats.handle_key(nav, DOWN)
    nav = ext_stats.handle_key(nav, DOWN)
    assert nav.ext_idx == 1
    nav = ext_stats.handle_key(nav, RIGHT)
    assert (nav.level, nav.file_idx) == ("files", 0)
    nav = ext_stats.handle_key(nav, DOWN)
    assert nav.file_idx == 0  # .png has only one file
    assert ext_stats.handle_key(nav, ENTER) is not None
    nav = ext_stats.handle_key(nav, LEFT)
    assert nav.level == "exts"
    assert ext_stats.handle_key(nav, ENTER) is None


def test_fit_width_keeps_tail_with_wide_chars():
    assert ext_stats.fit_width("short", 10) == "short"
    out = ext_stats.fit_width("abcdef日本", 6)
    assert out.endswith("日本") and ext_stats.display_width(out) <= 6
