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

brew install --cask sublime-text
brew install --cask visual-studio-code
brew install --cask keycastr
brew install --cask rectangle
brew install --cask obsidian
brew install --cask dropbox
brew install --cask microsoft-edge

# Docker stuff
brew install docker
brew install docker-compose

# Company stuff
brew cask install zoom
brew cask install microsoft-outlook
