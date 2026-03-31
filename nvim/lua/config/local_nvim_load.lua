-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local cwd = vim.fn.getcwd()
local filepath = cwd .. "/_billy/nvim.lua"
local trusted_paths = _G.TRUSTED
local has_local_config = u.file_exists(filepath)
local is_trusted = trusted_paths ~= nil and vim.tbl_contains(trusted_paths, cwd)

if has_local_config and is_trusted then
  vim.schedule(function()
    dofile(filepath)
  end)
elseif has_local_config then
  vim.schedule(function()
    vim.notify("Local nvim config present but cwd is not trusted: " .. cwd, vim.log.levels.WARN)
  end)
end
