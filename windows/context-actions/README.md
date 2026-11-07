# win-elit-utils

Windows context menu utilities — Python scripts integrated into the Windows shell via registry.

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (runs every action: `uv run --script elit.py ...`)
- [FFmpeg](https://ffmpeg.org/) (convert and scale actions)
- [7-Zip](https://www.7-zip.org/) (unzip actions)
- `bun` for **translate jp to zh** only

All tools must be available in the Windows PATH.

## Install

```powershell
uv run --no-project install.py
```

Reads `actions.json`, locates `uv.exe` in PATH and uses the current folder as the scripts path.
**No admin rights required** (writes to `HKEY_CURRENT_USER`).
Each run wipes the previous registration first and regenerates `actions_uninstall.reg` to match.

Menus are registered via `ExtendedSubCommandsKey`, not `SubCommands`: the latter silently drops
everything past 16 items in a cascading menu.

Explorer caches context menus — restart it to see changes:
`taskkill /f /im explorer.exe && start explorer.exe`.

Each menu item runs `"uv.exe" run --script "<dir>\elit.py" <args> ["%1"]` (`args` from
`actions.json`) straight from Explorer in a Windows console window — no mintty / Git Bash.
Git Bash (MSYS2) caps each path component at 255 UTF-8 bytes, so folders with long Japanese
names (3 bytes per character) could not even be listed; native Python has no such limit, and all
paths go through the `\\?\` prefix (`fsops.long_path`) so MAX_PATH (260) does not apply either.
The classic console window does no font fallback, so `console.py` switches it to `MingLiU`
(monospace; kana plus traditional and simplified Han) at startup; under Windows Terminal
(`WT_SESSION` set) it is left alone. Windows Terminal is not used as the host because its command
line splits on `;` even inside quotes, which would cut selected paths apart.
Background items work on the clicked folder (the process working directory); file / folder items
also get the selected path as the last argument, passed as one argv entry so `'`, `$`, `&` or
backticks in it are harmless.

## Uninstall

Double-click `actions_uninstall.reg`.

## Tests

```bash
uv run --no-project --with pytest --with pytest-cov pytest -q --cov=. test_*.py
```

Needs `ffmpeg`, `7z` and `uv` in PATH. Every action is also tested inside a folder whose name is
over 255 UTF-8 bytes. `test_install.py` runs the generated registry command line through the real
`uv` the way Explorer does.
CI (`.github/workflows/context-actions.yml`, `windows-latest`) runs the same command on changes under
`windows/context-actions/`.

## Actions (`elit.py <command>`)

The console always waits for Enter at the end (except `ext-stats`, which only waits on error).
An unexpected error prints the traceback.

### File conversion — `convert <name> [file]`

| Name | Description |
|------|-------------|
| `gif2mp4` | GIF → MP4 (H.264, 30fps, even dimensions) |
| `gif2webm` | GIF → WebM (VP9) |
| `img2jpg` | PNG / WebP / JPEG → JPG (one menu item; folder batch converts all three; transparency becomes dark gray; animated WebP or an existing target `.jpg` is skipped and the original kept) |
| `rpgmvp2png` | RPG Maker MV `.rpgmvp` / `.png_` → PNG; batch output goes to `png/<same relative path>` |

Single file (file right-click): converts that file next to itself, original kept.
Batch (folder background, or folder right-click for rpgmvp): converts every matching file
recursively, deleting each original on success (`ELIT_DELETE_ORIGINAL=false` keeps them).
Skips and ffmpeg errors are collected under `=== Warnings / errors ===` after the progress list.

### Image scaling — `scale <factor|more> [file]`

Nested submenu **scale image** (single file, factors `1`, `1.5`, `2`, `3`, `4`, `more...`) /
**scale all jpg** (folder background, `2` and `more...` only — that menu is near the 16-item
cap, see Install). Choosing `more...` prompts for a custom factor. Output is written to a `by<factor>/` subfolder
(e.g. `by2/`), downscaling via `ffmpeg -vf scale=iw/f:ih/f`.
For **scale all jpg**, if the folder has subfolders the console asks `Include subfolders? [y/N]`;
answering `y` scales every `*.jpg` recursively into the top-level `by<factor>/`, keeping the
directory structure (`sub/a.jpg` → `by2/sub/a.jpg`). Existing `by<number>/` folders are skipped.

### Directory management

| Command | Description |
|---------|-------------|
| `mv-up [dir]` | Move a folder's entries up one level as `<folder>-<name>`, then remove the folder; on folder background, applies to every subfolder. Stops with an error (nothing moved) if a target name already exists |
| `mv-up-renum [dir]` | Same, but files are renumbered (`<folder>-<n>.<ext>`, name order, zero-padded); subfolders keep their own name |
| `move-videos` | Recursively move each video (`mp4 mkv avi mov wmv flv webm m4v mpg mpeg 3gp gif`) into a `video/` subfolder of its own folder; files already under a `video/` folder are skipped |
| `rename-large [dir]` | Recursively rename `*.jpg_large` / `*.png_large` → `*.jpg` / `*.png` (skips when the target exists) |
| `rename-special` | Recursively replace each run of special characters in file and folder names (spaces, brackets, punctuation, etc.) with `-`, deepest first |

### Archives

| Command | Description |
|---------|-------------|
| `unzip-jp <zip>` | **unzip (JP/Shift-JIS)**: `unzip_jp.py` into a same-name folder (UTF-8/cp932 filename detection, prompts for the password on encrypted entries), original kept |
| `unzip-7z <file>` | **unzip** on a single `.7z`, or **unzip (7z multi-volume)** on `x.7z.001` (7z picks up the remaining volumes): extract into a same-name folder (`x/` for volumes), originals kept. A `.001` that is not `.7z.001` is rejected |
| `unzip-all` | Recursively extract every `.zip`/`.rar`/`.7z`/`.7z.001` under the current folder, each into a folder named after the archive, deleting the archive on success; archives that come out of an extraction are extracted too, until none are left. `.zip` goes through `unzip_jp.py` and falls back to 7z when it fails (e.g. AES-encrypted or Deflate64 zips); `.rar`/`.7z` go through 7z (multi-volume 7z deletes every `.7z.NNN` on success); trailing multi-volume `.partN.rar` are skipped and every part is deleted once the first succeeds. A failed archive is kept and skipped; at the end the failed paths are listed and `Open failed archive(s) in File Explorer? [y/N]` is asked (`y` opens Explorer with each failed archive selected) |

### Other

| Command | Description |
|---------|-------------|
| `rpgmv-trans` | **translate jp to zh**: runs `bun D:/Documents/unreal/tools/rpgmv-trans/src/cli.ts run <current folder>` to translate an RPG Maker MV/MZ game |
| `rpgview-render` | **render rpg interactive map**: runs `uv run --project D:/Projects/rpg-view python D:/Projects/rpg-view/render_interactive.py <current folder>` |
| `ext-stats [dir]` | **file count by extension**: `ext_stats.py` recursively counts files per extension and browses them in the console — ↑↓ select, → list the files of that extension, ← back, Enter on a file opens Explorer with it selected, Enter on the extension table exits |

### Modules

| File | Role |
|------|------|
| `elit.py` | CLI entry point (argparse subcommands), pause / error handling |
| `console.py` | CJK-capable console font |
| `fsops.py` | `\\?\` long paths, recursive file search, Explorer reveal, `ELIT_DELETE_ORIGINAL` |
| `convert.py` / `scale.py` | ffmpeg conversions and scaling |
| `archive.py` | Archive extraction (calls `unzip_jp.py` and `7z`) |
| `organize.py` | Move / rename actions |
| `ext_stats.py`, `unzip_jp.py` | Standalone scripts also used by `elit.py` |
