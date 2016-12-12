" Create the 'tags' file (need to install ctags first)
command! MakeTags !ctags -R .

inoremap {<CR> {<CR>}<Esc>ko
nnoremap <F5> <Esc>:w<CR>:!g++ % -o /tmp/a.out<CR>


" Below are some examples of the mapping (from vim wikia)
" The ':map' command creates a key map that works in normal, visual, select
" and operator pending modes.
map <F2> :echo 'Current time is ' . strftime('%c')<CR>
" The ':map!' command creates a key map that works in insert and command-line
" mode
map! <F3> <C-R>=strftime('%c')<CR>
