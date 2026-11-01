return {
  { "lewis6991/gitsigns.nvim", event = { "BufReadPost", "BufNewFile" }, opts = { current_line_blame = true, current_line_blame_opts = { delay = 700 },
      signs = { add = { text = "+" }, change = { text = "~" }, delete = { text = "-" }, topdelete = { text = "-" }, changedelete = { text = "~" } } } },
  { "tpope/vim-fugitive", cmd = { "Git", "Gdiffsplit", "Gblame" } },
  { "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewFileHistory" }, opts = {} },
  { "NeogitOrg/neogit", cmd = "Neogit", dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim", "ibhagwan/fzf-lua" }, opts = { integrations = { diffview = true, fzf_lua = true } } },
}
