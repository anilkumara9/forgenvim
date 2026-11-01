-- File tree (nvim-tree) configured the ForgeNvim way: it renders inside
-- the sidebar window, names stay plain unless git colours them, the root
-- shows the project folder name only, and a blank line of breathing room
-- sits above the listing.
local M = {}
local function ch(cp) return vim.fn.nr2char(cp) end
function M.root_name(path)
  if type(path) ~= "string" or path == "" then return "" end
  local name = vim.fn.fnamemodify(path:gsub("[\r\n]", ""), ":t")
  if name == "" or name == "/" then name = vim.fn.fnamemodify(path, ":h:t") end
  return name
end
function M.icons()
  local on = require("forge.settings").get().icons
  return {
    show = { file = on, folder = true, folder_arrow = true, git = false },
    padding = { icon = " ", folder_arrow = " " },
    web_devicons = { file = { enable = on, color = on }, folder = { enable = false, color = false } },
    glyphs = { folder = {
      arrow_closed = ">", arrow_open = "v",
      default = ch(0xE5FF), open = ch(0xE5FE), empty = ch(0xF114), empty_open = ch(0xF115),
      symlink = ch(0xF482), symlink_open = ch(0xF482),
    } },
  }
end
local spacing_ns = vim.api.nvim_create_namespace("forge_tree_spacing")
local function keep_top_spacing(buf)
  local function paint()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "NvimTree" then
      pcall(vim.api.nvim_buf_set_extmark, buf, spacing_ns, 0, 0, {
        id = 1, virt_lines = { { { " ", "Normal" } } }, virt_lines_above = true })
    end
  end
  paint()
  if vim.b[buf].forge_spacing_attached then return end
  vim.b[buf].forge_spacing_attached = true
  vim.api.nvim_buf_attach(buf, false, { on_lines = function() vim.schedule(paint) end })
end
function M.setup()
  return {
    on_attach = function(buf)
      local ok, api = pcall(require, "nvim-tree.api")
      if ok and api.config and api.config.mappings then api.config.mappings.default_on_attach(buf) end
      keep_top_spacing(buf)
      vim.wo.wrap = false
      vim.keymap.set("n", "<RightMouse>", function() require("forge.context_menu").open() end,
        { buffer = buf, silent = true, desc = "File tree context menu" })
      vim.keymap.set("n", "<S-F10>", function() require("forge.context_menu").open() end,
        { buffer = buf, silent = true, desc = "File tree context menu" })
    end,
    view = { width = function() return require("forge.sidebar").width() end },
    ui = { confirm = { remove = true } },
    renderer = {
      icons = M.icons(),
      highlight_git = "name",
      highlight_diagnostics = "none",
      highlight_opened_files = "none",
      highlight_modified = "none",
      root_folder_label = M.root_name,
    },
    git = { enable = true, show_on_dirs = true },
    diagnostics = { enable = false },
    modified = { enable = false },
    update_focused_file = { enable = true },
  }
end
function M.open_in(win)
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then return false end
  local cur = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(win)
  local ok2 = pcall(api.tree.open, { current_window = true })
  if vim.api.nvim_win_is_valid(cur) and cur ~= win then vim.api.nvim_set_current_win(cur) end
  return ok2
end
function M.apply_icons()
  local on = require("forge.settings").get().icons
  pcall(function() require("nvim-web-devicons").setup({ default = true, color_icons = on, strict = false }) end)
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then pcall(api.tree.reload) end
end
return M
