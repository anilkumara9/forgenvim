-- Agent pane: AI coding CLIs as real terminal sessions in a fixed 28% right
-- pane, tabbed, resumable by session id, persisted per project. Seven CLIs,
-- including Aider, plus a combined session picker.
local M = { sessions = {}, active = nil, win = nil, next_id = 0 }
local CLIS = {
  codex       = { bin = "codex",    label = "Codex",       cmd = "Codex",       prefix = "Codex ",
                  start = function() return { "codex" } end,
                  resume = function(id) return { "codex", "resume", id } end, capture = "codex" },
  cursor      = { bin = "agent",    label = "Cursor Agent", cmd = "CursorAgent", prefix = "Agent ",
                  start = function(id) return id and { "agent", "--resume=" .. id } or { "agent" } end,
                  resume = function(id) return { "agent", "--resume=" .. id } end },
  gemini      = { bin = "gemini",   label = "Gemini",      cmd = "Gemini",      prefix = "Gemini ",
                  start = function(id) return id and { "gemini", "--session-id", id } or { "gemini" } end,
                  resume = function(id) return { "gemini", "--resume", id } end },
  claude      = { bin = "claude",   label = "Claude",      cmd = "Claude",      prefix = "Claude ",
                  start = function() return { "claude" } end,
                  resume = function(id) return { "claude", "--resume", id } end, capture = "claude" },
  opencode    = { bin = "opencode", label = "OpenCode",    cmd = "OpenCode",    prefix = "OpenCode ",
                  start = function(id) return id and { "opencode", "--session", id } or { "opencode" } end,
                  resume = function(id) return { "opencode", "--session", id } end },
  antigravity = { bin = "agy",      label = "Antigravity", cmd = "Antigravity", prefix = "Antigravity ",
                  start = function() return { "agy" } end,
                  resume = function(id) return { "agy", "--conversation", id } end, capture = "antigravity" },
  aider       = { bin = "aider",    label = "Aider",       cmd = "Aider",       prefix = "Aider ",
                  start = function() return { "aider" } end,
                  resume = function(id) return { "aider", "--restore-chat-history", id } end },
}
M.order = { "codex", "cursor", "gemini", "claude", "opencode", "antigravity", "aider" }
local function width() return math.max(24, math.floor(vim.o.columns * 0.28)) end
local function valid() return M.win and vim.api.nvim_win_is_valid(M.win) end
local function valid_id(v) return type(v) == "string" and #v >= 6 and #v <= 80 and v:match("^[%w%-_]+$") ~= nil end
function M.term_env()
  local env = {}
  for k, v in pairs(vim.fn.environ()) do
    if type(k) == "string" and k ~= "" and type(v) == "string" and k ~= "NO_COLOR"
      and k ~= "TERM_PROGRAM" and k ~= "TERM_PROGRAM_VERSION" and not k:match("^WARP_") then env[k] = v end
  end
  env.TERM = "xterm-256color"; env.TERM_PROGRAM = "xterm"; env.COLORTERM = "256color"
  env.FORCE_COLOR = "2"; env.CLICOLOR_FORCE = "1"; env.TERM_THEME = "dark"; env.COLORFGBG = "15;0"
  return env
end
local function make_uuid()
  local hex = vim.fn.sha256(("%s:%s:%s"):format(vim.uv.hrtime(), math.random(), vim.uv.os_getpid()))
  return table.concat({ hex:sub(1,8), hex:sub(9,12), hex:sub(13,16), hex:sub(17,20), hex:sub(21,32) }, "-")
end
local function persist()
  local ok, s = pcall(require, "forge.session"); if ok and not s.busy then s.save() end
end

-- Capture ids the CLI itself creates (Codex and Claude assign their own
-- session ids; without this, resume would have nothing to resume).
local function known_ids(name)
  local seen = {}
  for _, s in pairs(M.sessions) do if s.name == name and valid_id(s.uuid) then seen[s.uuid] = true end end
  return seen
