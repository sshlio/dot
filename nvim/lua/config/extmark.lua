-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

-- docs: https://neovim.io/doc/user/api/#nvim_buf_set_extmark()

local ExtmarkState = {}
ExtmarkState.__index = ExtmarkState

function ExtmarkState.new(namespace)
  return setmetatable({
    namespace = namespace,
    by_buf = {},
  }, ExtmarkState)
end

function ExtmarkState:_key(extmark_id)
  return tostring(extmark_id)
end

function ExtmarkState:_normalize_buf(buf)
  if buf == 0 then
    return vim.api.nvim_get_current_buf()
  end

  return buf
end

function ExtmarkState:_ensure_buf(buf)
  buf = self:_normalize_buf(buf)

  if not self.by_buf[buf] then
    self.by_buf[buf] = {}
  end

  return self.by_buf[buf]
end

function ExtmarkState:get(buf, extmark_id)
  if not extmark_id then
    return nil
  end

  buf = self:_normalize_buf(buf)
  local states = self.by_buf[buf]
  if not states then
    return nil
  end

  return states[self:_key(extmark_id)]
end

function ExtmarkState:clear(state)
  if not state or not state.extmark then
    return
  end

  local extmark_id = state.extmark
  local pos = vim.api.nvim_buf_get_extmark_by_id(state.parentBuf, self.namespace, extmark_id, {})

  if pos and #pos > 0 then
    state.linenr = pos[1] + 1
  end

  pcall(vim.api.nvim_buf_del_extmark, state.parentBuf, self.namespace, extmark_id)
  state.extmark = false

  local states = self.by_buf[state.parentBuf]
  if states then
    states[self:_key(extmark_id)] = nil
    if vim.tbl_isempty(states) then
      self.by_buf[state.parentBuf] = nil
    end
  end
end

function ExtmarkState:set(state, opts)
  self:clear(state)

  local row = assert(opts.row, "ExtmarkState:set requires opts.row")

  local col = opts.col or 0
  local extmark_opts = vim.deepcopy(opts)
  extmark_opts.row = nil
  extmark_opts.col = nil

  state.extmark = vim.api.nvim_buf_set_extmark(state.parentBuf, self.namespace, row, col, extmark_opts)
  self:_ensure_buf(state.parentBuf)[self:_key(state.extmark)] = state

  return state.extmark
end

function ExtmarkState:get_marks_at_line(buf, linenr, opts)
  buf = self:_normalize_buf(buf)
  return vim.api.nvim_buf_get_extmarks(buf, self.namespace, { linenr - 1, 0 }, { linenr, 0 }, opts or {
    overlap = true,
  })
end

function ExtmarkState:get_state_at_line(buf, linenr, opts)
  buf = self:_normalize_buf(buf)
  local row = linenr - 1
  local marks = self:get_marks_at_line(buf, linenr, opts)

  for _, mark in ipairs(marks) do
    if mark[2] == row then
      local extmark_id = mark[1]
      return self:get(buf, extmark_id), extmark_id
    end
  end

  return nil, nil
end

function ExtmarkState:get_all_states(buf, opts)
  buf = self:_normalize_buf(buf)
  local marks = vim.api.nvim_buf_get_extmarks(buf, self.namespace, 0, -1, opts or {})
  local states = {}

  for _, mark in ipairs(marks) do
    local state = self:get(buf, mark[1])
    if state then
      table.insert(states, state)
    end
  end

  return states
end

_G.ExtmarkState = ExtmarkState

return ExtmarkState
