# README

## Files

* `wt-settings.json` - for Windows terminal, not sure whether it's portable

## Windows Environment Setup

Install Chocolatey first, then install using `choco` command.

``` ps1
choco install -y git --params "/NoGuiHereIntegration"
choco install -y `
  7zip `
  brave `
  cheatengine `
  discord `
  dropbox `
  ffmpeg `
  firefox `
  flameshot `
  gh `
  googlechrome `
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
  vscode `
  winmerge `
  youtube-dl
choco install bottom quicklook
choco install -y visualstudio2022community
```

## Registry Key

To apply dark theme via registry key:

``` reg
[Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"AppsUseLightTheme"=dword:00000000
```

## Manual Installation

Some packages are not in Chocolatey and Winget, or they are outdated, need to install manually.

* Game Related
  * Steam
  * GOG
  * Battlenet
* Utilities
  * AltBacktick
