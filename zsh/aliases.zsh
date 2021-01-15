#!/bin/zsh
# create handy aliases

platform=`uname`
if [[ ${platform} = 'Linux' ]]; then
    alias ls='ls --color'
    alias grep='grep --color'
    alias du1='sudo du -h --max-depth 1'
elif [[ ${platform} = 'Darwin' ]]; then
    alias ls='ls -G'
    alias grep='grep --color'
    alias du1='sudo du -h -d1'
    alias toggle-hidden-file='defaults write com.apple.Finder AppleShowAllFiles'
fi

alias al='alias'
alias vimrc='vim ~/.vimrc'
alias tmuxrc='vim ~/.tmux.conf'
alias zshrc='vim ~/.zshrc'
alias py=python
alias py3=python3
alias activate-venv='source venv/bin/activate'

towin10() {
    sudo grub-reboot "Windows 10 (loader) (on /dev/sda1)"
    sudo reboot
}
