local M = {
  ns = vim.api.nvim_create_namespace("motion"),
  labels = "jklhasdfgqwertyuiopcvbnmzx",
  label_highlights = {
    j = "DiffDelete",
    k = "MoreMsg",
    l = "MoreMsg",
  },
  special_mode = "j",
  exit_keys = { "<Left>", "<Right>", "<C-w>", "<Esc>", "<CR>", "<c-c>" },
  hidden_guicursor = "a:block-blinkon0-MotionHiddenCursor",
}

function M.origin_is_valid()
  return vim.api.nvim_win_is_valid(M.origin_win)
    and vim.api.nvim_win_get_buf(M.origin_win) == M.origin_buf
end

function M.move_origin(cursor)
  if M.origin_is_valid() then
    vim.api.nvim_win_set_cursor(M.origin_win, cursor)
  end
end

function M.clear_matches()
  if vim.api.nvim_buf_is_valid(M.origin_buf) then
    vim.api.nvim_buf_clear_namespace(M.origin_buf, M.ns, 0, -1)
  end
  M.jump_targets = {}
end

function M.finish(restore_cursor, target)
  if M.finished then return end
  M.finished = true
  M.clear_matches()

  if M.input_win and vim.api.nvim_win_is_valid(M.input_win) then
    vim.api.nvim_win_close(M.input_win, true)
  end
  if vim.o.guicursor == M.hidden_guicursor then
    vim.o.guicursor = M.original_guicursor
  end
  if vim.api.nvim_buf_is_valid(M.origin_buf)
      and vim.b[M.origin_buf]._specialMode == M.special_mode then
    vim.b[M.origin_buf]._specialMode = nil
  end

  if M.origin_is_valid() then
      vim.api.nvim_set_current_win(M.origin_win)
      if target then
        M.move_origin({ target.line, target.col_start })
        if M.insert then
          vim.cmd.startinsert()
        end
      elseif restore_cursor then
      M.move_origin(M.origin_cursor)
    end
  end
  vim.cmd.redrawstatus()
end

