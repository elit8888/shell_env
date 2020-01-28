" Configuration for ycm plugin

" Determine which path should / should not need confirm is `.ycm_extra_conf.py`
" is found. Detailed see below:
" https://github.com/ycm-core/YouCompleteMe#the-gycm_extra_conf_globlist-option
let g:ycm_extra_conf_globlist = ['~/python-env/*', '~/python-venv/*']
let g:ycm_global_ycm_extra_conf = '~/shell_env/.ycm_extra_conf.py'

" Key shortcut for YCM FixIt
map <F9> :YcmCompleter FixIt<CR>
