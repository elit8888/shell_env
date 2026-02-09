#Requires -Version 5.1
<#
.SYNOPSIS
    Registers context menu entries for win-elit-utils.
.DESCRIPTION
    Auto-detects Git for Windows (mintty.exe) and uses the directory
    containing this script as the scripts location. No hardcoded paths.
    Run from the folder where the .sh scripts live.
#>
$ErrorActionPreference = "Stop"

function Find-Mintty {
    # Check if mintty is directly in PATH
    $m = Get-Command mintty -ErrorAction SilentlyContinue
    if ($m) { return $m.Source }

    # Derive from git.exe location (handles Scoop, standalone installer, winget)
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        # git.exe may be under cmd\, bin\, or a shim one level up
        foreach ($levelsUp in 1, 2) {
            $root = $git.Source
            for ($i = 0; $i -lt $levelsUp; $i++) { $root = Split-Path $root }
            $c = Join-Path $root "usr\bin\mintty.exe"
            if (Test-Path $c) { return $c }
        }
    }

    # Common fallback locations
    foreach ($loc in @(
        "$env:ProgramFiles\Git\usr\bin\mintty.exe",
        "$env:LOCALAPPDATA\Programs\Git\usr\bin\mintty.exe",
        "$env:USERPROFILE\scoop\apps\git\current\usr\bin\mintty.exe"
    )) {
        if (Test-Path $loc) { return $loc }
    }

    throw "Cannot find mintty.exe. Ensure Git for Windows is installed and 'git' is in PATH."
}

# Convert Windows path to MSYS2/bash path  e.g. C:\foo\bar -> /c/foo/bar
function ConvertTo-BashPath([string]$path) {
    if ($path -match '^([A-Za-z]):\\?(.*)$') {
        return '/' + $Matches[1].ToLower() + '/' + $Matches[2].Replace('\', '/')
    }
    return $path.Replace('\', '/')
}

# Escape a string for use inside a .reg file string value
function Escape-Reg([string]$s) {
    return $s.Replace('\', '\\').Replace('"', '\"')
}

$mintty  = Find-Mintty
$bashDir = ConvertTo-BashPath $PSScriptRoot
Write-Host "mintty : $mintty"
Write-Host "scripts: $bashDir"
Write-Host ""

function cmd-single([string]$sh) {
    $raw = "`"$mintty`" --exec `"/usr/bin/bash`" -lc `"$bashDir/$sh '%1'`""
    return Escape-Reg $raw
}
function cmd-all([string]$sh) {
    $raw = "`"$mintty`" --exec `"/usr/bin/bash`" -lc `"$bashDir/$sh`""
    return Escape-Reg $raw
}

$reg = @"
Windows Registry Editor Version 5.00

; === GIF ===
[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.gif\shell\elit_actions]
"MUIVerb"="elit_actions"
"SubCommands"=""

[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.gif\shell\elit_actions\shell\convert_gif_2_mp4]
@="convert gif to mp4"
[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.gif\shell\elit_actions\shell\convert_gif_2_mp4\command]
@="$(cmd-single 'convert_gif_2_mp4.sh')"

[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.gif\shell\elit_actions\shell\convert_gif_2_webm]
@="convert gif to webm"
[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.gif\shell\elit_actions\shell\convert_gif_2_webm\command]
@="$(cmd-single 'convert_gif_2_webm.sh')"


; === PNG ===
[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.png\shell\elit_actions]
"MUIVerb"="elit_actions"
"SubCommands"=""

[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.png\shell\elit_actions\shell\convert_png_2_jpg]
@="convert png to jpg"
[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\.png\shell\elit_actions\shell\convert_png_2_jpg\command]
@="$(cmd-single 'convert_png_2_jpg.sh')"


; === Directory (folder right-click) ===
[HKEY_CURRENT_USER\Software\Classes\Directory\shell\elit_actions]
"MUIVerb"="elit_actions"
"SubCommands"=""

[HKEY_CURRENT_USER\Software\Classes\Directory\shell\elit_actions\shell\move_files_up_no_renum]
@="move files one folder up"
[HKEY_CURRENT_USER\Software\Classes\Directory\shell\elit_actions\shell\move_files_up_no_renum\command]
@="$(cmd-single 'mv_files_one_folder_up.sh')"

[HKEY_CURRENT_USER\Software\Classes\Directory\shell\elit_actions\shell\move_files_up_renum]
@="move files one folder up renumber"
[HKEY_CURRENT_USER\Software\Classes\Directory\shell\elit_actions\shell\move_files_up_renum\command]
@="$(cmd-single 'mv_files_one_folder_up_renum.sh')"


; === Directory Background (folder background right-click) ===
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions]
"MUIVerb"="elit_actions"
"SubCommands"=""

[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\convert_all_webp_2_jpg]
@="convert all webp to jpg"
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\convert_all_webp_2_jpg\command]
@="$(cmd-all 'convert_webp_2_jpg.sh')"

[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\convert_all_png_2_jpg]
@="convert all png to jpg"
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\convert_all_png_2_jpg\command]
@="$(cmd-all 'convert_png_2_jpg.sh')"

[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\convert_all_gif_2_mp4]
@="convert all gif to mp4"
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\convert_all_gif_2_mp4\command]
@="$(cmd-all 'convert_gif_2_mp4.sh')"

[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\rename_special_chars]
@="rename files with special chars"
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\rename_special_chars\command]
@="$(cmd-all 'rename_special_chars.sh')"

[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\move_all_files_up_no_renum]
@="move all files one folder up"
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\move_all_files_up_no_renum\command]
@="$(cmd-all 'mv_files_one_folder_up.sh')"

[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\move_all_files_up_renum]
@="move all files one folder up renumber"
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\move_all_files_up_renum\command]
@="$(cmd-all 'mv_files_one_folder_up_renum.sh')"

[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\unzip_all_files]
@="Unzip all files"
[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\elit_actions\shell\unzip_all_files\command]
@="$(cmd-all 'unzip_all_files.sh')"

"@

$temp = [System.IO.Path]::GetTempFileName() + ".reg"
$reg | Out-File -FilePath $temp -Encoding Unicode
Write-Host "Importing registry entries..."
Start-Process -FilePath regedit -ArgumentList "/s `"$temp`"" -Wait
Remove-Item $temp
Write-Host "Done! Context menu entries registered."
