# The expected location for this file can be checked via `echo $profile`
Set-PSReadlineOption -EditMode Emacs

function ghc {
    gh copilot @args
}
