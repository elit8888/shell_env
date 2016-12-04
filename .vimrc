set nu
set autoindent
set background=dark
set tabstop=4
set shiftwidth=4
set mouse=a
set hlsearch

set relativenumber

set scrolloff=3
set laststatus=2

set list
set lcs=tab:\|\ ,nbsp:%,trail:-
"highlight LeaderTab guifg=#666666
"match LeaderTab /^\t/

" Provides tab-completion for all file-related tasks
set path+=**

" Display all matching files when we tab complete
set wildmenu

" Back to last status
if has("autocmd")
	autocmd BufRead *.txt set tw=78
	autocmd BufReadPost *
	\ if line("'\"") > 0 && line ("'\"") <= line("$") |
	\   exe "normal g'\"" |
	\ endif
endif

" Create the 'tags' file (need to install ctags first)
command! MakeTags !ctags -R .

inoremap {<CR> {<CR>}<Esc>ko
nnoremap <F5> <Esc>:w<CR>:!g++ % -o /tmp/a.out<CR>


filetype indent on
filetype plugin on
syntax on

" :b

