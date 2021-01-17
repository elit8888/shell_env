# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-rust \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk

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
    OMZL::theme-and-appearance.zsh
zinit wait lucid for \
    OMZP::pip \
    OMZP::python \
    OMZP::docker-compose \
    OMZP::kubectl \
    OMZP::vagrant \
    OMZP::extract \
    OMZP::command-not-found \
    OMZP::colored-man-pages

# This should be loaded separated to avoid conflict with fzf
zinit snippet OMZL::key-bindings.zsh

zinit wait lucid for \
    atload"unalias grv" OMZP::git \
    as"completion"      OMZP::docker/_docker

zinit light djui/alias-tips

zinit ice from"gh-r" as"program"
zinit light junegunn/fzf-bin


# From document example minimal setup
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions

source ~/shell_env/zsh/aliases.zsh

[[ ! -f ~/.fzf.zsh ]] || source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
