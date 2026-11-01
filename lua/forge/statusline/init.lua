-- One global status strip (laststatus=3) built from the active theme's
-- chrome tokens: a filled mode block with a powerline cap, git branch and
-- hunks, the focused file or chat, the chat's usage when one is focused,
-- then on the right the search position, diagnostics grouped by source,
-- language servers, file details, and a filled cursor block with a raise.
local M = {}
local api = vim.api
local modes = {
  n = { "NORMAL", "Normal" }, no = { "NORMAL", "Normal" }, nov = { "NORMAL", "Normal" },
  noV = { "NORMAL", "Normal" }, niI = { "NORMAL", "Normal" }, niR = { "NORMAL", "Normal" },
  niV = { "NORMAL", "Normal" }, i = { "INSERT", "Insert" }, ic = { "INSERT", "Insert" },
  ix = { "INSERT", "Insert" }, v = { "VISUAL", "Visual" }, vs = { "VISUAL", "Visual" },
  V = { "V-LINE", "Visual" }, ["\22"] = { "V-BLOCK", "Visual" }, s = { "SELECT", "Visual" },
  S = { "S-LINE", "Visual" }, ["\19"] = { "S-BLOCK", "Visual" }, r = { "REPLACE", "Replace" },
  R = { "REPLACE", "Replace" }, Rc = { "REPLACE", "Replace" }, Rv = { "V-REPLACE", "Replace" },
  c = { "COMMAND", "Command" }, cv = { "EX", "Command" }, ce = { "EX", "Command" },
  t = { "TERMINAL", "Terminal" }, ["!"] = { "SHELL", "Terminal" },
}
local CAP = vim.fn.nr2char(0xE0B0)
local RAISE = vim.fn.nr2char(0xE0B2)
local BRANCH = vim.fn.nr2char(0xE0A0)
local function escape(s) return (tostring(s):gsub("%%", "%%%%"):gsub("[\r\n]", " ")) end
local function git_info(buf)
  local d = vim.b[buf].gitsigns_status_dict
  if d and d.head and d.head ~= "" then
    return { head = d.head, added = d.added or 0, changed = d.changed or 0, removed = d.removed or 0 }
  end
  local out = vim.fn.system({ "git", "-C", vim.fn.getcwd(), "branch", "--show-current" })
  local head = vim.trim(out)
  if vim.v.shell_error == 0 and head ~= "" then return { head = head, added = 0, changed = 0, removed = 0 } end
  return nil
end
local function file_label(buf)
  if vim.b[buf].chat_id then
    local agents = package.loaded["forge.agents"]
    local s = agents and agents.sessions[vim.b[buf].chat_id]
    if s then return s.label, nil end
  end
  local name = api.nvim_buf_get_name(buf)
  if vim.b[buf].forge_label then return vim.b[buf].forge_label, nil end
  if name:sub(1, 8) == "forge://" then return name:match("([^/]+)$") or name, nil end
  if name == "" then
    local t = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t")
    return (vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "[No Name]"), nil
  end
  local rel = vim.fn.fnamemodify(name, ":~:.")
  local icon
  if require("forge.settings").get().icons then
    local ok, dv = pcall(require, "nvim-web-devicons")
    if ok and dv.get_icon then icon = dv.get_icon(vim.fn.fnamemodify(name, ":t"), vim.fn.fnamemodify(name, ":e"), { default = true }) end
  end
  return rel, icon
end
local usage_titles = { codex = "Codex", cursor = "Cursor", claude = "Claude", opencode = "OpenCode", antigravity = "Antigravity", gemini = "Gemini", aider = "Aider" }
local function agent_usage(buf)
  if not vim.b[buf].chat_id then return nil end
  local agents = package.loaded["forge.agents"]
  local s = agents and agents.sessions[vim.b[buf].chat_id]
  if not s then return nil end
  local title = usage_titles[s.name] or s.label
  local lines = api.nvim_buf_get_lines(buf, math.max(0, api.nvim_buf_line_count(buf) - 80), -1, false)
  for i = #lines, 1, -1 do
    local line = lines[i]:gsub("\27%[[0-9;]*m", "")
    local low = line:lower()
    local pct = line:match("(%d+%%)")
    if pct and (low:find("usage", 1, true) or low:find("limit", 1, true) or low:find("5h", 1, true)) then
      local tail = vim.trim(line:gsub(".*%d+%%", "")):sub(1, 14)
      return title .. " Usage " .. pct .. (tail ~= "" and (" · " .. tail) or "")
    end
    if low:find("usage", 1, true) then
      local detail = vim.trim(line):sub(1, 28)
      if detail ~= "" then return title .. " " .. detail end
    end
  end
  return nil
end
local function special_buf(buf)
  local ft = vim.bo[buf].filetype
  if ft == "NvimTree" or vim.b[buf].forge_sidebar or vim.b[buf].forge_panel_kind then return true end
  return vim.b[buf].chat_id ~= nil
