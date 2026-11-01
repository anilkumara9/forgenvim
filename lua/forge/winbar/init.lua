-- Top bar, one segment per window, forming a single continuous strip:
--   sidebar window -> mode tabs: the active mode is a filled pill with its
--     icon and label; the other modes show as icons; powerline separators
--     join them.
--   editor window  -> buffer tabs with powerline dividers, file icons in
--     their own colours, a close button per tab and a + for a new tab.
--   chat window    -> session tabs right-aligned, close button first.
-- Colours come from the active theme's chrome tokens (forge.appearance).
local M = { offset = 0 }
local api = vim.api
local function click(id, handler, label, group)
  return "%#" .. group .. "#%" .. tostring(id) .. "@v:lua.require'forge.winbar'." .. handler .. "@" .. label .. "%X"
end
-- Click handlers (the numeric id arrives as the first argument)
function M.click_buffer(bufnr) if api.nvim_buf_is_valid(bufnr) then api.nvim_set_current_buf(bufnr) end end
function M.click_new() require("forge.tabs").new_context() end
function M.click_close(bufnr) if api.nvim_buf_is_valid(bufnr) then vim.api.nvim_set_current_buf(bufnr); require("forge.tabs").close() end end
function M.click_chat(id) require("forge.agents").show(id) end
function M.click_chat_close(id) require("forge.agents").close(id) end
function M.click_new_chat() require("forge.agents").select() end
function M.click_side(mode) require("forge.sidebar").set_mode(mode, true) end
local side_ids = { files = 1, git = 2, settings = 3, themes = 4, extensions = 5 }
function M.click_side_by_id(id) for name, i in pairs(side_ids) do if i == id then M.click_side(name) end end end
function M.click_cycle(id) M.offset = math.max(0, M.offset + (id == 1 and -1 or 1)); vim.cmd("redrawstatus") end
function M.click_scroll(dir) M.click_cycle(dir < 0 and 1 or 2) end
function M.click_scroll_left() M.click_cycle(1) end
function M.click_scroll_right() M.click_cycle(2) end
function M.setup_highlights() require("forge.appearance").apply_highlights() end

local function escape(s) return (tostring(s):gsub("%%", "%%%%"):gsub("[\r\n]", " ")) end
local function ch(cp) return vim.fn.nr2char(cp) end
local GLYPH = { solid_r = ch(0xE0B0), solid_l = ch(0xE0B2), thin_r = ch(0xE0B1), thin_l = ch(0xE0B3) }
function M.divider(solid, reverse, join)
  if join then return "%#PaneTabJoinSep#" .. (reverse and GLYPH.solid_l or GLYPH.solid_l) end
  if reverse then return (solid and "%#PaneTabActiveSep#" or "%#PaneTabSep#") .. (solid and GLYPH.solid_l or GLYPH.thin_l) end
  return (solid and "%#PaneTabActiveSep#" or "%#PaneTabSep#") .. (solid and GLYPH.solid_r or GLYPH.thin_r)
end
local function icon_hl(src)
  local kind = tostring(src or "Normal"):gsub("[^%w]", "")
  if kind == "" then kind = "Normal" end
  local name = "ForgeTabIcon" .. kind
  local ok, h = pcall(api.nvim_get_hl, 0, { name = kind, link = false })
  local fg = ok and h.fg or nil
  if not fg then local ok2, n = pcall(api.nvim_get_hl, 0, { name = "Normal", link = false }); fg = ok2 and n.fg or nil end
  pcall(api.nvim_set_hl, 0, name, { fg = fg })
  return name
end
local function file_icon(name)
  if not require("forge.settings").get().icons then return nil, nil end
  local ok, dv = pcall(require, "nvim-web-devicons")
  if not ok or not dv.get_icon then return nil, nil end
  local icon, hl = dv.get_icon(vim.fn.fnamemodify(name, ":t"), vim.fn.fnamemodify(name, ":e"), { default = true })
  if type(icon) == "string" and icon ~= "" and icon ~= " " then return icon, hl end
  return nil, nil
end
local function tab(item, click_cb, close_cb, reverse)
  local hl = item.active and "PaneTabActive" or "PaneTabInactive"
  local body = escape(item.label)
  if item.icon then
    local glyph = item.active and hl or icon_hl(item.icon_hl)
    body = "%#" .. glyph .. "#" .. escape(item.icon) .. " %#" .. hl .. "#" .. body
  end
  local function clickable(cb, text) return click(item.id, cb, text, hl) end
  if reverse then return clickable(close_cb, " × ") .. clickable(click_cb, body .. " ") end
  return clickable(click_cb, " " .. body) .. clickable(close_cb, " × ")
