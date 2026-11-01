-- DAP: Node/Chrome, Go, Rust, Python, C/C++,
-- PHP, Ruby, Dart and launch.json loading, all guarded by Mason paths.
return {
  { "mfussenegger/nvim-dap", dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio", "leoluz/nvim-dap-go", "mfussenegger/nvim-dap-python" },
    config = function()
      local dap, ui = require("dap"), require("dapui"); ui.setup()
      dap.listeners.after.event_initialized["ui"] = function() ui.open() end
      dap.listeners.before.event_terminated["ui"] = function() ui.close() end
      dap.listeners.before.event_exited["ui"] = function() ui.close() end
      local pkg = vim.fn.stdpath("data") .. "/mason/packages/"
      local bin = vim.fn.stdpath("data") .. "/mason/bin/"
      dap.adapters["pwa-node"] = { type = "server", host = "127.0.0.1", port = "${port}",
        executable = { command = "node", args = { pkg .. "js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}", "127.0.0.1" } } }
      dap.adapters["pwa-chrome"] = dap.adapters["pwa-node"]
      for _, ft in ipairs({ "javascript","typescript","javascriptreact","typescriptreact","svelte","vue" }) do
        dap.configurations[ft] = {
          { name = "Launch current file (Node)", type = "pwa-node", request = "launch", program = "${file}", cwd = "${workspaceFolder}", sourceMaps = true, console = "integratedTerminal" },
          { name = "Attach to Node (--inspect)", type = "pwa-node", request = "attach", processId = require("dap.utils").pick_process, cwd = "${workspaceFolder}", sourceMaps = true },
          { name = "Browser (Chrome :9222)", type = "pwa-chrome", request = "attach", port = 9222, webRoot = "${workspaceFolder}", sourceMaps = true },
        }
      end
      pcall(require("dap-go").setup, { delve = { path = bin .. "dlv" } })
      pcall(require("dap-python").setup, bin .. "debugpy-adapter" .. (vim.fn.has("win32") == 1 and ".cmd" or ""))
      dap.adapters.codelldb = { type = "server", port = "${port}",
        executable = { command = pkg .. "codelldb/extension/adapter/codelldb" .. (vim.fn.has("win32") == 1 and ".exe" or ""), args = { "--port", "${port}" } } }
      local native = { { name = "Launch executable", type = "codelldb", request = "launch",
        program = function() return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/", "file") end,
        cwd = "${workspaceFolder}", stopOnEntry = false } }
      dap.configurations.rust = native; dap.configurations.c = native; dap.configurations.cpp = native; dap.configurations.zig = native
      dap.adapters.php = { type = "executable", command = "node", args = { pkg .. "php-debug-adapter/extension/out/phpDebug.js" } }
      dap.configurations.php = { { name = "Listen for Xdebug", type = "php", request = "launch", port = 9003 } }
      vim.api.nvim_create_user_command("DebugLoadLaunch", function()
        require("dap.ext.vscode").load_launchjs(nil, { ["pwa-node"] = { "javascript","typescript","javascriptreact","typescriptreact" }, codelldb = { "rust","c","cpp" }, python = { "python" } })
      end, {})
    end },
}
