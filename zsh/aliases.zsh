#!/bin/zsh
# create handy aliases

export VIRTUALENV_PATH=$HOME/venv
# Create dynamic aliases in $VIRTUALENV_PATH
if [ -d ${VIRTUALENV_PATH} ]; then
    for env in $VIRTUALENV_PATH/*; do
        activate="$env/bin/activate"
        name=`basename $env`
        if [ -n $name ]; then
            alias so-virtualenv-$name=". $activate"
        fi
    done
fi


# Platform dependent arguments
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


# Command with default arguments
alias mv='mv -i'
alias scp='scp -r'
alias wget='wget -c'
alias tree='tree -C'


# Shortcut commands
alias l='ls -lCF'
alias l.='ls -ld .*'
alias la='ls -A'
alias ll='ls -l'
alias lld="ls --color -lh --group-directories-first"
alias lh='ls -lh'
alias al='alias'
alias hi='history'
alias steal='sudo chown -R `id -u`:`id -g`'
alias vimrc="vim ~/.vimrc"
alias tmuxrc="vim ~/.tmux.conf"
alias py=python
alias py3=python3
alias ka9='killall -9'
alias k9='kill -9'
alias rm-rf='rm -rf'
alias gau='git add -u'
alias activate-venv='source venv/bin/activate'
alias so-venv='source venv/bin/activate'
alias sai='sudo apt-get install'
alias hig='history | grep'
alias known_host='vim ~/.ssh/known_hosts'

grep2() {
    grep $1 | grep -v grep | grep --color $1
}

gopath() {
    if [ ! -z $1 ]; then
        export GOPATH=`cd $1 && pwd`
        export PATH=$GOPATH/bin:$PATH
    fi
    echo $GOPATH
}

towin10() {
    sudo grub-reboot "Windows 10 (loader) (on /dev/sda1)"
    sudo reboot
}
