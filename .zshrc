# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/home/elit/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="bira"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Only use on nvidia-docker
alias nvdocker="sudo nvidia-docker"
alias dockervim="sudo nvidia-docker run -idt --rm \
          --name vim \
          -v $HOME/Documents/my_docker/DeepLearning:/data elit-tensorflow:vim"
alias dockeripython3="sudo nvidia-docker run -idt --rm \
          -e DISPLAY=$DISPLAY \
          -v /tmp/.X11-unix:/tmp/.X11-unix \
          -v $HOME/Documents/my_docker/DeepLearning:/data \
          --name ipython3 elit-tensorflow:ipython3"
alias dockernotebook="sudo nvidia-docker run -idt \
          -p 8888:8888 \
          -p 6006:6006 \
          -p 8889:8889 \
          -v $HOME/Documents/my_docker/DeepLearning:/notebooks/data \
          --name jupyter_notebook elit-tensorflow:notebook"

alias remotedockervim="sudo nvidia-docker run -idt --rm \
          --net=host \
          -e DISPLAY=$(echo $DISPLAY | sed 's/^[^:]*:/:/g') \
          -v $HOME/.Xauthority:/root/.Xauthority \
          -v /tmp/.X11-unix:/tmp/.X11-unix \
          --name vim_remote \
          -v $HOME/Documents/my_docker/DeepLearning:/data elit-tensorflow:vim"
alias remotedockeripython3="sudo nvidia-docker run -idt --rm \
          --net=host \
          -e DISPLAY=$(echo $DISPLAY | sed 's/^[^:]*:/:/g') \
          -v $HOME/.Xauthority:/root/.Xauthority \
          -v /tmp/.X11-unix:/tmp/.X11-unix \
          -v $HOME/Documents/my_docker/DeepLearning:/data \
          --name ipython3_remote \
          elit-tensorflow:ipython3"

# ignore some commands in history
export HISTIGNORE="pwd:ls"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/shell_env/zsh/aliases.zsh ] && source ~/shell_env/zsh/aliases.zsh
[ -f ~/shell_env/zsh/settings.zsh ] && source ~/shell_env/zsh/settings.zsh
