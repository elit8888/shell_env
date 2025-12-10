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
  extras/antigravity
  extras/altsnap `
  bottom `
  extras/brave `
  chromedriver `
  extras/cursror `
  erdtree `
  extras/googlechrome `
  neovim `
  pipx `
  ripgrep `
  extras/tabby `
  extras/vscode `
  extras/window-switcher `
  extras/windsurf

scoop bucket add games
scoop install games/steam
```

Use `scoop cleanup *` to remove old versions.

Install Chocolatey, then install using `choco` command (requires admin) (some to be moved to scoop).

``` ps1
choco install -y git --params "/NoGuiHereIntegration"
choco install -y `
  cheatengine `
  discord `
  dropbox `
  ffmpeg `
  firefox `
  flameshot `
  gh `
  line `
  messenger `
  microsoft-windows-terminal `
  nodejs `
  notepadplusplus `
  obsidian `
  pdfxchangeeditor `
  powertoys `
  python3 `
  spotify `
  sublimetext4 `
  telegram `
  vagrant `
  virtualbox `
  winmerge `
  youtube-dl
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
