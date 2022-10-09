" Key maps that are not related to plugins, for plugin related keybindings,
" Go to setting.vimrc

" Create the 'tags' file (need to install ctags first)
command! MakeTags !ctags -R .

"******************************
" Below are mapping keys
"******************************

nnoremap zso :source ~/.vimrc<CR>
map zn :cnext<CR>
map zp :cprevious<CR>
nnoremap zcl :cclose<CR>

vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

" Move vertically by visual line
nnoremap j gj
nnoremap k gk

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Requires plugin fzf.vim
nnoremap <C-p> :Files<CR>

" For compile mapping, but not always work
" If opening different file type, the command will be overwritten to the
" latest one
if has("autocmd")
  autocmd filetype python nnoremap <F5> <Esc>:w <bar> exec '!python3 '.shellescape('%')<CR>
  autocmd filetype c nnoremap <F5> <Esc>:w <bar> exec '!gcc '.shellescape('%').' -o /tmp/a.out && /tmp/a.out'<CR>
  autocmd filetype cpp nnoremap <F5> <Esc>:w <bar> exec '!g++ -std=c++17 '.shellescape('%').' -o /tmp/a.out && /tmp/a.out'<CR>
endif
nnoremap <F6> <Esc>:w<CR>:!g++ % -o /tmp/a.out<CR>

" easy way of back to normal mode
inoremap jk <Esc>
inoremap jl <Esc>:w<CR>

" open file in vertical split
nnoremap <C-W><C-F> <C-W>vgf

"******************************
" Leader key
"******************************

" because git bash not working on windows
nnoremap <leader>a <C-]>
nnoremap <leader>rb :Call VimuxRunCommand("python3 " . bufname("%"))<CR>
nnoremap <leader>vx :VimuxInterruptRunner<CR>
nnoremap <leader>vq :VimuxCloseRunner<CR>


" Reduce time of creating testcase for Python
inoremap <F1> <Esc>mby?def test<CR>`bp/def <CR>O<Esc>?def test_<CR>f_la<Esc>
nnoremap <F1> mby?def test<CR>`bp/def <CR>O<Esc>?def test_<CR>f_la<Esc>
inoremap <A-.> self.
nnoremap <A-.> iself.

" Enable docstring for folded code
let g:SimpylFold_docstring_preview=1

" Below are some examples of the mapping (from vim wikia)
" The ':map' command creates a key map that works in normal, visual, select
" and operator pending modes.
map <F2> :echo 'Current time is ' . strftime('%c')<CR>
" The ':map!' command creates a key map that works in insert and command-line
" mode
map! <F3> <C-R>=strftime('%c')<CR>
