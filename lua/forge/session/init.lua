-- Per-project session: editor buffers (including unsaved snapshots) + agent
-- session ids, restored on launch. `nvim --clean` / FORGE_CLEAN=1 skips it.
local M = { busy = false, exiting = false }
local function is_clean()
  if vim.env.FORGE_CLEAN == "1" or vim.env.NVIM_CLEAN == "1" then return true end
  for _, a in ipairs(vim.fn.argv()) do if a == "--clean" then return true end end
  return false
end
M.clean = is_clean()
function M.dir() return vim.fn.stdpath("state") .. "/forge/sessions" end
function M.file()
  local key = vim.fn.sha256(vim.fn.getcwd()):sub(1, 16)
  return M.dir() .. "/" .. key .. ".json"
end
function M.save()
  if M.clean or M.busy then return end
  M.busy = true
  local data = { cwd = vim.fn.getcwd(), buffers = {}, agents = {}, saved_at = os.time() }
  local agents = package.loaded["forge.agents"]
  if agents and agents.snapshot then data.agents = agents.snapshot() end
  vim.fn.mkdir(M.dir() .. "/snapshots", "p")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      local entry = { name = name }
      if vim.bo[buf].modified or name == "" then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if #lines > 1 or (lines[1] and lines[1] ~= "") then
          local snap = M.dir() .. "/snapshots/" .. vim.fn.sha256(tostring(buf) .. name):sub(1, 12) .. ".txt"
          vim.fn.writefile(lines, snap); entry.snapshot = snap
        end
      end
      if entry.name ~= "" or entry.snapshot then data.buffers[#data.buffers+1] = entry end
    end
  end
  vim.fn.writefile({ vim.json.encode(data) }, M.file())
  M.busy = false
end
function M.restore()
  if M.clean then return false end
  if not require("forge.settings").get().session_restore then return false end
  local fd = vim.uv.fs_open(M.file(), "r", 384); if not fd then return false end
  local st = vim.uv.fs_fstat(fd); local raw = st and vim.uv.fs_read(fd, st.size, 0) or ""
  vim.uv.fs_close(fd)
  local ok, data = pcall(vim.json.decode, raw or ""); if not ok or type(data) ~= "table" then return false end
  for _, entry in ipairs(data.buffers or {}) do
    if entry.name and entry.name ~= "" and vim.uv.fs_stat(entry.name) then vim.cmd("edit " .. vim.fn.fnameescape(entry.name))
    elseif entry.snapshot and vim.uv.fs_stat(entry.snapshot) then
      vim.cmd("enew"); vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.readfile(entry.snapshot))
      vim.bo.modified = true
    end
  end
  local agents = require("forge.agents")
  for _, a in ipairs(data.agents or {}) do agents.new(a.name, { uuid = a.uuid, label = a.label }) end
  return true
end
function M.quit() M.exiting = true; M.save(); vim.cmd("qa") end
vim.api.nvim_create_user_command("ForgeQuit", M.quit, {})
vim.api.nvim_create_user_command("SessionQuit", M.quit, {})
vim.api.nvim_create_autocmd("VimLeavePre", { callback = function() M.exiting = true; M.save() end })
return M
