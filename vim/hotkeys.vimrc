" Create the 'tags' file (need to install ctags first)
command! MakeTags !ctags -R .




" Below are mapping keys

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

nnoremap <F5> <Esc>:w<CR>:!g++ % -o /tmp/a.out<CR>
inoremap {<CR> {<CR>}<Esc>ko
inoremap (<Space> (<Space><Space>)hi

" Below are some examples of the mapping (from vim wikia)
" The ':map' command creates a key map that works in normal, visual, select
" and operator pending modes.
map <F2> :echo 'Current time is ' . strftime('%c')<CR>
" The ':map!' command creates a key map that works in insert and command-line
" mode
map! <F3> <C-R>=strftime('%c')<CR>
