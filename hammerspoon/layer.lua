Layer = hs.hotkey.modal.new()
SudoLayer = hs.hotkey.modal.new()

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

  ScreenBorder:set({ red = .77, alpha = .7 })

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

SudoLayer:bind({"shift"}, 'q', function()
  local app = hs.application.frontmostApplication()

  if app then
    app:kill9()
  end

  hs.alert("force killed")
end)

Layer:bind({"cmd"}, "q", function()
  ActiveLayer:set(SudoLayer)

  ScreenBorder:set({ green = .77, alpha = .7 })
end)

