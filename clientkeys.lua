local awful = require("awful")
local gtable = require("gears.table")

return gtable.join(
  awful.key({ modkey,           }, "f",
    function (c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    {description = "toggle fullscreen", group = "client"}),
  awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
    {description = "close", group = "client"}),
  awful.key({ modkey,  }, "q",      function (c) c:kill()                         end,
    {description = "close", group = "client"}),
  -- awful.key({ modkey,           }, "o",  awful.client.floating.toggle                     ,
  --   {description = "toggle floating", group = "client"}),
  awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
    {description = "move to master", group = "client"}),
  awful.key({ modkey, "Control" }, "o",      function (c) c:move_to_screen()               end,
    {description = "move to screen", group = "client"}),
  awful.key({ modkey, "Control" }, "t", awful.titlebar.toggle,
    {description = "toggle titlebar", group = "client"}),
  -- awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
  --   {description = "toggle keep on top", group = "client"}),
  awful.key({ modkey,           }, "m",
    function (c)
      c.maximized = not c.maximized
      c:raise()
    end ,
    {description = "maximize", group = "client"})-- ,
  -- awful.key({ modkey,           }, "v",
  --   function (c)
  --     c.maximized_vertical = not c.maximized_vertical
  --     c:raise()
  --   end ,
  --   {description = "maximize vertically", group = "client"})
)
