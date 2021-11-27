# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# Add powerlevel10k, instructed by repo
zinit ice depth=1; zinit light romkatv/powerlevel10k


# Check `zshoptions manpge`
setopt HIST_VERIFY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Use ohmyzsh libraries and plugins
zinit wait lucid for \
    OMZL::git.zsh \
    OMZL::completion.zsh \
    OMZL::clipboard.zsh \
    OMZL::directories.zsh \
    OMZL::history.zsh \
    OMZL::theme-and-appearance.zsh
zinit wait lucid for \
    OMZP::pip \
    OMZP::python \
    OMZP::docker-compose \
    OMZP::kubectl \
    OMZP::minikube \
    OMZP::vagrant \
    OMZP::extract \
    OMZP::command-not-found \
    OMZP::pipenv \
    OMZP::colored-man-pages

# This should be loaded separated to avoid conflict with fzf
zinit snippet OMZL::key-bindings.zsh

zinit wait lucid for \
    atload"unalias grv" OMZP::git \
    as"completion"      OMZP::docker/_docker

zinit light djui/alias-tips

# zinit load iam4x/zsh-iterm-touchbar

zinit ice from"gh-r" as"program"
zinit light junegunn/fzf-bin


# From document example minimal setup
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions

source ~/shell_env/zsh/aliases.zsh

[[ ! -f ~/.fzf.zsh ]] || source ~/.fzf.zsh

export PYENV_ROOT="$HOME/.pyenv"
export PATH=$PYENV_ROOT/bin:$PATH:/usr/local/go/bin:~/.local/bin
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# For tmux, use different setting for better display
if [[ -v TMUX ]] && [[ -f ~/.p10k.tmux.zsh ]]; then
    zsh_p10k_file=~/.p10k.tmux.zsh
else
    zsh_p10k_file=~/.p10k.zsh
fi
[[ ! -f ${zsh_p10k_file} ]] || source ${zsh_p10k_file}

