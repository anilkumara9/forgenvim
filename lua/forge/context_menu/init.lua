-- Context menu: right-click and Shift+F10 open an action menu for the thing
-- under focus (file, git item, editor tab or chat).
local M = {}
function M.current()
  local buf = vim.api.nvim_get_current_buf()
  local items = {}
  local function add(label, fn) items[#items+1] = { label = label, fn = fn } end
  local in_panel = vim.b[buf].forge_sidebar or vim.bo[buf].filetype == "NvimTree"
  if in_panel then
    add("Open Files view", function() require("forge.sidebar").set_mode("files", true) end)
    add("Open Git view", function() require("forge.sidebar").set_mode("git", true) end)
    add("Refresh view", function() local m = require("forge.sidebar").mode; require("forge.sidebar").set_mode(m, true) end)
    add("New file or folder", function()
      vim.ui.input({ prompt = "New file path: " }, function(p)
        if p and p ~= "" then require("forge.tabs").focus_editor(); vim.cmd("edit " .. vim.fn.fnameescape(p)) end
      end) end)
    add("Copy relative path", function()
      local line = vim.api.nvim_get_current_line():gsub("^%s+", ""):gsub("%s+$", "")
      vim.fn.setreg("+", line); vim.notify("Copied " .. line)
    end)
    add("Rename file under cursor", function()
      local line = vim.api.nvim_get_current_line():match("([%w%._%-%/]+%.?%w*)$") or ""
      vim.ui.input({ prompt = "Rename to: ", default = line }, function(p)
        if p and p ~= "" and line ~= "" then vim.fn.system({ "git", "mv", line, p }); if vim.v.shell_error ~= 0 then vim.fn.rename(line, p) end end
      end) end)
    add("Delete file under cursor", function()
      local line = vim.api.nvim_get_current_line():match("([%w%._%-%/]+%.?%w*)$") or ""
      if line ~= "" and vim.fn.confirm("Delete " .. line .. "?", "&Yes\n&No", 2) == 1 then vim.fn.delete(line) end
    end)
  end
  if vim.b[buf].chat_id then
    add("New chat", function() require("forge.agents").select() end)
    add("Close this chat", function() require("forge.agents").close(vim.b[buf].chat_id) end)
  else
    add("Save", function() require("forge.tabs").save() end)
    add("Close tab", function() require("forge.tabs").close() end)
    add("Close other editor tabs", function()
      local cur = vim.api.nvim_get_current_buf()
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if b ~= cur and vim.bo[b].buflisted and vim.bo[b].buftype == "" and not vim.bo[b].modified then
          pcall(vim.api.nvim_buf_delete, b, { force = false })
        end
      end
    end)
    add("Copy file path", function()
      local n = vim.api.nvim_buf_get_name(buf)
      vim.fn.setreg("+", vim.fn.fnamemodify(n, ":~:.")); vim.notify("Copied path")
    end)
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
