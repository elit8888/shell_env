" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes
Plug 'junegunn/vim-easy-align'

" Access GitHub events (user dashboard, user/repo activity) in Vim.
" check if `:echo has('ruby')` prints 1
" Example:
"  GHDashboard! USER
"  GHActivity! USER
"  GHActivity! USER/REPO
" remove `!` for authentication
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Multiple Plug commands can be written in a single line using | separators
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
" Workaround for tab completion for snippets
Plug 'ervandew/supertab'

" Useful file explorer
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

"Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Use `:YcmGenerateConfig` to generate config
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Golang support
Plug 'fatih/vim-go', { 'tag': '*', 'do': ':GoInstallBinaries' }

" Python Support
"  <leader>g: Goto assignment
"  <leader>d: Goto definition
"  <leader>n: Usages
"  <leader>s: Goto (typing) stub
"  :Pyimport os: opens the `os` module
Plug 'davidhalter/jedi-vim'

" Plugin options
"Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Unmanaged plugin (manually installed and updated)
"Plug '~/my-prototype-plugin'


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

Plug 'mileszs/ack.vim'

Plug 'nightsense/office'
Plug 'yuttie/inkstained-vim'
Plug 'fatih/molokai'


call plug#end()
