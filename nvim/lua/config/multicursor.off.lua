-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

  
local myModeChange = false
local gonnaChange = false

local ns = vim.api.nvim_create_namespace('multicursor_marks')

local function has_extmarks(ns, bufnr)
  bufnr = bufnr or 0

  local marks = vim.api.nvim_buf_get_extmarks( bufnr, ns, 0, -1, { limit = 1 })

  return #marks > 0
end

local function mark_and_jump_next()
  local row = 248;

  local start = vim.fn.getpos('v')

  local start_row = start[2]
  local start_col = start[3]

  local endsel = vim.fn.getpos('.')

  local end_row = endsel[2]
  local end_col = endsel[3]

  vim.fn.setreg("/", "" .. vim.fn.expand("<cword>") .. "")
  vim.opt.hlsearch = false

  myModeChange = true

  vim.api.nvim_feedkeys("n", "x", false)

  -- vim.api.nvim_buf_add_highlight(0, ns, 'Visual', start_row - 1, start_col - 1, end_col)

  print(vim.inspect({
    start_col = start_col,
    end_col = end_col,
  }))

  vim.api.nvim_buf_set_extmark(0, ns, start_row - 1, start_col - 1, {
    end_col = end_col,
    hl_group = "Visual",
  })
end

vim.keymap.set('x', 'qn', mark_and_jump_next, {
  desc = 'Mark selection and jump to next match',
})

function add_cursor()
  local col = 0

  print('Cursor added')
  vim.api.nvim_buf_set_extmark(0, ns, 0, col, {
    end_col = col + 1,
    hl_group = "TermCursor",
  })
end

local function get_all_cursors()
  local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
  -- each item: { id, row, col, details }
  return marks
end

local function next_word_start_from(row, col)
  -- search from a given position, not from the real cursor
  vim.fn.cursor(row + 1, col + 1)

  -- \k = keyword char, \< = start of word
  local pos = vim.fn.searchpos([[\<\k]], "W")
  local new_row, new_col = pos[1], pos[2]

  if new_row == 0 then
    return nil
  end

  return new_row - 1, new_col - 1
end

local function run_builtin_motion(motion)
  vim.cmd({
    cmd = "normal",
    bang = true,
    args = { motion },
  })
end

local function move_extmark_with_builtin_motion(id, row, col, motion)
  local win = 0

  -- extmarks use 0-based rows/cols, cursor uses 1-based row / 0-based col
  vim.api.nvim_win_set_cursor(win, { row + 1, col })

  -- use builtin motion semantics
  run_builtin_motion(motion)

  local new_pos = vim.api.nvim_win_get_cursor(win)
  local new_row = new_pos[1] - 1
  local new_col = new_pos[2]

  vim.api.nvim_buf_set_extmark(0, ns, new_row, new_col, {
    id = id,
    end_row = new_row,
    end_col = new_col + 1,
    hl_group = "TermCursor",
    right_gravity = false,
    end_right_gravity = true,
  })
end

local function move_all_cursors_motion(motion)
  local marks = get_all_cursors()
  local saved = vim.api.nvim_win_get_cursor(0)

  for _, mark in ipairs(marks) do
    local id, row, col = mark[1], mark[2], mark[3]
    move_extmark_with_builtin_motion(id, row, col, motion)
  end

  vim.api.nvim_win_set_cursor(0, saved)
end

local function map_multicursor_motion(lhs, rhs)
  vim.keymap.set("n", lhs, function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    local motion = count .. rhs

    move_all_cursors_motion(motion)
    run_builtin_motion(motion)
  end, { noremap = true })
end

for _, motion in ipairs({
  "h",
  "j",
  "k",
  "l",
  "w",
  "W",
  "e",
  "E",
  "b",
  "B",
  "ge",
  "gE",
  "0",
  "^",
  "$",
  "gg",
  "G",
  "{",
  "}",
  "(",
  ")",
}) do
  -- map_multicursor_motion(motion, motion)
end

vim.keymap.set('n', 'qn', add_cursor, {
  desc = 'Add cursor at line 0',
})

vim.api.nvim_create_autocmd('ModeChanged', {
  pattern = {'v:n'},
  callback = function()
    if myModeChange then
      myModeChange = false

      return
    end

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end,
})

-- vim.api.nvim_create_autocmd('ModeChanged', {
--   pattern = 'i:i',
--   callback = function()
--     print("Gonna insert")
--   end,
-- })


vim.keymap.set("x", "c", function()
  gonnaChange = "r"
  return "c"
end, { expr = true, noremap = true })

vim.keymap.set("x", "A", function()
  gonnaChange = "a"
  return "A"
end, { expr = true, noremap = true })

vim.keymap.set("x", "I", function()
  gonnaChange = "i"
  myModeChange = true
  return "o<esc>i"
end, { expr = true, noremap = true })


local function apply_to_extmarks(text, mode)
  local bufnr = vim.api.nvim_get_current_buf()

  local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {
    details = true,
  })

  -- iterate backwards to avoid shifting issues
  for i = #marks, 1, -1 do
    local mark = marks[i]
    local id = mark[1]
    local row = mark[2]
    local col = mark[3]
    local details = mark[4]

    local end_row = details.end_row or row
    local end_col = details.end_col or col

    if mode == "r" then
      -- replace only if it's a range
      if details.end_row and details.end_col then
        vim.api.nvim_buf_set_text(bufnr, row, col, end_row, end_col, { text })
      else
        -- fallback: insert at point mark
        vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { text })
      end

    elseif mode == "i" then
      -- insert before start
      vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { text })

    elseif mode == "a" then
      -- append after end (or at point)
      vim.api.nvim_buf_set_text(bufnr, end_row, end_col, end_row, end_col, { text })
    end

    -- optional: remove mark after operation
    vim.api.nvim_buf_del_extmark(bufnr, ns, id)
  end
end

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    if not gonnaChange then
      return
    end
    changing_visual = false

    local start_pos = vim.fn.getpos("'[")
    local end_pos = vim.fn.getpos("']")

    local srow = start_pos[2] - 1
    local scol = start_pos[3] - 1
    local erow = end_pos[2] - 1
    local ecol = end_pos[3] - 1

    local text = vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})
    local inserted = table.concat(text, "\n")

    print(vim.inspect(inserted))

    apply_to_extmarks(inserted, gonnaChange)

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end,
})
