# cd related utils mimicing zsh
alias -- -='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias ........='cd ../../../../../../..'
alias .........='cd ../../../../../../../..'
alias ..........='cd ../../../../../../../../..'

dedup() {
  declare -a new=() copy=("${DIRSTACK[@]:1}")
  declare -A seen
  local v i
  seen[$PWD]=1
  for v in "${copy[@]}"; do
    if [ -z "${seen[$v]}" ]
      then new+=("$v")
           seen[$v]=1
    fi
  done
  dirs -c
  for ((i=${#new[@]}-1; i>=0; i--))
  do      builtin pushd -n "${new[i]}" >/dev/null
  done
}

pushd() {
  if [ $# -eq 0 ]; then
    DIR="${HOME}"
  else
    DIR="$1"
  fi

  builtin pushd "${DIR}" > /dev/null
  #echo -n "DIRSTACK: "
  #dirs
  dedup
}

d() {
  dirs -v | head -n 10
}
 
alias 1='cd "$(dirs -l +1)"'
alias 2='cd "$(dirs -l +2)"'
alias 3='cd "$(dirs -l +3)"'
alias 4='cd "$(dirs -l +4)"'
alias 5='cd "$(dirs -l +5)"'
alias 6='cd "$(dirs -l +6)"'
alias 7='cd "$(dirs -l +7)"'
alias 8='cd "$(dirs -l +8)"'
alias 9='cd "$(dirs -l +9)"'
alias cd='pushd'

alias g='git'
alias ga='git add'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gcam='git commit -a -m'
alias gcb='git checkout -b'
alias gcl='git clone --recurse-submodules'
alias gcm='git checkout master'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gdca='git diff --cached'
alias gf='git fetch'
alias gfa='git fetch --all --prune --jobs=10'
alias gfo='git fetch origin'
alias gl='git pull'
alias glg='git log --stat'
alias glgg='git log --graph'
alias glgp='git log --stat -p'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias gp='git push'
alias gr='git remote'
alias gra='git remote add'
alias gst='git status'

source ~/shell_env/aliases.sh
