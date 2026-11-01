-- Single left panel, 20% wide, with five internal modes:
-- Files | Git | Settings | Themes | Extensions.
-- One window, one slot: switching modes replaces the panel's content, never
-- opens another split. Files uses the tree; Git is a working panel with a
-- commit composer and the recent log at the bottom; the other modes render
-- their controls directly in the panel.
local M = { win = nil, mode = "files" }
M.modes = { "files", "git", "settings", "themes", "extensions" }
local function width() return math.max(24, math.floor(vim.o.columns * 0.20)) end
function M.width() return width() end
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
  vim.b[buf].forge_label = name
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
-- Panel painting namespace (settings/themes/extensions/git share it)
local panel_ns = vim.api.nvim_create_namespace("forge_panels")
local function paint_hl(buf, line0, group, from, to)
  pcall(vim.api.nvim_buf_add_highlight, buf, panel_ns, group, line0, from or 0, to or -1)
end

-- GIT ----------------------------------------------------------------------
-- Layout: blank line, branch, [Commit] / [Check Diff] / [Push] buttons, a
-- help line, then collapsible Staged Changes / Changes sections with bulk
-- actions inside, entries as "  +  M  <icon> path  x" coloured by status.
-- The composer (with an inline placeholder) and the COMMITS log are
-- stacked windows below the list.
local git_rows = {}
M.gitstate = { comp_win = nil, log_win = nil, comp_buf = nil, expanded = { staged = true, unstaged = true } }
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
local function change_highlight(status)
  if status:find("D", 1, true) then return "GitChangeDeleted" end
  if status:find("A", 1, true) or status == "?" then return "GitChangeAdded" end
  return "GitChangeModified"
