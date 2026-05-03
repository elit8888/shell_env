# Unregister Cursor context menu entries from the registry
# Usage: .\unregister_cursor_context_menu.ps1

# Open files
reg delete 'HKCU\Software\Classes\*\shell\Open with Cursor' /f 2>$null

# Right click ON a folder
reg delete 'HKCU\Software\Classes\Directory\shell\cursor' /f 2>$null

# Right click INSIDE a folder
reg delete 'HKCU\Software\Classes\Directory\Background\shell\cursor' /f 2>$null

Write-Host 'Cursor context menu entries removed.'
