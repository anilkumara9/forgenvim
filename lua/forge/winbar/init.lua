-- Top bar, segmented per window so the three segments form one continuous
-- strip across the screen:
--   sidebar window  ->  " Files | Git | Settings | Themes | Extensions "
--   editor window   ->  editor tabs on the left, "+" for a new tab
--   chat window     ->  chat tabs, "+" for a new chat
-- Active editor tab is highlighted with the theme accent; separators use
-- powerline glyphs. Overflow scrolls with the chevron buttons.
local M = { offset = 0 }
local function hl(name) local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false }); return ok and h or {} end
local function hex(n) return n and ("#%06x"):format(n) or "none" end
function M.setup_highlights()
  local normal = hl("Normal"); local bg = hex(normal.bg)
  local accent_h = hl("Function"); if not accent_h.fg then accent_h = hl("Title") end
  local accent = hex(accent_h.fg); local muted = hex((hl("Comment")).fg)
  vim.api.nvim_set_hl(0, "ForgeTabActive", { bg = accent, fg = bg, bold = true })
  vim.api.nvim_set_hl(0, "ForgeTabInactive", { bg = "none", fg = muted })
  vim.api.nvim_set_hl(0, "ForgeTabFill", { bg = "none", fg = muted })
  vim.api.nvim_set_hl(0, "ForgeTabAccentFg", { fg = accent, bg = "none" })
  vim.api.nvim_set_hl(0, "ForgeSideActive", { fg = accent, bold = true })
  vim.api.nvim_set_hl(0, "ForgeSideInactive", { fg = muted })
  pcall(vim.api.nvim_set_hl, 0, "WinBar", { bg = "none" })
  pcall(vim.api.nvim_set_hl, 0, "WinBarNC", { bg = "none" })
end
local function click(id, handler, label, group)
  return "%#" .. group .. "#%" .. tostring(id) .. "@" .. handler .. "@" .. label .. "%X"
end
-- Click handlers (winbar %@{id}@ syntax passes the id as first argument)
function M.click_buffer(bufnr) if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_set_current_buf(bufnr) end end
function M.click_new() require("forge.tabs").new_context() end
function M.click_close(bufnr) vim.api.nvim_set_current_buf(bufnr); require("forge.tabs").close() end
function M.click_chat(id) require("forge.agents").show(id) end
function M.click_new_chat() require("forge.agents").select() end
function M.click_side(mode) require("forge.sidebar").set_mode(mode) end
function M.click_scroll(dir) M.offset = math.max(0, M.offset + dir); vim.cmd("redrawtabline"); vim.cmd("redrawstatus") end
local side_modes = { { "files", "Files" }, { "git", "Git" }, { "settings", "Settings" }, { "themes", "Themes" }, { "extensions", "Extensions" } }
local side_ids = { files = 1, git = 2, settings = 3, themes = 4, extensions = 5 }
local function sidebar_segment()
  local mode = "files"
  local ok, sb = pcall(require, "forge.sidebar"); if ok and sb.mode then mode = sb.mode end
  local w = vim.api.nvim_win_get_width(vim.api.nvim_get_current_win())
  local parts = {}
  if w >= 52 then parts[#parts + 1] = " " end
  for i, m in ipairs(side_modes) do
    local group = (m[1] == mode) and "ForgeSideActive" or "ForgeSideInactive"
    local text
    if w >= 52 then text = ((m[1] == mode) and "● " or "○ ") .. m[2]
    elseif w >= 37 then text = m[2]
    else text = m[2]:sub(1, 1) end
    parts[#parts + 1] = click(side_ids[m[1]], "v:lua.require'forge.winbar'.click_side_by_id", text, group)
    if i < #side_modes then parts[#parts + 1] = (w >= 52) and " │ " or "│" end
  end
  return table.concat(parts)
end
local function editor_buffers()
  local out = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
      and not vim.b[buf].chat_id then out[#out+1] = buf end
  end
  return out
end
local function editor_segment(winwidth)
  local bufs = editor_buffers(); local cur = vim.api.nvim_get_current_buf()
  local parts = {}
  local start = M.offset + 1
  if M.offset > 0 then parts[#parts+1] = click(-1, "v:lua.require'forge.winbar'.click_scroll_left", " ‹ ", "ForgeTabInactive") end
  local used = 0
  for i = start, #bufs do
    local buf = bufs[i]
    local name = vim.api.nvim_buf_get_name(buf)
    local label = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")
    if require("forge.settings").get().icons then
      local okd, dv = pcall(require, "nvim-web-devicons")
      if okd then
        local icon = dv.get_icon(label, label:match("%.(%w+)$"), { default = true })
        if icon then label = icon .. " " .. label end
      end
    end
    if vim.bo[buf].modified then label = label .. " ●" end
    label = " " .. label .. " × "
    used = used + vim.fn.strdisplaywidth(label) + 1
    if winwidth > 0 and used > winwidth and i > start then
      parts[#parts+1] = click(1, "v:lua.require'forge.winbar'.click_scroll_right", " › ", "ForgeTabInactive"); break
    end
    if buf == cur then
      parts[#parts+1] = "%#ForgeTabAccentFg#"
      parts[#parts+1] = click(buf, "v:lua.require'forge.winbar'.click_buffer", label, "ForgeTabActive")
      parts[#parts+1] = "%#ForgeTabAccentFg#"
    else
      parts[#parts+1] = click(buf, "v:lua.require'forge.winbar'.click_buffer", label, "ForgeTabInactive") .. "%#ForgeTabInactive#"
    end
  end
  parts[#parts+1] = click(0, "v:lua.require'forge.winbar'.click_new", " + ", "ForgeTabInactive")
  return table.concat(parts)
end
function M.click_scroll_left() M.click_scroll(-3) end
function M.click_scroll_right() M.click_scroll(3) end
local function chat_segment()
  local agents = package.loaded["forge.agents"]
  local parts = {}
  if agents and agents.sessions then
    local ids = vim.tbl_keys(agents.sessions); table.sort(ids)
    for _, id in ipairs(ids) do
      local s = agents.sessions[id]
      if s and not s.exited then
        local group = (agents.active == id) and "ForgeTabActive" or "ForgeTabInactive"
        parts[#parts+1] = click(id, "v:lua.require'forge.winbar'.click_chat", " " .. s.label .. " ", group)
        parts[#parts+1] = "%#ForgeTabInactive#"
      end
    end
  end
  parts[#parts+1] = click(0, "v:lua.require'forge.winbar'.click_new_chat", " + ", "ForgeTabInactive")
  return table.concat(parts)
end
local function window_kind()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  if vim.b[buf].forge_panel_kind == "gitmeta" then return "gitmeta" end
  if ft == "neo-tree" or vim.b[buf].forge_sidebar then return "sidebar" end
  if vim.b[buf].chat_id then return "chat" end
  local agents = package.loaded["forge.agents"]
  if agents and agents.win and vim.api.nvim_get_current_win() == agents.win then return "chat" end
  return "editor"
end
function M.render()
  local ok, result = pcall(function()
    local kind = window_kind()
    local width = vim.api.nvim_win_get_width(0)
    if kind == "gitmeta" then return "%#ForgeSideInactive# " .. (vim.b[vim.api.nvim_get_current_buf()].forge_panel_title or "") end
    if kind == "sidebar" then return sidebar_segment() end
    if kind == "chat" then return chat_segment() end
    return editor_segment(width)
  end)
  return ok and result or ""
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = function() M.setup_highlights() end })
M.setup_highlights()
vim.o.winbar = "%{%v:lua.require('forge.winbar').render()%}"
return M
