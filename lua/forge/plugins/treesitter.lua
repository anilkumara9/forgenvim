return {
  { "nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate", event = { "BufReadPost", "BufNewFile" },
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter"); if not ok then return end
      -- The main-branch API requires an explicit setup() before install()
      -- works at all; without it install() dies inside their config module.
      pcall(ts.setup, {})
      local parsers = { "bash","c","cpp","css","csv","dart","diff","dockerfile","elixir","gitignore","go","gomod","graphql",
        "haskell","html","java","javascript","json","kotlin","lua","luadoc","make","markdown","markdown_inline",
        "php","python","query","regex","ruby","rust","scala","scss","solidity","sql","svelte","swift","terraform","toml",
        "tsx","typescript","vim","vimdoc","vue","xml","yaml","zig","zsh" }
      if ts.install then pcall(ts.install, parsers) end
      vim.api.nvim_create_autocmd("FileType", { callback = function(ev) pcall(vim.treesitter.start, ev.buf) end })
    end },
  { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" }, event = "VeryLazy",
    config = function()
      local ok, to = pcall(require, "nvim-treesitter-textobjects"); if not ok then return end
      pcall(to.setup, { select = { lookahead = true } })
      local sel = require("nvim-treesitter-textobjects.select")
      local function xmap(lhs, cap, desc)
        vim.keymap.set({ "x", "o" }, lhs, function() sel.select_textobject(cap, "textobjects") end, { desc = desc })
      end
      xmap("af", "@function.outer", "Select outer function")
      xmap("if", "@function.inner", "Select inner function")
      xmap("ac", "@class.outer", "Select outer class")
      xmap("ic", "@class.inner", "Select inner class")
      xmap("aa", "@parameter.outer", "Select outer parameter")
      xmap("ia", "@parameter.inner", "Select inner parameter")
    end },
  { "windwp/nvim-ts-autotag", ft = { "html","javascriptreact","typescriptreact","vue","svelte","xml" }, opts = {} },
}