end
local function newest_codex_uuid(cwd, known)
  local fd = vim.uv.fs_open(vim.fn.expand("~/.codex/session_index.jsonl"), "r", 384)
  if not fd then return nil end
  local st = vim.uv.fs_fstat(fd); local raw = st and vim.uv.fs_read(fd, st.size, 0) or ""
  vim.uv.fs_close(fd)
  local best; local abs = vim.fn.fnamemodify(cwd, ":p")
  for line in vim.gsplit(raw, "\n", { plain = true, trimempty = true }) do
    local ok, row = pcall(vim.json.decode, line)
    if ok and type(row) == "table" then
      local id = row.id or row.session_id or row.uuid
      local rc = row.cwd or row.cwd_path or row.directory or row.workdir
      if valid_id(id) and not known[id] and (not rc or vim.fn.fnamemodify(rc, ":p") == abs) then best = id end
    end
  end
  return best
end
local function newest_antigravity_id(cwd, known, baseline)
  local fd = vim.uv.fs_open(vim.fn.expand("~/.gemini/antigravity-cli/cache/last_conversations.json"), "r", 384)
  if not fd then return nil end
  local st = vim.uv.fs_fstat(fd); local raw = st and vim.uv.fs_read(fd, st.size, 0) or ""
  vim.uv.fs_close(fd)
  local ok, cache = pcall(vim.json.decode, raw or "")
  if not ok or type(cache) ~= "table" then return nil end
  local workspace = vim.fn.fnamemodify(cwd, ":p"):gsub("/+$", "")
  local id = cache[workspace]
  if valid_id(id) and not known[id] and id ~= baseline then return id end
  return nil
end
local function newest_claude_uuid(cwd, known)
  local abs = vim.fn.fnamemodify(cwd, ":p"):gsub("/$", "")
  local dir = vim.fn.expand("~/.claude/projects/" .. abs:gsub("[^%w]", "-"))
  local handle = vim.uv.fs_scandir(dir); local best, best_mtime
  while handle do
    local name = vim.uv.fs_scandir_next(handle); if not name then break end
    local id = name:match("^([%x%-]+)%.jsonl$")
    if id and valid_id(id) and not known[id] then
      local st = vim.uv.fs_stat(dir .. "/" .. name)
      local m = st and st.mtime and st.mtime.sec or 0
      if not best_mtime or m >= best_mtime then best, best_mtime = id, m end
    end
  end
  return best
end
local function capture_after_start(id, finder)
  local attempts = 0
  local function tick()
    attempts = attempts + 1
    local s = M.sessions[id]
    if not s or valid_id(s.uuid) then return end
    local uuid = finder(vim.fn.getcwd(), known_ids(s.name))
    if uuid then s.uuid = uuid; persist(); return end
    if attempts < 8 then vim.defer_fn(tick, 250) end
  end
  vim.defer_fn(tick, 250)
end
function M.active_label()
  local s = M.active and M.sessions[M.active]; return s and (" " .. s.label) or ""
end
function M.show(id)
  local s = M.sessions[id]; if not s or s.exited or not vim.api.nvim_buf_is_valid(s.buf) then return end
  if not valid() then vim.cmd("botright vsplit"); M.win = vim.api.nvim_get_current_win() end
  vim.api.nvim_set_current_win(M.win); vim.api.nvim_win_set_buf(M.win, s.buf)
  vim.api.nvim_win_set_width(M.win, width()); vim.wo[M.win].winfixwidth = true
  vim.wo[M.win].wrap = false; vim.wo[M.win].number = false; vim.wo[M.win].relativenumber = false
  vim.wo[M.win].signcolumn = "no"; vim.wo[M.win].foldcolumn = "0"; vim.wo[M.win].statuscolumn = ""
  M.active = id; vim.cmd("redrawstatus")
  if vim.bo[s.buf].buftype == "terminal" then vim.cmd.startinsert() end
