# README

## Files

* `wt-settings.json` - for Windows terminal, not sure whether it's portable

## Windows Environment Setup

Install Chocolatey first, then install using `choco` command.

``` ps1
choco install -y git --params "/NoGuiHereIntegration"
choco install -y `
  7zip gh obsidian pdfxchangeeditor python3 `
  dropbox line spotify telegram `
  brave firefox googlechrome `
  notepadplusplus sublimetext4 vscode `
  microsoft-windows-terminal powertoys `
  ffmpeg youtube-dl flameshot `
  virtualbox vagrant
choco install quicklook bottom
choco install -y visualstudio2022community
```

## Registry Key

To apply dark theme via registry key:

``` reg
[Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"AppsUseLightTheme"=dword:00000000
```
