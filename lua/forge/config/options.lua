-- Editor options: the complete modern set.
local o = vim.opt
o.number = true
o.relativenumber = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.termguicolors = true
o.signcolumn = "yes"
o.cursorline = true
o.updatetime = 200
o.timeoutlen = 300
o.ttimeoutlen = 10
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.ignorecase = true
o.smartcase = true
o.inccommand = "split"
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true
o.breakindent = true
o.linebreak = true
o.undofile = true
o.undolevels = 10000
o.swapfile = false -- Forge session snapshots recover unsaved buffers.
o.backup = false
o.writebackup = false
o.scrolloff = 5
o.sidescrolloff = 0
o.completeopt = { "menu", "menuone", "noselect", "fuzzy", "popup" }
o.wildmode = "longest:full,full"
o.pumheight = 15
o.pumblend = 10
o.winblend = 10
o.laststatus = 3
o.showmode = false
o.showtabline = 2
o.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
o.foldlevel = 99
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.fillchars = { eob = " ", fold = " ", foldopen = "▾", foldclose = "▸", diff = "╱" }
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
o.confirm = true
o.jumpoptions = "view"
o.virtualedit = "block"
o.smoothscroll = true
vim.g.markdown_recommended_style = 0
-- Per-language indent defaults are set by autocmds / editorconfig.

-- Windows: prefer PowerShell 7 / Windows PowerShell over cmd for :terminal and !
if vim.fn.has("win32") == 1 then
  if vim.fn.executable("pwsh") == 1 then
    vim.o.shell = "pwsh"; vim.o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.o.shellquote = ""; vim.o.shellxquote = ""
  elseif vim.fn.executable("powershell") == 1 then
    vim.o.shell = "powershell"; vim.o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.o.shellquote = ""; vim.o.shellxquote = ""
  end
  vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
end
