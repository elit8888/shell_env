# The expected location for this file can be checked via `echo $profile`, or may just `nvim $profile`.
Set-PSReadlineOption -EditMode Emacs
# Import-Module 'C:\src\vcpkg\scripts\posh-vcpkg'

New-Alias grep findstr
New-Alias which Get-Command
New-Alias vim nvim
New-Alias realpath Resolve-Path

function ghc {
    gh copilot @args
}
