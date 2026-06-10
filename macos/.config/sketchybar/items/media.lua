local icons = require("icons")
local colors = require("colors")

local whitelist = { ["Spotify"] = true,
                    ["Music"] = true    };

-- macOS 15.4+ broke the built-in media_change event (MediaRemote lockdown).
-- helpers/media_stream.sh streams updates from media-control and fires this
-- custom event instead.
sbar.add("event", "media_update")

local config_dir = os.getenv("CONFIG_DIR") or (os.getenv("HOME") .. "/.config/sketchybar")
local stream_script = config_dir .. "/helpers/media_stream.sh"
sbar.exec("pkill -f 'helpers/media_stream.sh' >/dev/null 2>&1; (nohup '" .. stream_script .. "' >/dev/null 2>&1 &)")

local media_cover = sbar.add("item", {
  position = "right",
  background = {
    image = {
      -- Artwork thumbnails are 128px (see helpers/media_stream.sh); draw at ~26pt
      scale = 0.2,
      corner_radius = 9,
    },
    color = colors.transparent,
  },
  label = { drawing = false },
  icon = { drawing = false },
  drawing = false,
  updates = true,
  popup = {
    align = "center",
    horizontal = true,
  }
})

local media_artist = sbar.add("item", {
  position = "right",
  drawing = false,
  padding_left = 3,
  padding_right = 0,
  width = 0,
  icon = { drawing = false },
  label = {
    width = 0,
    font = { size = 9 },
    color = colors.with_alpha(colors.white, 0.6),
    max_chars = 18,
    y_offset = 6,
  },
})

local media_title = sbar.add("item", {
  position = "right",
  drawing = false,
  padding_left = 3,
  padding_right = 0,
  icon = { drawing = false },
  label = {
    font = { size = 11 },
    width = 0,
    max_chars = 16,
    y_offset = -5,
  },
})

local media_control = "/opt/homebrew/bin/media-control"

sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.back },
  label = { drawing = false },
  click_script = media_control .. " previous-track",
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.play_pause },
  label = { drawing = false },
  click_script = media_control .. " toggle-play-pause",
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  click_script = media_control .. " next-track",
})

local interrupt = 0
local function animate_detail(detail)
  if (not detail) then interrupt = interrupt - 1 end
  if interrupt > 0 and (not detail) then return end

  sbar.animate("tanh", 30, function()
    media_artist:set({ label = { width = detail and "dynamic" or 0 } })
    media_title:set({ label = { width = detail and "dynamic" or 0 } })
  end)
end

media_cover:subscribe("media_update", function(env)
  local drawing = (whitelist[env.APP] ~= nil) and (env.STATE == "playing")
  media_artist:set({ drawing = drawing, label = env.ARTIST, })
  media_title:set({ drawing = drawing, label = env.TITLE, })
  media_cover:set({
    drawing = drawing,
    background = { image = (env.ARTWORK ~= "") and env.ARTWORK or nil },
  })

  if drawing then
    animate_detail(true)
    interrupt = interrupt + 1
    sbar.delay(5, animate_detail)
  else
    media_cover:set({ popup = { drawing = false } })
  end
end)

media_cover:subscribe("mouse.entered", function(env)
  interrupt = interrupt + 1
  animate_detail(true)
end)

media_cover:subscribe("mouse.exited", function(env)
  animate_detail(false)
end)

media_cover:subscribe("mouse.clicked", function(env)
  media_cover:set({ popup = { drawing = "toggle" }})
end)

media_title:subscribe("mouse.exited.global", function(env)
  media_cover:set({ popup = { drawing = false }})
end)