end
local function diag_groups(buf)
  local order, by = {}, {}
  for _, d in ipairs(vim.diagnostic.get(buf)) do
    local src = d.source or "lsp"
    if not by[src] then by[src] = { label = src, e = 0, w = 0, i = 0, h = 0 }; order[#order + 1] = by[src] end
    local b = by[src]
    if d.severity == vim.diagnostic.severity.ERROR then b.e = b.e + 1
    elseif d.severity == vim.diagnostic.severity.WARN then b.w = b.w + 1
    elseif d.severity == vim.diagnostic.severity.INFO then b.i = b.i + 1
    else b.h = b.h + 1 end
  end
  return order
end
local function location(win, buf)
  local pos = api.nvim_win_get_cursor(win)
  local row, col = pos[1], pos[2] + 1
  if win == api.nvim_get_current_win() then col = vim.fn.virtcol(".") end
  local total = math.max(1, api.nvim_buf_line_count(buf))
  local pct
  if total <= 1 or row <= 1 then pct = "TOP"
  elseif row >= total then pct = "BOT"
  else pct = string.format("%d%%%%", math.floor((row - 1) / (total - 1) * 100 + 0.5)) end
  return string.format("%d:%d", row, col), pct
end
function M.render()
  local ok, out = pcall(function()
    local win = vim.g.statusline_winid
    if not win or not api.nvim_win_is_valid(win) then win = api.nvim_get_current_win() end
    local buf = api.nvim_win_get_buf(win)
    local parts = {}
    local function add(group, text) if text and text ~= "" then parts[#parts + 1] = "%#" .. group .. "#" .. text end end
    local mode = modes[api.nvim_get_mode().mode] or { "NORMAL", "Normal" }
    add("SLMode" .. mode[2], " " .. mode[1] .. " ")
    add("SLMode" .. mode[2] .. "Sep", CAP)
    local left = false
    local function left_item() add("StatusLine", left and "  " or " "); left = true end
    local git = git_info(buf)
    if git then
      left_item()
      add("SLGit", BRANCH .. " " .. escape(git.head))
      if git.added > 0 then add("SLGitAdd", " +" .. git.added) end
      if git.changed > 0 then add("SLGitChange", " ~" .. git.changed) end
      if git.removed > 0 then add("SLGitDelete", " -" .. git.removed) end
    end
    local label, icon = file_label(buf)
    left_item()
    add("SLFile", (icon and (icon .. " ") or "") .. escape(label))
    if vim.bo[buf].modified then add("SLModified", " ●") end
    if vim.bo[buf].readonly or not vim.bo[buf].modifiable then add("SLMeta", " RO") end
    local usage = agent_usage(buf)
    if usage then left_item(); add("SLAgent", escape(usage)) end
    local rec = vim.fn.reg_recording()
    if rec ~= "" then left_item(); add("SLRec", " REC @" .. escape(rec) .. " ") end
    local okd, dap = pcall(require, "dap")
    if okd and dap.session and dap.session() then left_item(); add("SLDebug", " DEBUG ") end
    parts[#parts + 1] = "%#StatusLine# %="
    local right = false
    local function right_item() if right then add("StatusLine", "  ") end; right = true end
    if vim.v.hlsearch == 1 then
      local ok2, sc = pcall(vim.fn.searchcount, { recompute = false, maxcount = 99 })
      if ok2 and sc and (sc.total or 0) > 0 then right_item(); add("SLSearch", string.format("%d/%d", sc.current or 0, sc.total)) end
    end
    if not special_buf(buf) then
      for _, bucket in ipairs(diag_groups(buf)) do
        right_item()
        add("SLBucket", bucket.label)
        if bucket.e > 0 then add("SLDiagError", " E:" .. bucket.e) end
        if bucket.w > 0 then add("SLDiagWarn", " W:" .. bucket.w) end
        if bucket.i > 0 then add("SLDiagInfo", " I:" .. bucket.i) end
        if bucket.h > 0 then add("SLDiagHint", " H:" .. bucket.h) end
      end
      local clients = vim.lsp.get_clients({ bufnr = buf })
      if #clients > 0 then
        local names = {}
        for _, c in ipairs(clients) do names[#names + 1] = c.name end
        right_item(); add("SLLsp", escape(table.concat(names, ",")))
      end
      local ft = vim.bo[buf].filetype
      if ft ~= "" then right_item(); add("SLFt", escape(ft)) end
      local enc = vim.bo[buf].fileencoding; if enc == "" then enc = vim.o.encoding end
      if enc ~= "utf-8" then right_item(); add("SLMeta", escape(enc)) end
      local ff = vim.bo[buf].fileformat
      if ff == "dos" then right_item(); add("SLMeta", "CRLF")
      elseif ff == "mac" then right_item(); add("SLMeta", "CR") end
      local shift = vim.bo[buf].shiftwidth; if shift == 0 then shift = vim.bo[buf].tabstop end
      if vim.bo[buf].expandtab then
        if shift ~= 2 then right_item(); add("SLMeta", "spaces:" .. shift) end
      else right_item(); add("SLMeta", "tabs:" .. vim.bo[buf].tabstop) end
    end
    if right then add("StatusLine", " ") end
    local pos, pct = location(win, buf)
    add("SLRightSep", RAISE)
    add("SLRight", " " .. pos .. "  " .. pct .. " ")
    return table.concat(parts)
  end)
  return ok and out or " %f %m%=%l:%c "
end
function M.setup_highlights() require("forge.appearance").apply_highlights() end
vim.o.laststatus = 3
vim.o.statusline = "%{%v:lua.require('forge.statusline').render()%}"
return M
