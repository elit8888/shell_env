# The expected location for this file can be checked via `echo $profile`, or may just `nvim $profile`.
Set-PSReadlineOption -EditMode Emacs
oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/unicorn.omp.json' | Invoke-Expression

New-Alias grep findstr
New-Alias which Get-Command
New-Alias vim nvim
New-Alias realpath Resolve-Path

$Env:EDITOR = "nvim"
$Env:VISUAL = $Env:EDITOR
