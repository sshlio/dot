Signal = {}
Signal.__index = Signal

function Signal.new(val)
  local self = setmetatable({}, Signal)

  self.val = val
  self.listeners = {}

  return self
end

function Signal:get()
  return self.val
end

function Signal:listen(listener)
  assert(type(listener) == "function", "Signal listener must be a function")

  local subscription = { listener = listener, active = true }
  table.insert(self.listeners, subscription)
  listener(self.val)

  return function()
    subscription.active = false
    subscription.listener = nil
  end
end

function Signal:log(name)
  assert(type(name) == "string", "Signal log name must be a string")

  return self:listen(function(value)
    print("Signal [" .. name .. "]", hs.inspect(value))
  end)
end

function Signal:set(newVal)
  self.val = newVal

  local listenerCount = #self.listeners
  for index = 1, listenerCount do
    local subscription = self.listeners[index]
    if subscription.active then
      subscription.listener(newVal)
    end
  end
end

local function isSignal(value)
  return getmetatable(value) == Signal
end

function Signal:flatMap(mapper)
  assert(type(mapper) == "function", "Signal mapper must be a function")

  local inner = mapper(self:get())
  assert(isSignal(inner), "Signal flatMap mapper must return a Signal")

  local mapped = Signal.new(inner:get())
  local stopInner

  local function follow(nextInner)
    assert(isSignal(nextInner), "Signal flatMap mapper must return a Signal")

    if stopInner then
      stopInner()
    end

    inner = nextInner
    mapped:set(inner:get())

    local initialNotification = true
    stopInner = inner:listen(function(value)
      if initialNotification then
        initialNotification = false
        return
      end

      mapped:set(value)
    end)
  end

  local initialNotification = true
  self:listen(function(value)
    if initialNotification then
      initialNotification = false
      return
    end

    follow(mapper(value))
  end)

  follow(inner)
  return mapped
end

function Signal:map(mapper)
  return Signal.mapN(mapper, self)
end

function Signal:memo()
  local previous = self:get()
  local memoized = Signal.new(previous)

  self:map(function(value)
    local changed = not rawequal(value, previous)
    previous = value

    if changed then
      memoized:set(value)
    end
  end)

  return memoized
end

function Signal.mapN(first, ...)
  local mapper
  local signals

  if isSignal(first) then
    local arguments = { ... }
    mapper = table.remove(arguments, 1)
    signals = { first, table.unpack(arguments) }
  else
    mapper = first
    signals = { ... }
  end

  assert(type(mapper) == "function", "Signal mapper must be a function")
  assert(#signals > 0, "Signal mapN requires at least one Signal")

  local values = {}
  for index, signal in ipairs(signals) do
    assert(isSignal(signal), "Signal mapN sources must be Signals")
    values[index] = signal:get()
  end

  local signalCount = #signals
  local mapped = Signal.new(mapper(table.unpack(values, 1, signalCount)))

  for index, signal in ipairs(signals) do
    local initialNotification = true
    signal:listen(function(value)
      if initialNotification then
        initialNotification = false
        return
      end

      values[index] = value
      mapped:set(mapper(table.unpack(values, 1, signalCount)))
    end)
  end

  return mapped
end

function Signal:resource(fn)
  local prev = function() end

  self:listen(function(val)
    prev()
    prev = fn(val)
  end)
end
