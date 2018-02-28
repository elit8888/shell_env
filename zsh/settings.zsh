# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

# Use `unset export HISTIGNORE` to unset
export HISTIGNORE="pwd:ls:ls -l:ls -al:date:"
export HISTCONTROL=ignoredups
bindkey -e
# End of lines configured by zsh-newuser-install

# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit
# End of lines added by compinstall

zstyle ':completion*' completer _complete _ignored _files
#zstyle ':completion*' completer _files

vimode() {
    bindkey -v
    bindkey '^P' up-history
    bindkey '^N' down-history
    bindkey '^A' vi-beginning-of-line
    bindkey '^E' vi-end-of-line
    bindkey '^U' kill-whole-line

    bindkey '^p' up-history
    bindkey '^n' down-history
    bindkey '^a' vi-beginning-of-line
    bindkey '^e' vi-end-of-line
    bindkey '^u' kill-whole-line
}

export ENV_PATH=$HOME/.env
export PATH=/usr/local/bin:/usr/local/sbin:$ENV_PATH/bin:$PATH

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='mvim'
fi
