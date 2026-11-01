-- Check Diff: a read-only diff for one file, opened in the editor pane.
-- Staged entries compare index with HEAD; unstaged compare worktree with
-- index; untracked and deleted files get a content preview. Closing the
-- diff restores the editor tab that was there before.
local M = { prev = nil, is_open = false }
local function git_out(root, args)
  local out = vim.fn.system(vim.list_extend({ "git", "-C", root }, args))
  return vim.v.shell_error == 0 and out or ""
end
function M.open(root, entry)
  if not entry or not entry.path then return end
  local content
  local xy = entry.xy or ""
  if entry.untracked or xy:find("?", 1, true) then
    local abs = root .. "/" .. entry.path
    content = "Untracked file preview: " .. entry.path .. "\n\n" .. table.concat(vim.fn.readfile(abs), "\n")
  elseif xy:find("D", 1, true) then
    content = git_out(root, { "show", "HEAD:" .. entry.path })
    if content == "" then content = "(no HEAD version)" end
  elseif entry.staged then
    content = git_out(root, { "diff", "--cached", "--", entry.path })
  else
    content = git_out(root, { "diff", "--", entry.path })
  end
  if not content or vim.trim(content) == "" then
    vim.notify("No diff for " .. entry.path .. " (save the file first if it has unsaved changes)", vim.log.levels.WARN)
    return
  end
  local win = require("forge.tabs").focus_editor()
  if not win then return end
  M.is_open = true
  M.prev = vim.api.nvim_win_get_buf(win)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"; vim.bo[buf].filetype = "diff"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, "forge://diff/" .. entry.path)
  vim.api.nvim_win_set_buf(win, buf)
  vim.keymap.set("n", "q", function() M.close() end, { buffer = buf })
end
function M.close()
  M.is_open = false
  local win = require("forge.tabs").focus_editor()
  if win and M.prev and vim.api.nvim_buf_is_valid(M.prev) then
    vim.api.nvim_win_set_buf(win, M.prev)
  end
  M.prev = nil
end
vim.api.nvim_create_user_command("ForgeDiffClose", M.close, {})
return M
