-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local patterns = {
  "%(%s*$",  -- line ends with '('
  "%{%s*$",  -- line ends with '{'
  "%[%s*$",  -- line ends with '['
  " then$",   -- ends with 'then'
  " else$",   -- ends with 'else'
  "%s*%<[^/][^%>]*[^/]%>$",   -- html tags, not</div>
}

function _G.FirstNonEmptyIndent()
  local lnum = vim.v.lnum
  local mode = vim.fn.mode()

  local line = vim.fn.getline(lnum)
  local trimmed = line:match("^%s*(.-)%s*$")

  local baseIndent = vim.fn.indent(lnum)

  if baseIndent > 0 then
    -- Dont mess wit it
    return baseIndent
  end

  print("current line", line)
  -- Search upwards for the first non-empty line
  for i = lnum - 1, 1, -1 do
    local line = vim.fn.getline(i)

    if line ~= "" then
      local extra = 0

      if mode ~= "i" then
        map(
          patterns,
          function(pat)
            if line:match(pat) then
              extra = 2
            end
          end
        )
      end

      return vim.fn.indent(i) + extra
    end
  end

  return vim.fn.indent(lnum - 1)
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  callback = function(args)
    vim.bo[args.buf].indentexpr = "v:lua.FirstNonEmptyIndent()"
  end,
  desc = "Force custom indentexpr",
})
