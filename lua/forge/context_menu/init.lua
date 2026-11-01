-- Context menu: right-click and Shift+F10 open an action menu for the thing
-- under focus (file, git item, editor tab or chat).
local M = {}
function M.current()
  local buf = vim.api.nvim_get_current_buf()
  local items = {}
  local function add(label, fn) items[#items+1] = { label = label, fn = fn } end
  if vim.b[buf].chat_id then
    add("New chat", function() require("forge.agents").select() end)
    add("Close this chat", function() require("forge.agents").close(vim.b[buf].chat_id) end)
  else
    add("Save", function() require("forge.tabs").save() end)
    add("Close tab", function() require("forge.tabs").close() end)
    add("Find files", function() require("forge.palette").files() end)
    add("Format", function() require("conform").format({ async = true }) end)
    add("Git status", function() vim.cmd("Git") end)
    add("Git diff (file)", function() vim.cmd("Gdiffsplit") end)
    add("Stage hunk", function() local ok, g = pcall(require, "gitsigns"); if ok then g.stage_hunk() end end)
    add("Code outline", function() vim.cmd("AerialToggle! right") end)
    add("Split below", function() vim.cmd("split") end)
    add("Split right", function() vim.cmd("vsplit") end)
  end
  add("Command palette", function() require("forge.palette").open() end)
  add("Settings", function() vim.cmd("ForgeSettings") end)
  local labels = {}; for _, i in ipairs(items) do labels[#labels+1] = i.label end
  vim.ui.select(labels, { prompt = "Context menu" }, function(choice)
    for _, i in ipairs(items) do if i.label == choice then i.fn() end end
  end)
end
vim.api.nvim_create_user_command("ContextMenu", M.current, {})
vim.api.nvim_create_user_command("ForgeContextMenu", M.current, {})
vim.keymap.set("n", "<S-F10>", "<Cmd>ContextMenu<CR>", { desc = "Context menu" })
vim.keymap.set("n", "<RightMouse>", "<Cmd>ContextMenu<CR>", { desc = "Context menu" })
return M
