local ns = vim.api.nvim_create_namespace("line_completion")
local mode_group = vim.api.nvim_create_augroup("line_completion", { clear = true })

local M = {}
local u = M;

local idx = 1
local trail = "";

function u.uniq(list)
  local seen = {}
  local result = {}

  for _, value in ipairs(list) do
    if not seen[value] then
      seen[value] = true
      result[#result + 1] = value
    end
  end

  return result
end

function u.matchAny(text, patterns)
  for _, pattern in ipairs(patterns) do
    local match = text:match(pattern)

    if match ~= nil then
      return match
    end
  end

  return nil
end

function u.reverse(list)
  local result = {}

  for i = #list, 1, -1 do
    result[#result + 1] = list[i]
  end

  return result
end

local mark_id

local lines = {}

function M.updateLines()
  local line_count = vim.api.nvim_buf_line_count(0)
  local start_line = math.max(0, line_count - 10000)

  lines = vim.api.nvim_buf_get_lines(
    0,
    start_line,
    line_count,
    false
  )

  local result = {}

  for _, line in ipairs(lines) do
    for _, part in ipairs(vim.split(line, "; ", { plain = true, trimempty = true })) do
      table.insert(result, vim.trim(part))
    end
  end

  lines = result;

  lines = vim.tbl_filter(function(line)
    return (
      (not line:match("^%s$"))
      and vim.fn.stridx("codex ", line) ~= 0
      and vim.fn.stridx("/ ", line) ~= 0
      and vim.fn.stridx(" ", line) ~= 0
      and vim.fn.stridx("# ", line) ~= 0
    )
  end, lines)

  lines = u.reverse(lines)
end

function M.candidate(line)
  local found = M.candidates(line)[idx]

  return found
end

function M.candidates(line)
  return vim.tbl_filter(function(value)
    return vim.fn.stridx(value, line) == 0 and value != line
  end, u.uniq(vim.list_extend({trail}, lines)))
end

local function update_virtual_text()
  local curr = vim.api.nvim_win_get_cursor(0)
  local row = curr[1] - 1
  local line = vim.api.nvim_get_current_line()
  local col = #line

  if col == 0 or curr[2] < (col) then
    M.clear()
    return
  end

  local parts = vim.split(line, "; ", { plain = true, trimempty = true })
  local last = parts[#parts]

  print('"' .. last .. '"')

  local found = M.candidate(last)

  if found == nil then
    M.clear()
    return
  end

  found = found:sub(#last + 1)

  mark_id = vim.api.nvim_buf_set_extmark(0, ns, row, col, {
    id = mark_id, -- updates existing mark when non-nil
    virt_text = {{ found, "Comment" }},
    virt_text_pos = "overlay",
  })
end

function M.clear()
  if not mark_id then
    return
  end
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  mark_id = nil
end

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*/_billy/console.nu",
  callback = function(args)
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = mode_group,
      buffer = args.buf,
      callback = function()
        local old_mode = vim.v.event.old_mode
        local new_mode = vim.v.event.new_mode

        if new_mode == "i" then
          M.updateLines()
          idx = 1
          trail = ""
          update_virtual_text()
        end

        if mark_id and old_mode == "i" then
          vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
          mark_id = nil
        end

      end,
    })

    vim.api.nvim_create_autocmd( { "CursorMovedI" } , {
      group = mode_group,
      buffer = args.buf,
      callback = function()
        index = 0
        update_virtual_text()
      end,
    })
  end
})

vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

function M.fill()
  local line = vim.api.nvim_get_current_line()
  local col = #line

  local parts = vim.split(line, "; ", { plain = true, trimempty = true })
  local last = parts[#parts]

  local candidate = M.candidate(last)

  if not candidate then
    return
  end

  found = candidate:sub(#last + 1)

  local first = u.matchAny(found, { "^%s%S*", "%S+" })

  if not first then
    return
  end

  if first != found then
    first = first .. " "
  end

  vim.api.nvim_put({ first }, "c", true, true)
  trail = candidate
  idx = 1
end


function M.fillLine()
  local line = vim.api.nvim_get_current_line()
  local col = #line

  local parts = vim.split(line, "; ", { plain = true, trimempty = true })
  local last = parts[#parts]

  local found = M.candidate(last)

  if not found then
    return
  end

  found = found:sub((#last) + 1)

  vim.api.nvim_put({ found }, "c", true, true)
end

vim.keymap.set("i", "<c-f>", function() M.fill() end)

vim.keymap.set("i", "<right>", function()
  local line = vim.api.nvim_get_current_line()
  local col = #line
  local curr = vim.api.nvim_win_get_cursor(0)

  if curr[2] >= col then
    vim.schedule(function() M.fillLine(true) end)
    return ""
  end

  return "<right>"
end, { expr = true })

vim.keymap.set("i", "<up>", function()
  local line = vim.api.nvim_get_current_line()
  local col = #line

  local parts = vim.split(line, "; ", { plain = true, trimempty = true })
  local last = parts[#parts]

  local candidates = M.candidates(last)

  idx = math.min(#candidates, idx + 1)

  print("<up>",idx, #candidates - 1)

  update_virtual_text()
end)

vim.keymap.set("i", "<down>", function()
  idx = math.max(1, idx - 1)
  print("<down>",idx)

  update_virtual_text()
end)

