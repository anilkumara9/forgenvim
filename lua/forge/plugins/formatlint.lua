return {
  { "stevearc/conform.nvim", event = { "BufWritePre" }, cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        javascript = { "prettierd" }, typescript = { "prettierd" }, javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" }, vue = { "prettierd" }, svelte = { "prettierd" }, html = { "prettierd" },
        css = { "prettierd" }, scss = { "prettierd" }, less = { "prettierd" }, json = { "prettierd" },
        jsonc = { "prettierd" }, yaml = { "prettierd" }, markdown = { "prettierd" }, graphql = { "prettierd" },
        lua = { "stylua" }, toml = { "taplo" }, rust = { "rustfmt" }, go = { "gofumpt", "goimports" },
        sh = { "shfmt" }, bash = { "shfmt" }, zsh = { "shfmt" },
        -- Forge scale-up
        python = { "ruff_fix", "ruff_format" }, c = { "clang_format" }, cpp = { "clang_format" },
        java = { "google-java-format" }, kotlin = { "ktlint" }, php = { "pint" }, ruby = { "rubocop" },
        sql = { "sqlfmt" }, terraform = { "terraform_fmt" }, zig = { "zigfmt" }, elixir = { "mix" },
      },
      formatters = { shfmt = { prepend_args = { "-i", "2", "-ci" } } },
      -- No format_on_save: formatting is on demand only (Space f or the
      -- palette), matching the reference behaviour.
    } },
  { "mfussenegger/nvim-lint", event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = { python = { "ruff" }, javascript = { "eslint_d" }, typescript = { "eslint_d" },
        go = { "golangcilint" }, lua = { "luacheck" }, dockerfile = { "hadolint" }, terraform = { "tflint" },
        php = { "phpstan" }, ruby = { "rubocop" }, sh = { "shellcheck" }, markdown = { "markdownlint" } }
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" },
        { callback = function() pcall(lint.try_lint, nil, { ignore_errors = true }) end })
    end },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", dependencies = { "mason-org/mason.nvim" },
    event = { "BufReadPre", "BufNewFile" }, cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
    opts = { ensure_installed = { "prettierd","stylua","shfmt","ruff","debugpy","codelldb","js-debug-adapter",
      "delve","gofumpt","goimports","clang-format","shellcheck","eslint_d","luacheck","tree-sitter-cli" }, auto_update = false,
      run_on_start = true } },
}
