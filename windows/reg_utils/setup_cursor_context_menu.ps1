# Register Cursor context menu entries directly into the registry
# Usage: .\setup_cursor_context_menu.ps1

$username = $env:USERNAME
$scoopBase = "C:\Users\$username\scoop\apps\cursor\current"
$exe = "$scoopBase\Cursor.exe"
$userData = "$scoopBase\data\user-data"
$extensionsDir = "$scoopBase\data\extensions"

$icon = "$exe,0"

function Build-Command($placeholder) {
    return ('"' + $exe + '" --user-data-dir "' + $userData + '" --extensions-dir "' + $extensionsDir + '" "' + $placeholder + '"')
}

# Open files
$fileBase = 'HKCU\Software\Classes\*\shell\Open with Cursor'
reg add $fileBase /ve /d 'Edit with Cursor' /f
reg add $fileBase /v Icon /d $icon /f
reg add "$fileBase\command" /ve /d (Build-Command '%1') /f

# Right click ON a folder
$dirBase = 'HKCU\Software\Classes\Directory\shell\cursor'
reg add $dirBase /ve /d 'Open Folder as Cursor Project' /f
reg add $dirBase /v Icon /d $icon /f
reg add "$dirBase\command" /ve /d (Build-Command '%1') /f

# Right click INSIDE a folder
$bgBase = 'HKCU\Software\Classes\Directory\Background\shell\cursor'
reg add $bgBase /ve /d 'Open Folder as Cursor Project' /f
reg add $bgBase /v Icon /d $icon /f
reg add "$bgBase\command" /ve /d (Build-Command '%V') /f

Write-Host 'Cursor context menu entries registered.'
