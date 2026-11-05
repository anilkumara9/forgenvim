-- Context menu: right-click and Shift+F10 open a small floating menu for
-- the thing under the cursor (file, git item, editor tab or chat), with
-- the same entries the reference menu offers in each place. Enter or a
-- click runs the entry; Esc or q closes.
local M = {}

function M.show(items)
  if #items == 0 then return end
  local width = 0
  for _, it in ipairs(items) do width = math.max(width, #it.label) end
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  for i, it in ipairs(items) do lines[i] = " " .. it.label end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor", row = 1, col = 0, width = width + 2, height = #items,
    style = "minimal", border = "single", zindex = 80,
  })
  vim.wo[win].cursorline = true
  local function close() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end
  local function choose()
    local idx = vim.api.nvim_win_get_cursor(win)[1]
    local it = items[idx]
    close()
    if it and it.fn then it.fn() end
  end
  vim.keymap.set("n", "<CR>", choose, { buffer = buf })
  vim.keymap.set("n", "<LeftMouse>", function()
    local pos = vim.fn.getmousepos()
    if pos.winid == win then vim.api.nvim_win_set_cursor(win, { pos.line, 0 }); choose() else close() end
  end, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })
  return win
end

local function item(label, fn) return { label = label, fn = fn } end

-- File tree ------------------------------------------------------------
function M.tree()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then return end
  local node = api.tree.get_node_under_cursor()
  local items = {}
  if node and node.type == "file" then
    items = {
      item("Open file", function() api.node.open.edit() end),
      item("Open in new editor tab", function() api.node.open.tab() end),
      item("Copy relative path", function() api.fs.copy.relative_path() end),
      item("Rename", function() api.fs.rename() end),
      item("Delete", function() api.fs.remove() end),
      item("New file or folder", function() api.fs.create() end),
      item("Refresh tree", function() api.tree.reload() end),
    }
  elseif node then
    items = {
      item("Expand / collapse", function() api.node.open.edit() end),
      item("Copy relative path", function() api.fs.copy.relative_path() end),
      item("Rename", function() api.fs.rename() end),
      item("Delete", function() api.fs.remove() end),
      item("New file or folder", function() api.fs.create() end),
      item("Refresh tree", function() api.tree.reload() end),
    }
  else
    items = {
      item("New file or folder", function() api.fs.create() end),
      item("Refresh tree", function() api.tree.reload() end),
    }
  end
  M.show(items)
end

-- Editor tab ------------------------------------------------------------
function M.editor_tab(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local items = { item("Focus tab", function() require("forge.tabs").focus_editor() end) }
  local name = vim.api.nvim_buf_get_name(buf)
  if name ~= "" then
    items[#items + 1] = item("Copy file path", function()
      vim.fn.setreg("+", vim.fn.fnamemodify(name, ":~:."))
      vim.notify("Copied path")
    end)
  end
  items[#items + 1] = item("Close tab", function() require("forge.tabs").close() end)
  items[#items + 1] = item("Close other editor tabs", function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= buf and vim.bo[b].buflisted and vim.bo[b].buftype == "" and not vim.bo[b].modified then
        pcall(vim.api.nvim_buf_delete, b, { force = false })
      end
    end
  end)
  M.show(items)
end

-- Chat tab ---------------------------------------------------------------
function M.chat_tab(chat_id)
  M.show({
    item("Focus chat", function() require("forge.agents").show(chat_id) end),
    item("Close chat", function() require("forge.agents").close(chat_id) end),
  })
end

-- Sidebar view tab ---------------------------------------------------------
function M.sidebar_tab(view)
  M.show({
    item("Open " .. view, function() require("forge.sidebar").set_mode(view, true) end),
    item("Refresh " .. view, function() require("forge.sidebar").set_mode(view, true) end),
  })
end

-- Dispatch -----------------------------------------------------------------
function M.current()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "NvimTree" then M.tree(); return end
  if vim.b[buf].chat_id then M.chat_tab(vim.b[buf].chat_id); return end
  local ok, sb = pcall(require, "forge.sidebar")
  if ok and sb.in_git_context and sb.in_git_context() then sb.context_menu(); return end
  if vim.b[buf].forge_sidebar then M.sidebar_tab(sb.mode or "files"); return end
  M.editor_tab(buf)
end
M.open = M.current
vim.api.nvim_create_user_command("ContextMenu", M.current, {})
vim.api.nvim_create_user_command("ForgeContextMenu", M.current, {})
vim.keymap.set("n", "<S-F10>", "<Cmd>ContextMenu<CR>", { desc = "Context menu" })
vim.keymap.set("n", "<RightMouse>", "<Cmd>ContextMenu<CR>", { desc = "Context menu" })
return M
