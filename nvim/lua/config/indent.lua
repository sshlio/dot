-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local baseindent = nil

local patterns = {
  "%(%s*$",  -- line ends with '('
  "%{%s*$",  -- line ends with '{'
  "%[%s*$",  -- line ends with '['

  " then$", "^then$",   -- ends with 'then'
  " else$", "^else$",   -- ends with 'else'
  " do$",   "^do$",   -- ends with 'else'

  "^%s*function",
  "%sfunction%(%)$",
  "%(function%(%)$",
  "%,function%(%)$",
  "%s*%<[^/][^%>]*[^/]%>$",   -- html tags, not</div>
}

function _G.Flat()
  local lnum = vim.v.lnum
  local mode = vim.fn.mode()
  local indent = vim.fn.indent(vim.v.lnum)

  if mode == "i" then
    local base = vim.fn.prevnonblank(lnum - 1)
    return vim.fn.indent(base)
  end

  if baseindent == nil then
    local base = vim.fn.prevnonblank(lnum - 1)

    if lnum == 1 then
      base = 0
    end

    local linecontent = vim.fn.getline(base)

    lastline = vim.fn.indent(base)
    baseindent = lastline - indent

    for _, pat in ipairs(patterns) do
      if linecontent:match(pat) then
        baseindent = baseindent + 2
        break
      end
    end




    print("prevnonblank", lnum, base, lastline, baseindent)

    vim.schedule(function()
      baseindent = nil
    end)
  end

  -- print("idnent", lnum, indent + baseindent, indent, baseindent, vim.fn.mode())

  return indent + baseindent
end


vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  callback = function(args)
    vim.bo[args.buf].indentexpr = "v:lua.Flat()"
  end,
  desc = "Force custom indentexpr",
})

