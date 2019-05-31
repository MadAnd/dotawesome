------------------------------------------------------------------------
--- kbdlayout allows for flexible language switching configuration (with
--- setxkbmap).
-- @author Andriy Kmit' &lt;dev@madand.net&gt;
-- @copyright 2016 Andriy Kmit'
-- @module kbdlayout
------------------------------------------------------------------------

local awful = require("awful")
local gfs = require("gears.filesystem")
local gtable = require("gears.table")
local wibox = require("wibox")
local naughty = require("naughty")

--- Keyboard layout switcher with (optional) wibox indicator.
local kbdlayout = { mt = {} }

local client_layouts = {}
setmetatable(client_layouts, { __mode = 'k' })
local widgets = {}
local current_layout
local current_client

--- Definition of a single keyboard layout.
-- @table layout_definition
-- @tfield string layout XKB layout name.
-- @tfield string icon Icon file name. It must be a path relative to @{module_config:icon_dir}
-- @tfield[opt] string variant XKB layout variant name.
-- @tfield[opt] string post_switch_cmd Command to be executed after layout switch.

--- List of keyboard layout definitions.
-- @see layout_definition
kbdlayout.layouts = {}

--- Index of a layout from @{layouts}, to be used as a default for new clients.
--
-- Default: 1
-- @see layouts
kbdlayout.default_layout_index = 1

--- Example expansion: { setxkbmap us dvorak && post_switch_cmd }&
kbdlayout.switch_cmd_format = "{ setxkbmap %s %s && %s; }&"

--- Additional command to be executed after the layout was set.
-- Can be overridden on a per layout basis by defining `post_switch_cmd` key.
--
-- Default: ":" (a no operation command).
-- @see layout_definition
kbdlayout.post_switch_cmd = ":"

--- Directory containing flag icons.
--
-- Default: "~/.config/awesome/kbdlayout/icons/"
kbdlayout.icon_dir = gfs.get_configuration_dir() .. "/kbdlayout/icons/"

local function update_widgets(icon)
  for _, widget in ipairs(widgets) do
    widget:set_image(kbdlayout.icon_dir .. icon)
  end
end

-- Signal handlers for maintaining per-client keyboard layout

local function on_focus(c)
  current_client = c

  if client_layouts[current_client] == nil then
    client_layouts[current_client] = kbdlayout.default_layout_index
  end

  kbdlayout.switch(client_layouts[current_client])
end

local function on_unfocus()
  current_client = nil
end

local function on_unmanage(c)
  client_layouts[c] = nil
end

local function attach_client_signal_handlers()
  client.connect_signal("focus", on_focus)
  client.connect_signal("unfocus", on_unfocus)
  client.connect_signal("unmanage", on_unmanage)
end

local function show_warning(title, text)
  naughty.notify({ preset = naughty.config.presets.critical,
                   title = title,
                   text = text })
end

local initialized = false

--- Initilize the module.
-- @tparam module_config config Module configuration. This will be merged with
-- @{default_config}.
function kbdlayout.init(config)
  if not (config.layouts and #config.layouts > 0) then
    show_warning(
      "invalid configuration of kbdlayout",
      "You must provide at least the 'layouts' config."
    )
    return
  end

  for k,v in pairs(config) do
    if type(kbdlayout[k]) ~= "function" then
      kbdlayout[k] = v
    end
  end

  initialized = true

  kbdlayout.switch(kbdlayout.default_layout_index)
  attach_client_signal_handlers()
end

local function exec_switch_cmd(layoutCfg)
  os.execute(
    kbdlayout.switch_cmd_format:format(
      layoutCfg.layout,
      layoutCfg.variant or "",
      layoutCfg.post_switch_cmd or kbdlayout.post_switch_cmd
    )
  )
end

function kbdlayout.switch(layout)
  if not initialized then
    return
  end

  local new_layout

  if layout then
    new_layout = layout
  elseif current_layout then
    new_layout = current_layout % #(kbdlayout.layouts) + 1
  else
    new_layout = kbdlayout.default_layout_index
  end

  if new_layout == current_layout then
    return
  end

  current_layout = new_layout

  if current_client then
    client_layouts[current_client] = current_layout
  end

  local layoutCfg = kbdlayout.layouts[current_layout]
  update_widgets(layoutCfg.icon)
  exec_switch_cmd(layoutCfg)
end

--- Constructor
function kbdlayout.new(args)
  if not initialized then
    show_warning(
      "kbdlayout is not initialized",
      "You must call kbdlayout.init() with proper arguments before using the widget."
    )

    return
  end

  local w = wibox.widget.imagebox()
  table.insert(widgets, w)

  -- Mouse bindings
  w:buttons(
    gtable.join(awful.button({ }, 1, function () kbdlayout.switch() end))
  )

  if current_layout then
    w:set_image(kbdlayout.icon_dir .. kbdlayout.layouts[current_layout].icon)
  end

  return w
end

local _instance = nil;

function kbdlayout.mt:__call(...)
  if _instance == nil then
    _instance = kbdlayout.new(...)
  end
  return _instance
end

return setmetatable(kbdlayout, kbdlayout.mt)
