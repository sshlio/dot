local frontmostApplication = hs.application.frontmostApplication()
local app = Signal.new(frontmostApplication and frontmostApplication:name() or "unknown"):memo()


applicationWatcher = hs.application.watcher.new(function(name, event)
  if event == hs.application.watcher.activated then
    app:set(name)
  end
end)

applicationWatcher:start()


------


G.mappings = {};

G.mappings.default = {
  ["q"] = function() hs.alert.show("hyper+q is free to take") end,
  ["m"] = function() hs.alert.show("hyper+m is free to take") end,
};

G.mappings["Google Chrome"] = {
  ["q"] = function() hs.alert.show("hyper+q is free to take") end,
  ["m"] = function() hs.alert.show("hyper+m is free to take") end,
  ["s"] = function() hs.alert.show("hyper+s is free to take") end,
  ["d"] = function() hs.alert.show("hyper+d is free to take") end,
  ["a"] = function() hs.alert.show("hyper+a is free to take") end,
  ["e"] = function() hs.alert.show("hyper+e is free to take") end,
};


G.mapping = {}

local mappint = app:map(function(appName)
  G.mapping = G.mappings[appName] or G.mappings.default

  return G.mapping
end)

mappint:log("mapping")

-- local keyboardName = Signal.new("unknown")
-- local combined = Signal.mapN(function(one, two) return { one, two } end, app:memo(), keyboardName)
--
-- keyboardName:set("Logitch")
--
-- combined:log("combined")
