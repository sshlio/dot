-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

vim.keymap.set({ 'x', 'i' }, '<f13>', '<esc>');
vim.keymap.set({ 'n' }, '<f13>', '<nop>');

_G.macro_instance_6701 = _G.macro_instance_6701 or {}

local M = _G.macro_instance_6701;

if M.currentMacro == nil then
  M.currentMacro = "-"
end

vim.api.nvim_create_user_command('Macro', function(opts)
  local macro = opts.fargs[1]

  M.currentMacro = macro;

  M.execute()
end, { nargs = 1 })

function M.execute()
  local lazyredraw = vim.o.lazyredraw

  vim.o.lazyredraw = true
  local ok, err = pcall(vim.api.nvim_feedkeys,
  vim.api.nvim_replace_termcodes(M.currentMacro .. "<f13>", true, true, true), "mx", false)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", true) -- ok
  vim.o.lazyredraw = lazyredraw

  if not ok then
    error(err)
  end
end

vim.keymap.set('x', 'sq', function()
  local sel = u.getVisualLine()

  if not sel[3] then
    vim.api.nvim_command('normal! o')
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", true) -- ok

  local times = sel[2] - sel[1];

  for i = 0, times do
    vim.api.nvim_win_set_cursor(0, { sel[1] + i, 0 })
    M.execute()
  end
end)

vim.keymap.set('n', 'qq', M.execute, { desc = "Execute macro" })

return M;
