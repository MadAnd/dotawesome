-- Standard awesome library
local common = require("awful.widget.common")
local gears = require("gears")
local gfs = require("gears.filesystem")
local gtable = require("gears.table")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- Standard widgets
local hotkeys_popup = require("awful.hotkeys_popup").widget

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({ preset = naughty.config.presets.critical,
                   title = "Oops, there were errors during startup!",
                   text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal("debug::error", function (err)
                           -- Make sure we don't go into an endless error loop
                           if in_error then return end
                           in_error = true

                           naughty.notify({ preset = naughty.config.presets.critical,
                                            title = "Oops, an error happened!",
                                            text = tostring(err) })
                           in_error = false
  end)
end
-- }}}

-- Load custom theme
beautiful.init(gfs.get_configuration_dir() .. "/theme.lua")

-- Split-out config parts
-- Default modkey. Define it before requiring external hotkey files!
modkey = "Mod4"
require("rules")
local globalkeys = require("globalkeys")
local taglistcfg = require("taglistcfg")
local tasklistcfg = require("tasklistcfg")

-- Private libs. Non-local to be accessible via awesome-client.
multimedia = require("multimedia")
kbdlayout = require("kbdlayout")
volume_control = require("volume-control")
cpuload = require("cpuload")

-- {{{ Variable definitions

-- This is used later as the default terminal and editor to run.
terminal = "urxvt "
editor = os.getenv("EDITOR") or "emacsclient -c"
editor_cmd = terminal .. " -e " .. editor

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
  awful.layout.suit.max,
  awful.layout.suit.tile,
  awful.layout.suit.tile.left,
  awful.layout.suit.tile.bottom,
  awful.layout.suit.tile.top,
  -- awful.layout.suit.fair,
  -- awful.layout.suit.fair.horizontal,
  awful.layout.suit.max.fullscreen,
  awful.layout.suit.floating,
  -- awful.layout.suit.magnifier
  -- awful.layout.suit.corner.nw,
  -- awful.layout.suit.corner.ne,
  -- awful.layout.suit.corner.sw,
  -- awful.layout.suit.corner.se,
}

local default_layout = awful.layout.layouts[1]
-- }}}

