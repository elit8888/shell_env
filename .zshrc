# Source config files
ZSH_CONFIG_PATH=~/shell_env/zsh
if [ -d ${ZSH_CONFIG_PATH} ]; then
	for cfg_file in ${ZSH_CONFIG_PATH}/*.zsh; do
		source ${cfg_file}
	done
fi

FZF=~/.fzf.zsh
if [ -f $FZF ]; then
	source $FZF
fi
