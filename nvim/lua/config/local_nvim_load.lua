-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local cwd = vim.fn.getcwd()
local filepath = cwd .. "/_billy/nvim.lua"

if u.file_exists(filepath) then
  vim.schedule(function() 
    dofile(filepath)
  end)
end