end
function M.new(name, opts)
  opts = opts or {}
  local cli = CLIS[name]
  if not cli then vim.notify("Unknown chat CLI: " .. tostring(name), vim.log.levels.ERROR); return end
  if vim.fn.executable(cli.bin) == 0 then
    vim.notify(cli.label .. " (" .. cli.bin .. ") is not on PATH; editor still works", vim.log.levels.WARN); return nil
  end
  local restoring = valid_id(opts.uuid)
  local uuid = restoring and opts.uuid or (name == "gemini" or name == "opencode") and make_uuid() or nil
  M.next_id = M.next_id + 1; local id = M.next_id
  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].chat_id = id; vim.bo[buf].bufhidden = "hide"
  local s = { buf = buf, name = name, uuid = uuid, label = opts.label or (cli.prefix .. id) }
  M.sessions[id] = s; M.show(id)
  local argv = restoring and cli.resume(uuid) or cli.start(uuid)
  local function finish() s.exited = true
    local sess = package.loaded["forge.session"]; if not (sess and sess.exiting) then M.close(id) end end
  s.job = vim.fn.jobstart(argv, { term = true, cwd = vim.fn.getcwd(), env = M.term_env(), clear_env = true,
    on_exit = function() vim.defer_fn(finish, 20) end })
  if s.job <= 0 and restoring then
    s.uuid = nil; vim.notify("Could not resume " .. cli.bin .. "; starting fresh", vim.log.levels.WARN)
    s.job = vim.fn.jobstart(cli.start(nil), { term = true, cwd = vim.fn.getcwd(), env = M.term_env(), clear_env = true,
      on_exit = function() vim.defer_fn(finish, 20) end })
  end
  if s.job <= 0 then s.exited = true; vim.notify("Could not start " .. cli.bin, vim.log.levels.ERROR) end
  if s.job > 0 and cli.capture and not valid_id(s.uuid) then
    if cli.capture == "antigravity" then
      local baseline = newest_antigravity_id(vim.fn.getcwd(), {})
      capture_after_start(id, function(cwd, known) return newest_antigravity_id(cwd, known, baseline) end)
    else
      capture_after_start(id, cli.capture == "codex" and newest_codex_uuid or newest_claude_uuid)
    end
  end
  vim.keymap.set("t", "<Esc>", function() if not s.exited and s.job then vim.api.nvim_chan_send(s.job, "\27") end end,
    { buffer = buf, nowait = true, desc = "Send Escape to agent" })
  persist(); return id
end
function M.toggle(name)
  if valid() and M.sessions[M.active] and M.sessions[M.active].name == name then
    vim.api.nvim_win_close(M.win, false); M.win = nil; return
  end
  for id, s in pairs(M.sessions) do if s.name == name and not s.exited then M.show(id); return end end
  M.new(name)
end
function M.close(id)
  local s = M.sessions[id]; if not s then return end
  M.sessions[id] = nil
  if s.job then pcall(vim.fn.jobstop, s.job) end
  s.exited = true
  if M.active == id then M.active = nil end
  local ids = vim.tbl_keys(M.sessions); table.sort(ids)
  if #ids > 0 then M.show(ids[#ids])
  elseif valid() and #vim.api.nvim_list_wins() > 1 then pcall(vim.api.nvim_win_close, M.win, false); M.win = nil end
  if vim.api.nvim_buf_is_valid(s.buf) then pcall(vim.api.nvim_buf_delete, s.buf, { force = true }) end
  persist()
end
function M.select()
  local labels = {}; for _, n in ipairs(M.order) do labels[#labels+1] = CLIS[n].label end
  vim.ui.select(labels, { prompt = "New chat - choose CLI:" }, function(choice)
    for n, c in pairs(CLIS) do if c.label == choice then M.new(n) end end
  end)
end
function M.snapshot()
  local out = {}
  for _, s in pairs(M.sessions) do if not s.exited then out[#out+1] = { name = s.name, uuid = s.uuid, label = s.label } end end
  return out
end
vim.api.nvim_create_autocmd("VimResized", { callback = function() if valid() then vim.api.nvim_win_set_width(M.win, width()) end end })
vim.api.nvim_create_user_command("ForgeAgentSelect", M.select, {})
vim.api.nvim_create_user_command("AgentSelect", M.select, {})
for _, name in ipairs(M.order) do
  vim.api.nvim_create_user_command(CLIS[name].cmd, function() M.toggle(name) end, {})
end
return M
