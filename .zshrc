# Source config files
source ~/shell_env/zsh/aliases.zsh
# originally, use antigen, now I use antibody, but antigen require no sudo
# permission, might be useful in some way
# source ~/shell_env/zsh/antigen_config.zsh

# setup for antibody
if [ ! -f /usr/local/bin/antibody ]; then
	curl -sfL git.io/antibody | sudo sh -s - -b /usr/local/bin
fi
# reference: https://github.com/getantibody/antibody/issues/261
ANTIBODY_HOME="$(antibody home)"
ZSH_THEME="bira"
plugins=(
  git
  pip
)
export ZSH="$ANTIBODY_HOME"/https-COLON--SLASH--SLASH-github.com-SLASH-robbyrussell-SLASH-oh-my-zsh
DISABLE_AUTO_UPDATE="true"
# antibody bundle < ~/.zsh_plugins.txt
if [ ! -f ~/.zsh_plugins.sh ]; then
	antibody bundle < ~/shell_env/.zsh_plugins.txt > ~/.zsh_plugins.sh
fi
source ~/.zsh_plugins.sh
source ~/shell_env/zsh/settings.zsh

FZF=~/.fzf.zsh
if [ -f $FZF ]; then
	source $FZF
fi
