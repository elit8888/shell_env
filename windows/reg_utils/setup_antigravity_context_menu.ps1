# Register Antigravity context menu entries directly into the registry
# Usage: .\generate_antigravity_reg.ps1

$username = $env:USERNAME
$scoopBase = "C:\Users\$username\scoop\apps\antigravity\current"
$exe = "$scoopBase\antigravity.exe"
$userData = "$scoopBase\data\user-data"
$extensionsDir = "$scoopBase\data\extensions"

$icon = "$exe,0"

function Build-Command($placeholder) {
    return ('"' + $exe + '" --user-data-dir "' + $userData + '" --extensions-dir "' + $extensionsDir + '" "' + $placeholder + '"')
}

# Open files
$fileBase = 'HKCU\Software\Classes\*\shell\Open with Antigravity'
reg add $fileBase /ve /d 'Edit with Antigravity' /f
reg add $fileBase /v Icon /d $icon /f
reg add "$fileBase\command" /ve /d (Build-Command '%1') /f

# Right click ON a folder
$dirBase = 'HKCU\Software\Classes\Directory\shell\antigravity'
reg add $dirBase /ve /d 'Open Folder in Antigravity' /f
reg add $dirBase /v Icon /d $icon /f
reg add "$dirBase\command" /ve /d (Build-Command '%1') /f

# Right click INSIDE a folder
$bgBase = 'HKCU\Software\Classes\Directory\Background\shell\antigravity'
reg add $bgBase /ve /d 'Open Folder in Antigravity' /f
reg add $bgBase /v Icon /d $icon /f
reg add "$bgBase\command" /ve /d (Build-Command '%V') /f

Write-Host 'Antigravity context menu entries registered.'
