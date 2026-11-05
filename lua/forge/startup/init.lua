-- Startup layout: sidebar opens at 20%,
-- focus stays in the editor, the project session (files + chats) restores, or
-- two default chats start (Codex visible, Cursor running behind it).
local M = {}; local opened = false
function M.is_open() return opened end
function M.open()
  if opened then return end; opened = true
  local dir = vim.fn.argv(0)
  if type(dir) == "string" and vim.fn.isdirectory(dir) == 1 then vim.cmd.cd(vim.fn.fnameescape(vim.fn.fnamemodify(dir, ":p"))) end
  pcall(function() require("forge.sidebar").set_mode("files", false) end)
  local editor = vim.api.nvim_get_current_win()
  local session = require("forge.session")
  local restored = false
  if require("forge.settings").get().session_restore and not session.clean then restored = session.restore() end
  if not restored and vim.env.FORGE_NO_DEFAULT_AGENTS ~= "1" then
    local agents = require("forge.agents")
    local first = agents.new("codex"); agents.new("cursor")
    if first then agents.show(first) end
  end
  if vim.api.nvim_win_is_valid(editor) then vim.api.nvim_set_current_win(editor) end
  vim.cmd.stopinsert()
end
vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function()
  if #vim.api.nvim_list_uis() > 0 then vim.schedule(M.open) end
end })
return M
