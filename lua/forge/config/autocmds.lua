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
