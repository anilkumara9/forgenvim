-- LSP: 32 servers preconfigured. Neovim 0.11+ native config API.
return {
  { "mason-org/mason.nvim", cmd = "Mason", build = ":MasonUpdate", opts = { ui = { border = "rounded" } } },
  {
    "mason-org/mason-lspconfig.nvim", event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      local servers = {
        -- web, systems and Lua core
        "vtsls","vue_ls","svelte","html","cssls","tailwindcss","eslint","rust_analyzer","gopls",
        "solidity_ls_nomicfoundation","taplo","jsonls","yamlls","lua_ls",
        -- data, infra and more languages
        "pyright","ruff","clangd","bashls","dockerls","docker_compose_language_service","marksman",
        "phpactor","ruby_lsp","zls","kotlin_language_server","sqlls","terraformls","ansiblels",
        "elixirls","hls","ocamllsp","nim_langserver",
      }
      require("mason-lspconfig").setup({ ensure_installed = servers, automatic_enable = true })
      local caps = vim.lsp.protocol.make_client_capabilities()
      caps.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
      local ok, blink = pcall(require, "blink.cmp"); if ok then caps = blink.get_lsp_capabilities(caps) end
      vim.lsp.config("*", { capabilities = caps })
      vim.lsp.config("vtsls", { settings = { typescript = { inlayHints = { parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true }, variableTypes = { enabled = true } } } } })
      vim.lsp.config("pyright", { settings = { python = { analysis = { typeCheckingMode = "basic", autoImportCompletions = true } } } })
      vim.lsp.config("rust_analyzer", { settings = { ["rust-analyzer"] = { check = { command = "clippy" }, cargo = { allFeatures = true } } } })
      vim.lsp.config("gopls", { settings = { gopls = { gofumpt = true, staticcheck = true, analyses = { unusedparams = true } } } })
      vim.lsp.config("clangd", { cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" } })
      vim.lsp.config("lua_ls", { settings = { Lua = { runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false }, telemetry = { enable = false } } } })
      vim.lsp.config("jsonls", { settings = { json = { validate = { enable = true } } } })
      vim.lsp.config("yamlls", { settings = { yaml = { keyOrdering = false } } })
      vim.diagnostic.config({ virtual_text = { spacing = 2 }, severity_sort = true,
        float = { border = "rounded" }, signs = { text = { [vim.diagnostic.severity.ERROR] = "E",
        [vim.diagnostic.severity.WARN] = "W", [vim.diagnostic.severity.INFO] = "I", [vim.diagnostic.severity.HINT] = "H" } } })
      vim.api.nvim_create_autocmd("LspAttach", { callback = function(ev)
        local function m(k, f, d) vim.keymap.set("n", k, f, { buffer = ev.buf, desc = d }) end
        m("gd", vim.lsp.buf.definition, "Go to definition"); m("gD", vim.lsp.buf.declaration, "Declaration")
        m("gr", vim.lsp.buf.references, "References"); m("gi", vim.lsp.buf.implementation, "Implementation")
        m("gy", vim.lsp.buf.type_definition, "Type definition"); m("K", vim.lsp.buf.hover, "Documentation")
        m("<leader>rn", vim.lsp.buf.rename, "Rename"); m("<leader>ca", vim.lsp.buf.code_action, "Code action")
        m("<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
        m("<leader>ih", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf }) end, "Toggle inlay hints")
        vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = ev.buf, desc = "Signature help" })
      end })
    end,
  },
  { "folke/lazydev.nvim", ft = "lua", opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } } },
}
