return {
  { "nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate", event = { "BufReadPost", "BufNewFile" },
    config = function()
      local parsers = { "bash","c","cpp","css","csv","dart","diff","dockerfile","elixir","gitignore","go","gomod","graphql",
        "haskell","html","java","javascript","json","jsonc","kotlin","lua","luadoc","make","markdown","markdown_inline",
        "php","python","query","regex","ruby","rust","scala","scss","solidity","sql","svelte","swift","terraform","toml",
        "tsx","typescript","vim","vimdoc","vue","xml","yaml","zig","zsh" }
      local ok, ts = pcall(require, "nvim-treesitter"); if ok and ts.install then pcall(ts.install, parsers) end
      vim.api.nvim_create_autocmd("FileType", { callback = function(ev) pcall(vim.treesitter.start, ev.buf) end })
    end },
  { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main", dependencies = { "nvim-treesitter/nvim-treesitter" }, event = "VeryLazy" },
  { "windwp/nvim-ts-autotag", ft = { "html","javascriptreact","typescriptreact","vue","svelte","xml" }, opts = {} },
}
