-- One global status strip for the whole UI (laststatus=3):
-- mode block + powerline arrow | git branch and hunks | focused file or chat |
-- diagnostics per severity | search count | LSP ..... filetype | position
-- with the cursor segment highlighted in the theme accent.
local M = {}
local modes = { n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK",
  R = "REPLACE", c = "COMMAND", t = "TERMINAL", s = "SELECT", S = "SELECT" }
local function hl(name) local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false }); return ok and h or {} end
local function hex(n) return n and ("#%06x"):format(n) or "none" end
function M.setup_highlights()
  local bg = hex(hl("Normal").bg)
  local picks = {
    ForgeModeN = (hl("Function").fg or hl("Title").fg), ForgeModeI = hl("String").fg,
    ForgeModeV = hl("Constant").fg, ForgeModeR = hl("Error").fg, ForgeModeC = hl("Type").fg,
  }
  for name, fg in pairs(picks) do vim.api.nvim_set_hl(0, name, { bg = hex(fg), fg = bg, bold = true }) end
  local accent = hex(hl("Function").fg or hl("Title").fg)
  vim.api.nvim_set_hl(0, "ForgeBar", { bg = "none", fg = hex(hl("Normal").fg) })
  vim.api.nvim_set_hl(0, "ForgeBarMuted", { bg = "none", fg = hex(hl("Comment").fg) })
  vim.api.nvim_set_hl(0, "ForgeCursor", { bg = accent, fg = bg, bold = true })
  vim.api.nvim_set_hl(0, "ForgeDiagE", { fg = hex(hl("DiagnosticError").fg), bg = "none", bold = true })
  vim.api.nvim_set_hl(0, "ForgeDiagW", { fg = hex(hl("DiagnosticWarn").fg), bg = "none", bold = true })
  pcall(vim.api.nvim_set_hl, 0, "StatusLine", { bg = "none" })
  pcall(vim.api.nvim_set_hl, 0, "StatusLineNC", { bg = "none" })
end
local mode_group = { n = "ForgeModeN", i = "ForgeModeI", v = "ForgeModeV", V = "ForgeModeV",
  ["\22"] = "ForgeModeV", R = "ForgeModeR", c = "ForgeModeC", t = "ForgeModeN", s = "ForgeModeV", S = "ForgeModeV" }
function M.render()
  local ok, out = pcall(function()
    local m = vim.api.nvim_get_mode().mode
    local parts = { "%#" .. (mode_group[m] or "ForgeModeN") .. "# " .. (modes[m] or m:upper()) .. " ",
      "%#ForgeBarMuted# " }
    local git = vim.b.gitsigns_status_dict
    if git and git.head and git.head ~= "" then
      local g = "  " .. git.head
      if (git.added or 0) > 0 then g = g .. " +" .. git.added end
      if (git.changed or 0) > 0 then g = g .. " ~" .. git.changed end
      if (git.removed or 0) > 0 then g = g .. " -" .. git.removed end
      parts[#parts+1] = g .. "  "
    end
    local buf = vim.api.nvim_get_current_buf()
    local agents = package.loaded["forge.agents"]
    if vim.b[buf].chat_id and agents then
      parts[#parts+1] = "%#ForgeBar#" .. (agents.active_label and agents.active_label() or " chat ")
    else
      local name = vim.api.nvim_buf_get_name(buf)
      parts[#parts+1] = "%#ForgeBar#" .. (name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~:."))
      if vim.bo[buf].modified then parts[#parts+1] = " ●" end
    end
    local counts = vim.diagnostic.count(buf)
    local e = counts[vim.diagnostic.severity.ERROR] or 0
    local wn = counts[vim.diagnostic.severity.WARN] or 0
    if e > 0 then parts[#parts+1] = "  %#ForgeDiagE#E:" .. e end
    if wn > 0 then parts[#parts+1] = "  %#ForgeDiagW#W:" .. wn end
    local sc = vim.fn.searchcount({ maxcount = 0 })
    if sc and sc.total and sc.total > 0 then parts[#parts+1] = "%#ForgeBarMuted#  " .. sc.current .. "/" .. sc.total end
    local clients = vim.lsp.get_clients({ bufnr = buf })
    if #clients > 0 then parts[#parts+1] = "%#ForgeBarMuted#  " .. clients[1].name end
    parts[#parts+1] = "%=%#ForgeBarMuted# " .. (vim.bo[buf].filetype or "") .. "  "
    local pos = vim.api.nvim_win_get_cursor(0)
    parts[#parts+1] = "%#ForgeCursor# " .. pos[1] .. ":" .. pos[2] .. " "
    return table.concat(parts)
  end)
  return ok and out or ""
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = function() M.setup_highlights() end })
M.setup_highlights()
vim.o.laststatus = 3
vim.o.statusline = "%{%v:lua.require('forge.statusline').render()%}"
return M
