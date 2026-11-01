local M = {}
function M.bufdelete()
  local buf = vim.api.nvim_get_current_buf()
  local wins = vim.fn.win_findbuf(buf)
  vim.cmd("bprevious")
  if #wins > 0 and vim.api.nvim_get_current_buf() == buf then vim.cmd("enew") end
  pcall(vim.api.nvim_buf_delete, buf, { force = false })
end
M.is_windows = vim.fn.has("win32") == 1
M.sep = M.is_windows and "\\" or "/"
function M.root()
  local markers = { ".git", "package.json", "pyproject.toml", "Cargo.toml", "go.mod", "pom.xml", "build.gradle", "composer.json" }
  local found = vim.fs.find(markers, { upward = true, path = vim.fn.expand("%:p:h") })[1]
  return found and vim.fs.dirname(found) or vim.fn.getcwd()
end
function M.notify(msg, level) vim.notify(msg, level or vim.log.levels.INFO, { title = "ForgeNvim" }) end
return M
