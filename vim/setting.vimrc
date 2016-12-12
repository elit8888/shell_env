set nu
set autoindent
set relativenumber
set scrolloff=3
set laststatus=2
set background=dark
set tabstop=4
set shiftwidth=4

" Show the cursor position all the time (at right below)
set ruler

" Highlight search result
set hlsearch

" Do incremental searching
set incsearch

" Display incomplete commands
set showcmd

" Enable mouse to control
if has('mouse')
  set mouse=a
endif

" Print the tab and whitespace with '|' & '-'
set list
set lcs=tab:\|\ ,nbsp:%,trail:-
"highlight LeaderTab guifg=#666666
"match LeaderTab /^\t/

" Provides tab-completion for all file-related tasks
set path+=**

" Display all matching files when we tab complete
set wildmenu

" Back to last status
"if has("autocmd")
"	autocmd BufRead *.txt set tw=78
"	autocmd BufReadPost *
"	\ if line("'\"") > 0 && line ("'\"") <= line("$") |
"	\   exe "normal g'\"" |
"	\ endif
"endif


"filetype indent on
"filetype plugin on
syntax on

set t_Co=256

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

" :b

" Type command below to read from an example vimrc
":r $VIMRUNTIME/vimrc_example.vim

" Type command below for more vimrc information
":help vimrc-intro
"
" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

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
  set autoindent		" always set autoindenting on
endif " has("autocmd")
