return {
  { "nvim-neotest/neotest", cmd = { "Neotest" }, dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter", "nvim-neotest/neotest-python", "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-jest", "rouge8/neotest-rust", "fredrikaverpil/neotest-golang" },
    config = function()
      require("neotest").setup({ adapters = {
        require("neotest-python")({ dap = { justMyCode = false } }),
        require("neotest-go")({}), require("neotest-golang")({}),
        require("neotest-jest")({ jestCommand = "npm test --" }),
        require("neotest-rust")({ args = { "--no-capture" } }),
      }, status = { virtual_text = true }, output = { open_on_run = "short" } })
    end },
  { "stevearc/overseer.nvim", cmd = { "OverseerRun", "OverseerToggle" }, opts = { templates = { "builtin" } } },
  { "folke/persistence.nvim", event = "BufReadPre", opts = { need = 1 },
    keys = { { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
             { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
             { "<leader>qd", function() require("persistence"). stop() end, desc = "Stop session recording" } } },
}
