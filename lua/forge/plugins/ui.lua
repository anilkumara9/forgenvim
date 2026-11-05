-- UI: layout -- left sidebar 20%, editor centre, AI pane 28% right,
-- one global status strip at the bottom, clickable tabs on top.
return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },
  { "nvim-lua/plenary.nvim", lazy = true },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require("nvim-tree").setup(require("forge.tree").setup()) end },
  { "folke/noice.nvim", event = "VeryLazy", dependencies = { "MunifTanjim/nui.nvim" },
    opts = { lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true } },
      presets = { bottom_search = true, command_palette = true, long_message_to_split = true } } },
  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "helix", icons = { mappings = false } },
    config = function(_, opts) local wk = require("which-key"); wk.setup(opts)
      wk.add({ { "<leader>a", group = "AI agents" }, { "<leader>g", group = "git" }, { "<leader>f", group = "find/format" },
        { "<leader>t", group = "test/tasks" }, { "<leader>d", group = "debug" }, { "<leader>x", group = "diagnostics" },
        { "<leader>u", group = "UI" }, { "<leader>h", group = "hunks/harpoon" }, { "<leader>s", group = "search" } }) end },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", event = { "BufReadPost", "BufNewFile" }, opts = { indent = { char = "▏" }, scope = { enabled = true } } },
  { "kevinhwang91/nvim-ufo", dependencies = { "kevinhwang91/promise-async" }, event = "BufReadPost",
    config = function() vim.o.foldcolumn = "1"; require("ufo").setup({ provider_selector = function() return { "treesitter", "indent" } end }) end },
  { "folke/trouble.nvim", cmd = "Trouble", opts = { focus = true,
      -- The reference look is a plain, icon-free list. Current trouble.nvim
      -- crashes on icons=false (its renderer indexes icons.indent), so the
      -- same look is expressed with blank glyphs in a complete table.
      icons = {
        indent = { top = "  ", middle = "  ", last = "  ", fold_open = "v ", fold_closed = "> ", ws = "  " },
        folder_closed = "", folder_open = "",
        kinds = { Array = "", Boolean = "", Class = "", Constant = "", Constructor = "", Enum = "",
          EnumMember = "", Event = "", Field = "", File = "", Function = "", Interface = "", Key = "",
          Method = "", Module = "", Namespace = "", Null = "", Number = "", Object = "", Operator = "",
          Package = "", Property = "", String = "", Struct = "", TypeParameter = "", Variable = "" },
      } } },
  { "mihovilrak/scroll.nvim", lazy = false,
    opts = { enabled = false, visibility = "always", winblend = 55, mouse = true, minimap = false,
      vertical = { enabled = true }, horizontal = { enabled = true },
      explorer = { enabled = true, filetypes = { "NvimTree" }, horizontal = true },
      excluded_filetypes = { "help", "qf", "TelescopePrompt", "lazy", "mason", "git-composer" },
      excluded_buftypes = { "terminal", "prompt", "quickfix" } } },
  { "folke/todo-comments.nvim", event = { "BufReadPost", "BufNewFile" }, opts = {} },
}
