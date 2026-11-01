-- Restart: persist the project session first, then use :restart when the
-- running Neovim provides it (0.12+), otherwise say what to do.
local M = {}
function M.restart()
  local ok, session = pcall(require, "forge.session")
  if ok and session.save then session.save() end
  if vim.fn.exists(":restart") == 2 then vim.cmd("restart")
  else vim.notify("Restart Neovim to apply (this version has no :restart)", vim.log.levels.WARN) end
end
vim.api.nvim_create_user_command("ForgeRestart", M.restart, {})
return M
