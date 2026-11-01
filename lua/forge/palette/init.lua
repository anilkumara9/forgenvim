-- Command palette + pickers, with graceful fallbacks when plugins are absent.
local M = {}
local function has(mod) local ok, m = pcall(require, mod); return ok and type(m) == "table" end
function M.files()
  if has("fzf-lua") then
    local fd_cmd = vim.fn.executable("fd") == 1 and "fd --type f --hidden --exclude .git --exclude node_modules --exclude target --exclude dist --exclude build" or nil
    require("fzf-lua").files({ hidden = true, no_ignore = false, cmd = fd_cmd,
      file_ignore_patterns = { "node_modules/", "%.git/", "dist/", "build/", "target/" },
      actions = { ["default"] = function(selected)
        if not selected or not selected[1] then return end
        local path = require("fzf-lua.path").entry_to_file(selected[1])
        local file = path and (path.path or path.stripped) or selected[1]
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf) == vim.fn.fnamemodify(file, ":p") then
            require("forge.tabs").focus_editor(); vim.api.nvim_set_current_buf(buf); return
          end
        end
        require("forge.tabs").focus_editor(); vim.cmd("edit " .. vim.fn.fnameescape(file))
      end } })
    return
  end
  if has("telescope.builtin") then require("telescope.builtin").find_files() return end
  vim.ui.input({ prompt = "Open file: " }, function(p) if p then vim.cmd.edit(p) end end)
end
function M.grep()
  if has("fzf-lua") then require("fzf-lua").live_grep() return end
  if has("telescope.builtin") then require("telescope.builtin").live_grep() return end
  vim.cmd("grep ")
end
local actions = {
  { "Find file", function() M.files() end },
  { "Search project text", function() M.grep() end },
  { "Save file", function() require("forge.tabs").save() end },
  { "Format current file", function() require("conform").format({ async = true, lsp_format = "fallback" }) end },
  { "Open image", function() vim.cmd("ImageOpen") end },
  { "Show diagnostics", function() vim.cmd("Trouble diagnostics toggle") end },
  { "Git changes", function() vim.cmd("GitChanges") end },
  { "Open Settings", function() vim.cmd("ForgeSettings") end },
  { "Open Extensions", function() vim.cmd("SetupExtensions") end },
  { "Open Themes", function() vim.cmd("SetupThemes") end },
  { "Toggle file icons", function() require("forge.settings").toggle("icons") end },
  { "Toggle line numbers", function() require("forge.settings").toggle("number") end },
  { "Reload settings", function() require("forge.settings").reload() end },
  { "Install extension", function() require("forge.sidebar").set_mode("extensions", true) end },
  { "Restart Neovim", function() vim.cmd("ForgeRestart") end },
  -- ForgeNvim extras
  { "File explorer (20%)", function() vim.cmd("ForgeSidebar") end },
  { "Git diff view", function() vim.cmd("DiffviewOpen") end },
  { "New AI chat", function() vim.cmd("ForgeAgentSelect") end },
  { "Tools (Mason)", function() vim.cmd("Mason") end },
  { "Run nearest test", function() require("neotest").run.run() end },
  { "Run task (Overseer)", function() vim.cmd("OverseerRun") end },
  { "Project search and replace", function() vim.cmd("GrugFar") end },
  { "Code outline", function() vim.cmd("AerialToggle! right") end },
  { "Health check", function() vim.cmd("ForgeHealth") end },
  { "Lazygit", function() if Snacks then Snacks.lazygit() end end },
}
function M.open()
  vim.ui.select(actions, { prompt = "Command Palette", format_item = function(a) return a[1] end },
    function(choice) if choice then choice[2]() end end)
end
vim.api.nvim_create_user_command("ForgePalette", M.open, {})
vim.api.nvim_create_user_command("FindProjectFiles", function() M.files() end, {})
vim.api.nvim_create_user_command("FindProjectText", function() M.grep() end, {})
vim.api.nvim_create_user_command("CommandPalette", M.open, {})
vim.api.nvim_create_user_command("ForgeAIInline", function()
  if vim.env.FORGE_AI_INLINE == "1" then vim.cmd("AvanteAsk")
  else vim.notify("Inline AI is opt-in: set FORGE_AI_INLINE=1 (agent pane works without it)", vim.log.levels.INFO) end
end, {})
vim.api.nvim_create_user_command("ForgeRefactor", function()
  vim.ui.select({ "Extract function", "Extract variable", "Inline variable", "Rename (LSP)", "Code action (LSP)" },
    { prompt = "Refactor" }, function(choice)
      if choice == "Rename (LSP)" then vim.lsp.buf.rename()
      elseif choice == "Code action (LSP)" then vim.lsp.buf.code_action()
      elseif choice then local ok, r = pcall(require, "refactoring"); if ok then r.select_refactor() end end
    end)
end, {})
return M
