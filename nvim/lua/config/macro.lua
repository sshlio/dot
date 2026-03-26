-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

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
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(M.currentMacro, true, true, true), "m", false)
end

vim.keymap.set('x', 'sq', function()
  -- TODO This is not defined yet in the utils maaan
  local sel = u.getVisualLine()

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true) -- ok

  if not sel[3] then
    vim.api.nvim_command('normal! o')
  end

  local times = sel[2] - sel[1] + 1;

  for i = 1, times do
    M.execute()
  end

  -- vim.schedule(function()
  --   vim.api.nvim_command('normal! gv')
  -- end)
end)

vim.keymap.set('n', 'qq', function()
  M.execute()
end)

return M;
