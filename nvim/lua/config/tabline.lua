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
  n = { "NORMAL", "Cursor" },
  i = { "INSERT", "WildMenu" },
  t = { " TERM ", "WildMenu" },
  v = { "VISUAL", "Visual" },
  V = { "V-LINE", "Visual" },
  ["\22"] = { "V-BLCK", "Visual" },
  c = { "COMMAND", "IncSearch" },
  R = { "REPLACE", "WarningMsg" },
  nt = { "VISIBLE", "Comment" },
}

function _G.statusline()
  local is_active = vim.g.statusline_winid == vim.fn.win_getid()
  local mode_info
  if is_active then
    local m = vim.fn.mode()
    mode_info = mode_map[m] or { m, "StatusLine" }
  else
    mode_info = { "INACTV", "Comment" }
  end
  return " "
    .. colorful(" " .. mode_info[1] .. " ", mode_info[2])
    .. " %{expand('%:.')}"
end
