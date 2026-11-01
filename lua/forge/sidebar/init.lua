-- Single left panel, 20% wide, with five internal modes:
-- Files | Git | Settings | Themes | Extensions.
-- One window, one slot: switching modes replaces the panel's content, never
-- opens another split. Files uses the tree; Git is a working panel with a
-- commit composer and the recent log at the bottom; the other modes render
-- their controls directly in the panel.
local M = { win = nil, mode = "files" }
M.modes = { "files", "git", "settings", "themes", "extensions" }
local function width() return math.max(24, math.floor(vim.o.columns * 0.20)) end
local function valid_win() return M.win and vim.api.nvim_win_is_valid(M.win) end
function M.ensure_win()
  if valid_win() then return M.win end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("topleft vsplit")
  M.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(M.win, width())
  vim.wo[M.win].winfixwidth = true
  vim.wo[M.win].number = false; vim.wo[M.win].relativenumber = false
  vim.wo[M.win].signcolumn = "no"; vim.wo[M.win].foldcolumn = "0"; vim.wo[M.win].statuscolumn = ""
  vim.api.nvim_set_current_win(cur)
  return M.win
end
local function render(lines, name)
  local win = M.ensure_win()
  local cur = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"; vim.bo[buf].bufhidden = "wipe"; vim.bo[buf].swapfile = false
  vim.b[buf].forge_sidebar = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, name)
  vim.api.nvim_win_set_buf(win, buf)
  vim.keymap.set("n", "q", function() M.close() end, { buffer = buf })
  vim.keymap.set("n", "1", function() M.set_mode("files", true) end, { buffer = buf })
  vim.keymap.set("n", "2", function() M.set_mode("git", true) end, { buffer = buf })
  vim.keymap.set("n", "3", function() M.set_mode("settings", true) end, { buffer = buf })
  vim.keymap.set("n", "4", function() M.set_mode("themes", true) end, { buffer = buf })
  vim.keymap.set("n", "5", function() M.set_mode("extensions", true) end, { buffer = buf })
  if cur ~= win and vim.api.nvim_win_is_valid(cur) then vim.api.nvim_set_current_win(cur) end
  return buf, win
end
-- GIT ----------------------------------------------------------------------
local git_rows = {}
local function git_out(args)
  local out = vim.fn.system(vim.list_extend({ "git", "-C", vim.fn.getcwd() }, args))
  return vim.v.shell_error == 0 and out or ""
