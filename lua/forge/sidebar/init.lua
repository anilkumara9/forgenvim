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
-- Three stacked windows in the sidebar column: change list (with action
-- buttons), commit composer, and the COMMITS log at 30% of the window
-- height. Colours follow status: green added/untracked, yellow modified,
-- red deleted. Every action has a key; buttons also run with Enter.
local git_rows = {}
M.gitstate = { comp_win = nil, log_win = nil, comp_buf = nil }
local function git_out(args)
  local out = vim.fn.system(vim.list_extend({ "git", "-C", vim.fn.getcwd() }, args))
  return vim.v.shell_error == 0 and out or ""
end
local function git_ok(args) vim.fn.system(vim.list_extend({ "git", "-C", vim.fn.getcwd() }, args)); return vim.v.shell_error == 0 end
function M.close_git_extras()
  for _, key in ipairs({ "comp_win", "log_win" }) do
    local win = M.gitstate[key]
    if win and vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
    M.gitstate[key] = nil
  end
end
local function kind_of(xy, section)
  if xy:find("D") then return "del" end
  if xy:find("A") or xy:find("?") then return "add" end
  return "mod"
end
local function git_data()
  local staged, unstaged = {}, {}
  local status = git_out({ "status", "--porcelain=v1" })
  for line in vim.gsplit(status, "\n", { plain = true, trimempty = true }) do
    local xy, path = line:match("^(..)%s+(.*)$")
    if path then
      local x, y = xy:sub(1, 1), xy:sub(2, 2)
      if x ~= " " and x ~= "?" then staged[#staged+1] = { xy = xy, path = path, staged = true } end
      if y ~= " " or x == "?" then unstaged[#unstaged+1] = { xy = xy, path = path, staged = false, untracked = x == "?" } end
    end
  end
  return staged, unstaged
end
function M.git_commit()
  local buf = M.gitstate.comp_buf
  local msg = ""
  if buf and vim.api.nvim_buf_is_valid(buf) then
    msg = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
  end
  if msg == "" then vim.notify("Commit message is empty - type it in the composer (i)", vim.log.levels.WARN); return end
  local staged = git_data()
  if #staged == 0 then
    if vim.fn.confirm("Nothing staged. Stage all changes and commit?", "&Yes\n&No", 2) ~= 1 then return end
    git_ok({ "add", "-A" })
  end
  local out = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "commit", "-m", msg })
  vim.notify(vim.trim(out ~= "" and out or "Committed"), vim.log.levels.INFO)
  if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_set_lines(buf, 0, -1, false, {}) end
  M.render_git()
