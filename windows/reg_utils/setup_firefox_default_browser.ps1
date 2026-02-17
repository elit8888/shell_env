# Register Firefox as a default browser option in Windows Settings
# Required when Firefox is installed via Scoop
# NOTE: Requires administrator privileges (writes to HKLM)
# Usage: Run as admin: .\setup_firefox_default_browser.ps1
# To uninstall: .\setup_firefox_default_browser.ps1 -Uninstall

param(
    [switch]$Uninstall
)

# Check for admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'This script requires administrator privileges. Run as admin.'
    exit 1
}

$username = $env:USERNAME
$exe = "C:\Users\$username\scoop\apps\firefox\current\firefox.exe"
$base = 'HKLM\SOFTWARE\Clients\StartMenuInternet\FirefoxHTML'

if ($Uninstall) {
    reg delete $base /f 2>$null
    reg delete 'HKLM\SOFTWARE\Classes\FirefoxHTML' /f 2>$null
    reg delete 'HKLM\SOFTWARE\RegisteredApplications' /v Firefox /f 2>$null
    Write-Host 'Firefox default browser entries removed.'
    exit 0
}

$cmd = '"' + $exe + '" "%1"'

# StartMenuInternet entry
reg add $base /ve /d 'Firefox' /f
reg add "$base\shell\open\command" /ve /d $cmd /f

# Capabilities
reg add "$base\Capabilities" /v ApplicationName /d 'Firefox' /f
reg add "$base\Capabilities" /v ApplicationDescription /d 'Firefox Web Browser' /f
reg add "$base\Capabilities\FileAssociations" /v .html /d 'FirefoxHTML' /f
reg add "$base\Capabilities\FileAssociations" /v .htm /d 'FirefoxHTML' /f
reg add "$base\Capabilities\URLAssociations" /v http /d 'FirefoxHTML' /f
reg add "$base\Capabilities\URLAssociations" /v https /d 'FirefoxHTML' /f

# RegisteredApplications
reg add 'HKLM\SOFTWARE\RegisteredApplications' /v Firefox /d 'Software\Clients\StartMenuInternet\FirefoxHTML\Capabilities' /f

# ProgId definition
reg add 'HKLM\SOFTWARE\Classes\FirefoxHTML' /ve /d 'Firefox HTML Document' /f
reg add 'HKLM\SOFTWARE\Classes\FirefoxHTML\DefaultIcon' /ve /d "$exe,0" /f
reg add 'HKLM\SOFTWARE\Classes\FirefoxHTML\shell\open\command' /ve /d $cmd /f
reg add 'HKLM\SOFTWARE\Classes\FirefoxHTML' /v 'URL Protocol' /d '' /f

Write-Host 'Firefox registered as default browser option.'
