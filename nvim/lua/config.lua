-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT


for _, file in ipairs(vim.fn.readdir(vim.fn.stdpath('config')..'/lua/config', [[v:val =~ '\.lua\(\.off\)\?$']])) do
  if not file:match('%.off.lua$') then
    require('config.'..file:gsub('%.lua$', ''))
  end
end
