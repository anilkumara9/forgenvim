-- User extensions: a small manifest of extra plugins (owner/repo) that the
-- user adds from the Extensions panel. Built-in plugins stay pinned by the
-- main spec; manifest entries load through lazy like everything else.
local M = { featured = {
  { id = "folke/todo-comments.nvim", description = "Highlight and search TODO comments" },
  { id = "kylechui/nvim-surround", description = "Edit surrounding quotes and brackets" },
  { id = "windwp/nvim-autopairs", description = "Insert matching brackets and quotes" },
  { id = "numToStr/Comment.nvim", description = "Toggle code comments" },
  { id = "folke/flash.nvim", description = "Jump quickly through visible text" },
} }
function M.file() return vim.fn.stdpath("data") .. "/forge/user_plugins.json" end
function M.read()
  local fd = vim.uv.fs_open(M.file(), "r", 384)
  if not fd then return {} end
  local st = vim.uv.fs_fstat(fd); local raw = st and vim.uv.fs_read(fd, st.size, 0) or ""
  vim.uv.fs_close(fd)
  local ok, data = pcall(vim.json.decode, raw or "")
  return (ok and type(data) == "table") and data or {}
end
function M.write(list)
  vim.fn.mkdir(vim.fn.fnamemodify(M.file(), ":h"), "p")
  local fd = vim.uv.fs_open(M.file(), "w", 438)
  if fd then vim.uv.fs_write(fd, vim.json.encode(list)); vim.uv.fs_close(fd) end
end
local function valid_id(id) return type(id) == "string" and id:match("^[%w%._%-]+/[%w%._%-]+$") ~= nil end
function M.add(id)
  if not valid_id(id) then vim.notify("Plugin id must look like owner/repo", vim.log.levels.WARN); return false end
  local list = M.read()
  for _, p in ipairs(list) do if p == id then return true end end
  list[#list+1] = id; M.write(list)
  vim.notify("Added " .. id .. " - restart to load it", vim.log.levels.INFO)
  return true
end
function M.remove(id)
  local list, out = M.read(), {}
  for _, p in ipairs(list) do if p ~= id then out[#out+1] = p end end
  M.write(out)
end
function M.specs()
  local specs = {}
  for _, id in ipairs(M.read()) do specs[#specs+1] = { id } end
  return specs
end
return M