end
function M.render_git()
  git_rows = {}
  local branch = vim.trim(git_out({ "branch", "--show-current" }))
  local lines = { " GIT  " .. (branch ~= "" and ("(" .. branch .. ")") or "(no repo)"), "" }
  local status = git_out({ "status", "--porcelain=v1" })
  if status == "" then lines[#lines+1] = "  Working tree clean"
  else
    lines[#lines+1] = " Changes  (Enter open, d diff, a stage, u unstage, r revert)"
    for line in vim.gsplit(status, "\n", { plain = true, trimempty = true }) do
      local xy, path = line:match("^(..)%s+(.*)$")
      if path then lines[#lines+1] = ("  %s %s"):format(xy, path); git_rows[#lines] = { xy = xy, path = path } end
    end
  end
  lines[#lines+1] = ""; lines[#lines+1] = " [c] Commit staged   [R] Refresh"
  lines[#lines+1] = ""; lines[#lines+1] = " Log"
  local log = git_out({ "log", "--oneline", "-8" })
  if log == "" then lines[#lines+1] = "  (no commits yet)"
  else for line in vim.gsplit(log, "\n", { plain = true, trimempty = true }) do lines[#lines+1] = "  " .. line end end
  local buf = render(lines, "ForgeGit")
  local function row() return git_rows[vim.api.nvim_win_get_cursor(0)[1]] end
  local function in_editor(fn)
    local win = require("forge.tabs").focus_editor(); if win then fn() end
  end
  vim.keymap.set("n", "<CR>", function() local r = row(); if r then in_editor(function() vim.cmd("edit " .. vim.fn.fnameescape(r.path)) end) end end, { buffer = buf })
  vim.keymap.set("n", "d", function() local r = row(); if r then in_editor(function() vim.cmd("edit " .. vim.fn.fnameescape(r.path)); vim.cmd("Gdiffsplit") end) end end, { buffer = buf })
  vim.keymap.set("n", "a", function() local r = row(); if r then git_out({ "add", "--", r.path }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "u", function() local r = row(); if r then git_out({ "restore", "--staged", "--", r.path }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "r", function() local r = row()
    if r and vim.fn.confirm("Revert " .. r.path .. "?", "&Yes\n&No", 2) == 1 then git_out({ "restore", "--", r.path }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "c", function()
    vim.ui.input({ prompt = "Commit message (staged changes): " }, function(msg)
      if msg and msg ~= "" then
        local out = git_out({ "commit", "-m", msg })
        vim.notify(out ~= "" and vim.trim(out) or "Nothing committed (stage changes first)", vim.log.levels.INFO)
        M.render_git()
      end
    end) end, { buffer = buf })
  vim.keymap.set("n", "R", function() M.render_git() end, { buffer = buf })
end
-- SETTINGS -----------------------------------------------------------------
function M.render_settings()
  local s = require("forge.settings"); local cur = s.get()
  local lines = { " SETTINGS  (Enter toggles / cycles)", "" }
  local rows = {}; local section = ""
  for _, o in ipairs(s.options) do
    if o.section ~= section then section = o.section; lines[#lines+1] = " " .. section end
    local val = o.kind == "theme" and cur.theme or tostring(cur[o.key])
    lines[#lines+1] = ("  %-26s %s"):format(o.label, val); rows[#lines] = o
  end
  local buf = render(lines, "ForgeSettings")
  vim.keymap.set("n", "<CR>", function()
    local o = rows[vim.api.nvim_win_get_cursor(0)[1]]; if not o then return end
    if o.kind == "boolean" then s.toggle(o.key)
    elseif o.kind == "theme" then M.set_mode("themes", true); return
    elseif o.values then s.cycle(o.key) end
    M.render_settings()
  end, { buffer = buf })
end
-- THEMES -------------------------------------------------------------------
function M.render_themes()
  local lines = { " THEMES  (Enter applies)", "" }
  local rows = {}
  local current = require("forge.settings").get().theme
  for _, t in ipairs(require("forge.themes").list) do
    lines[#lines+1] = (t.id == current and " ● " or " ○ ") .. t.label; rows[#lines] = t
  end
  local buf = render(lines, "ForgeThemes")
  vim.keymap.set("n", "<CR>", function()
    local t = rows[vim.api.nvim_win_get_cursor(0)[1]]
    if t then require("forge.themes").apply(t.id); M.render_themes() end
  end, { buffer = buf })
end
-- EXTENSIONS ---------------------------------------------------------------
function M.render_extensions()
  local lines = { " EXTENSIONS", "",
    "  Plugins        :Lazy", "  Tools / LSP    :Mason", "  Parsers        :TSUpdate",
    "  Tests          :Neotest", "  Tasks          :OverseerRun", "",
    "  [L] Plugin manager   [M] Tool manager" }
  local buf = render(lines, "ForgeExtensions")
  vim.keymap.set("n", "L", function() vim.cmd("Lazy") end, { buffer = buf })
  vim.keymap.set("n", "M", function() vim.cmd("Mason") end, { buffer = buf })
  vim.keymap.set("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
    local cmdname = line:match(":(%w+)"); if cmdname then vim.cmd(cmdname) end
  end, { buffer = buf })
end
-- MODE SWITCH ---------------------------------------------------------------
function M.set_mode(mode, focus)
  if not vim.tbl_contains(M.modes, mode) then return end
  M.mode = mode
  local win = M.ensure_win()
  if mode == "files" then
    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(win)
    local ok = pcall(vim.cmd, "Neotree filesystem")
    if not ok then render({ " FILES", "", "  File tree loads with the plugin set.", "  Run :Lazy sync on first launch." }, "ForgeFiles") end
    if not focus and vim.api.nvim_win_is_valid(cur) and cur ~= win then vim.api.nvim_set_current_win(cur) end
  elseif mode == "git" then M.render_git()
  elseif mode == "settings" then M.render_settings()
  elseif mode == "themes" then M.render_themes()
  elseif mode == "extensions" then M.render_extensions() end
  if focus and valid_win() then vim.api.nvim_set_current_win(M.win) end
  vim.cmd("redraw")
end
function M.close() if valid_win() then pcall(vim.api.nvim_win_close, M.win, false); M.win = nil end end
function M.toggle()
  if valid_win() then M.close() else M.set_mode(M.mode or "files", true) end
end
function M.toggle_files() M.toggle() end
function M.git() M.set_mode("git", true) end
function M.settings() M.set_mode("settings", true) end
function M.themes() M.set_mode("themes", true) end
function M.extensions() M.set_mode("extensions", true) end
vim.api.nvim_create_user_command("ForgeSettings", M.settings, {})
vim.api.nvim_create_user_command("SetupSettings", M.settings, {})
vim.api.nvim_create_user_command("SetupThemes", M.themes, {})
vim.api.nvim_create_user_command("SetupExtensions", M.extensions, {})
vim.api.nvim_create_user_command("ForgeSidebar", function() M.toggle() end, {})
vim.api.nvim_create_user_command("GitChanges", M.git, {})
return M
