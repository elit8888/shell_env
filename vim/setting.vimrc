" Set statusline style
"source $HOME/shell_env/vim/statusline.vimrc

colorscheme molokai

" Uncomment below to use plugin config
"source $HOME/shell_env/vim/plugin/syntastic.config.vimrc
"source $HOME/shell_env/vim/plugin/ycm.config.vimrc
source $HOME/shell_env/vim/plugin/nerdtree.vimrc
"source $HOME/shell_env/vim/plugin/ultisnips.vimrc
"source $HOME/shell_env/vim/plugin/taglist.vimrc
"source $HOME/shell_env/vim/plugin/srcexpl.vimrc
"source $HOME/shell_env/vim/plugin/trinity.vimrc
"source $HOME/shell_env/vim/plugin/vim-go.vimrc
source $HOME/shell_env/vim/plugin/jedi-vim.vimrc
source $HOME/shell_env/vim/plugin/easymotion.vimrc
augroup EditVim
   autocmd!
   "autocmd FileType cpp    source ~/.vim/.vimrc_cpp
   "autocmd FileType cpp    source $HOME/.vim/.vimrc_coc
   autocmd FileType cpp    colorscheme gruv-vsassist
augroup END

"*****************************************************************************************"
"For vim-lsp
"*****************************************************************************************"
" autocmd FileType cpp source ~/.vim/.vimrc_clangd
"
" if executable('clangd')
"     augroup lsp_clangd
"         autocmd!
"         autocmd User lsp_setup call lsp#register_server({
"                     \ 'name': 'clangd',
"                     \ 'cmd': {server_info->['clangd']},
"                     \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp'],
"                     \ })
"         autocmd FileType c setlocal omnifunc=lsp#complete
"         autocmd FileType cpp setlocal omnifunc=lsp#complete
"         autocmd FileType objc setlocal omnifunc=lsp#complete
"         autocmd FileType objcpp setlocal omnifunc=lsp#complete
"     augroup end
" endif

" autosave delay, cursorhold trigger, default: 4000ms
setl updatetime=300

" highlight the word under cursor (CursorMoved is inperformant)
highlight WordUnderCursor cterm=underline gui=underline
autocmd CursorHold * call HighlightCursorWord()
function! HighlightCursorWord()
    " if hlsearch is active, don't overwrite it!
    let search = getreg('/')
    let cword = expand('<cword>')
    if match(cword, search) == -1
        exe printf('match WordUnderCursor /\V\<%s\>/', escape(cword, '/\'))
    endif
endfunction

set number
set relativenumber
set showcmd     " Display incomplete commands, the same as set sc
set ruler       " Show the cursor position all the time (at right below)
set hlsearch    " Highlight search result
set incsearch   " Do incremental searching
set ignorecase  " case insensitive search, use \C to switch to case sensitive
set smartcase   " switch to case sensitive search if keyword contains Uppercase char
set title
set nowrap
set cursorline
"set autowrite
highlight cursorline cterm=none ctermfg=none ctermbg=256

" type ":help clipboard" for more info
set clipboard=unnamed,unnamedplus

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Show the lines at line 88
if exists('+colorcolumn')
    set colorcolumn=88
else
    au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>88v.\+', -1)
endif

" Enable folding
set foldmethod=indent
set foldlevel=99

set background=dark
set backspace=indent,eol,start " Same as set backspace=2, type ':help backspace'
set tabstop=4   " Number of spaces of a tab
set shiftwidth=4    " Spaces of a indent
set scrolloff=3
set laststatus=2

" Test mouse option
"if has("mouse_sgr")
"    set ttymouse=sgr
"else
"    set ttymouse=xterm2
"end

" Enable mouse to control
if has('mouse')
  set mouse=a
endif

" Print the tab and whitespace with '|' & '-'
set list
if has('gui_running')
  set listchars=tab:▶\ ,trail:·,extends:\#,nbsp:.
else
  " set listchars=tab:\|\ ,nbsp:%,trail:-
  set listchars=tab:▸\ ,nbsp:%,trail:-
endif
"highlight LeaderTab guifg=#666666
"match LeaderTab /^\t/

" Provides tab-completion for all file-related tasks
set path+=**

" Display all matching files when we tab complete the command
set wildmenu

" Switch syntax highlighting on when the terminal has colors
" Also switch on highlighting the last used search pattern.
if (&t_Co > 2 || has("gui_running")) && !exists("syntax_on")
    syntax on
endif

set t_Co=256

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
          \ | wincmd p | diffthis
endif

" Type command below to read from an example vimrc
":r $VIMRUNTIME/vimrc_example.vim

" Type command below for more vimrc information
":help vimrc-intro
"
" Only do this part when compiled with support for autocommands.
if has("autocmd")
  autocmd BufWritePre *.py if exists(":Black") | execute ':Black'
  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  "autocmd FileType text setlocal textwidth=78
  autocmd FileType cpp setlocal expandtab
  autocmd FileType vim setlocal expandtab softtabstop=2 shiftwidth=2
  autocmd FileType json setlocal expandtab softtabstop=2 shiftwidth=2
  autocmd User Node if &filetype == "javascript" | setlocal expandtab | endif

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END

else
  set autoindent        " always set autoindenting on
endif   " has("autocmd")

" Set syntax style
au BufNewFile,BufRead *Jenkinsfile setf groovy
