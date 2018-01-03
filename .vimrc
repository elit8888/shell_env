" The vim settings are separated to different files
" This vimrc file will source them
" The idea is from rightson, thanks to him

" =Begin=

" Plug install, this will download the plugins if it's not found, only run at
" the first time.
" Reference:
" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source ~/.vimrc
endif
source $HOME/shell_env/vim/plug.vimrc
source $HOME/shell_env/vim/hotkeys.vimrc
source $HOME/shell_env/vim/setting.vimrc
" =End=

