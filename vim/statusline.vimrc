" From
" http://got-ravings.blogspot.tw/2008/08/vim-pr0n-making-statuslines-that-own.html
" type help statusline for mor information


set statusline=%F\        "full filename
"set statusline+=\ [%{strlen(&fenc)?&fenc:'none'},   "file encoding
"set statusline+=%{&ff}]   "file encoding
set statusline+=%h        "help file flag
set statusline+=%m        "modified flag
set statusline+=%r        "read only flag
set statusline+=%w        "help buffer flag
set statusline+=%y        "file type
set statusline+=%=        "left/right separator
set statusline+=%l,%c\    "cursor line,cursor column
set statusline+=%L        "total lines
set statusline+=\ %P      "percent through file


" Set statusline color
hi StatusLine cterm=bold ctermfg=LightBlue ctermbg=Black
