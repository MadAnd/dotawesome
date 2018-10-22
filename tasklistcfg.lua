-- Configuration bits for awful.widget.tasklist

local type = type
local ipairs = ipairs
local awful = require("awful")
local capi = { button = button }
local common = require("awful.widget.common")
local gears = require("gears")
local gtable = require("gears.table")
local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi

-- Module table
local tasklistcfg = { }

tasklistcfg.filter = awful.widget.tasklist.filter.currenttags

function tasklistcfg.layout()
  return wibox.layout.fixed.vertical()
end


local function client_menu_toggle_fn()
  local instance = nil

  return function ()
    if instance and instance.wibox.visible then
      instance:hide()
      instance = nil
    else
      instance = awful.menu.clients { theme = { width = 250 } }
    end
  end
end

tasklistcfg.buttons = gtable.join(
  awful.button({ }, 1, function (c)
      if c == client.focus then
        -- c.minimized = true
      else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() and c.first_tag then
          c.first_tag:view_only()
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
      end
  end),
  awful.button({ }, 3, client_menu_toggle_fn())
)

--- Update fn for tasklist widget.
-- @param w The widget.
-- @tab buttons
-- @func label Function to generate label parameters from an object.
--   The function gets passed an object from `objects`, and
--   has to return `text`, `bg`, `bg_image`, `icon`.
-- @tab data Current data/cache, indexed by objects.
-- @tab objects Objects to be displayed / updated.
function tasklistcfg.update_function(w, buttons, label, data, objects)
    -- update the widgets, creating them if needed
    w:reset()
    for i, o in ipairs(objects) do
        local cache = data[o]
        local ib, tb, bgb, tbm, ibm, l
        if cache then
            ib = cache.ib
            tb = cache.tb
            bgb = cache.bgb
            tbm = cache.tbm
            ibm = cache.ibm
        else
            ib = wibox.widget.imagebox()
            tb = wibox.widget.textbox()
            bgb = wibox.container.background()
            tbm = wibox.container.margin(tb, dpi(2), dpi(2))
            ibm = wibox.container.margin(ib, dpi(2), dpi(2), dpi(2), dpi(2))
            l = wibox.layout.fixed.horizontal()

            -- All of this is added in a fixed widget
            l:fill_space(true)
            l:add(ibm)
            l:add(tbm)

            -- And all of this gets a background
            bgb:set_widget(l)

            bgb:buttons(common.create_buttons(buttons, o))

            data[o] = {
                ib  = ib,
                tb  = tb,
                bgb = bgb,
                tbm = tbm,
                ibm = ibm,
            }
        end

        local text, bg, bg_image, icon, args = label(o, tb)
        args = args or {}

        -- The text might be invalid, so use pcall.
        if text == nil or text == "" then
            tbm:set_margins(0)
        else
            if not tb:set_markup_silently(text) then
                tb:set_markup("<i>&lt;Invalid text&gt;</i>")
            end
        end
        bgb:set_bg(bg)
        if type(bg_image) == "function" then
            -- TODO: Why does this pass nil as an argument?
            bg_image = bg_image(tb,o,nil,objects,i)
        end
        bgb:set_bgimage(bg_image)
        if icon then
            ib:set_image(icon)
        else
            ibm:set_margins(0)
        end

        bgb:set_shape(gears.shape.rounded_rect, 6)

        w:add(bgb)
   end
end

--- Create new tasklist widget.
-- @
function tasklistcfg.widget(s)
  return awful.widget.tasklist(
    s,
    tasklistcfg.filter,
    tasklistcfg.buttons,
    nil,
    tasklistcfg.update_function,
    tasklistcfg.layout()
  )
end

return tasklistcfg
