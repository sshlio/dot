local borderSignal = Signal.new(false)

local border = nil

borderSignal:log("border")

borderSignal:resource(function(val)
  if not val then
    return
  end

  local screenFrame = hs.screen.mainScreen():fullFrame()
  local borderWidth = 4
  local fieldHeight = 22

  local border = hs.canvas.new(screenFrame):appendElements({
    type = "rectangle",
    action = "stroke",
    strokeColor = val.color,
    strokeWidth = borderWidth,
    frame = {
      x = borderWidth / 2,
      y = borderWidth / 2,
      w = screenFrame.w - borderWidth,
      h = screenFrame.h - borderWidth,
    },
  }):show()

  local field = hs.canvas.new(screenFrame):appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = val.color,
    frame = {
      x = 0,
      y = 0,
      w = 100,
      h = fieldHeight,
    },
  }, {
    type = "text",
    text = val.text,
    textAlignment = "left",
    textColor = { black = 1 },
    textFont = "Helvetica-Bold",
    textSize = 16,
    frame = {
      y = 3,
      x = 6,
      w = 200,
      h = fieldHeight - 1,
    },
  }):show()

  return function()
    border:delete()
    field:delete()
  end
end)

hs.alert.defaultStyle.radius = 6
hs.alert.defaultStyle.textSize = 16
hs.alert.defaultStyle.strokeColor = { white = 1, alpha = .2 }
hs.alert.defaultStyle.fadeInDuration = 0
hs.alert.defaultStyle.fadeOutDuration = 0

ScreenBorder = borderSignal
