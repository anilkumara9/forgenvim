local aug = function(name) return vim.api.nvim_create_augroup("forge_" .. name, { clear = true }) end
-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", { group = aug("yank"),
  callback = function() vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 }) end })
-- Restore last cursor position
vim.api.nvim_create_autocmd("BufReadPost", { group = aug("lastloc"),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end })
-- Close helper buffers with q
vim.api.nvim_create_autocmd("FileType", { group = aug("close_q"),
  pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "neotest-summary", "dap-float" },
  callback = function(ev) vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = ev.buf, silent = true }) end })
-- Auto-create parent dirs on save
vim.api.nvim_create_autocmd("BufWritePre", { group = aug("mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+://") then return end
    local dir = vim.fn.fnamemodify(ev.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
  end })
-- Check for external changes
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, { group = aug("checktime"),
  callback = function() if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end end })
-- 4-space languages
vim.api.nvim_create_autocmd("FileType", { group = aug("indent4"),
  pattern = { "python", "rust", "go", "java", "kotlin", "scala", "php" },
  callback = function() vim.opt_local.shiftwidth = 4; vim.opt_local.tabstop = 4 end })
-- Spell + wrap for prose
vim.api.nvim_create_autocmd("FileType", { group = aug("prose"),
  pattern = { "markdown", "text", "gitcommit" },
  callback = function() vim.opt_local.wrap = true; vim.opt_local.spell = true end })
-- Big-file guard: generated bundles, huge logs and data dumps stay fast.
-- Past ~3 MB or ~60k lines the heavy per-buffer machinery (Tree-sitter,
-- language servers, linters) stands down for that buffer only; editing,
-- search and the panels keep working normally.
vim.api.nvim_create_autocmd("BufReadPre", { group = aug("bigfile"),
  callback = function(ev)
    local path = ev.match
    if not path or path == "" or path:match("^%w%w+://") then return end
    local st = vim.uv.fs_stat(path)
    if st and st.size > 3 * 1024 * 1024 then vim.b[ev.buf].forge_bigfile = true end
  end })
vim.api.nvim_create_autocmd("BufReadPost", { group = aug("bigfile_post"),
  callback = function(ev)
    if not vim.b[ev.buf].forge_bigfile and vim.api.nvim_buf_line_count(ev.buf) <= 60000 then return end
    vim.b[ev.buf].forge_bigfile = true
    pcall(vim.treesitter.stop, ev.buf)
    vim.bo[ev.buf].swapfile = false
    vim.bo[ev.buf].undofile = false
    -- (User-facing "big file" notice comes from the snacks bigfile
    -- feature, which is also enabled; this layer adds the LSP detach.)
  end })
vim.api.nvim_create_autocmd("LspAttach", { group = aug("bigfile_lsp"),
  callback = function(ev)
    if vim.b[ev.buf].forge_bigfile then
      vim.schedule(function() pcall(vim.lsp.buf_detach_client, ev.buf, ev.data.client_id) end)
    end
  end })
