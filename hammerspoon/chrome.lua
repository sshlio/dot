Chrome = {}

local app = "Google Chrome"

function Chrome:focus(work)
  local chrome = hs.application.get(app)

  if not chrome then
    hs.application.launchOrFocus(app)
    return
  end

  local windows = chrome:visibleWindows()

  local wins = {}

  print("----------------")
  print("----------------")
  print("")

  for i, win in ipairs(windows) do

    if win:isMaximizable() then
      print("----------------", idx)
      print("title:", win:title():lower())

      local private = (win:title():lower():find("private%)?$") ~= nil)
      print("private:", private)

      table.insert(wins, {
        private = private,
        win = win,
      })
    end
  end

  if work then
    local win = filter(wins, function(w) return not w.private end)[1]

    if win then
      win.win:focus()
      win.win:focus()
    end
  else
    local win = filter(wins, function(w) return w.private end)[1]

    win.win:focus()
    win.win:focus()
  end
end
