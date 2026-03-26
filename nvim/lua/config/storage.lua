-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local file = vim.fn.stdpath("data") .. "/kvstore.json"




-- load data from disk
local function load()
  local f = io.open(file, "r")
  if not f then return {} end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and data or {}
end

-- save data to disk
local function save(tbl)
  local f = io.open(file, "w")
  if not f then return end
  f:write(vim.json.encode(tbl))
  f:close()
end

local cache = load()

local function kget(key, default)
  return cache[key] or default
end

local function kset(key, value)
  cache[key] = value
  save(cache)
end

_G.kset = kset
_G.kget = kget

