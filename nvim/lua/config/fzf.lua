-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

-- fzf_term.lua
-- Neovim Lua (no plugin deps). Requires `fzf` available in $PATH.

local M = {}

-- opts: array-like table of strings (e.g. { "option1", "option2" })
-- cb: function(selection) | selection is nil if cancelled
function M.pick(opts, cb)
  opts = opts or {}
  cb = cb or function(_) end

  local out = vim.fn.tempname()

  -- Build: printf '%s\n' ... | fzf > <out>
  local parts = { "sh", "-c" }
  local escaped = {}
  for _, o in ipairs(opts) do
    escaped[#escaped + 1] = vim.fn.shellescape(tostring(o))
  end

  local cmd = ("printf '%%s\\n' %s | fzf > %s"):format(
    table.concat(escaped, " "),
    vim.fn.shellescape(out)
  )

  -- Open a new split for the terminal
  vim.cmd("botright 12new")
  vim.cmd("resize " .. math.floor(vim.o.lines * 0.3))

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  vim.fn.termopen({ parts[1], parts[2], cmd })

  -- vim.api.nvim_create_autocmd("TermClose", {
  --   buffer = buf,
  --   once = true,
  --   callback = function()
  --
  --     vim.schedule(function()
  --       if vim.api.nvim_win_is_valid(win) then
  --         pcall(vim.api.nvim_win_close, win, true)
  --       end
  --
  --       if vim.fn.filereadable(out) == 1 then
  --         local lines = vim.fn.readfile(out)
  --         vim.fn.delete(out)
  --
  --         if lines[1] then
  --           vim.notify("Picked: " .. lines[1] .. ';')
  --         end
  --       end
  --     end)
  --   end,
  -- })

  vim.cmd("startinsert")
end

-- Convenience: accept varargs (strings) as options
function M.pick_args(cb, ...)
  local opts = { ... }
  return M.pick(opts, cb)
end

function _G.fzf(opts, cb)
  return M.pick(opts, cb)
end


return M
