-- Headless validator: load core in minimal mode and assert the public contract.
vim.env.FORGE_MINIMAL = "1"
local root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:p"), ":h:h")
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
local gl = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(sb.win), 0, 2, false)
expect(table.concat(gl):find("GIT") ~= nil, "sidebar git panel renders")
sb.set_mode("themes", false)
local tl = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(sb.win), 0, -1, false)
expect(#tl >= 28, "sidebar themes panel lists all themes")
sb.set_mode("settings", false)
expect(sb.mode == "settings", "sidebar settings mode")
if #fails > 0 then print("FORGE VALIDATE FAIL: " .. table.concat(fails, "; ")); vim.cmd("cquit 1") end
print("FORGE VALIDATE OK: core, agents(7), themes(28), settings, commands")
vim.cmd("qa")
