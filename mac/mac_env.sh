#!/bin/bash

# Some softwares do not have brew support, which require app store to install:
# * fb messenger
# * LINE
# * Microsoft Remote Desktop

set -xe

# Note that some steps may require user password

brew install cmake
brew install macvim
brew install tmux
brew install python mono go nodejs

brew cask install sublime-text
brew cask install visual-studio-code
brew cask install keycastr
brew cask install rectangle
brew cask install obsidian
brew cask install dropbox
brew cask install microsoft-edge

# Docker stuff
brew cask install docker
brew install docker-compose

# Company stuff
brew cask install zoomus
brew cask install microsoft-outlook
