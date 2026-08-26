local colors = require("colors")
local settings = require("settings")

-- Next meeting indicator (what MeetingBar shows in the native menu bar).
-- Data comes from the macOS Calendar via icalBuddy; hidden when no
-- meetings remain today. Click joins the meeting link if one is found
-- in the event, otherwise opens Calendar.

local ICALBUDDY = "/opt/homebrew/bin/icalBuddy"
local QUERY = ICALBUDDY
  .. [[ -n -li 1 -ea -b "" -nc -iep "title,datetime" -po "datetime,title" -ps "|;|" -tf "%H:%M" -df "" eventsToday]]

local meeting = sbar.add("item", "meeting", {
  position = "right",
  drawing = false,
  update_freq = 60,
  icon = {
    string = "􀍉", -- SF Symbol: video
    color = colors.yellow,
    padding_left = 8,
    font = {
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 8,
    font = { family = settings.font.numbers },
  },
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.bg2,
    border_color = colors.black,
    border_width = 1,
  },
  -- Click: open MeetingBar's native dropdown (status items live in
  -- "menu bar 2"; needs Accessibility permission for sketchybar).
  -- Fallback when MeetingBar isn't running: join the meeting link
  -- directly, or open Calendar.
  click_script = [[if pgrep -x MeetingBar >/dev/null; then
    osascript -e 'tell application "System Events" to tell process "MeetingBar" to click menu bar item 1 of menu bar 2'
  else
    url=$(]] .. ICALBUDDY .. [[ -n -li 1 -ea -b "" -nc eventsToday \
      | grep -oE 'https://[a-zA-Z0-9./?=_%&#:-]+' \
      | grep -Ei 'zoom\.us|meet\.google|teams\.microsoft|whereby|webex' \
      | head -1)
    [ -n "$url" ] && open "$url" || open -a Calendar
  fi]],
})

local function trim_title(title, max)
  if #title > max then
    return title:sub(1, max - 1) .. "…"
  end
  return title
end

local function update()
  sbar.exec(QUERY, function(out)
    out = out:gsub("%s+$", "")
    local start_time, title = out:match("^(%d+:%d+)[^;]*;%s*(.+)$")
    if not start_time or not title then
      meeting:set({ drawing = false })
      return
    end

    local h, m = start_time:match("(%d+):(%d+)")
    local now = os.date("*t")
    local mins = (tonumber(h) * 60 + tonumber(m)) - (now.hour * 60 + now.min)

    local when
    if mins <= 0 then
      when = "now"
    elseif mins < 60 then
      when = "in " .. mins .. "m"
    else
      when = "at " .. start_time
    end

    meeting:set({
      drawing = true,
      -- 20 keeps icon + title + " at HH:MM" right of the notch on the
      -- built-in display, with margin for wider widget labels (e.g. 100%).
      label = { string = trim_title(title, 20) .. " " .. when },
      icon = { color = mins <= 5 and colors.red or colors.yellow },
    })
  end)
end

meeting:subscribe({ "forced", "routine", "system_woke" }, function(_)
  update()
end)
