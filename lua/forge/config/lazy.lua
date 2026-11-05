-- lazy.nvim bootstrap + spec import. Plugin versions are pinned by the
-- lazy-lock.json shipped in this repo (the exact set the release was
-- tested with); :Lazy update deliberately moves past it. FORGE_MINIMAL=1
-- skips plugins entirely so CI and the validator can load the core with
-- zero network.
if vim.env.FORGE_MINIMAL == "1" then return end
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
  if vim.v.shell_error ~= 0 then
    vim.notify("ForgeNvim: failed to clone lazy.nvim\n" .. out, vim.log.levels.ERROR)
    return
  end
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  spec = { { import = "forge.plugins" }, require("forge.extensions").specs() },
  defaults = { lazy = true, version = false },
  install = { colorscheme = { "gruvbox", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
  rocks = { enabled = false },
  performance = {
    cache = { enabled = true },
    rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" } },
  },
  ui = { border = "rounded" },
})