end
function M.git_push()
  local branch = vim.trim(git_out({ "branch", "--show-current" }))
  if branch == "" then vim.notify("No current branch to push", vim.log.levels.WARN); return end
  git_ok({ "rev-parse", "--abbrev-ref", "@{u}" })
  local args = { "git", "-C", vim.fn.getcwd(), "push" }
  if vim.v.shell_error ~= 0 then args[#args+1] = "-u" end
  vim.list_extend(args, { "origin", branch })
  vim.notify("Pushing " .. branch .. "...", vim.log.levels.INFO)
  vim.fn.jobstart(args, { on_exit = function(_, code)
    vim.schedule(function()
      vim.notify(code == 0 and ("Pushed " .. branch) or "Push failed", code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
      M.render_git()
    end)
  end })
end
local buttons = { "Commit", "Check Diff", "Push", "Stage All", "Unstage All", "Revert All" }
local function run_button(label)
  if label == "Commit" then
    if M.gitstate.comp_win and vim.api.nvim_win_is_valid(M.gitstate.comp_win) then
      vim.api.nvim_set_current_win(M.gitstate.comp_win); vim.cmd.startinsert()
    end
  elseif label == "Check Diff" then
    local staged, unstaged = git_data()
    local first = staged[1] or unstaged[1]
    if first then require("forge.diff").open(vim.fn.getcwd(), first) end
  elseif label == "Push" then M.git_push()
  elseif label == "Stage All" then git_ok({ "add", "-A" }); M.render_git()
  elseif label == "Unstage All" then git_ok({ "restore", "--staged", "." }); M.render_git()
  elseif label == "Revert All" then
    if vim.fn.confirm("Revert ALL changes?", "&Yes\n&No", 2) == 1 then git_ok({ "restore", "." }); M.render_git() end
  end
end
function M.render_git()
  local list_win = M.ensure_win()
  M.mode = "git"
  local staged, unstaged = git_data()
  local branch = vim.trim(git_out({ "branch", "--show-current" }))
  local lines = {}
  git_rows = {}
  local btn_line = " "
  local spans = {}
  for _, b in ipairs(buttons) do
    local label = "[" .. b .. "]"
    spans[#spans+1] = { from = #btn_line + 1, to = #btn_line + #label, label = b }
    btn_line = btn_line .. label .. " "
  end
  lines[1] = btn_line; git_rows[1] = { buttons = spans }
  lines[#lines+1] = ""
  lines[#lines+1] = (" Git (%s)"):format(branch ~= "" and branch or "no repo")
  local function section(title, entries, section_name)
    lines[#lines+1] = ""
    lines[#lines+1] = (" %s (%d)"):format(title, #entries)
    if #entries == 0 then lines[#lines+1] = "   (none)" end
    for _, e in ipairs(entries) do
      local icon = ""
      local okd, dv = pcall(require, "nvim-web-devicons")
      if okd and require("forge.settings").get().icons then
        icon = (dv.get_icon(e.path, e.path:match("%.(%w+)$"), { default = true }) or "") .. " "
      end
      lines[#lines+1] = "  " .. icon .. e.path
      git_rows[#lines] = { entry = e, section = section_name, kind = kind_of(e.xy, section_name) }
    end
  end
  section("Staged Changes", staged, "staged")
  section("Changes", unstaged, "unstaged")
  lines[#lines+1] = ""
  lines[#lines+1] = " s stage · u unstage · x revert · d diff · C message · r refresh · q files"
  local buf = render(lines, "ForgeGit")
  -- Status colours + file icons already embedded; colour the filename per status.
  local ns = vim.api.nvim_create_namespace("forge_git")
  vim.api.nvim_set_hl(0, "ForgeGitAdd", { link = "String" })
  vim.api.nvim_set_hl(0, "ForgeGitMod", { link = "Type" })
  vim.api.nvim_set_hl(0, "ForgeGitDel", { link = "Error" })
  for ln, row in pairs(git_rows) do
    if row.kind then
      local grp = row.kind == "add" and "ForgeGitAdd" or row.kind == "del" and "ForgeGitDel" or "ForgeGitMod"
      pcall(vim.api.nvim_buf_add_highlight, buf, ns, grp, ln - 1, 2, -1)
    end
  end
  local function cur() return git_rows[vim.api.nvim_win_get_cursor(0)[1]] end
  local function entry() local r = cur(); return r and r.entry end
  vim.keymap.set("n", "<CR>", function()
    local r = cur()
    if r and r.buttons then
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1
      for _, sp in ipairs(r.buttons) do if col >= sp.from and col <= sp.to then run_button(sp.label); return end end
      run_button("Commit"); return
    end
    local e = entry()
    if e then require("forge.tabs").focus_editor(); vim.cmd("edit " .. vim.fn.fnameescape(e.path)) end
  end, { buffer = buf })
  vim.keymap.set("n", "s", function() local e = entry(); if e and not e.staged then git_ok({ "add", "--", e.path }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "u", function() local e = entry(); if e and e.staged then git_ok({ "restore", "--staged", "--", e.path }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "x", function() local e = entry()
    if e and vim.fn.confirm("Revert " .. e.path .. "?", "&Yes\n&No", 2) == 1 then
      if e.untracked then vim.fn.delete(vim.fn.getcwd() .. "/" .. e.path)
      elseif e.staged then git_ok({ "restore", "--source=HEAD", "--staged", "--worktree", "--", e.path })
      else git_ok({ "restore", "--", e.path }) end
      M.render_git()
    end end, { buffer = buf })
  vim.keymap.set("n", "S", function() git_ok({ "add", "-A" }); M.render_git() end, { buffer = buf })
  vim.keymap.set("n", "U", function() git_ok({ "restore", "--staged", "." }); M.render_git() end, { buffer = buf })
  vim.keymap.set("n", "X", function() if vim.fn.confirm("Revert ALL changes?", "&Yes\n&No", 2) == 1 then git_ok({ "restore", "." }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "P", function() M.git_push() end, { buffer = buf })
  vim.keymap.set("n", "d", function() local e = entry(); if e then require("forge.diff").open(vim.fn.getcwd(), e) end end, { buffer = buf })
  vim.keymap.set("n", "C", function() M.focus_composer() end, { buffer = buf })
  vim.keymap.set("n", "i", function() M.focus_composer() end, { buffer = buf })
  vim.keymap.set("n", "r", function() M.render_git() end, { buffer = buf })
  vim.keymap.set("n", "q", function() M.set_mode("files", true) end, { buffer = buf })
  vim.keymap.set("n", "<Tab>", function() M.focus_composer() end, { buffer = buf })
  vim.keymap.set("n", "<C-CR>", function() M.git_commit() end, { buffer = buf })
  M.git_ensure_subwindows()
end
function M.focus_composer()
  M.git_ensure_subwindows()
  if M.gitstate.comp_win and vim.api.nvim_win_is_valid(M.gitstate.comp_win) then
    vim.api.nvim_set_current_win(M.gitstate.comp_win); vim.cmd.startinsert()
  end
end
function M.git_ensure_subwindows()
  local list_win = M.ensure_win()
  -- Composer window
  if not (M.gitstate.comp_win and vim.api.nvim_win_is_valid(M.gitstate.comp_win)) then
    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(list_win)
    vim.cmd("belowright split")
    M.gitstate.comp_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(M.gitstate.comp_win, 4)
    vim.wo[M.gitstate.comp_win].winfixheight = true
    if not (M.gitstate.comp_buf and vim.api.nvim_buf_is_valid(M.gitstate.comp_buf)) then
      M.gitstate.comp_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[M.gitstate.comp_buf].buftype = "acwrite"; vim.bo[M.gitstate.comp_buf].swapfile = false
      vim.b[M.gitstate.comp_buf].forge_panel_kind = "gitmeta"
      vim.b[M.gitstate.comp_buf].forge_panel_title = "Commit message - C or Ctrl+Enter commits"
      pcall(vim.api.nvim_buf_set_name, M.gitstate.comp_buf, "ForgeCommitMessage")
      vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = M.gitstate.comp_buf, callback = function() M.git_commit() end })
    end
    vim.api.nvim_win_set_buf(M.gitstate.comp_win, M.gitstate.comp_buf)
    local cbuf = M.gitstate.comp_buf
    vim.keymap.set({ "n", "i" }, "<C-CR>", function() M.git_commit() end, { buffer = cbuf })
    vim.keymap.set("n", "C", function() M.git_commit() end, { buffer = cbuf })
    vim.keymap.set("n", "<Tab>", function()
      if M.gitstate.log_win and vim.api.nvim_win_is_valid(M.gitstate.log_win) then vim.api.nvim_set_current_win(M.gitstate.log_win) end
    end, { buffer = cbuf })
    vim.keymap.set("n", "q", function()
      if valid_win() then vim.api.nvim_set_current_win(M.win) end
    end, { buffer = cbuf })
    if vim.api.nvim_win_is_valid(cur) and cur ~= M.gitstate.comp_win then vim.api.nvim_set_current_win(cur) end
  end
  -- Log window at 30% of the screen height
  if not (M.gitstate.log_win and vim.api.nvim_win_is_valid(M.gitstate.log_win)) then
    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(M.gitstate.comp_win)
    vim.cmd("belowright split")
    M.gitstate.log_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(M.gitstate.log_win, math.max(5, math.floor(vim.o.lines * 0.30)))
    vim.wo[M.gitstate.log_win].winfixheight = true
    if vim.api.nvim_win_is_valid(cur) and cur ~= M.gitstate.log_win then vim.api.nvim_set_current_win(cur) end
  end
  -- (Re)render the log content
  local log_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[log_buf].buftype = "nofile"; vim.bo[log_buf].bufhidden = "wipe"
  vim.b[log_buf].forge_panel_kind = "gitmeta"; vim.b[log_buf].forge_panel_title = "COMMITS"
  local log = git_out({ "log", "--graph", "--oneline", "-30" })
  local llines = { }
  if log == "" then llines = { " (no commits yet)" }
  else for line in vim.gsplit(log, "\n", { plain = true, trimempty = true }) do llines[#llines+1] = " " .. line end end
  vim.api.nvim_buf_set_lines(log_buf, 0, -1, false, llines)
  vim.bo[log_buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, log_buf, "ForgeGitLog")
  vim.api.nvim_win_set_buf(M.gitstate.log_win, log_buf)
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local hash = line:match("([0-9a-f]+)%s")
    if hash then
      local win = require("forge.tabs").focus_editor()
      if win then
        local b = vim.api.nvim_create_buf(false, true)
        vim.bo[b].buftype = "nofile"; vim.bo[b].filetype = "git"
        vim.api.nvim_buf_set_lines(b, 0, -1, false, vim.split(git_out({ "show", hash }), "\n"))
        vim.bo[b].modifiable = false
        vim.api.nvim_win_set_buf(win, b)
      end
    end
  end, { buffer = log_buf })
  vim.keymap.set("n", "<Tab>", function() if valid_win() then vim.api.nvim_set_current_win(M.win) end end, { buffer = log_buf })
  vim.keymap.set("n", "r", function() M.render_git() end, { buffer = log_buf })
  vim.keymap.set("n", "q", function() M.set_mode("files", true) end, { buffer = log_buf })
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
  local filter = M.theme_filter or ""
  local lines = { " THEMES  (Enter applies" .. (filter ~= "" and (", /" .. filter) or ", / searches") .. ")", "" }
  local rows = {}
  local current = require("forge.settings").get().theme
  for _, t in ipairs(require("forge.themes").list) do
    if filter == "" or t.label:lower():find(filter:lower(), 1, true) then
      lines[#lines+1] = (t.id == current and " ● " or " ○ ") .. t.label; rows[#lines] = t
    end
  end
  if #lines == 2 then lines[#lines+1] = "  (no match)" end
  local buf = render(lines, "ForgeThemes")
  vim.keymap.set("n", "<CR>", function()
    local t = rows[vim.api.nvim_win_get_cursor(0)[1]]
    if t then require("forge.themes").apply(t.id); M.render_themes() end
  end, { buffer = buf })
  vim.keymap.set("n", "/", function()
    vim.ui.input({ prompt = "Filter themes: ", default = filter }, function(q)
      M.theme_filter = q or ""
      M.render_themes()
    end)
  end, { buffer = buf })
end
-- EXTENSIONS ---------------------------------------------------------------
local ext_rows = {}
local function render_extensions()
  local ext = require("forge.extensions")
  local mine = ext.read()
  local lines = { " EXTENSIONS", "" }
  ext_rows = {}
  lines[#lines+1] = " Your plugins (a add · x remove · R restart)"
  if #mine == 0 then lines[#lines+1] = "   (none yet)" end
  for _, id in ipairs(mine) do
    lines[#lines+1] = "  ✓ " .. id
    ext_rows[#lines] = { kind = "mine", id = id }
  end
  lines[#lines+1] = ""
  lines[#lines+1] = " Featured (Enter adds)"
  for _, f in ipairs(ext.featured) do
    lines[#lines+1] = ("  + %-32s %s"):format(f.id, f.description)
    ext_rows[#lines] = { kind = "featured", id = f.id }
  end
  lines[#lines+1] = ""
  lines[#lines+1] = " [m] Search Mason tools   [L] Plugin manager   [M] Mason"
  ext_rows.mason = nil
  local buf = render(lines, "ForgeExtensionsPanel")
  local function cur() return ext_rows[vim.api.nvim_win_get_cursor(0)[1]] end
  vim.keymap.set("n", "<CR>", function()
    local r = cur()
    if r then ext.add(r.id); render_extensions() end
  end, { buffer = buf })
  vim.keymap.set("n", "a", function()
    vim.ui.input({ prompt = "Plugin (owner/repo): " }, function(id)
      if id and id ~= "" then ext.add(id); render_extensions() end
    end)
  end, { buffer = buf })
  vim.keymap.set("n", "x", function()
    local r = cur()
    if r and r.kind == "mine" then ext.remove(r.id); render_extensions() end
  end, { buffer = buf })
  vim.keymap.set("n", "R", function() vim.cmd("ForgeRestart") end, { buffer = buf })
  vim.keymap.set("n", "L", function() vim.cmd("Lazy") end, { buffer = buf })
  vim.keymap.set("n", "M", function() vim.cmd("Mason") end, { buffer = buf })
  vim.keymap.set("n", "m", function()
    vim.ui.input({ prompt = "Search Mason tools: " }, function(q)
      if not q or q == "" then return end
      local ok, reg = pcall(require, "mason-registry")
      if not ok then vim.notify("Mason is not loaded yet", vim.log.levels.WARN); return end
      local hits = {}
      for _, name in ipairs(reg.get_all_package_names()) do
        if name:lower():find(q:lower(), 1, true) then hits[#hits+1] = name end
      end
      if #hits == 0 then vim.notify("No Mason tools match " .. q, vim.log.levels.WARN); return end
      vim.ui.select(hits, { prompt = "Install tool:" }, function(choice)
        if choice then vim.cmd("MasonInstall " .. choice) end
      end)
    end)
  end, { buffer = buf })
end
function M.render_extensions() render_extensions() end

-- MODE SWITCH ---------------------------------------------------------------
function M.set_mode(mode, focus)
  if not vim.tbl_contains(M.modes, mode) then return end
  if mode ~= "git" and M.close_git_extras then M.close_git_extras() end
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
vim.api.nvim_create_user_command("SidebarFilesToggle", function() M.toggle() end, {})
vim.api.nvim_create_user_command("GitChanges", M.git, {})
return M
