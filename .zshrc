# Source config files
source ~/shell_env/zsh/aliases.zsh
source ~/shell_env/zsh/antigen_config.zsh
source ~/shell_env/zsh/settings.zsh

FZF=~/.fzf.zsh
if [ -f $FZF ]; then
	source $FZF
fi
