# README

## Files

* `wt-settings.json` - for Windows terminal, not sure whether it's portable

## Windows Environment Setup

Install Chocolatey first, then install using `choco` command.

``` powershell
choco install -y git --params "/NoGuiHereIntegration"
choco install -y `
  7zip gh obsidian pdfxchangeeditor python3 `
  dropbox line spotify telegram `
  brave firefox googlechrome `
  notepadplusplus sublimetext4 vscode `
  microsoft-windows-terminal powertoys `
  ffmpeg youtube-dl `
  virtualbox vagrant
choco install -y visualstudio2022community
```
