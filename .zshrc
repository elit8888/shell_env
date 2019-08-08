# Source config files
source ~/shell_env/zsh/aliases.zsh
source ~/shell_env/zsh/antigen_config.zsh
source ~/shell_envzsh/settings.zsh

FZF=~/.fzf.zsh
if [ -f $FZF ]; then
	source $FZF
fi
