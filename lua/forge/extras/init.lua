-- Forge extras: capabilities layered ON TOP of the core environment. The
-- core layout, panels and chrome stay exactly as designed; these are
-- additive commands only.
--   :ForgeAgents            Mission Control board for every AI session
--   :ForgeSnapshot save|load|list|delete <name>   named workspace snapshots
--   :ForgeAiCommit          draft a commit message with an installed agent CLI
--   :ForgeBench             readiness board (plugins, parsers, tools, agents)
local M = {}

local function float(lines, title, keymap_fn)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"; vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local w = 0; for _, l in ipairs(lines) do w = math.max(w, vim.fn.strdisplaywidth(l)) end
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = math.min(w + 4, vim.o.columns - 4),
    height = math.min(#lines + 2, vim.o.lines - 6),
    row = math.floor((vim.o.lines - #lines) / 2), col = math.floor((vim.o.columns - w) / 2),
    style = "minimal", border = "rounded", title = " " .. title .. " ", title_pos = "center",
  })
  vim.keymap.set("n", "q", function() pcall(vim.api.nvim_win_close, win, true) end, { buffer = buf })
  vim.keymap.set("n", "<Esc>", function() pcall(vim.api.nvim_win_close, win, true) end, { buffer = buf })
  if keymap_fn then keymap_fn(buf, win) end
  return buf, win
end

-- ---------------------------------------------------------------- agents board
function M.board()
  local agents = require("forge.agents")
  local ids = {}
  for id in pairs(agents.sessions) do ids[#ids + 1] = id end
  table.sort(ids)
  local lines = { "  AI SESSIONS  (Enter jump - x close - r resume - q quit)", "" }
  local row_id = {}
  if #ids == 0 then lines[#lines + 1] = "  No agent sessions yet. :AgentSelect starts one." end
  for _, id in ipairs(ids) do
    local s = agents.sessions[id]
    local cli = agents.CLIS[s.name]
    local state = s.exited and "exited " or "running"
    lines[#lines + 1] = ("  %-18s %-14s %s  %s"):format(s.label, cli and cli.label or s.name,
      state, s.uuid and ("id " .. s.uuid:sub(1, 8)) or "no saved id")
    row_id[#lines] = id
  end
  local buf, win = float(lines, "Mission Control", function(b)
    local function act(fn)
      local row = vim.api.nvim_win_get_cursor(win)[1]
      local id = row_id[row]; if id then fn(id) end
    end
    vim.keymap.set("n", "<CR>", function() act(function(id) pcall(vim.api.nvim_win_close, win, true); agents.show(id) end) end, { buffer = b })
    vim.keymap.set("n", "x", function() act(function(id) agents.close(id) end); vim.api.nvim_win_close(win, true); M.board() end, { buffer = b })
    vim.keymap.set("n", "r", function() act(function(id)
      local s = agents.sessions[id]
      if s then local name, uuid = s.name, s.uuid; agents.close(id); agents.new(name, { uuid = uuid }) end
      pcall(vim.api.nvim_win_close, win, true)
    end) end, { buffer = b })
  end)
  return buf, win
end

-- ---------------------------------------------------------------- snapshots
local function snap_dir() return vim.fn.stdpath("state") .. "/forge/named-snapshots" end
local function snap_file(name) return snap_dir() .. "/" .. name:gsub("[^%w%-_]", "_") .. ".json" end
local function list_snaps()
  local out = {}
  for _, f in ipairs(vim.fn.glob(snap_dir() .. "/*.json", false, true)) do out[#out + 1] = vim.fn.fnamemodify(f, ":t:r") end
  table.sort(out); return out
end
function M.snapshot(action, name)
  vim.fn.mkdir(snap_dir(), "p")
  if action == "list" or (action == nil and name == nil) then
    local names = list_snaps()
    float(#names > 0 and vim.list_extend({ "  SNAPSHOTS", "" }, vim.tbl_map(function(n) return "  " .. n end, names))
      or { "  SNAPSHOTS", "", "  None saved yet. :ForgeSnapshot save <name>" }, "Snapshots")
    return
  end
  if not name or name == "" then vim.notify("ForgeSnapshot: a name is required", vim.log.levels.WARN); return end
  if action == "save" then
    local data = { cwd = vim.fn.getcwd(), theme = require("forge.settings").get().theme,
      agents = require("forge.agents").snapshot(), buffers = {}, saved_at = os.time() }
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
        local nm = vim.api.nvim_buf_get_name(buf)
        local e = { name = nm }
        if vim.bo[buf].modified or nm == "" then
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          if #lines > 1 or (lines[1] and lines[1] ~= "") then e.lines = lines end
        end
        if e.name ~= "" or e.lines then data.buffers[#data.buffers + 1] = e end
      end
    end
    vim.fn.writefile({ vim.json.encode(data) }, snap_file(name))
    vim.notify("Snapshot '" .. name .. "' saved (" .. #data.buffers .. " buffers, " .. #data.agents .. " agents)")
  elseif action == "load" then
    local ok, raw = pcall(vim.fn.readfile, snap_file(name))
    if not ok then vim.notify("No snapshot named '" .. name .. "'", vim.log.levels.WARN); return end
    local okd, data = pcall(vim.json.decode, table.concat(raw, "\n"))
    if not okd then vim.notify("Snapshot '" .. name .. "' is unreadable", vim.log.levels.ERROR); return end
    if data.theme then require("forge.themes").apply(data.theme) end
    for _, e in ipairs(data.buffers or {}) do
      if e.name and e.name ~= "" and vim.uv.fs_stat(e.name) then vim.cmd("edit " .. vim.fn.fnameescape(e.name))
      elseif e.lines then vim.cmd("enew"); vim.api.nvim_buf_set_lines(0, 0, -1, false, e.lines); vim.bo.modified = true end
    end
    local agents = require("forge.agents")
    for _, a in ipairs(data.agents or {}) do agents.new(a.name, { uuid = a.uuid, label = a.label }) end
    vim.notify("Snapshot '" .. name .. "' loaded")
  elseif action == "delete" then
    vim.fn.delete(snap_file(name)); vim.notify("Snapshot '" .. name .. "' deleted")
  else
    vim.notify("ForgeSnapshot: use save, load, list or delete", vim.log.levels.WARN)
  end
end

-- ---------------------------------------------------------------- AI commit
local AI_PROVIDERS = {
  { bin = "claude", args = function(p) return { "-p", p } end },
  { bin = "codex", args = function(p) return { "exec", p } end },
  { bin = "gemini", args = function(p) return { "-p", p } end },
  { bin = "agent", args = function(p) return { "-p", p } end },
  { bin = "opencode", args = function(p) return { "run", p } end },
}
function M.ai_commit()
  local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
  if not root or root == "" then vim.notify("Not inside a git repository", vim.log.levels.WARN); return end
  local diff = vim.fn.system({ "git", "-C", root, "diff", "--cached" })
  if not diff or vim.trim(diff) == "" then
    vim.notify("Stage changes first, then :ForgeAiCommit drafts the message", vim.log.levels.WARN); return
  end
  local provider
  for _, p in ipairs(AI_PROVIDERS) do if vim.fn.executable(p.bin) == 1 then provider = p; break end end
  if not provider then
    vim.notify("No agent CLI on PATH to draft with (claude, codex, gemini, agent, opencode)", vim.log.levels.WARN); return
  end
  local prompt = "Write a git commit message for the staged diff below. One subject line "
    .. "(imperative, max 72 chars), optionally a short body. Output ONLY the commit message.\n\n"
    .. diff:sub(1, 6000)
  vim.notify("Drafting commit message with " .. provider.bin .. "...")
  local chunks = {}
  vim.fn.jobstart(vim.list_extend({ provider.bin }, provider.args(prompt)), {
    stdout_buffered = true, stderr_buffered = true,
    on_stdout = function(_, d) for _, l in ipairs(d or {}) do chunks[#chunks + 1] = l end end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then vim.notify("Commit draft failed (" .. provider.bin .. " exited " .. code .. ")", vim.log.levels.ERROR); return end
        local text = vim.trim(table.concat(chunks, "\n")):gsub("^```[%w]*\n", ""):gsub("\n```$", "")
        local msg = {}
        for line in vim.gsplit(text, "\n") do
          msg[#msg + 1] = line
          if #msg >= 6 then break end
        end
        if #msg == 0 or msg[1] == "" then vim.notify("The agent returned no message", vim.log.levels.WARN); return end
        local sidebar = require("forge.sidebar")
        if sidebar.gitstate.comp_buf and vim.api.nvim_buf_is_valid(sidebar.gitstate.comp_buf) then
          vim.api.nvim_buf_set_lines(sidebar.gitstate.comp_buf, 0, -1, false, msg)
          if sidebar.gitstate.comp_win and vim.api.nvim_win_is_valid(sidebar.gitstate.comp_win) then
            vim.api.nvim_set_current_win(sidebar.gitstate.comp_win)
          end
          vim.notify("Commit message drafted by " .. provider.bin .. " - review it, then Ctrl+Enter")
        else
          vim.fn.setreg("+", table.concat(msg, "\n"))
          vim.notify("Commit message drafted by " .. provider.bin .. " (copied to clipboard, open Git to use it)")
        end
      end)
    end,
  })
end

-- ---------------------------------------------------------------- bench board
function M.bench()
  local lines = { "  FORGENVIM READINESS", "" }
  local lazy_ok, lazy = pcall(require, "lazy")
  if lazy_ok then
    local st = lazy.stats()
    lines[#lines + 1] = ("  Plugins        %d of %d loaded - startup %.0f ms"):format(st.loaded, st.count, st.startuptime)
  end
  local parsers = vim.api.nvim_get_runtime_file("parser/*.so", true)
  lines[#lines + 1] = ("  Syntax parsers %d installed"):format(#parsers)
  local pkgs = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/*", false, true)
  lines[#lines + 1] = ("  Mason tools    %d installed"):format(#pkgs)
  local agents = require("forge.agents")
  local have, missing = {}, {}
  for _, name in ipairs(agents.order) do
    local cli = agents.CLIS[name]
    if vim.fn.executable(cli.bin) == 1 then have[#have + 1] = cli.label else missing[#missing + 1] = cli.label end
  end
  lines[#lines + 1] = "  Agent CLIs     ready: " .. (#have > 0 and table.concat(have, ", ") or "none")
  if #missing > 0 then lines[#lines + 1] = "                 missing: " .. table.concat(missing, ", ") end
  local active = 0; for _ in pairs(agents.sessions) do active = active + 1 end
  lines[#lines + 1] = ("  Sessions       %d open in this project"):format(active)
  lines[#lines + 1] = "  Themes         " .. #require("forge.themes").list .. " available"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  q to close"
  return float(lines, "ForgeBench")
end

vim.api.nvim_create_user_command("ForgeAgents", M.board, {})
vim.api.nvim_create_user_command("ForgeAiCommit", M.ai_commit, {})
vim.api.nvim_create_user_command("ForgeBench", M.bench, {})
vim.api.nvim_create_user_command("ForgeSnapshot", function(o)
  local parts = vim.split(o.args, "%s+")
  M.snapshot(parts[1], parts[2])
end, { nargs = "*", complete = function(_, line)
  local parts = vim.split(line, "%s+")
  if #parts <= 2 then return { "save", "load", "list", "delete" } end
  if parts[2] == "load" or parts[2] == "delete" then return list_snaps() end
  return {}
end })
return M
