local wibox = require("wibox")
local awful = require("awful")
local helpers = require("./helpers")

local widget = {}

-- {{{ Define subwidgets
widget.text = wibox.widget.textbox()
widget.icon = wibox.widget.imagebox()

-- Change the draw method so icons can be drawn smaller
helpers:set_draw_method(widget.icon)
-- }}}

-- {{{ Define interactive behaviour
--widget.icon:buttons(awful.util.table.join(
--    awful.button({ }, 1, function () awful.util.spawn("gnome-control-center sound") end)
--))
-- }}}

-- {{{ Update method
function widget:update()
    local fd = io.popen("xbacklight -get")
    local status= fd:read("*all")
    fd:close()
 
    local brightness = math.floor( status )
    widget.text:set_markup(brightness .. "%")

    local iconpath = "/usr/share/icons/gnome/scalable/status/display-brightness-symbolic.svg" 

    widget.icon:set_image(iconpath)

end
-- }}}

-- {{{ Listen
helpers:listen(widget)
-- }}}

return widget
