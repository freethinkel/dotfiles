local icons = require("icons")

local whitelist = { ["Spotify"] = true, ["Music"] = true }

local media = sbar.add("item",
  {
    icon = { drawing = false },
    padding_right = 30,
    position = "right",
    updates = true,
  })


local app_name = ""

media:subscribe("media_change", function(env)
  print("Media item initialized", app_name)
  app_name = env.INFO.app
  if whitelist[env.INFO.app] then
    media:set({
      drawing = (env.INFO.state == "playing") and true or false,
      label = icons.music .. " " .. env.INFO.artist .. " – " .. env.INFO.title,
    })
  end
end)

media:subscribe("mouse.clicked", function()
  sbar.exec("open -a '" .. app_name .. "'")
end)
