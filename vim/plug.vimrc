" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Any valid git URL is allowed
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Multiple Plug commands can be written in a single line using | separators
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'ervandew/supertab'

" On-demand loading
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using a non-master branch
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
Plug 'fatih/vim-go', { 'tag': '*', 'do': ':GoInstallBinaries' }

" Plugin options
"Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Unmanaged plugin (manually installed and updated)
Plug '~/my-prototype-plugin'

" Initialize plugin system


"
" Add by myself
"


" side bar
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" window
Plug 'maciej-ka/ZoomWin'

" navigation
Plug 'ctrlpvim/ctrlp.vim'

" code tracer
Plug 'vim-scripts/cscope_macros.vim'
Plug 'vim-scripts/autoload_cscope.vim'

" Combine with tmux
Plug 'benmills/vimux'

" Syntax checking
Plug 'vim-syntastic/syntastic'

" Quick locate character
Plug 'easymotion/vim-easymotion'

" Auto-Completion
Plug 'Valloric/YouCompleteMe'

Plug 'wesleyche/SrcExpl'
Plug 'vim-scripts/taglist.vim'
Plug 'wesleyche/Trinity'

Plug 'AndrewRadev/splitjoin.vim'

Plug 'nightsense/office'
Plug 'yuttie/inkstained-vim'
Plug 'fatih/molokai'


call plug#end()
