local awful = require("awful")
local gtable = require("gears.table")

local clientkeys = require("clientkeys")

-- Mouse button bindings for clients. 1 = LMB, 2 = MBM, 3 = RMB.
clientbuttons = gtable.join(
  awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
  -- All clients will match this rule.
  { rule = { },
    properties = {
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      screen = awful.screen.preferred,
      size_hints_honor = false,
      placement = awful.placement.no_overlap+awful.placement.no_offscreen,
  }},

  -- Add title bars to normal clients and dialogs
  { rule_any = {
      type = { "normal", "dialog" }
  }, properties = { titlebars_enabled = true }},

  -- Make Thunderbird Message Compose window non-floating.
  { rule_any = {
      role = { "Msgcompose" }
  }, properties = { floating = false }},

  -- Floating clients.
  { rule_any = {
      instance = {
        "DTA",  -- Firefox addon DownThemAll.
        "copyq",  -- Includes session name in class.
      },
      class = {
        "Arandr",
        "Gpick",
        "Kruler",
        "MessageWin",  -- kalarm.
        "Sxiv",
        "Wpa_gui",
        "pinentry",
        "veromix",
        "xtightvncviewer"},
      name = {
        "Event Tester",  -- xev.
      },
      role = {
        "AlarmWindow",  -- Thunderbird's calendar.
        "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
      }
  }, properties = { floating = true }},

  -- Set Firefox to always map on the tag named "2" on screen 1.
  -- { rule = { class = "Firefox" },
  --   properties = { screen = 1, tag = "1" } },

  { rule = { class = "mpv" },
    properties = { fullscreen = true, floating = true } },
}
