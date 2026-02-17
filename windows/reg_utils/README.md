# Registry Utility Scripts

PowerShell scripts to register context menu entries and app associations for Scoop-installed apps. Paths are resolved dynamically using `$env:USERNAME`.

## Scripts

| Script | Requires Admin | Description |
|--------|:-:|---|
| `setup_antigravity_context_menu.ps1` | No | Adds "Edit with Antigravity" / "Open Folder in Antigravity" to Explorer context menu. Includes `--user-data-dir` and `--extensions-dir` args. |
| `setup_cursor_context_menu.ps1` | No | Adds "Edit with Cursor" / "Open Folder as Cursor Project" to Explorer context menu. Includes `--user-data-dir` and `--extensions-dir` args. |
| `setup_firefox_default_browser.ps1` | **Yes** | Registers Firefox in the default browser selection list. Use `-Uninstall` to remove. |