end
-- Append a windowed run of tabs (same windowing as the reference layout:
-- slots of ~14 cells, labels truncated with an ellipsis, overflow cyclers).
local function append(out, items, click_cb, close_cb, reverse, available)
  local active = 1
  for i, item in ipairs(items) do if item.active then active = i end end
  local slots = math.max(1, math.floor(available / 14))
  local first = math.max(1, math.min(active - math.floor(slots / 2), #items - slots + 1))
  local last = math.min(#items, first + slots - 1)
  local label_width = math.max(4, math.floor(available / math.max(1, last - first + 1)) - 4)
  local last_active = false
  for i = first, last do
    if i > first then
      local solid
      if reverse then solid = items[i].active else solid = items[i - 1].active end
      local join = (not solid) and ((reverse and items[i - 1].active) or ((not reverse) and items[i].active)) or false
      out[#out + 1] = M.divider(solid, reverse, join)
    end
    local item = items[i]
    local label = item.label
    local icon_pad = item.icon and (vim.fn.strdisplaywidth(item.icon) + 1) or 0
    local max_label = math.max(1, label_width - icon_pad)
    if vim.fn.strdisplaywidth(label) > max_label then
      label = vim.fn.strcharpart(label, 0, math.max(1, max_label - 1)) .. "…"
    end
    local copy = vim.tbl_extend("force", item, { label = label })
    out[#out + 1] = tab(copy, click_cb, close_cb, reverse)
  end
  last_active = items[last] and items[last].active or false
  if #items > slots then
    out[#out + 1] = M.divider(last_active and not reverse, reverse, last_active and reverse)
    out[#out + 1] = click(1, "click_cycle", " ‹ ", "PaneTabInactive") .. click(2, "click_cycle", " › ", "PaneTabInactive")
    last_active = false
  end
  return last_active
end

local side_items = {
  { view = "files", icon = ch(0xF0F6), label = "Files" },
  { view = "git", icon = ch(0xE725), label = "Git" },
  { view = "settings", icon = ch(0xE615), label = "Settings" },
  { view = "themes", icon = ch(0xE22B), label = "Themes" },
  { view = "extensions", icon = ch(0xF1E6), label = "Extensions" },
}
local function sidebar_segment()
  local sb = require("forge.sidebar")
  local out = {}
  for i, item in ipairs(side_items) do
    local active = sb.mode == item.view
    local last = i == #side_items
    if active then
      out[#out + 1] = click(side_ids[item.view], "click_side_by_id", " " .. item.icon .. " " .. item.label .. " ", "SidebarTabActive")
    else
      out[#out + 1] = click(side_ids[item.view], "click_side_by_id", " " .. item.icon .. " ", "SidebarTabInactive")
    end
    if not last then
      if active then out[#out + 1] = "%#SidebarTabActiveSep#"
      elseif sb.mode == side_items[i + 1].view then out[#out + 1] = "%#SidebarTabJoinSep#"
      else out[#out + 1] = "%#SidebarTabInactiveSep#" end
    elseif active then
      out[#out + 1] = "%#SidebarTabActiveSep#"
    end
  end
  out[#out + 1] = "%#WinBar#"
  return table.concat(out)
end

local function editor_buffers()
  local out = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
      and not vim.b[buf].chat_id and not vim.b[buf].forge_sidebar then
      out[#out + 1] = buf
    end
  end
  return out
end
local function editor_segment(win)
  local buf = api.nvim_win_get_buf(win)
  local available = math.max(8, api.nvim_win_get_width(win) - 16)
  local items = {}
  for _, b in ipairs(editor_buffers()) do
    local name = api.nvim_buf_get_name(b)
    local label = name == "" and "[New]" or vim.fn.fnamemodify(name, ":t")
    local icon, ihl
    if name ~= "" then icon, ihl = file_icon(name) end
    items[#items + 1] = { id = b, label = label .. (vim.bo[b].modified and " ●" or ""), icon = icon, icon_hl = ihl, active = b == buf }
  end
  local out = {}
  local last_active = append(out, items, "click_buffer", "click_close", false, available)
  if #out > 0 then out[#out + 1] = M.divider(last_active, false) end
  out[#out + 1] = click(0, "click_new", " + ", "PaneTabInactive")
  return table.concat(out) .. "%#WinBar#"
end
local function chat_segment(win)
  local buf = api.nvim_win_get_buf(win)
  local agents = require("forge.agents")
  local ids = vim.tbl_keys(agents.sessions); table.sort(ids)
  local items = {}
  for _, id in ipairs(ids) do
    local s = agents.sessions[id]
    if s and not s.exited and api.nvim_buf_is_valid(s.buf) then
      items[#items + 1] = { id = id, label = s.label, active = s.buf == buf }
    end
  end
  local available = math.max(8, api.nvim_win_get_width(win) - 16)
  local out = {}
  out[#out + 1] = click(0, "click_new_chat", " + ", "PaneTabInactive")
  if #items > 0 then out[#out + 1] = M.divider(items[1].active, true) end
  append(out, items, "click_chat", "click_chat_close", true, available)
  return "%#WinBar#%=" .. table.concat(out) .. "%#WinBar#"
end

local function window_kind(win)
  local buf = api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype
  if vim.b[buf].forge_panel_kind == "gitmeta" then return "gitmeta" end
  if ft == "NvimTree" or vim.b[buf].forge_sidebar then return "sidebar" end
  if vim.b[buf].chat_id then return "chat" end
  local agents = package.loaded["forge.agents"]
  if agents and agents.win and win == agents.win then return "chat" end
  return "editor"
end
function M.render()
  local ok, result = pcall(function()
    local win = vim.g.statusline_winid
    if not win or not api.nvim_win_is_valid(win) then win = api.nvim_get_current_win() end
    local kind = window_kind(win)
    if kind == "gitmeta" then return "" end
    if kind == "sidebar" then return sidebar_segment() end
    if kind == "chat" then return chat_segment(win) end
    return editor_segment(win)
  end)
  return ok and result or ""
end
vim.o.winbar = "%{%v:lua.require('forge.winbar').render()%}"
return M
