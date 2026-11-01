-- ForgeNvim entry point. Original code, MIT licensed.
-- Fast path: disable built-in plugins we replace before anything else loads.
local disabled = {
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin", "getscript", "getscriptPlugin",
  "vimball", "vimballPlugin", "2html_plugin", "logipat", "rrhelper",
  "spellfile_plugin", "matchit", "tutor", "tohtml",
}
for _, p in ipairs(disabled) do vim.g["loaded_" .. p] = 1 end
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("forge.config.options")
require("forge.settings")
require("forge.extensions")
require("forge.config.lazy")
require("forge.config.keymaps")
require("forge.config.autocmds")
require("forge.agents")
require("forge.session")
require("forge.palette")
require("forge.sidebar")
require("forge.tabs")
require("forge.images")
require("forge.hscroll")
require("forge.context_menu")
require("forge.winbar")
require("forge.statusline")
require("forge.restart")
require("forge.appearance")
require("forge.diff")
require("forge.health")
require("forge.startup")
