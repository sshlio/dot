-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local cwd = vim.fn.getcwd()
local filepath = cwd .. "/_billy/nvim.lua"
local noncepath = cwd .. "/_billy/.nonce"

local function read_file(path)
  local f = io.open(path, "r")

  if not f then
    return nil
  end

  local content = f:read("*a")
  f:close()

  return content
end

local nonce = read_file(noncepath)

if nonce then
  nonce = nonce:gsub("%s+$", "")
end

if u.file_exists(filepath) and nonce ~= nil and _G.NONCE ~= nil and nonce == tostring(_G.NONCE) then
  vim.schedule(function()
    dofile(filepath)
  end)
end
