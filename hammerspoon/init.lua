-- ~/.hammerspoon/init.lua

print("V13")

-- Page Down/Up scroll step size (pixels per key press)
local pageScrollStep = 550
local pageScrollStepSmall = 200

-- Map horizontal scroll to Cmd+[ or Cmd]
local eventtap = require("hs.eventtap")
local eventTypes = eventtap.event.types

-- Threshold for horizontal scroll detection
local scrollThreshold = 15

local lastScrollTime = 1
local cooldown = 0.3
local touches = 0

function filter(tbl, predicate)
  local out = {}
  for i, v in ipairs(tbl) do
    if predicate(v, i, tbl) then
      table.insert(out, v)
    end
  end
  return out
end

local function chrome(work)
  print("==============")
  print("CHROME")
  print("==============")

  local chrome = hs.application.get("Google Chrome")

  if not chrome then
    hs.application.launchOrFocus("Google Chrome")
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

      local private = (win:title():lower():find("- private") ~= nil)
      print("private:", private)

      table.insert(wins, {
        private = private,
        win = win,
      })
    end
  end

  if work then
    local win = filter(wins, function(w) return not w.private end)[1]

    print("Found win", win.win:title())

    if win then
      win.win:focus()
      win.win:focus()
    end
  else
    print("------ Show private")
    local win = filter(wins, function(w) return w.private end)[1]

    win.win:focus()
    win.win:focus()
  end

  -- hs.application.launchOrFocus("Google Chrome")
end

-- Create the scroll event watcher
scrollWatcher = eventtap.new({eventTypes.scrollWheel}, function(e)
  local mods = e:getFlags()

  local delta = e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis2)
  local deltaY = e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)


  local now = hs.timer.secondsSinceEpoch()

  if now - lastScrollTime < cooldown then
    if delta == 0 and deltaY ==0 then
      return true
    end

    -- lastScrollTime = now - 0.1

    -- print("HIT coolodow", delta, deltaY)
    return true
  end

  -- print("diff", now - lastScrollTime)

  if touches >= 3 then
    -- hs.eventtap.keyStroke({"cmd", "shift"}, "[", 0)
    delta = delta *15 * -1
    -- print("Three finger", delta, deltaY)

    if delta == 0 and deltaY < 0 then
      hs.eventtap.middleClick(hs.mouse.absolutePosition())

      lastScrollTime = now

      return true
    end

    if delta == 0 and deltaY > 0 then
      hs.eventtap.keyStroke({"cmd"}, "w", 0)


      lastScrollTime = now

      return true
    end

  end

  if delta == 0 then
    if touches >=3 then
      return true
    end
    return false
  end

  if mods.shift then
    return false
  end

  if delta >= 5 then
    lastScrollTime = now

    if mods.cmd then
      hs.eventtap.keyStroke({"cmd"}, "[", 0)
    else
      hs.eventtap.keyStroke({"cmd", "shift"}, "[", 0)
    end

    return true
  elseif delta <= -5 then
    lastScrollTime = now

    if mods.cmd then
      hs.eventtap.keyStroke({"cmd"}, "]", 0)
    else
      hs.eventtap.keyStroke({"cmd", "shift"}, "]", 0)
    end

    return true
  end

  if delta ~= 0 then
    return true
  end
end)


-- Mouse button 4 is usually "button 4" (back side button)
button4Watcher = eventtap.new({ eventTypes.otherMouseDown }, function(event)
  local button = event:getProperty(eventtap.event.properties.mouseEventButtonNumber)

  print("button", button)

  if button == 3 then -- Mouse button numbering starts at 0 (0=left,1=right,2=middle,3=button4)
    hs.eventtap.keyStroke({"cmd"}, "w", 0)
    return true -- swallow the event
  end

  if button == 4 then -- Mouse button numbering starts at 0 (0=left,1=right,2=middle,3=button4)
    hs.eventtap.keyStroke({"cmd"}, ";", 0)
    return true -- swallow the event
  end

  if button == 5 then -- Mouse button numbering starts at 0 (0=left,1=right,2=middle,3=button4)
    hs.eventtap.keyStroke({}, "return", 0)
    return true -- swallow the event
  end

  if button == 6 then
    chrome(true)
    local output = hs.audiodevice.defaultOutputDevice()
    output:setMuted(true)
    return true -- swallow the event
  end

  return false
end)

myTap = hs.eventtap.new( { eventTypes.gesture }, function(e)
  local gestureType = e:getTouches()

  if #gestureType == 0 then
    return false
  end

  if #gestureType == 2 then
    scrollWatcher:stop()
    return false
  end

  scrollWatcher:start()
  touches = #gestureType
end)

hs.hotkey.bind({"cmd"}, "1", function()
  hs.application.launchOrFocus("kitty")
end)

hs.hotkey.bind({"cmd"}, "space", function()
  hs.application.launchOrFocus("kitty")

  hs.eventtap.keyStroke({"ctrl"}, "y")
end)