function M.prefix_pattern()
  return vim.fn.escape(M.chain, [[\^$~[]]):gsub("0", "[0-9]")
end

function M.find_matches()
  if not M.origin_is_valid() then return {} end

  local viewport = vim.api.nvim_win_call(M.origin_win, function()
    return { vim.fn.line("w0"), vim.fn.line("w$") }
  end)
  local first, last = unpack(viewport)
  local lines = vim.api.nvim_buf_get_lines(M.origin_buf, first - 1, last, false)
  local prefix_pattern = M.prefix_pattern()
  local pattern = prefix_pattern .. [[\k*]]
  local matches = {}

  for line_offset, line in ipairs(lines) do
    local search_from = 0
    while true do
      local text, col_start, col_stop = unpack(vim.fn.matchstrpos(line, pattern, search_from))
      if text == "" then break end

      local prefix_stop = vim.fn.matchend(line, prefix_pattern, col_start)
      matches[#matches + 1] = {
        line = first + line_offset - 1,
        col_start = col_start,
        prefix = line:sub(col_start + 1, prefix_stop),
        next_char = line:sub(prefix_stop + 1, prefix_stop + 1),
      }

      if col_stop <= search_from then break end
      search_from = col_stop
    end
  end

  return matches
end

function M.available_labels(matches)
  local next_chars = {}
  for _, match in ipairs(matches) do
    if match.next_char ~= "" then
      next_chars[match.next_char] = true
    end
  end
  return M.labels:gsub(".", function(label)
    return next_chars[label] and "" or label
  end)
end

function M.label_order(matches)
  local ordered = {}

  local function is_in_direction(match)
    local same_line = match.line == M.origin_cursor[1]
    if M.backward then
      return match.line < M.origin_cursor[1] or same_line and match.col_start < M.origin_cursor[2]
    end
    return match.line > M.origin_cursor[1] or same_line and match.col_start > M.origin_cursor[2]
  end

  local function append(directional)
    local first, last, step = 1, #matches, 1
    if M.backward then
      first, last, step = #matches, 1, -1
    end
    for index = first, last, step do
      local match = matches[index]
      if is_in_direction(match) == directional then
        ordered[#ordered + 1] = match
      end
    end
  end

  append(true)
  append(false)

  return ordered
end

function M.assign_labels(matches)
  local available = M.available_labels(matches)
  local ordered = M.label_order(matches)
  for index, match in ipairs(ordered) do
    local label = available:sub(index, index)
    if label == "" then break end
    match.label = label
    M.jump_targets[label] = match
  end
  return ordered[1]
end

function M.render_matches(matches)
  for _, match in ipairs(matches) do
    local text
    if match.label then
      local label_highlight = M.label_highlights[match.label] or "TermCursor"
      text = { { match.label, label_highlight } }
      local remainder = vim.fn.strcharpart(match.prefix, 1)
      if remainder ~= "" then
        text[#text + 1] = { remainder, "IncSearch" }
      end
    else
      text = { { match.prefix, "IncSearch" } }
    end
    vim.api.nvim_buf_set_extmark(M.origin_buf, M.ns, match.line - 1, match.col_start, {
      virt_text = text,
      virt_text_pos = "overlay",
      hl_mode = "combine",
    })
  end
end

function M.update()
  if not M.origin_is_valid() then
    M.finish(false)
    return
  end

  local matches = M.find_matches()

  M.clear_matches()
  local nearest = M.assign_labels(matches)
  M.render_matches(matches)

  if nearest then
    M.move_origin({ nearest.line, nearest.col_start })
  end

  vim.cmd.redraw()
end

function M.render_chain()
  vim.api.nvim_buf_clear_namespace(M.input_buf, M.ns, 0, -1)
  if M.chain ~= "" then
    vim.api.nvim_buf_set_extmark(M.input_buf, M.ns, 0, 0, {
      virt_text = { { M.chain, "IncSearch" } },
      virt_text_pos = "overlay",
    })
  end
end

function M.handle_char(char)
  local target = M.jump_targets[char]

  if target then
    M.finish(false, target)
  elseif char == ";" then
    M.finish(false)
  else
    M.chain = M.chain .. char
    M.render_chain()
    M.update()
  end
end

function M.handle_backspace()
  M.chain = M.chain:sub(1, -2)
  M.render_chain()
  if M.chain == "" then
    M.clear_matches()
    M.move_origin(M.origin_cursor)
  else
    M.update()
  end
end

function M.prepare_input_buffer()
  M.input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M.input_buf].buftype = "nofile"
  vim.bo[M.input_buf].bufhidden = "wipe"
  vim.bo[M.input_buf].swapfile = false
  vim.bo[M.input_buf].modifiable = false
  vim.bo[M.input_buf].readonly = true
end

function M.open_input_window()
  _G.ingoreNextWinLeave = true
  M.input_win = vim.api.nvim_open_win(M.input_buf, true, {
    relative = "editor",
    row = vim.o.lines - vim.o.cmdheight - 1,
    col = 0,
    width = vim.o.columns,
    height = 1,
    style = "minimal",
    hide = true,
    zindex = 1,
  })

  vim.wo[M.input_win].winhighlight = "Normal:NormalFloat,Cursor:NormalFloat"
  local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
  local hidden_cursor_hl = { blend = 100, nocombine = true }
  if normal_float.bg then
    hidden_cursor_hl.fg = normal_float.bg
    hidden_cursor_hl.bg = normal_float.bg
  end
  vim.api.nvim_set_hl(0, "MotionHiddenCursor", hidden_cursor_hl)
  vim.o.guicursor = M.hidden_guicursor

  vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    buffer = M.input_buf,
    once = true,
    callback = function()
      M.finish(false)
    end,
  })
end

function M.bind_input_keys()
  local opts = { buffer = M.input_buf, nowait = true, silent = true }
  for byte = 32, 126 do
    local char = string.char(byte)
    local lhs = char == "<" and "<lt>" or char == " " and "<Space>" or char
    vim.keymap.set("n", lhs, function()
      M.handle_char(char)
    end, opts)
  end

  vim.keymap.set("n", "<BS>", M.handle_backspace, opts)

  for _, key in ipairs(M.exit_keys) do
    vim.keymap.set("n", key, function()
      M.finish(false)
    end, opts)
  end
end

function M.motion(insert, backward)
  M.origin_buf = vim.api.nvim_get_current_buf()
  M.origin_win = vim.api.nvim_get_current_win()
  M.origin_cursor = vim.api.nvim_win_get_cursor(M.origin_win)
  M.chain = ""
  M.jump_targets = {}
  M.finished = false
  M.insert = insert == true
  M.backward = backward == true
  M.original_guicursor = vim.o.guicursor

  vim.b[M.origin_buf]._specialMode = M.special_mode
  M.prepare_input_buffer()
  M.open_input_window()
  M.bind_input_keys()
end

vim.keymap.set("n", "f", function()
  M.motion(false, false)
end)
vim.keymap.set("n", "F", function()
  M.motion(false, true)
end)
vim.keymap.set("i", "<C-f>", function()
  vim.cmd.stopinsert()
  M.motion(true, false)
end)

return M
