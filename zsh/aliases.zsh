#!/bin/zsh
# create handy aliases

alias al='alias'
alias vimrc='vim ~/.vimrc'
alias tmuxrc='vim ~/.tmux.conf'
alias zshrc='vim ~/.zshrc'
alias py='python'
alias py3='python3'
alias activate-venv='source venv/bin/activate'

towin10() {
    sudo grub-reboot "Windows 10 (loader) (on /dev/sda1)"
    sudo reboot
}
