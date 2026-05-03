# Unregister Antigravity context menu entries from the registry
# Usage: .\unregister_antigravity_context_menu.ps1

# Open files
reg delete 'HKCU\Software\Classes\*\shell\Open with Antigravity' /f 2>$null

# Right click ON a folder
reg delete 'HKCU\Software\Classes\Directory\shell\antigravity' /f 2>$null

# Right click INSIDE a folder
reg delete 'HKCU\Software\Classes\Directory\Background\shell\antigravity' /f 2>$null

Write-Host 'Antigravity context menu entries removed.'
