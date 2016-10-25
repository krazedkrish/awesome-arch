local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local helpers = require("./helpers")

local widget = {}

-- {{{ Define subwidgets
widget.text = wibox.widget.textbox()
widget.icon = wibox.widget.imagebox()

-- Change the draw method so icons can be drawn smaller
helpers:set_draw_method(widget.icon)
-- }}}

-- {{{ Define interactive behaviour
widget.icon:buttons(awful.util.table.join(
                      awful.button({ }, 1, function () awful.util.spawn("thunderbird") end)
))
-- }}}


function showEmailWidgetPopup()	
	local save_offset = offset
	local popuptext = "test"
	naughty.notify({
		title = "Unread emails",
		text = awful.util.pread("python /home/codekathmandu/.config/awesome/getUnreadEmails.py"),
		timeout = 10, 
		width = 300,
		fg = "#ffffff",
		bg = "#333333aa",
		})
end

widget.icon:set_image("/usr/share/icons/gnome/scalable/status/mail-unread-symbolic.svg")
widget.icon:connect_signal("mouse::enter", function() showEmailWidgetPopup() end)

dbus.request_name("session", "ru.console.df")
dbus.add_match("session", "interface='ru.console.df', member='fsValue' " )
dbus.connect_signal("ru.console.df", 
	function (...)
		local data = {...}
		local dbustext = data[2]
		widget.text:set_text(dbustext)
	end)

emailCountTimer = timer ({timeout = 5})
emailCountTimer:connect_signal ("timeout", 
	function ()
		awful.util.spawn_with_shell("dbus-send --session --dest=org.naquadah.awesome.awful /ru/console/df ru.console.df.fsValue string:$(python3 /home/codekathmandu/.config/awesome/getUnreadEmailsNum.py)" )
	end)
emailCountTimer:start()

return widget
