" Automatically close NerdTree when open a file
let NERDTreeQuitOnOpen = 1
let NERDTreeWinPos = "right"

map <C-n> :NERDTreeToggle<CR>
map <C-m> :NERDTreeFind<CR>

" Automatically close a tab if the only remaining window is NerdTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
