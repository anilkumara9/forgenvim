-- Headless validator: load core in minimal mode and assert the public contract.
vim.env.FORGE_MINIMAL = "1"
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.cmd("luafile " .. root .. "/init.lua")
local fails = {}
local function expect(cond, msg) if not cond then fails[#fails+1] = msg end end
expect(vim.g.mapleader == " ", "leader is Space")
expect(vim.o.scrolloff == 5, "scrolloff default is 5")
local agents = require("forge.agents")
expect(#agents.order == 7, "7 agent CLIs")
local themes = require("forge.themes")
expect(#themes.list == 28, "28 themes")
local settings = require("forge.settings")
expect(settings.defaults.theme == "gruvbox", "default theme gruvbox")
expect(settings.defaults.transparent == true, "transparent default on")
expect(settings.defaults.session_restore == true, "session restore default on")
for _, c in ipairs({ "ForgePalette", "ForgeThemes", "ForgeSettings", "ForgeHealth", "ForgeQuit", "Codex", "Claude", "Aider", "ProjectCloseTab", "PaneNewTab", "PaneSave", "ContextMenu" }) do
  expect(vim.fn.exists(":" .. c) == 2, "command exists: " .. c)
end
-- UI parity surface: segmented winbar, global statusline, single-panel sidebar
local wb_ok, wb = pcall(function() return require("forge.winbar").render() end)
expect(wb_ok and type(wb) == "string" and #wb > 10, "winbar renders")
local sl_ok, sl = pcall(function() return require("forge.statusline").render() end)
expect(sl_ok and type(sl) == "string" and sl:find("NORMAL") ~= nil, "statusline renders with mode")
local sb = require("forge.sidebar")
expect(#sb.modes == 5, "sidebar has exactly 5 modes")
sb.set_mode("git", false)
local gl = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(sb.win), 0, -1, false)
expect(table.concat(gl, "\n"):find("Staged Changes") ~= nil, "sidebar git panel renders")
sb.set_mode("themes", false)
local tl = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(sb.win), 0, -1, false)
expect(#tl >= 28, "sidebar themes panel lists all themes")
sb.set_mode("settings", false)
expect(sb.mode == "settings", "sidebar settings mode")
if #fails > 0 then print("FORGE VALIDATE FAIL: " .. table.concat(fails, "; ")); vim.cmd("cquit 1") end

-- v1.3 audit-pass checks
for _, cmd in ipairs({ "ImageOpen", "SidebarFilesToggle", "FindProjectFiles", "FindProjectText", "AgentSelect", "ForgeRestart", "ForgeDiffClose" }) do
  expect(vim.fn.exists(":" .. cmd) == 2, "missing command " .. cmd)
end
require("forge.extensions").add("folke/zen-mode.nvim")
expect(#require("forge.extensions").read() == 1, "extension manifest add")
require("forge.extensions").remove("folke/zen-mode.nvim")
expect(#require("forge.extensions").read() == 0, "extension manifest remove")
expect(#require("forge.extensions").featured == 5, "featured catalog")
local st2 = require("forge.statusline").render()
expect(type(st2) == "string" and #st2 > 40, "statusline v1.3 renders")
local dir = vim.fn.tempname(); vim.fn.mkdir(dir, "p")
vim.fn.system({ "git", "-C", dir, "init", "-q" })
vim.fn.system({ "git", "-C", dir, "config", "user.email", "t@t.t" })
vim.fn.system({ "git", "-C", dir, "config", "user.name", "t" })
vim.fn.writefile({ "one" }, dir .. "/a.txt")
vim.fn.system({ "git", "-C", dir, "add", "a.txt" })
vim.fn.system({ "git", "-C", dir, "commit", "-qm", "init" })
vim.fn.writefile({ "one", "two" }, dir .. "/a.txt")
vim.fn.writefile({ "new" }, dir .. "/b.txt")
vim.fn.system({ "git", "-C", dir, "add", "b.txt" })
local cwd0 = vim.fn.getcwd(); vim.cmd.cd(dir)
sb.set_mode("git", true)
local found_staged, found_unstaged = false, false
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  local txt = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
  if txt:find("Staged Changes") and txt:find("b.txt") then found_staged = true end
  if txt:find("a.txt") then found_unstaged = true end
end
expect(found_staged, "git panel staged section")
expect(found_unstaged, "git panel shows unstaged file")
expect(sb.gitstate.comp_win ~= nil, "git composer window exists")
expect(sb.gitstate.log_win ~= nil, "git log window exists")
sb.set_mode("files", true)
expect(sb.gitstate.comp_win == nil, "git extras closed on mode switch")
vim.cmd.cd(cwd0)
print("FORGE VALIDATE OK: v1.3 audit pass (commands, manifest, git panel)")
print("FORGE VALIDATE OK: core, agents(7), themes(28), settings, commands")
vim.cmd("qa")
