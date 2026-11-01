-- Completion: blink.cmp (Rust core, an order of magnitude faster than any
-- classic cmp setup) + LuaSnip + friendly-snippets. Copilot is opt-in.
return {
  { "L3MON4D3/LuaSnip", build = "make install_jsregexp", dependencies = { "rafamadriz/friendly-snippets" },
    config = function() require("luasnip.loaders.from_vscode").lazy_load() end },
  { "saghen/blink.cmp", version = "*", event = "InsertEnter", dependencies = { "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default", ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" }, ["<CR>"] = { "accept", "fallback" } },
      appearance = { use_nvim_cmp_as_default = false, nerd_font_variant = "mono" },
      snippets = { preset = "luasnip" },
      sources = { default = { "lsp", "path", "snippets", "buffer" },
        providers = { buffer = { min_keyword_length = 3 } } },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true }, menu = { border = "rounded" } },
      signature = { enabled = true, window = { border = "rounded" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    } },
  { "zbirenbaum/copilot.lua", enabled = vim.env.FORGE_COPILOT == "1", cmd = "Copilot", event = "InsertEnter",
    opts = { suggestion = { enabled = true, auto_trigger = true, keymap = { accept = "<M-l>", next = "<M-]>", prev = "<M-[>" } }, panel = { enabled = false } } },
}
