#!/bin/zsh
# Config file for antigen

# Use Antigen
ANTIGEN=~/rc/antigen.zsh
if [ ! -f $ANTIGEN ]; then
	mkdir -p ~/rc
	curl -L git.io/antigen > $ANTIGEN
fi
source $ANTIGEN

#antigen use oh-my-zsh
# Plugins
#antigen bundle git
#antigen bundle pip
antigen bundle zsh-users/zsh-syntax-highlighting
#antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
# Theme
#
#antigen theme robbyrussell
#antigen theme bira

# Tell antigen that I'm done.
antigen apply


# Some variables modification
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=3'

