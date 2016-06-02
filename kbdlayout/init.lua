---------------------------------------------------------------------------
-- @author Andriy Kmit' &lt;dev@madand.net&gt;
-- @copyright 2016 Andriy Kmit'
-- @module kbdlayout
---------------------------------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")

--- Keyboard layout switcher with (optional) wibox indicator.
local kbdlayout = {}

local client_layout, widgets = {}, {}
local current_layout, current_client


--- List of keyboard layout definitions.
-- @see layout_definition
kbdlayout.layouts = {}

--- Index of a layout from @{layouts}, to be used as a default for new clients.
--
-- Default: 1
-- @see layouts
kbdlayout.default_layout = 1

--- Additional command to be executed after the layout was set.
-- Can be overridden on a per layout basis by defining `post_cmd` key.
--
-- Default: ":" (a no operation command).
-- @see layout_definition
kbdlayout.default_post_cmd = ":"

--- Example expansion: { setxkbmap us dvorak && default_post_cmd }&
kbdlayout.cmd_format = "{ setxkbmap %s %s && %s; }&"

--- Directory containing flag icons.
--
-- Default: "~/.config/awesome/kbdlayout/icons/"
kbdlayout.icon_dir = awful.util.getdir("config") .. "/kbdlayout/icons/"

local function update_widgets(icon)
  for _, widget in ipairs(widgets) do
    widget:set_image(kbdlayout.icon_dir .. icon)
  end
end

function kbdlayout.widget()
  local w = wibox.widget.imagebox()
  table.insert(widgets, w)

  -- Mouse bindings
  w:buttons(
    awful.util.table.join(awful.button({ }, 1, function () kbdlayout.switch() end))
  )

  if current_layout then
    w:set_image(kbdlayout.icon_dir .. kbdlayout.layouts[current_layout].icon)
  end

  return w
end


function kbdlayout.switch(layout)
  local new_layout
  if layout then
    new_layout = layout
  elseif current_layout then
    new_layout = current_layout % #(kbdlayout.layouts) + 1
  else
    new_layout = kbdlayout.default_layout
  end

  if new_layout == current_layout then
    return
  end

  current_layout = new_layout

  if current_client then
    client_layout[current_client] = current_layout
  end

  local t = kbdlayout.layouts[current_layout]
  update_widgets(t.icon)
  os.execute(
    kbdlayout.cmd_format:format(t.layout, t.variant, kbdlayout.default_post_cmd)
  )
end

-- Signal handlers for maintaining per-client keyboard layout

local function on_focus(c)
  current_client = c.window

  if client_layout[current_client] == nil then
    client_layout[current_client] = kbdlayout.default_layout
  end

  kbdlayout.switch(client_layout[current_client])
end

local function on_unfocus()
  current_client = nil
end

local function on_unmanage(c)
  client_layout[c.window] = nil
end

client.connect_signal("focus", on_focus)
client.connect_signal("unfocus", on_unfocus)
client.connect_signal("unmanage", on_unmanage)

--- Definition of a single keyboard layout.
-- These are put into the @{layouts} table.
-- @name layout_definition
-- @class table
-- @tfield string setlayout_args
-- @tfield[opt] string post_cmd

return kbdlayout
