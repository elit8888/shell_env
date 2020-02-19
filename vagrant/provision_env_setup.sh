#!/bin/bash
set -xe

sudo apt-get update
sudo apt-get -y install cscope zsh python

git clone https://github.com/elit8888/shell_env.git ~/shell_env
cp ~/shell_env/.vimrc ~/
cp ~/shell_env/.tmux.conf ~/
cp ~/shell_env/.zshrc ~/
# Install all vim plugins
vim +PlugInstall +qall

# Git config
git config --global user.name "elit"
git config --global user.email "elit@local"

# Change shell to zsh
echo "vagrant" | chsh -s `which zsh` `whoami`
