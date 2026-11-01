-- Inline AI is opt-in (FORGE_AI_INLINE=1) so the default install stays fast and
-- key-free; the agent pane (forge.agents) is always available.
return {
  { "yetone/avante.nvim", enabled = vim.env.FORGE_AI_INLINE == "1", event = "VeryLazy", build = "make",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons", "MeanderingProgrammer/render-markdown.nvim" },
    opts = { provider = "claude", auto_suggestions_provider = "claude" } },
  { "olimorris/codecompanion.nvim", enabled = vim.env.FORGE_AI_INLINE == "1", event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" }, opts = {} },
  { "mistweaverco/kulala.nvim", ft = { "http", "rest" }, opts = { global_keymaps = true } },
  { "kristijanhusak/vim-dadbod-ui", dependencies = { "tpope/vim-dadbod", "kristijanhusak/vim-dadbod-completion" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" } },
  { "folke/snacks.nvim", priority = 1000, lazy = false,
    opts = { bigfile = { enabled = true }, quickfile = { enabled = true }, notifier = { enabled = true },
      dashboard = { enabled = false }, -- ForgeNvim starts straight into the workspace layout
      explorer = { enabled = false }, picker = { enabled = true }, terminal = { enabled = true },
      lazygit = { enabled = true }, indent = { enabled = false }, scroll = { enabled = true },
      statuscolumn = { enabled = true }, words = { enabled = true } },
    keys = { { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
             { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" } } },
}
