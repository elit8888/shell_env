set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

highlight SyntasticErrorSign guifg=white guibg=black
" let g:syntastic_quiet_messages = { "type": "style" }
let g:syntastic_loc_list_height = 3

let g:syntastic_error_symbol = '>>'
let g:syntastic_warning_symbol = '>'

let g:syntastic_mode_map = { "mode": "active", "passive_filetypes": ["rst"] }

" py checkers
let g:syntastic_python_checkers = ['flake8']
let g:syntastic_aggregate_errors = 1
let g:syntastic_python_flake8_args = "--ignore E501"
