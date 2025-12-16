# README

## Files

* `Microsoft.PowerShell_profile.ps1` - for powershell profile
* `wt-settings.json` - for Windows terminal, not sure whether it's portable

## Windows Environment Setup

Install scoop, then install the following:

``` ps1
scoop bucket add extras
scoop install `
  7zip `
  extras/altdrag `
  extras/antigravity `
  extras/altsnap `
  bottom `
  extras/brave `
  chromedriver `
  extras/cursror `
  extras/discord `
  erdtree `
  ffmpeg `
  extras/firefox `
  fzf `
  gallery-dl `
  gh `
  git `
  extras/googlechrome `
  lf `
  neovim `
  nodejs `
  extras/notepadplusplus `
  pipx `
  pwsh `
  ripgrep `
  extras/spotify `
  extras/sublime-text `
  extras/tabby `
  extras/telegram `
  extras/vscode `
  extras/window-switcher `
  extras/windsurf `
  extras/winmerge `
  yt-dlp

scoop bucket add games
scoop install games/steam

# post action
reg import "$env:USERPROFILE\scoop\apps\7zip\current\install-context.reg"
reg import "$env:USERPROFILE\scoop\apps\notepadplusplus\current\install-context.reg"
reg import "$env:USERPROFILE\scoop\apps\sublime-text\current\install-context.reg"
reg import "$env:USERPROFILE\scoop\apps\vscode\current\install-context.reg"

# may need to change the content inside to not registering GUI
reg import "$env:USERPROFILE\scoop\apps\git\current\install-context.reg"
```

Use `scoop cleanup *` to remove old versions.

Install Chocolatey, then install using `choco` command (requires admin) (some to be moved to scoop).

``` ps1
choco install -y `
  cheatengine `
  dropbox `
  flameshot `
  line `
  microsoft-windows-terminal `
  obsidian `
  pdfxchangeeditor `
  powertoys `
  python3 `
  virtualbox
choco install -y quicklook
choco install -y visualstudio2022community
```


## Registry Key

To apply dark theme via registry key:

``` reg
[Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"AppsUseLightTheme"=dword:00000000
```

## Setup References

* May use https://github.com/Raphire/Win11Debloat for cleaning up Windows during initial setup.
