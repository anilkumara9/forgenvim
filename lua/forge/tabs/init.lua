-- Pane tab context: Ctrl+T / Ctrl+W act on the *focused pane*
-- (editor tab, or chat tab when a chat is focused). Ctrl+S saves and
-- asks for a name when the buffer is unnamed.
local M = {}
local function current_chat()
  local buf = vim.api.nvim_get_current_buf()
  return vim.b[buf].chat_id
end
function M.new_context()
  if current_chat() then require("forge.agents").select()
  else vim.cmd("enew") end
end
function M.close()
  local id = current_chat()
  if id then require("forge.agents").close(id); return end
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    vim.notify("Unsaved changes - save first (Ctrl+S), tab not closed", vim.log.levels.WARN)
    return
  end
  require("forge.util").bufdelete()
end
function M.save()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype == "terminal" then return end
  if vim.api.nvim_buf_get_name(buf) == "" then
    vim.ui.input({ prompt = "Save as: ", completion = "file" }, function(name)
      if name and name ~= "" then vim.cmd("write " .. vim.fn.fnameescape(name)) end
    end)
  else vim.cmd("write") end
end
function M.focus_editor()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" and not vim.b[buf].chat_id then
      vim.api.nvim_set_current_win(win); return win
    end
  end
end
vim.api.nvim_create_user_command("ProjectCloseTab", M.close, {})
vim.api.nvim_create_user_command("PaneNewTab", M.new_context, {})
vim.api.nvim_create_user_command("PaneSave", M.save, {})
for _, mode in ipairs({ "n", "i" }) do
  vim.keymap.set(mode, "<C-t>", "<Cmd>PaneNewTab<CR>", { desc = "New tab in focused pane" })
  vim.keymap.set(mode, "<C-w>", "<Cmd>ProjectCloseTab<CR>", { desc = "Close tab in focused pane" })
  vim.keymap.set(mode, "<C-s>", "<Cmd>PaneSave<CR>", { desc = "Save (asks for a name if unnamed)" })
end
vim.keymap.set("t", "<C-t>", "<C-\\><C-n><Cmd>PaneNewTab<CR>", { desc = "New chat tab" })
vim.keymap.set("t", "<C-w>", "<C-\\><C-n><Cmd>ProjectCloseTab<CR>", { desc = "Close chat tab" })
vim.keymap.set("t", "<C-s>", "<C-\\><C-n><Cmd>PaneSave<CR>", { desc = "Save editor file" })
vim.keymap.set("t", "<C-q>", "<C-\\><C-n><Cmd>ForgeQuit<CR>", { desc = "Quit, persisting session" })
-- macOS Cmd+P
vim.keymap.set({ "n", "i" }, "<D-p>", function() require("forge.palette").files() end, { desc = "Find project files" })
return M
