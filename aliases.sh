# create handy aliases

alias al='alias'
alias vimrc='vim ~/.vimrc'
alias tmuxrc='vim ~/.tmux.conf'
alias zshrc='vim ~/.zshrc'
alias bashrc='vim ~/.bashrc'
alias lfrc='vim ~/.config/lf/lfrc'
alias py='python'
alias py2='docker run -it --rm python:2'
alias py3='python3'
alias activate-venv='source venv/bin/activate'

mdcd() {
  mkdir -p $1 && cd $1
}

if command -v apt > /dev/null; then
  # debian specific
  towin10() {
    # Use `grep -i "menuentry '" /boot/grub/grub.cfg` to list the menuentry
    sudo grub-reboot "Windows 10 (on /dev/sda1)"
    sudo reboot
  }

  reset_sound() {
    rm -f ~/.config/pulse/*
    sudo killall pulseaudio
  }

  auu() {
    sudo apt update
    sudo apt -y upgrade
  }
fi