eschs = hs.hotkey.bind({}, "Escape", function()
  hs.eventtap.keyStroke({}, "`")
end)

seschs = hs.hotkey.bind({"cmd"}, "Escape", function()
  hs.eventtap.keyStroke({"cmd"}, "`")
end)

sseschs = hs.hotkey.bind({"shift"}, "Escape", function()
  hs.eventtap.keyStroke({"shift"}, "`")
end)

hs.hotkey.bind({"cmd"}, ";", function()
  eschs:disable()
  hs.eventtap.keyStroke({}, "Escape")
  eschs:enable()
end)

hs.hotkey.bind({"cmd"}, "3", function()
  hs.application.launchOrFocus("Slack")
end)

hs.hotkey.bind({"cmd"}, "2", function()
  chrome(true)
end)

hs.hotkey.bind({"cmd"}, "4", function()
  chrome(false)
end)


configWatcher = hs.pathwatcher.new(
  hs.configdir,                     -- usually "~/.hammerspoon"
  function(files)
    hs.reload()
  end
):start()


hs.hotkey.bind({"cmd"}, "l", function()
  hs.eventtap.keyStroke({}, "right")
end)

hs.hotkey.bind({}, "F11", function()
  output = hs.audiodevice.defaultOutputDevice()

  output:setVolume(output:volume() - 10)
end)

hs.hotkey.bind({}, "F12", function()
  output = hs.audiodevice.defaultOutputDevice()

  output:setVolume(output:volume() + 10)
end)

hs.hotkey.bind({"cmd"}, "h", function()
  hs.eventtap.keyStroke({}, "left")
end)


-- semi_key_tap:start()

hs.hotkey.bind({"cmd"}, "j", function()
  hs.eventtap.keyStroke({}, "down")
end)

cmdkbinding = hs.hotkey.bind({"cmd"}, "k", function()
  hs.eventtap.keyStroke({}, "up")
end)

local ignoreNext = false

chromebinding = hs.hotkey.bind({"cmd"}, "d", function()
    hs.eventtap.scrollWheel({0, -pageScrollStep}, {}, "pixel")
end)

chromebinding2 = hs.hotkey.bind({"cmd"}, "e", function()
    hs.eventtap.keyStroke({"cmd", "shift"}, "[")
end)

chromebinding3 = hs.hotkey.bind({"cmd"}, "s", function()
    hs.eventtap.keyStroke({"cmd", "shift"}, "]")
end)

-- chromebinding4 = hs.hotkey.bind({"cmd", "shift"}, "s", function()
--     print("cmd+shift+s triggered")
--     chromebinding3:disable()
--     print("chromebinding3 disabled, sending cmd+s")
--     hs.eventtap.keyStroke({"cmd"}, "s")
--     print("cmd+s sent, re-enabling chromebinding3")
--     chromebinding3:enable()
-- end)

chromebinding5 = hs.hotkey.bind({"cmd"}, "u", function()
    hs.eventtap.scrollWheel({0, pageScrollStep}, {}, "pixel")
end)

chromebinding:disable()
chromebinding2:disable()
chromebinding3:disable()
-- chromebinding4:disable()
chromebinding5:disable()

-- Page Down/Up to scroll events
hs.hotkey.bind({}, "pagedown", function()
  hs.eventtap.scrollWheel({0, -pageScrollStep}, {}, "pixel")
end)

hs.hotkey.bind({}, "pageup", function()
  hs.eventtap.scrollWheel({0, pageScrollStep}, {}, "pixel")
end)

hs.hotkey.bind({"shift"}, "pagedown", function()
  hs.eventtap.scrollWheel({0, -pageScrollStepSmall}, {}, "pixel")
end)

hs.hotkey.bind({"shift"}, "pageup", function()
  hs.eventtap.scrollWheel({0, pageScrollStepSmall}, {}, "pixel")
end)

thingsbinding = hs.hotkey.bind({"cmd"}, "d", function()
    cmdkbinding:disable()
    hs.eventtap.keyStroke({"cmd"}, "k")
    cmdkbinding:enable()
end)
thingsbinding:disable()

w = hs.application.watcher.new(function(name, ev)
  print("APP", name, ev == hs.application.watcher.activated)

  if ev == hs.application.watcher.activated then
    if name == "Google Chrome" or name == "Slack" then
      chromebinding:enable()
      chromebinding2:enable()
      chromebinding3:enable()
      chromebinding4:enable()
      chromebinding5:enable()
    else
      chromebinding:disable()
      chromebinding2:disable()
      chromebinding3:disable()
      chromebinding4:disable()
      chromebinding5:disable()
    end
  end

  if name == "Things" then
    if ev == hs.application.watcher.activated then
      thingsbinding:enable()
    else
      thingsbinding:disable()
    end
  end
end)

w:start()
scrollWatcher:start()
button4Watcher:start()
myTap:start()      

-- "world "