-- {{{ Menu

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibar
-- Create a textclock widget
os.setlocale("uk_UA.UTF-8", "time")
local mytextclock = wibox.widget {
  {
    {
      widget = wibox.widget.textclock("%H:%M"),
      font = beautiful.font_small,
      align = "center",
    },
    {
      widget = wibox.widget.textclock("%a %d"),
      font = beautiful.font_small,
      align = "center",
    },
    layout = wibox.layout.fixed.vertical
  },
  layout = wibox.container.margin,
  top = 0,
  bottom = 2,
}

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local mycputemp_cmd = [[bash -c "cat /sys/class/hwmon/hwmon0/temp1_input |
    awk '{ print substr($1, 1, 2) \"°C\"; }'"]]
local cputemp_callback = function (widget, stdout, stderr, exitreason, exitcode)
  widget:set_text(trim(stdout))
end
local cputemp_textbox = wibox.widget {
  widget = wibox.widget.textbox,
  align = "center",
  font = beautiful.font_small,
}
local mycputemp = wibox.widget {
  awful.widget.watch(mycputemp_cmd, nil, cputemp_callback, cputemp_textbox),
  layout = wibox.container.margin,
  top = 2,
  bottom = 2,
}

-- Configure sound volume control module
volumecfg = volume_control {
  timeout = 2,
  mclick  = terminal .. "-e alsamixer",
  rclick  = terminal .. "-e alsamixer",
}
volumecfg.widget:set_font(beautiful.font_small)

-- Setup kbdlayout module
kbdlayout.init {
    layouts = {
      { layout="us", variant="dvp" , icon="us.png" },
      -- { layout="us", variant="dvorak" , icon="us.png" },
      -- { layout="us", icon="us.png" },
      { layout="ua,us", variant=",dvp", icon="ua.png" }
    },
    post_switch_cmd = "xmodmap ~/.Xmodmap",
}

-- Create a wibox for each screen and add it
local function set_wallpaper(s)
  -- Wallpaper
  if beautiful.wallpaper then
    local wallpaper = beautiful.wallpaper
    -- If wallpaper is a function, call it with the screen
    if type(wallpaper) == "function" then
      wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)
  end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag.add("1", { screen = s, layout = default_layout })
    awful.tag.add("2", { screen = s, layout = awful.layout.suit.max.fullscreen, selected = true })
    awful.tag.add("3", { screen = s, layout = default_layout })
    awful.tag.add("4", { screen = s, layout = default_layout })
    awful.tag.add("5", { screen = s, layout = default_layout })
    awful.tag.add("6", { screen = s, layout = default_layout })
    awful.tag.add("7", { screen = s, layout = default_layout })
    awful.tag.add("8", { screen = s, layout = awful.layout.suit.max.fullscreen })
    awful.tag.add("9", { screen = s, layout = default_layout })

    -- Create a taglist widget
    local mytagslayout = wibox.layout.grid("vertical")
    mytagslayout:set_forced_num_cols(2)
    local mytagfilter = awful.widget.taglist.filter.all
    s.mytaglist = awful.widget.taglist(s, mytagfilter, taglistcfg.buttons, nil, taglistcfg.update_function, mytagslayout)

    -- Create a tasklist widget
    s.mytasklist = tasklistcfg.widget(s)

    -- Create systray widget
    s.mysystray = wibox.widget {
      {
        widget = wibox.widget.systray,
        horizontal = false
      },
      layout = wibox.container.margin,
      left = dpi(4, s),
      right = dpi(4, s),
      top = dpi(2, s),
      bottom = dpi(2, s),
    }

    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    local wlayoutbox = awful.widget.layoutbox(s)
    wlayoutbox:buttons(gtable.join(
                            awful.button({ }, 1, function () awful.layout.inc( 1) end),
                            awful.button({ }, 3, function () awful.layout.inc(-1) end),
                            awful.button({ }, 4, function () awful.layout.inc( 1) end),
                            awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    s.mylayoutbox = wibox.widget {
      wlayoutbox,
      layout = wibox.container.margin,
      left = dpi(4, s),
      right = dpi(4, s),
    }

    -- Create the wibox
    -- s.mywibox = awful.wibar({ position = "top", height = 22, screen = s })
    s.mywibox = awful.wibar {
        position = "right",
        width = 30,
        screen = s,
    }

    -- Add widgets to the wibox
    s.mywibox:setup {
      layout = wibox.layout.align.vertical,
      s.mytaglist, -- Top widget
      s.mytasklist, -- Middle widget
      { -- Bottom widgets
        layout = wibox.layout.fixed.vertical,
        s.mysystray,
        cpuload,
        kbdlayout(),
        volumecfg.widget,
        mycputemp,
        mytextclock,
        s.mylayoutbox,
      },
    }
end)
-- }}}

-- Global hotkeys.
root.keys(
  gtable.join(
    globalkeys,
    -- Hotkeys help pop-up.
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
      {description="show help", group="awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
      {description = "show the menubar", group = "launcher"}),
    -- Switch keyboard layout: Mod4 + l (qwerty) or Mod4 + n (dvorak).
    awful.key({ modkey }, "#46", function () kbdlayout.switch() end,
      {description = "switch keyboard layout", group = "client"}),
    -- Volume control
    awful.key({}, "XF86AudioRaiseVolume", function () volumecfg:up() end),
    awful.key({}, "XF86AudioLowerVolume", function () volumecfg:down() end),
    awful.key({}, "XF86AudioMute",        function () volumecfg:toggle_snd() end),
    awful.key({}, "XF86AudioMicMute",        function () volumecfg:toggle_mic() end),
    -- Playback control
    awful.key({}, "XF86AudioPlay", multimedia.playback_toggle),
    awful.key({}, "XF86AudioStop", multimedia.playback_stop),
    awful.key({}, "XF86AudioNext", multimedia.playback_next),
    awful.key({}, "XF86AudioPrev", multimedia.playback_prev)
  )
)

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
  -- Set the windows at the slave,
  -- i.e. put it at the end of others instead of setting it master.
  -- if not awesome.startup then awful.client.setslave(c) end

  if awesome.startup and
    not c.size_hints.user_position
  and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal(
  "request::titlebars",
  function(c)
    -- buttons for the titlebar
    local buttons = gtable.join(
      awful.button({ }, 1, function()
          client.focus = c
          c:raise()
          awful.mouse.client.move(c)
      end),
      awful.button({ }, 3, function()
          client.focus = c
          c:raise()
          awful.mouse.client.resize(c)
      end)
    )

    awful.titlebar(c) : setup {
      { -- Left
        awful.titlebar.widget.iconwidget(c),
        buttons = buttons,
        layout  = wibox.layout.fixed.horizontal
      },
      { -- Middle
        { -- Title
          align  = "center",
          widget = awful.titlebar.widget.titlewidget(c)
        },
        buttons = buttons,
        layout  = wibox.layout.flex.horizontal
      },
      { -- Right
        awful.titlebar.widget.floatingbutton (c),
        awful.titlebar.widget.maximizedbutton(c),
        awful.titlebar.widget.stickybutton   (c),
        awful.titlebar.widget.ontopbutton    (c),
        awful.titlebar.widget.closebutton    (c),
        layout = wibox.layout.fixed.horizontal()
      },
      layout = wibox.layout.align.horizontal
    }

    local l = awful.layout.get(c.screen)
    if not (l.name == "floating" or c.floating) then
      awful.titlebar.hide(c)
    end
end)

-- Border styling for the focused client.
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- Workaround for xrandr monitor switching moves all clients to tag 1.
screen.connect_signal("removed", awesome.restart)
screen.connect_signal("added", awesome.restart)

--- Hide border on maximized/fullscreen windows to save a bit of space.
-- https://stackoverflow.com/a/51687321
-- I believe it correctly handles maximized windows, windows that are the only
-- visible one in the layout, and windows in the 'max' layout. It also ignores
-- floating clients as it should.
screen.connect_signal("arrange", function (s)
  if s.selected_tag == nil then
    return
  end

  local max = s.selected_tag.layout.name == "max"
  -- use tiled_clients so that other floating windows don't affect the count
  -- but iterate over clients instead of tiled_clients as tiled_clients doesn't include maximized windows
  local only_one = #s.tiled_clients == 1
  for _, c in pairs(s.clients) do
    if (max or only_one) and not c.floating or c.maximized then
      c.border_width = 0
    else
      c.border_width = beautiful.border_width
    end
  end
end)


--- Try to preserve client-tag relationship when switching screens.
-- https://github.com/awesomeWM/awesome/issues/1382#issuecomment-289378695
tag.connect_signal("request::screen", function(t)
  local fallback_tag = nil

  -- find tag with same name on any other screen
  for other_screen in screen do
    if other_screen ~= t.screen then
      fallback_tag = awful.tag.find_by_name(other_screen, t.name)
      if fallback_tag ~= nil then
        break
      end
    end
  end

  -- no tag with same name exists, chose random one
  if fallback_tag == nil then
    fallback_tag = awful.tag.find_fallback()
  end

  -- delete the tag and move it to other screen
  t:delete(fallback_tag, true)
end)

--- Show titlebars on floating clients.
-- http://www.holgerschurig.de/en/awesome-4.0-titlebars/
client.connect_signal("property::floating", function (c)
  if c.floating then
    awful.titlebar.show(c)
  else
    awful.titlebar.hide(c)
  end
end)

--- Show titlebars with floating layout.
-- http://www.holgerschurig.de/en/awesome-4.0-titlebars/
awful.tag.attached_connect_signal(s, "property::layout", function (t)
  local float = t.layout.name == "floating"
  for _,c in pairs(t:clients()) do
    c.floating = float
  end
end)

-- }}}
