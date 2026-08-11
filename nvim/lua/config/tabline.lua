-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

-- https://vieitesss.github.io/posts/Neovim-custom-status-line/

o.showtabline = 0
vim.o.tabline = '%!v:lua.tabline()'

-- vim.o.winbar = " - %f"
vim.o.statusline = "%!v:lua.statusline()"
vim.diagnostic.status()
vim.lsp.status()

local function colorful(text, color)
  return "%#" .. color .. "#" .. text .. "%*"
end

function _G.tabline()
  return " "
    .. colorful("  neovim ", "IncSearch")
    .. " "
    .. vim.fn.getcwd():gsub("/Users/billy/p/", "")
end

local mode_map = {
  n =  { "NORMAL", "StatusNormal" },
  i =  { "INSERT", "StatusInsert" },
  t =  { " TERM ", "StatusInsert" },
  v =  { "VISUAL", "StatusVisual" },
  V =  { "V-LINE", "StatusVisual" },
  c =  { "COMMAND", "IncSearch" },
  R =  { "REPLACE", "WarningMsg" },
  j =  { "JUMP   ", "StatusInsert" },
  nt = { "VISIBLE", "Comment" },
  ["\22"] = { "V-BLCK", "Visual" },
}

function _G.statusline()
  local statusline_win = vim.g.statusline_winid
  local is_active = statusline_win == vim.fn.win_getid()
  local special_mode
  if statusline_win and vim.api.nvim_win_is_valid(statusline_win) then
    local statusline_buf = vim.api.nvim_win_get_buf(statusline_win)
    local buffer_mode = vim.b[statusline_buf]._specialMode
    if type(buffer_mode) == "table" and buffer_mode.winnr == statusline_win then
      special_mode = buffer_mode.mode
    end
  end
  local mode_info
  if is_active then
    local m = vim.fn.mode()
    mode_info = mode_map[m] or { m, "StatusLine" }
  elseif special_mode then
    mode_info = mode_map[special_mode] or { special_mode, "IncSearch" }
  else
    mode_info = { "------", "Comment" }
  end
  return " "
    .. colorful(" " .. mode_info[1] .. " ", mode_info[2])
    .. " %{expand('%:.')}"
end
