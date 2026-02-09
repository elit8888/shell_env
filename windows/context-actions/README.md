# win-elit-utils

Windows context menu utilities — bash scripts integrated into the Windows shell via registry.

## Prerequisites

- [Git for Windows](https://gitforwindows.org/) (provides `bash` and `mintty`)
- [FFmpeg](https://ffmpeg.org/) (required by all convert scripts)
- [7-Zip](https://www.7-zip.org/) (required by `unzip_all_files.sh`)

All tools must be available in PATH.

## Install

Run in PowerShell:

```powershell
.\install.ps1
```

Auto-detects `mintty.exe` (supports Scoop, standalone installer, winget) and uses the current folder as the scripts path. **No admin rights required** (writes to `HKEY_CURRENT_USER`).

## Uninstall

Double-click `actions_uninstall.reg`.

## Scripts

### File conversion (single file right-click / folder background right-click)

| Script | Description |
|--------|-------------|
| `convert_gif_2_mp4.sh` | GIF → MP4 (H.264, 30fps, even dimensions) |
| `convert_gif_2_webm.sh` | GIF → WebM (VP9) |
| `convert_png_2_jpg.sh` | PNG → JPG |
| `convert_webp_2_jpg.sh` | WebP → JPG |

Single file: right-click the file to convert it.
Batch: right-click folder background to convert all matching files in that folder.

### Directory management (folder right-click / folder background right-click)

| Script | Description |
|--------|-------------|
| `mv_files_one_folder_up.sh` | Move files from a subfolder up one level, prefixing filenames with the folder name |
| `mv_files_one_folder_up_renum.sh` | Same, but renumbers files by modification time |
| `mv_all_files_one_folder_up.sh` | Apply the above to all subfolders |
| `mv_all_files_one_folder_up_renum.sh` | Same, with renumbering |

### Other

| Script | Description |
|--------|-------------|
| `rename_special_chars.sh` | Recursively replace special characters in filenames (spaces, brackets, punctuation, etc.) with `-` |
| `unzip_all_files.sh` | Extract all `.zip` files in the current directory, each into its own folder, then delete the archives |

### Shared utilities

`utils.sh` is sourced by the convert scripts. Contains FFmpeg conversion functions and the `elit_call` dispatcher.
