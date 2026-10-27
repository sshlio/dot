Layer = hs.hotkey.modal.new()
SudoLayer = hs.hotkey.modal.new()
RawLayer = hs.hotkey.modal.new()
ControlLayer = hs.hotkey.modal.new()

RawLayer.name = "RawLayer"
ControlLayer.name = "ControlLayer"
SudoLayer.name = "SudoLayer"
Layer.name = "Layer"

ActiveLayer = Signal.new(nil)

ActiveLayer:map(function(l) return l and l.name end):log("ActiveLayer")

ActiveLayer:resource(function(layer)
  if not layer then
    return function()  end
  end

  print('Entering layer', layer.name)
  layer:enter()

  return function()
    print('Exiting layer', layer.name)
    layer:exit()
  end
end)

function raw()
  ActiveLayer:set(nil)

  hs.alert("Raw input")

  ScreenBorder:set({
    color = { red = .77, alpha = .7 },
    text = "Raw input",
  })

  timer = hs.timer.doAfter(3, function()
    ScreenBorder:set(false)
    ActiveLayer:set(Layer)
  end)
end

SudoLayer:bind({"cmd"}, ';', function()
  ActiveLayer:set(Layer)
  ScreenBorder:set(false)
end)

SudoLayer:bind({}, 'r', raw)

SudoLayer:bind({}, 'f', function()
  local window = hs.window.focusedWindow()

  if window then
    local screenFrame = window:screen():frame()
    local appName = window:application():name()

    local floatingApps = {
      ["1Password"] = true,
      ["Calendar"] = true,
      ["Messages"] = true,
      ["Reminders"] = true,
      ["Things"] = true,
    }

    if floatingApps[appName] then
      local width = math.min(screenFrame.w, 1800)
      local height = math.min(screenFrame.h, 1200)
      local xRoom = math.floor((screenFrame.w - width) / 2)
      local yRoom = math.floor((screenFrame.h - height) / 2)
      local xOffset = math.random(-math.min(xRoom, 50), math.min(xRoom, 50))
      local yOffset = math.random(-math.min(yRoom, 50), math.min(yRoom, 50))

      window:setFrame({
        x = screenFrame.x + (screenFrame.w - width) / 2 + xOffset,
        y = screenFrame.y + (screenFrame.h - height) / 2 + yOffset,
        w = width,
        h = height,
      }, 0)
    else
      window:setFrame(screenFrame, 0)
    end
  end
end)

SudoLayer:bind({"shift"}, 'q', function()
  local app = hs.application.frontmostApplication()

  if app then
    app:kill9()
  end

  hs.alert("force killed")
end)

SudoLayer:bind({"shift"}, 's', function()
  ActiveLayer:set(Layer)
  ScreenBorder:set(false)

  hs.caffeinate.systemSleep()
end)

SudoLayer:bind({}, 'l', function()
  ActiveLayer:set(Layer)
  ScreenBorder:set(false)

  hs.caffeinate.lockScreen()
end)

SudoLayer:bind({}, 'c', function()
  ActiveLayer:set(ControlLayer)
  ScreenBorder:set(false)
end)

Layer:bind({"cmd"}, "q", function()
  ActiveLayer:set(SudoLayer)

  ScreenBorder:set({
    color = { green = .77, alpha = .7 },
    text = SudoLayer.name,
  })
end)

print("Layer defined")

FastBinding = {}

ActiveLayer:listen(function(layer)
  local bindings = {}
  for key, target in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    bindings[hs.keycodes.map[key]] = { keyCode = hs.keycodes.map[target], flags = {} }
  end

  if layer == Layer or layer == ControlLayer then
    bindings[hs.keycodes.map[";"]] = { keyCode = hs.keycodes.map.escape, flags = {} }
  end

  if layer == ControlLayer then
    for letter in ("abcdefgimnopqrstuwxyz"):gmatch(".") do
      bindings[hs.keycodes.map[letter]] = { control = true }
    end
  end

  FastBinding = bindings
end)

-- Mark synthetic shortcuts which must bypass the remaps.
FastBindingBypass = 0x46415354

FastBindingTap = hs.eventtap.new({
  hs.eventtap.event.types.keyDown,
  hs.eventtap.event.types.keyUp,
}, function(event)
  if event:getProperty(hs.eventtap.event.properties.eventSourceUserData) == FastBindingBypass then
    return false
  end

  local flags = event:getFlags()
  local binding = FastBinding[event:getKeyCode()]
  if not binding or not flags.cmd then
    return false
  end

  if binding.control then
    flags.cmd = nil
    flags.ctrl = true
    event:setFlags(flags)
  elseif flags:containExactly({ "cmd" }) then
    event:setKeyCode(binding.keyCode)
    event:setFlags(binding.flags)
  end
  return false
end):start()

windowWatcher = hs.window.filter.new()

OnTitleChanged = function(window, appName)
  print('OnTitleChanged', window:title())
  if window:title():lower():find(G.controlWindowTitle) ~= nil then
    ActiveLayer:set(ControlLayer)
  else
    ActiveLayer:set(Layer)
  end
end

windowWatcher:subscribe(hs.window.filter.windowFocused, OnTitleChanged)
