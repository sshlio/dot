-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

-- Put this in (for example) lua/float20.lua and require it, or drop in init.lua
local M = {}

M.files = { "README.md" }

function M.open_float20()
  local buf = vim.api.nvim_create_buf(false, true) -- [scratch][nomodifiable]

  local opts = {
    relative = "editor",   -- relative to the full editor, not the cursor
    anchor = "SW",         -- South-West corner (bottom-left)
    row = vim.o.lines - 2, -- position from top (a bit above bottom)
    col = 6,               -- left edge
    width = 100,
    height = 20,
    style = "minimal",
    border = "rounded",
    noautocmd = true,
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_set_option_value("cursorline", true, { win = win })

  M.win = win

  local lines = vim.list_extend({  }, M.files)

  local last_buffers = M.fill_with_recent_files(buf, 10, lines)

  table.insert(lines, '" --------------')

  local cur = #lines + 2

  lines = vim.list_extend(lines, last_buffers)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  pcall(vim.api.nvim_win_set_cursor, 0, { cur, 0 })

  -- set filetype to Vimscript
  vim.bo.filetype = "vim"   -- equivalent: vim.cmd([[setfiletype vim]])

  -- Optional: close with <Esc> while focused
  vim.keymap.set("n", "<cr>", function()
    local line = vim.api.nvim_get_current_line()
    line = line:gsub("^%s+", ""):gsub("%s+$", "")

    if line == "" or line:match("^%-%-") then
      return
    end

    local path = vim.fn.fnamemodify(line, ":p")

    print("path: " .. path)

    M.close()

    vim.cmd.edit(vim.fn.fnameescape(path))
  end, { buffer = buf })

  vim.keymap.set("n", "<esc>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf })

  vim.keymap.set("n", "<c-o>", function() M.close() end, { buffer = buf })
  vim.keymap.set("n", "<c-w>", function() M.close() end, { buffer = buf })
end

function M.close()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Filter out lines that start with a double quote
  local filtered = {}

  for _, line in ipairs(lines) do
    if line:match('^%s*"') then  -- ignores leading spaces too
      break
    else
      table.insert(filtered, line)
    end
  end

  M.files = filtered

  if vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
end

function M.fill_with_recent_files(buf, max_items)
  max_items = max_items or 50

  local seen = {}
  local out = {}

  local function add_path(abs_path)
    if abs_path ~= "" and vim.fn.filereadable(abs_path) == 1 and not seen[abs_path] then
      seen[abs_path] = true
      table.insert(out, vim.fn.fnamemodify(abs_path, ':.')) -- relative when possible
    end
  end

  -- 1) Current buffer first
  add_path(vim.api.nvim_buf_get_name(0))

  -- 2) Files from the jumplist (most recent → oldest)
  local jl = vim.fn.getjumplist()[1] or {}
  for i = #jl, 1, -1 do
    local bufnr = jl[i].bufnr
    if bufnr and bufnr > 0 then
      add_path(vim.api.nvim_buf_get_name(bufnr))
      if #out >= max_items then break end
    end
  end

  if #out == 0 then
    out = { "-- no files found in jumplist --" }
  end

  return out
end

-- Optional: :Float20 command
vim.api.nvim_create_user_command("Float20", function()
  M.open_float20()
end, {})


vim.keymap.set("n", "<c-r>", function()
  M.open_float20()

end, { buffer = buf })

return M
