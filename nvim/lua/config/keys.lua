local mode = "n"
local prefixes ="<>sg[qm]"
local ns = vim.api.nvim_create_namespace("billy_keys")


local function pad_right(str, length, char)
  char = char or " "

  if #str >= length then
    return str
  end

  return str .. string.rep(char, length - #str)
end

function openHelp(fn)
  local buf = vim.api.nvim_create_buf(false, true) -- [scratch][nomodifiable]

  local mappings = vim.api.nvim_get_keymap(mode)
  vim.list_extend(mappings, vim.api.nvim_buf_get_keymap(0, mode))
  table.sort(mappings, function(a, b)
    return a.lhs < b.lhs
  end)

  local opts = {
    relative = "editor",   -- relative to the full editor, not the cursor
    anchor = "SW",         -- South-West corner (bottom-left)
    row = vim.o.lines - 2, -- position from top (a bit above bottom)
    col = 6,               -- left edge
    width = 100,
    height = 40,
    style = "minimal",
    border = { "","","", "▐","","","","▌" },
    noautocmd = true,
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_set_option_value("cursorline", true, { win = win })

  local lines = {}
  local extmark = {}

  for _, map in ipairs(mappings) do
    -- if prefixes:find(map.lhs:sub(1, 1), 1, true) == nil and map.desc ~= "<nop>" then
    if fn(map.lhs) and map.desc ~= "<nop>" then
      -- print(vim.inspect(map))

      table.insert(lines, pad_right(map.lhs, 10) .. (map.desc or "unknown"))

      table.insert(extmark, {
        row = #lines - 1,
        col = 0,
        opts = {
          end_col = 10,
          hl_group = "Title",
        },
      })

      local desc_hl = map.desc and "Include" or "Conceal"

      table.insert(extmark, {
        row = #lines - 1,
        col = 10,
        opts = {
          end_col = -1,
          hl_group = desc_hl,
          strict = false,
        },
      })
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, mark in ipairs(extmark) do
    vim.api.nvim_buf_set_extmark(buf, ns, mark.row, mark.col, mark.opts)
  end
end
function openHelpForGlobal()  end

function openHelpForPrefix(prefix)
  local fn = function(lhs) return (
    lhs:sub(1, 1) == prefix
    and lhs ~= prefix
    and lhs ~= prefix .. "?"
  ) end
  openHelp(fn)
end

vim.keymap.set('n', 's?', function() openHelpForPrefix("s") end)
vim.keymap.set('n', 'g?', function() openHelpForPrefix("g") end)
vim.keymap.set('n', ']?', function() openHelpForPrefix("]") end)
vim.keymap.set('n', 'z?', function() openHelpForPrefix("z") end)

