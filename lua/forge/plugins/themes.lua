-- All theme plugins, lazy-loaded.
return {
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000, config = function()
      require("gruvbox").setup({ transparent_mode = true, terminal_colors = true, inverse = false })
      local id = require("forge.settings").get().theme
      if not pcall(function() require("forge.themes").apply(id) end) then vim.cmd.colorscheme("gruvbox") end
  end },
  { "ydkulks/cursor-dark.nvim", lazy = true },
  { "Mofiqul/vscode.nvim", lazy = true },
  { "projekt0n/github-nvim-theme", lazy = true, name = "github-nvim-theme" },
  { "navarasu/onedark.nvim", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "folke/tokyonight.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "gbprod/nord.nvim", lazy = true },
  { "neanias/everforest-nvim", lazy = true },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "bluz71/vim-moonfly-colors", lazy = true, name = "moonfly" },
  { "sainnhe/gruvbox-material", lazy = true },
}
