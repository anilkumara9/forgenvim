-- Settings: defaults, sections and persistence. Stored globally as JSON
-- and applied live.
local M = {}
M.defaults = {
  icons = true, number = true, relativenumber = true, clipboard = true,
  indent = 2, scrolloff = 5, ignorecase = true, smartcase = true,
  transparent = true, scrollbars = false, session_restore = true, theme = "gruvbox",
}
M.options = {
  { section = "Appearance", key = "theme", label = "Color theme", kind = "theme" },
  { section = "Appearance", key = "icons", label = "File icons", kind = "boolean" },
  { section = "Appearance", key = "transparent", label = "Transparent background", kind = "boolean" },
  { section = "Appearance", key = "scrollbars", label = "Scrollbars", kind = "boolean" },
  { section = "Appearance", key = "number", label = "Line numbers", kind = "boolean" },
  { section = "Appearance", key = "relativenumber", label = "Relative line numbers", kind = "boolean" },
  { section = "Editing", key = "indent", label = "Indent width", kind = "choice", values = { 2, 4, 8 } },
  { section = "Editing", key = "scrolloff", label = "Scroll margin", kind = "choice", values = { 0, 3, 5, 8, 10 } },
  { section = "Editing", key = "clipboard", label = "System clipboard", kind = "boolean" },
  { section = "Search", key = "ignorecase", label = "Ignore case", kind = "boolean" },
  { section = "Search", key = "smartcase", label = "Smart case", kind = "boolean" },
  { section = "Sessions", key = "session_restore", label = "Restore project session", kind = "boolean" },
}
local current = vim.deepcopy(M.defaults)
function M.file() return vim.fn.stdpath("state") .. "/forge/settings.json" end
function M.get() return vim.deepcopy(current) end
function M.load()
  local fd = vim.uv.fs_open(M.file(), "r", 384)
  if fd then
    local st = vim.uv.fs_fstat(fd); local raw = st and vim.uv.fs_read(fd, st.size, 0) or ""
    vim.uv.fs_close(fd)
    local ok, data = pcall(vim.json.decode, raw or "")
    if ok and type(data) == "table" then
      for k, v in pairs(M.defaults) do if type(data[k]) == type(v) then current[k] = data[k] end end
    end
  end
  return current
end
function M.save()
  vim.fn.mkdir(vim.fn.fnamemodify(M.file(), ":h"), "p")
  local fd = vim.uv.fs_open(M.file(), "w", 438)
  if not fd then return false end
  vim.uv.fs_write(fd, vim.json.encode(current)); vim.uv.fs_close(fd); return true
end
function M.apply()
  vim.o.number = current.number; vim.o.relativenumber = current.relativenumber
  vim.o.clipboard = current.clipboard and "unnamedplus" or ""
  vim.o.shiftwidth = current.indent; vim.o.tabstop = current.indent
  vim.o.scrolloff = current.scrolloff
  vim.o.ignorecase = current.ignorecase; vim.o.smartcase = current.smartcase
  local ok, appearance = pcall(require, "forge.appearance")
  if ok and appearance.apply_scroll_plugin then pcall(appearance.apply_scroll_plugin) end
end
function M.default(key) return M.defaults[key] end
function M.reset(key) if M.defaults[key] ~= nil then M.set(key, M.defaults[key]) end end
function M.set_silent(key, value) current[key] = value; M.save() end
function M.set(key, value)
  current[key] = value; M.save(); M.apply()
  if key == "icons" then pcall(function() require("forge.tree").apply_icons() end) end
  if key == "theme" then pcall(function() require("forge.themes").apply(value) end) end
  if key == "transparent" then pcall(function() require("forge.appearance").apply_highlights() end) end
end
function M.toggle(key) M.set(key, not current[key]) end
function M.reload() M.load(); M.apply(); vim.notify("Settings reloaded", vim.log.levels.INFO) end
function M.cycle(key)
  for _, o in ipairs(M.options) do
    if o.key == key and o.values then
      for i, v in ipairs(o.values) do if v == current[key] then M.set(key, o.values[i % #o.values + 1]); return end end
    end
  end
end
M.load(); M.apply()
return M
