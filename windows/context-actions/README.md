# win-elit-utils

Windows context menu utilities — bash scripts integrated into the Windows shell via registry.

## Prerequisites

- [Git for Windows](https://gitforwindows.org/) (provides `bash` and `mintty`)
- [FFmpeg](https://ffmpeg.org/) (required by all convert scripts)
- [7-Zip](https://www.7-zip.org/) (required by `unzip_7z.sh`, `unzip_all_files.sh`, and `.rar`/`.7z` in `unzip_all_recursive.sh`)

All tools must be available in PATH.

## Install

```powershell
python install.py
```

Reads `actions.json`, auto-detects `mintty.exe` (supports Scoop, standalone installer, winget) and uses
the current folder as the scripts path. **No admin rights required** (writes to `HKEY_CURRENT_USER`).
Each run wipes the previous registration first and regenerates `actions_uninstall.reg` to match.

Menus are registered via `ExtendedSubCommandsKey`, not `SubCommands`: the latter silently drops
everything past 16 items in a cascading menu.

Explorer caches context menus — restart it to see changes:
`taskkill /f /im explorer.exe && start explorer.exe`.

The selected path is passed to bash as `$1` (`bash -lc '... "$1"' _ "%1"`), never spliced into the
command string, so paths containing `'`, `$` or backticks work.
Test the generated commands with `uv run --no-project --with pytest pytest test_install.py`.
CI (`.github/workflows/context-actions.yml`, `windows-latest`) runs every `test_*.sh` plus `test_install.py` on changes under `windows/context-actions/`.

## Uninstall

Double-click `actions_uninstall.reg`.

## Scripts

### File conversion (single file right-click / folder background right-click)

| Function (`utils.sh`) | Description |
|--------|-------------|
| `gif2mp4` | GIF → MP4 (H.264, 30fps, even dimensions) |
| `gif2webm` | GIF → WebM (VP9) |
| `img2jpg` | PNG / WebP / JPEG → JPG (one menu item; folder batch converts all three; animated WebP is skipped and kept) |

Single file: right-click the file to convert it.
Batch: right-click folder background to convert all matching files in that folder.

### Image scaling (single `.jpg` / folder background)

Nested submenu **scale image** (single file, factors `1`, `1.5`, `2`, `3`, `4`, `more...`) /
**scale all jpg** (folder background, `2` and `more...` only — that menu is near the 16-item
cap, see Install). Choosing `more...` opens a console prompt to enter a custom factor. Output is written to a `by<factor>/` subfolder
(e.g. `by2/`), downscaling via `ffmpeg -vf scale=iw/f:ih/f`.

### Directory management (folder right-click / folder background right-click)

| Script | Description |
|--------|-------------|
| `mv_files_one_folder_up.sh` | Move files from a subfolder up one level, prefixing filenames with the folder name; on folder background, applies to all subfolders |
| `mv_files_one_folder_up_renum.sh` | Same, but files are renumbered (`<folder>-<n>.<ext>`, name order, zero-padded); subfolders keep their own name |

### Other

| Script | Description |
|--------|-------------|
| `rename_special_chars.sh` | Recursively replace special characters in filenames (spaces, brackets, punctuation, etc.) with `-` |
| `unzip_7z.sh` | **unzip** on a single `.7z`, or **unzip (7z multi-volume)** on `x.7z.001` (7z picks up the remaining volumes): extract into a same-name folder (`x/` for volumes), originals kept. A `.001` that is not `.7z.001` is rejected |
| `unzip_all_files.sh` | Extract all `.zip`/`.7z`/`.7z.001` files in the current directory, each into its own folder, then delete the archives (all volumes for multi-volume 7z) |
| `unzip_all_recursive.sh` | Recursively extract every `.zip`/`.rar`/`.7z`/`.7z.001` under the current directory, each into a folder named after the archive, deleting the archive on success. `.zip` goes through `unzip_jp.py` (UTF-8/cp932 filename detection, prompts for the password on encrypted entries), `.rar`/`.7z` through 7z (multi-volume 7z deletes every `.7z.NNN` on success); trailing multi-volume `.partN.rar` are skipped and every part is deleted once the first succeeds. Stops at the first failure, prints the offending path and asks `Open in File Explorer? [y/N]` (`y` opens Explorer with the failed archive selected); the console always waits for Enter |
| `rpgmv_trans.sh` | **translate jp to zh**: runs `bun D:/Documents/unreal/tools/rpgmv-trans/src/cli.ts run <current folder>` (Windows path via `pwd -W`) to translate an RPG Maker MV/MZ game; requires `bun` in PATH |
| `rpgview_render.sh` | **render rpg interactive map**: runs `uv run --project D:/Projects/rpg-view python D:/Projects/rpg-view/render_interactive.py <current folder>` to generate the interactive map viewer HTML; requires `uv` in PATH |

### Shared utilities

`utils.sh` is sourced by the convert scripts. Contains FFmpeg conversion functions and the `elit_call` dispatcher.
