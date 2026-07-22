Layer = hs.hotkey.modal.new()
SudoLayer = hs.hotkey.modal.new()
RawLayer = hs.hotkey.modal.new()

RawLayer.name = "RawLayer"
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
    window:setFrame(window:screen():frame(), 0)
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

Layer:bind({"cmd"}, "q", function()
  ActiveLayer:set(SudoLayer)

  ScreenBorder:set({
    color = { green = .77, alpha = .7 },
    text = SudoLayer.name,
  })
end)

SudoLayer:bind({}, "n", function()
  hs.eventtap.keyStroke({ "cmd", "alt" }, "j")

  hs.timer.doAfter(.3, function()
    hs.eventtap.keyStroke({ "cmd", "shift" }, "n")
    hs.eventtap.keyStrokes("Show Network panel")
    hs.eventtap.keyStroke({}, "return")
  end)
end)
