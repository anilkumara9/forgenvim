-- Command palette + pickers, with graceful fallbacks when plugins are absent.
local M = {}
local function has(mod) return pcall(require, mod) end
function M.files()
  if has("fzf-lua") then require("fzf-lua").files() return end
  if has("telescope.builtin") then require("telescope.builtin").find_files() return end
  vim.ui.input({ prompt = "Open file: " }, function(p) if p then vim.cmd.edit(p) end end)
end
function M.grep()
  if has("fzf-lua") then require("fzf-lua").live_grep() return end
  if has("telescope.builtin") then require("telescope.builtin").live_grep() return end
  vim.cmd("grep ")
end
local actions = {
  { "Find files", function() M.files() end }, { "Search project text", function() M.grep() end },
  { "Sidebar panel (20%)", function() vim.cmd("ForgeSidebar") end },
  { "Git status", function() vim.cmd("Neogit") end }, { "Git diff view", function() vim.cmd("DiffviewOpen") end },
  { "New AI chat", function() vim.cmd("ForgeAgentSelect") end },
  { "Settings", function() vim.cmd("ForgeSettings") end }, { "Themes", function() vim.cmd("ForgeThemes") end },
  { "Extensions (Lazy)", function() vim.cmd("Lazy") end }, { "Tools (Mason)", function() vim.cmd("Mason") end },
  { "Format buffer", function() require("conform").format({ async = true }) end },
  { "Run nearest test", function() require("neotest").run.run() end },
  { "Run task (Overseer)", function() vim.cmd("OverseerRun") end },
  { "Project search and replace", function() vim.cmd("GrugFar") end },
  { "Code outline", function() vim.cmd("AerialToggle! right") end },
  { "Diagnostics", function() vim.cmd("Trouble diagnostics toggle") end },
  { "Health check", function() vim.cmd("ForgeHealth") end },
  { "Lazygit", function() if Snacks then Snacks.lazygit() end end },
}
function M.open()
  vim.ui.select(actions, { prompt = "Command Palette", format_item = function(a) return a[1] end },
    function(choice) if choice then choice[2]() end end)
end
vim.api.nvim_create_user_command("ForgePalette", M.open, {})
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