end
local function git_data()
  local staged, unstaged = {}, {}
  local status = git_out({ "status", "--porcelain=v1" })
  for line in vim.gsplit(status, "\n", { plain = true, trimempty = true }) do
    local xy, path = line:match("^(..)%s+(.*)$")
    if path then
      local x, y = xy:sub(1, 1), xy:sub(2, 2)
      if x ~= " " and x ~= "?" then staged[#staged+1] = { xy = xy, path = path, status = x, staged = true } end
      if y ~= " " or x == "?" then unstaged[#unstaged+1] = { xy = xy, path = path, status = x == "?" and "?" or y, staged = false, untracked = x == "?" } end
    end
  end
  return staged, unstaged
end
local function git_branch() return vim.trim(git_out({ "branch", "--show-current" })) end
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
  local branch = git_branch()
  if branch == "" then vim.notify("No current branch to push", vim.log.levels.WARN); return end
  git_ok({ "rev-parse", "--abbrev-ref", "@{u}" })
  local args = { "git", "-C", vim.fn.getcwd(), "push" }
  if vim.v.shell_error ~= 0 then args[#args+1] = "-u" end
  vim.list_extend(args, { "origin", branch })
  vim.notify("Pushing " .. branch .. "...", vim.log.levels.INFO)
  vim.fn.jobstart(args, { on_exit = function(_, code)
    vim.schedule(function()
      vim.notify(code == 0 and ("Pushed " .. branch) or "Push failed", code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
      if M.mode == "git" then M.render_git() end
    end)
  end })
end
local function revert_entry(e)
  if e.untracked then vim.fn.delete(vim.fn.getcwd() .. "/" .. e.path)
  elseif e.staged then git_ok({ "restore", "--source=HEAD", "--staged", "--worktree", "--", e.path })
  else git_ok({ "restore", "--", e.path }) end
end
function M.render_git()
  local staged, unstaged = git_data()
  local branch = git_branch()
  local lines, rows = {}, {}
  lines[#lines+1] = ""
  lines[#lines+1] = "  " .. (branch ~= "" and branch or "no branch")
  lines[#lines+1] = "  [Commit]  Ctrl+Enter"; rows[#lines] = { kind = "commit" }
  lines[#lines+1] = "  [Check Diff]"; rows[#lines] = { kind = "check_diff" }
  lines[#lines+1] = "  [Push]"; rows[#lines] = { kind = "push" }
  local diffmod = package.loaded["forge.diff"]
  if diffmod and diffmod.is_open then
    lines[#lines+1] = "  [Close Diff]"; rows[#lines] = { kind = "close_diff" }
  end
  local help_line = #lines + 1
  lines[#lines+1] = "  d diff  P push  s/u  x revert  i message"
  lines[#lines+1] = ""
  local entry_colors = {}
  local function section(title, items, name)
    local expanded = M.gitstate.expanded[name]
    lines[#lines+1] = (" %s %s  (%d)"):format(vim.fn.nr2char(expanded and 0x25BE or 0x25B8), title, #items)
    rows[#lines] = { kind = "section", group = name }
    if expanded then
      if #items == 0 then
        lines[#lines+1] = "     No changes"
      else
        if name == "staged" then
          lines[#lines+1] = "   [Unstage All]"; rows[#lines] = { kind = "bulk", group = "staged" }
        else
          lines[#lines+1] = "   [Stage All]  [Revert All]"; rows[#lines] = { kind = "bulk", group = "unstaged" }
        end
        for _, e in ipairs(items) do
          local symbol = e.staged and vim.fn.nr2char(0x2212) or "+"
          local prefix = ("  %s  %s  "):format(symbol, e.status)
          local icon, ihl = "", nil
          if require("forge.settings").get().icons then
            local okd, dv = pcall(require, "nvim-web-devicons")
            if okd then icon, ihl = dv.get_icon(e.path, e.path:match("%.(%w+)$"), { default = true }); icon = icon or "" end
          end
          lines[#lines+1] = prefix .. icon .. " " .. e.path .. "  x"
          rows[#lines] = { kind = "entry", entry = e }
          entry_colors[#entry_colors+1] = { line = #lines, status = e.status, icon = icon, ihl = ihl, prefix_len = #prefix }
        end
      end
    end
    lines[#lines+1] = ""
  end
  section("Staged Changes", staged, "staged")
  section("Changes", unstaged, "unstaged")
  local buf = render(lines, "ForgeGit")
  git_rows = rows
  for ln, row in pairs(rows) do
    if row.kind == "commit" or row.kind == "check_diff" or row.kind == "push" or row.kind == "close_diff" or row.kind == "bulk" then
      paint_hl(buf, ln - 1, "GitButton")
    end
  end
  paint_hl(buf, help_line - 1, "GitHelp")
  for _, c in ipairs(entry_colors) do
    paint_hl(buf, c.line - 1, change_highlight(c.status))
    if c.ihl and c.icon ~= "" then paint_hl(buf, c.line - 1, c.ihl, c.prefix_len, c.prefix_len + #c.icon) end
  end
  local function cur() return git_rows[vim.api.nvim_win_get_cursor(0)[1]] end
  local function first_entry() return staged[1] or unstaged[1] end
  vim.keymap.set("n", "<CR>", function()
    local r = cur(); if not r then return end
    if r.kind == "commit" then M.focus_composer()
    elseif r.kind == "check_diff" then local e = first_entry(); if e then require("forge.diff").open(vim.fn.getcwd(), e) end
    elseif r.kind == "push" then M.git_push()
    elseif r.kind == "close_diff" then require("forge.diff").close(); M.render_git()
    elseif r.kind == "section" then M.gitstate.expanded[r.group] = not M.gitstate.expanded[r.group]; M.render_git()
    elseif r.kind == "bulk" then
      if r.group == "staged" then git_ok({ "restore", "--staged", "." })
      else git_ok({ "add", "-A" }) end
      M.render_git()
    elseif r.kind == "entry" then require("forge.tabs").focus_editor(); vim.cmd("edit " .. vim.fn.fnameescape(r.entry.path)) end
  end, { buffer = buf })
  vim.keymap.set("n", "s", function() local r = cur(); if r and r.kind == "entry" and not r.entry.staged then git_ok({ "add", "--", r.entry.path }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "u", function() local r = cur(); if r and r.kind == "entry" and r.entry.staged then git_ok({ "restore", "--staged", "--", r.entry.path }); M.render_git() end end, { buffer = buf })
  vim.keymap.set("n", "x", function()
    local r = cur(); if not r then return end
    if r.kind == "entry" then
      if vim.fn.confirm("Revert " .. r.entry.path .. "?", "&Yes\n&No", 2) == 1 then revert_entry(r.entry); M.render_git() end
    elseif r.kind == "bulk" and r.group == "unstaged" then
      if vim.fn.confirm("Revert ALL changes?", "&Yes\n&No", 2) == 1 then git_ok({ "restore", "." }); M.render_git() end
    end
  end, { buffer = buf })
  vim.keymap.set("n", "S", function() git_ok({ "add", "-A" }); M.render_git() end, { buffer = buf })
  vim.keymap.set("n", "U", function() git_ok({ "restore", "--staged", "." }); M.render_git() end, { buffer = buf })
  vim.keymap.set("n", "P", function() M.git_push() end, { buffer = buf })
  vim.keymap.set("n", "d", function() local r = cur(); local e = (r and r.kind == "entry") and r.entry or first_entry(); if e then require("forge.diff").open(vim.fn.getcwd(), e) end end, { buffer = buf })
  vim.keymap.set("n", "C", function() M.focus_composer() end, { buffer = buf })
  vim.keymap.set("n", "i", function() M.focus_composer() end, { buffer = buf })
  vim.keymap.set("n", "r", function() M.render_git() end, { buffer = buf })
  vim.keymap.set("n", "q", function() M.set_mode("files", true) end, { buffer = buf })
  vim.keymap.set("n", "<Tab>", function() M.focus_composer() end, { buffer = buf })
  vim.keymap.set("n", "<C-CR>", function() M.git_commit() end, { buffer = buf })
  M.git_ensure_subwindows()
  M.paint_composer_placeholder()
end
function M.focus_composer()
  M.git_ensure_subwindows()
  if M.gitstate.comp_win and vim.api.nvim_win_is_valid(M.gitstate.comp_win) then
    vim.api.nvim_set_current_win(M.gitstate.comp_win); vim.cmd.startinsert()
  end
end
local composer_ns = vim.api.nvim_create_namespace("forge_composer")
function M.paint_composer_placeholder()
  local buf = M.gitstate.comp_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, composer_ns, 0, -1)
  pcall(vim.api.nvim_buf_set_extmark, buf, composer_ns, 0, 0, {
    id = 99, virt_lines = { { { " ", "Normal" } } }, virt_lines_above = true })
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines == 1 and lines[1] == "" then
    local branch = git_branch()
    local short = branch:match("^([^%s%.]+)") or "HEAD"
    pcall(vim.api.nvim_buf_set_extmark, buf, composer_ns, 0, 0, {
      id = 100, virt_text = { { "Message (Ctrl+Enter to commit on " .. short .. ")", "Comment" } },
      virt_text_pos = "overlay" })
  end
end
function M.git_ensure_subwindows()
  local list_win = M.ensure_win()
  if not (M.gitstate.comp_win and vim.api.nvim_win_is_valid(M.gitstate.comp_win)) then
    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(list_win)
    vim.cmd("aboveleft 5split")
    M.gitstate.comp_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(M.gitstate.comp_win, 5)
    vim.wo[M.gitstate.comp_win].winfixheight = true
    if not (M.gitstate.comp_buf and vim.api.nvim_buf_is_valid(M.gitstate.comp_buf)) then
      M.gitstate.comp_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[M.gitstate.comp_buf].buftype = "acwrite"; vim.bo[M.gitstate.comp_buf].swapfile = false
      vim.b[M.gitstate.comp_buf].forge_panel_kind = "gitmeta"
      vim.b[M.gitstate.comp_buf].forge_label = "ForgeCommitMessage"
      vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = M.gitstate.comp_buf, callback = function() M.git_commit() end })
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { buffer = M.gitstate.comp_buf, callback = function() M.paint_composer_placeholder() end })
    end
    vim.api.nvim_win_set_buf(M.gitstate.comp_win, M.gitstate.comp_buf)
    local cbuf = M.gitstate.comp_buf
    vim.keymap.set({ "n", "i" }, "<C-CR>", function() M.git_commit() end, { buffer = cbuf })
    vim.keymap.set("n", "C", function() M.git_commit() end, { buffer = cbuf })
    vim.keymap.set("n", "<Tab>", function()
      if valid_win() then vim.api.nvim_set_current_win(M.win) end
    end, { buffer = cbuf })
    vim.keymap.set("n", "q", function() if valid_win() then vim.api.nvim_set_current_win(M.win) end end, { buffer = cbuf })
    if vim.api.nvim_win_is_valid(cur) and cur ~= M.gitstate.comp_win then vim.api.nvim_set_current_win(cur) end
  end
  if not (M.gitstate.log_win and vim.api.nvim_win_is_valid(M.gitstate.log_win)) then
    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(list_win)
    vim.cmd("belowright split")
    M.gitstate.log_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(M.gitstate.log_win, math.max(3, math.floor(vim.o.lines * 0.30)))
    vim.wo[M.gitstate.log_win].winfixheight = true
    if vim.api.nvim_win_is_valid(cur) and cur ~= M.gitstate.log_win then vim.api.nvim_set_current_win(cur) end
  end
  local log_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[log_buf].buftype = "nofile"; vim.bo[log_buf].bufhidden = "wipe"
  vim.b[log_buf].forge_panel_kind = "gitmeta"
  local log = git_out({ "-c", "color.ui=never", "log", "--graph", "--oneline", "--decorate", "--no-color", "--max-count=40" })
  local entries = {}
  for line in vim.gsplit(log, "\n", { plain = true, trimempty = true }) do entries[#entries+1] = line end
  local llines = { "  COMMITS  (" .. #entries .. ")", "  Enter show  Tab files" }
  if #entries == 0 then llines[#llines+1] = "     No commits"
  else for _, e in ipairs(entries) do llines[#llines+1] = " " .. e end end
  vim.api.nvim_buf_set_lines(log_buf, 0, -1, false, llines)
  vim.bo[log_buf].modifiable = false
  vim.b[log_buf].forge_label = "ForgeGitLog"
  vim.api.nvim_win_set_buf(M.gitstate.log_win, log_buf)
  paint_hl(log_buf, 0, "GitButton")
  paint_hl(log_buf, 1, "GitHelp")
  for i, e in ipairs(entries) do paint_hl(log_buf, i + 1, e:match("(%x%x%x%x%x%x%x+)") and "GitButton" or "GitHelp") end
  vim.keymap.set("n", "<CR>", function()
    if vim.api.nvim_win_get_cursor(0)[1] <= 2 then return end
    local hash = vim.api.nvim_get_current_line():match("(%x%x%x%x%x%x%x+)")
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

-- SETTINGS -------------------------------------------------------------------
local setting_rows = {}
function M.render_settings()
  local s = require("forge.settings")
  local cur = s.get()
  local lines = { "", "  Enter/click to change. x resets. q: Files.", "" }
  setting_rows = {}
  local section
  for _, o in ipairs(s.options) do
    if section ~= o.section then
      section = o.section
      lines[#lines+1] = "  " .. section
    end
    local value = cur[o.key]
    local display
    if o.kind == "theme" then display = require("forge.themes").label(value)
    elseif type(value) == "boolean" then display = value and "On" or "Off"
    else display = tostring(value) end
    lines[#lines+1] = "    " .. o.label .. ": " .. display .. (o.restart and " (restart)" or "")
    setting_rows[#lines] = { kind = "setting", option = o }
  end
  lines[#lines+1] = ""
  lines[#lines+1] = "  [Reload config]"; setting_rows[#lines] = { kind = "reload" }
  lines[#lines+1] = "  [Command palette]"; setting_rows[#lines] = { kind = "palette" }
  local buf = render(lines, "ForgeSettings")
  paint_hl(buf, 1, "SetupHelp")
  for i, line in ipairs(lines) do
    if setting_rows[i] then paint_hl(buf, i - 1, setting_rows[i].kind == "setting" and "SetupChoiceOn" or "SetupButton")
    elseif line:match("^  %w") and i > 3 then paint_hl(buf, i - 1, "SetupSection") end
  end
  local function activate()
    local r = setting_rows[vim.api.nvim_win_get_cursor(0)[1]]
    if not r then return end
    if r.kind == "reload" then s.reload(); M.render_settings()
    elseif r.kind == "palette" then vim.cmd("ForgePalette")
    elseif r.kind == "setting" then
      local o = r.option
      if o.kind == "boolean" then s.toggle(o.key)
      elseif o.kind == "theme" then
        local list = require("forge.themes").list
        for i, th in ipairs(list) do if th.id == cur.theme then s.set("theme", list[i % #list + 1].id); break end end
      elseif o.kind == "choice" then s.cycle(o.key) end
      M.render_settings()
    end
  end
  vim.keymap.set("n", "<CR>", activate, { buffer = buf })
  vim.keymap.set("n", "x", function()
    local r = setting_rows[vim.api.nvim_win_get_cursor(0)[1]]
    if r and r.kind == "setting" then s.reset(r.option.key); M.render_settings() end
  end, { buffer = buf })
end

-- THEMES ---------------------------------------------------------------------
local theme_rows = {}
function M.render_themes()
  local themes = require("forge.themes")
  local query = M.theme_filter or ""
  local active = require("forge.settings").get().theme
  local lines = { "", "  > " .. (query == "" and "Search themes..." or query), "" }
  theme_rows = { [2] = { kind = "search" } }
  for _, th in ipairs(themes.list) do
    if query == "" or th.label:lower():find(query:lower(), 1, true) then
      lines[#lines+1] = "  " .. (th.id == active and (vim.fn.nr2char(0x25CF) .. " ") or "  ") .. th.label
      theme_rows[#lines] = { kind = "theme", id = th.id }
      lines[#lines+1] = "    " .. themes.flavor_for(th.id)
      theme_rows[#lines] = { kind = "theme", id = th.id }
    end
  end
  if #lines == 3 then lines[#lines+1] = "    No matches" end
  local buf = render(lines, "ForgeThemes")
  paint_hl(buf, 1, "SetupHelp")
  for i, r in pairs(theme_rows) do
    if r.kind == "theme" then paint_hl(buf, i - 1, r.id == active and "SetupChoiceOn" or "SetupChoiceOff") end
  end
  local function search()
    vim.ui.input({ prompt = "Search themes: ", default = query }, function(q)
      M.theme_filter = q or ""
      M.render_themes()
    end)
  end
  vim.keymap.set("n", "<CR>", function()
    local r = theme_rows[vim.api.nvim_win_get_cursor(0)[1]]
    if not r then return end
    if r.kind == "search" then search()
    else require("forge.themes").apply(r.id); M.render_themes() end
  end, { buffer = buf })
  vim.keymap.set("n", "/", search, { buffer = buf })
end

-- EXTENSIONS -----------------------------------------------------------------
local ext_rows = {}
local mason_query = ""
local featured_tools = { "lua-language-server", "pyright", "typescript-language-server", "rust-analyzer",
  "gopls", "prettierd", "stylua", "eslint-lsp", "bash-language-server", "dockerfile-language-server",
  "yaml-language-server" }
local function short(s, n) s = tostring(s or ""); return #s > n and s:sub(1, n - 1) .. "…" or s end
function M.render_extensions()
  local ext = require("forge.extensions")
  local win_w = math.max(20, M.width() - 4)
  local lines = { "", "  Mason tools and Neovim plugins", "  > " .. (mason_query == "" and "Search Mason extensions..." or mason_query), "" }
  ext_rows = { [3] = { kind = "mason_search" } }
  local ok, registry = pcall(require, "mason-registry")
  if ok then
    local installed = {}
    pcall(function() installed = registry.get_installed_package_names() end)
    table.sort(installed)
    local installed_set = {}
    for _, n in ipairs(installed) do installed_set[n] = true end
    local results = {}
    if mason_query == "" then
      for _, name in ipairs(featured_tools) do results[#results+1] = name end
    else
      pcall(function()
        for _, name in ipairs(registry.get_all_package_names()) do
          if name:lower():find(mason_query:lower(), 1, true) then results[#results+1] = name end
        end
      end)
    end
    lines[#lines+1] = "  MARKETPLACE  " .. (mason_query == "" and "Featured" or (#results .. " results"))
    if #results == 0 then lines[#lines+1] = "  No matches. Try another search." end
    for i = 1, math.min(#results, 40) do
      local name = results[i]
      local desc, category = "Mason package", "Tool"
      pcall(function()
        local pkg = registry.get_package(name)
        local spec = pkg and (pkg.spec or pkg)
        if spec then desc = spec.description or desc; category = (spec.categories and spec.categories[1]) or category end
      end)
      local action = { kind = "mason_package", name = name, installed = installed_set[name] or false }
      lines[#lines+1] = "  " .. vim.fn.nr2char(0x25C6) .. " " .. short(name, win_w - 4); ext_rows[#lines] = action
      lines[#lines+1] = "    " .. short(desc, win_w - 4); ext_rows[#lines] = action
      lines[#lines+1] = "    " .. short(category, math.max(1, win_w - 17)) .. "  [" .. (action.installed and "Installed" or "Install") .. "]"; ext_rows[#lines] = action
      lines[#lines+1] = ""
    end
    lines[#lines+1] = "  INSTALLED  " .. #installed
    for _, name in ipairs(installed) do
      lines[#lines+1] = "  " .. vim.fn.nr2char(0x25C6) .. " " .. short(name, win_w - 4) .. "  [Remove]"
      ext_rows[#lines] = { kind = "mason_package", name = name, installed = true }
    end
  else
    lines[#lines+1] = "  Mason unavailable"
  end
  lines[#lines+1] = ""
  lines[#lines+1] = "  MORE ACTIONS"
  for _, item in ipairs({
    { "Search Neovim plugins", "search_plugins" }, { "Add GitHub repository", "add" },
    { "Open Mason full manager", "mason" }, { "Refresh Mason registry", "mason_refresh" },
    { "Install syntax parser", "parser" }, { "Reload Neovim", "restart" },
  }) do
    lines[#lines+1] = "  [" .. item[1] .. "]"
    ext_rows[#lines] = { kind = item[2] }
  end
  lines[#lines+1] = ""
  lines[#lines+1] = "  NEOVIM PLUGINS"
  local mine = ext.read()
  if #mine == 0 then lines[#lines+1] = "  None added yet" end
  for _, id in ipairs(mine) do
    lines[#lines+1] = "  " .. vim.fn.nr2char(0x25C6) .. " " .. short(id, win_w - 4) .. "  [Remove]"
    ext_rows[#lines] = { kind = "plugin", id = id }
  end
  local buf = render(lines, "ForgeExtensionsPanel")
  for i, line in ipairs(lines) do
    if i == 2 then paint_hl(buf, i - 1, "SetupHelp")
    elseif i == 3 then paint_hl(buf, i - 1, "SetupButton")
    elseif line:match("^  [A-Z][A-Z ]+%s") or line:match("^  MARKETPLACE") or line:match("^  INSTALLED") or line:match("^  MORE ACTIONS") or line:match("^  NEOVIM PLUGINS") then paint_hl(buf, i - 1, "SetupSection")
    elseif line:find("%[Install%]") or line:find("%[Installed%]") then paint_hl(buf, i - 1, "SetupChoiceOn")
    elseif line:match("^  %[") then paint_hl(buf, i - 1, "SetupButton")
    elseif line:find(vim.fn.nr2char(0x25C6), 1, true) then paint_hl(buf, i - 1, "SetupTitle")
    elseif line:match("^    ") then paint_hl(buf, i - 1, "SetupHelp") end
  end
  local function mason_search()
    vim.ui.input({ prompt = "Search Mason extensions: ", default = mason_query }, function(q)
      mason_query = q or ""
      M.render_extensions()
    end)
  end
  vim.keymap.set("n", "<CR>", function()
    local r = ext_rows[vim.api.nvim_win_get_cursor(0)[1]]
    if not r then return end
    if r.kind == "mason_search" then mason_search()
    elseif r.kind == "mason_package" then
      if r.installed then
        if vim.fn.confirm("Remove " .. r.name .. "?", "&Yes\n&No", 2) == 1 then vim.cmd("MasonUninstall " .. r.name) end
      else vim.cmd("MasonInstall " .. r.name) end
    elseif r.kind == "plugin" then
      if vim.fn.confirm("Remove " .. r.id .. "?", "&Yes\n&No", 2) == 1 then ext.remove(r.id); M.render_extensions() end
    elseif r.kind == "add" then
      vim.ui.input({ prompt = "GitHub owner/repository: " }, function(id)
        if id and id ~= "" then ext.add(id); M.render_extensions() end
      end)
    elseif r.kind == "search_plugins" then
      vim.ui.input({ prompt = "Plugin (owner/repo): " }, function(id)
        if id and id ~= "" then ext.add(id); M.render_extensions() end
      end)
    elseif r.kind == "mason" then vim.cmd("Mason")
    elseif r.kind == "mason_refresh" then vim.cmd("MasonUpdate")
    elseif r.kind == "parser" then
      vim.ui.input({ prompt = "Tree-sitter parser: " }, function(p)
        if p and p ~= "" then vim.cmd("TSInstall " .. p) end
      end)
    elseif r.kind == "restart" then vim.cmd("ForgeRestart") end
  end, { buffer = buf })
  vim.keymap.set("n", "/", mason_search, { buffer = buf })
end

-- MODE SWITCH ---------------------------------------------------------------
function M.set_mode(mode, focus)
  if not vim.tbl_contains(M.modes, mode) then return end
  if mode ~= "git" and M.close_git_extras then M.close_git_extras() end
  M.mode = mode
  local win = M.ensure_win()
  if mode == "files" then
    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(win)
    local ok_tree, tree = pcall(require, "forge.tree")
    local ok = ok_tree and tree.open_in(win)
    if not ok then render({ "", "  Files", "", "  File tree loads with the plugin set.", "  Run :Lazy sync on first launch." }, "ForgeFiles") end
    if not focus and vim.api.nvim_win_is_valid(cur) and cur ~= win then vim.api.nvim_set_current_win(cur) end
  elseif mode == "git" then M.render_git()
  elseif mode == "settings" then M.render_settings()
  elseif mode == "themes" then M.render_themes()
  elseif mode == "extensions" then M.render_extensions() end
  if focus and valid_win() then vim.api.nvim_set_current_win(M.win) end
  vim.cmd("redraw")
end
function M.close() M.close_git_extras(); if valid_win() then pcall(vim.api.nvim_win_close, M.win, false); M.win = nil end end
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
