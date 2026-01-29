-- Check `:h lua-guide`, `:Tutor`

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.o.number = true
vim.o.relativenumber = true
vim.o.showcmd = true
vim.o.ruler = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 3
vim.o.list = true
vim.o.confirm = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.wrap = false
vim.o.colorcolumn = '88'
vim.o.updatetime = 300
vim.o.title = true
vim.o.listchars = 'tab:▸ ,nbsp:%,trail:-'
vim.o.mouse = 'a'
vim.o.wildmenu = true
vim.o.laststatus = 2
vim.o.backspace = 'indent,eol,start'



-- Sync clipboard between OS and Neovim. Schedule the setting after `UiEnter` because it can
-- increase startup-time. Remove this option if you want your OS clipboard to remain independent.
-- See `:help 'clipboard'`
vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    vim.o.clipboard = 'unnamedplus'
  end,
})


-- [[ Set up keymaps ]] See `:h vim.keymap.set()`, `:h mapping`, `:h keycodes`

-- Use <Esc> to exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

-- Map <A-j>, <A-k>, <A-h>, <A-l> to navigate between windows in any modes
vim.keymap.set({ 't', 'i' }, '<A-h>', '<C-\\><C-n><C-w>h')
vim.keymap.set({ 't', 'i' }, '<A-j>', '<C-\\><C-n><C-w>j')
vim.keymap.set({ 't', 'i' }, '<A-k>', '<C-\\><C-n><C-w>k')
vim.keymap.set({ 't', 'i' }, '<A-l>', '<C-\\><C-n><C-w>l')
vim.keymap.set({ 'n' }, '<A-h>', '<C-w>h')
vim.keymap.set({ 'n' }, '<A-j>', '<C-w>j')
vim.keymap.set({ 'n' }, '<A-k>', '<C-w>k')
vim.keymap.set({ 'n' }, '<A-l>', '<C-w>l')

-- Visual line movement
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')

-- Quickfix navigation
vim.keymap.set('n', 'zn', ':cnext<CR>')
vim.keymap.set('n', 'zp', ':cprevious<CR>')
vim.keymap.set('n', 'zcl', ':cclose<CR>')

vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('i', 'jl', '<Esc>:w<CR>')

-- Search for visually selected text
vim.keymap.set('v', '//', function()
  -- Get the visually selected text
  local esc = vim.fn.escape
  local getreg = vim.fn.getreg

  -- Yank the visual selection into the default register
  vim.cmd('normal! y')

  -- Get the yanked text and escape it for literal search
  local text = esc(getreg('"'), [[\/]])

  -- Start a literal search using \V
  vim.cmd('normal! /\\V' .. text .. '\r')
end)

-- [[ Basic Autocommands ]].
-- See `:h lua-guide-autocommands`, `:h autocmd`, `:h nvim_create_autocmd()`

-- Highlight when yanking (copying) text.
-- Try it with `yap` in normal mode. See `:h vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  callback = function()
    vim.hl.on_yank()
  end,

})

-- Highlight Word Under Cursor
-- Ported from highlight CursorHold * call HighlightCursorWord()
vim.api.nvim_create_autocmd('CursorHold', {
  desc = 'Highlight word under cursor',
  callback = function()
    local search = vim.fn.getreg('/')
    local cword = vim.fn.expand('<cword>')
    -- escape logic can be complex in Lua vs Vimscript, but matchadd handles it.
    -- If hlsearch is active and matches, don't overwrite.
    if vim.fn.match(cword, search) == -1 then
        -- Clear previous match if we want to be strict, but vimrc didn't seem to clear explicitly inside the function, 
        -- though usually one would use logic to clear old matches. 
        -- The vimrc used `match WordUnderCursor`. `match` command clears previous `match`.
        -- vim.fn.matchadd doesn't auto-clear. `vim.cmd('match ...')` does.
        vim.cmd('match WordUnderCursor /\\V\\<' .. vim.fn.escape(cword, '/\\') .. '\\>/')
    end
  end,
})
-- Need to define the highlight group
vim.cmd('highlight WordUnderCursor cterm=underline gui=underline')


-- Restore cursor position
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Restore cursor position',
  pattern = '*',
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- [[ Create user commands ]]
-- See `:h nvim_create_user_command()` and `:h user-commands`

-- Create a command `:GitBlameLine` that print the git blame for the current line
vim.api.nvim_create_user_command('GitBlameLine', function()
  local line_number = vim.fn.line('.') -- Get the current line number. See `:h line()`
  local filename = vim.api.nvim_buf_get_name(0)
  print(vim.fn.system({ 'git', 'blame', '-L', line_number .. ',+1', filename }))

end, { desc = 'Print the git blame for the current line' })

vim.api.nvim_create_user_command('DiffOrig', function()
  vim.cmd('vert new | set bt=nofile | r ++edit # | 0d_ | diffthis')
  vim.cmd('wincmd p | diffthis')
end, { desc = 'Compare buffer with file on disk' })


-- [[ Add optional packages ]]
-- Nvim comes bundled with a set of packages that are not enabled by
-- default. You can enable any of them by using the `:packadd` command.

-- For example, to add the "nohlsearch" package to automatically turn off search highlighting after
-- 'updatetime' and when going to insert mode
-- vim.cmd('packadd! nohlsearch')

vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'Enter terminal mode directly',
  pattern = '*',
  callback = function()
    vim.cmd('startinsert')
  end,
})


-- C/C++/JSON specific settings
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp', 'json' },
  callback = function()
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
  end,
})

