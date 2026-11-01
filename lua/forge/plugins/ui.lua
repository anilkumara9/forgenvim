-- UI: layout -- left sidebar 20%, editor centre, AI pane 28% right,
-- one global status strip at the bottom, clickable tabs on top.
return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    opts = {
      close_if_last_window = false, popup_border_style = "rounded",
      filesystem = { follow_current_file = { enabled = true }, use_libuv_file_watcher = true,
        window = { width = function() return math.max(24, math.floor(vim.o.columns * 0.20)) end } },
      git_status = { window = { width = function() return math.max(24, math.floor(vim.o.columns * 0.20)) end } },
      default_component_configs = { indent = { with_expanders = true }, git_status = { symbols = {
        added = "+", modified = "~", deleted = "x", renamed = "r", untracked = "?", ignored = "/", unstaged = "u", staged = "s", conflict = "!" } } },
      window = { mappings = { ["<space>"] = "none" } },
    },
  },
  { "folke/noice.nvim", event = "VeryLazy", dependencies = { "MunifTanjim/nui.nvim" },
    opts = { lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true } },
      presets = { bottom_search = true, command_palette = true, long_message_to_split = true } } },
  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "helix" },
    config = function(_, opts) local wk = require("which-key"); wk.setup(opts)
      wk.add({ { "<leader>a", group = "AI agents" }, { "<leader>g", group = "git" }, { "<leader>f", group = "find/format" },
        { "<leader>t", group = "test/tasks" }, { "<leader>d", group = "debug" }, { "<leader>x", group = "diagnostics" },
        { "<leader>u", group = "UI" }, { "<leader>h", group = "hunks/harpoon" }, { "<leader>s", group = "search" } }) end },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", event = { "BufReadPost", "BufNewFile" }, opts = { indent = { char = "▏" }, scope = { enabled = true } } },
  { "kevinhwang91/nvim-ufo", dependencies = { "kevinhwang91/promise-async" }, event = "BufReadPost",
    config = function() vim.o.foldcolumn = "1"; require("ufo").setup({ provider_selector = function() return { "treesitter", "indent" } end }) end },
  { "folke/trouble.nvim", cmd = "Trouble", opts = { focus = true } },
  { "folke/todo-comments.nvim", event = { "BufReadPost", "BufNewFile" }, opts = {} },
}
