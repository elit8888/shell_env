" Create the 'tags' file (need to install ctags first)
command! MakeTags !ctags -R .

"******************************
"*  Below are mapping keys    *
"******************************

" Move vertically by visual line
nnoremap j gj
nnoremap k gk

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" For compile mapping, but not always work
nnoremap <F5> <Esc>:w<CR>:!g++ % -o /tmp/a.out<CR>
nnoremap <F11> <Esc>:w<CR>:!g++ % -o /tmp/a.out && /tmp/a.out<CR>
nnoremap <F6> <Esc>:w<CR>:!python3 %<CR>

inoremap {<CR> {<CR>}<Esc>ko
inoremap jk <Esc>

" Leader key

" because git bash not working on windows
nnoremap <leader>a <C-]>
nnoremap <leader>rb :Call VimuxRunCommand("python3 " . bufname("%"))<CR>
nnoremap <leader>vx :VimuxInterruptRunner<CR>
nnoremap <leader>vq :VimuxCloseRunner<CR>


" Enable docstring for folded code
let g:SimpylFold_docstring_preview=1

" Below are some examples of the mapping (from vim wikia)
" The ':map' command creates a key map that works in normal, visual, select
" and operator pending modes.
map <F2> :echo 'Current time is ' . strftime('%c')<CR>
" The ':map!' command creates a key map that works in insert and command-line
" mode
map! <F3> <C-R>=strftime('%c')<CR>
