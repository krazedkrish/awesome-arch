-- Standard awesome libraru
local gears = require("gears")
local awful = require("awful")
local common = require("awful.widget.common") 
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- Custom libraries
local helpers = require("helpers")

-- Custom widgets
local myvolume = require("volume")
local mybrightness= require("brightness")
local mybattery = require("battery")
local mymail = require("email")
local mywifi = require("wifi")
-- local foggy = require('foggy')  -- for xrandr

-- -- Foggy config
-- local foggyicon = wibox.widget.background(wibox.widget.imagebox('path-to-image.png'), '#313131')
-- foggyicon:buttons(awful.util.table.join(
--                     awful.button({ }, 1, function (c)
--                         foggy.menu(s)
--                     end)
-- ))

-- Load Debian menu entries
require("archmenu")

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
                                            text = err })
                           in_error = false
  end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.init("~/.config/awesome/themes/current/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "terminal"
editor = "emacs" or "editor"
editor_cmd = terminal .. " -e " .. editor .. " -nw "

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
  {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    awful.layout.suit.spiral,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
  }
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
  for s = 1, screen.count() do
    gears.wallpaper.maximized(beautiful.wallpaper, s, true)
  end
end
-- }}}

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

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
  names  = {
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  },
  layout = {
    layouts[2],   -- 1:firefox
    layouts[2],  -- 2:emacs
    layouts[3],  -- 3:browsers
    layouts[7],  -- 4:thunderbird
    layouts[2],   -- 5:docs
    layouts[6],  -- 6:multimedia
    layouts[5],  -- 7:terminal
    layouts[5],   -- 8:chat
    layouts[5],  -- 9:facepalm
  }
}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
  { "&manual", terminal .. " -e man awesome" },
  { "&edit config", editor_cmd .. " " .. awesome.conffile },
  { "&restart", awesome.restart },
  { "&quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "&Arch", xdgmenu, beautiful.arch_icon },
                            { "a&wesome", myawesomemenu, beautiful.awesome_icon },
                            { "&gmrun", "gmrun"},
                            { "&terminal", terminal }
}
                       })

mylauncher = awful.widget.launcher({ image = beautiful.arch_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Define custom tasklist updater
function tasklistupdate(w, buttons, labelfunc, data, objects)
  w:reset()

  -- Main container
  local l = wibox.layout.fixed.horizontal()
  l:fill_space(true)

  -- Text widget for displaying the name of the focused client
  local activeclient = nil;

  -- The inactive icons container
  local inactiveclients = wibox.layout.fixed.horizontal()

  -- Loop through all clients
  for i, o in ipairs(objects) do
    -- Init widget cache
    local cache = data[o]

    -- Get client informaion
    local text, bg, bg_image, icon = labelfunc(o)
    
    -- If cache is defined, use cache
    if cache then
      icon = cache.icon
      label = cache.label
      background = cache.background
      
      -- Else start from scratch
    else
      -- Inactive icon widgets
      icon = wibox.widget.imagebox()
      background = wibox.widget.background()
      background:set_widget(icon)

      -- Active label widget
      label = wibox.widget.textbox()

      -- Cache widgets
      data[o] = {
        icon = icon,
        label = label,
        background = background
      }
      
      -- Make icon clickable
      icon:buttons(common.create_buttons(buttons, o))
      
      -- Use custom drawing method for drawing icons
      helpers:set_draw_method(icon)
    end

    -- Use a fallback for clients without icons
    local iconsrc = o.icon

    if iconsrc == nil or iconsrc == "" then
      iconsrc = "/usr/share/icons/Faba/symbolic/emblems/emblem-system-symbolic.svg"
    end

    -- Update background
    background:set_bg(bg)

    -- Update icon image
    icon:set_image(iconsrc)

    -- Always add the background and icon
    inactiveclients:add(background)
    
    -- If client is focused, add text and set as active client
    if bg == theme.tasklist_bg_focus then
      local labeltext = text

      -- Append (F) if client is floating
      if awful.client.floating.get(o) then
        labeltext = labeltext .. " (F)"
      end

      label:set_markup("   " .. labeltext .. "   ")
      
      activeclient = label
    end
  end
  
  -- Add the inactive clients as icons first
  l:add(inactiveclients)

  -- Then add the active client as a text widget
  if activeclient then
    l:add(activeclient)
  end
  
  -- Add the main container to the parent widget
  w:add(l)
end

-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
  awful.button({ }, 1, function(t) t:view_only() end),
  awful.button({ modkey }, 1, function(t)
      if client.focus then
        client.focus:move_to_tag(t)
      end
  end),
  awful.button({ }, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, function(t)
      if client.focus then
        client.focus:toggle_tag(t)
      end
  end),
  awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
  awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)

)
local tasklist_buttons = awful.util.table.join(
  awful.button({ }, 1, function (c)
      if c == client.focus then
        c.minimized = true
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
  awful.button({ }, 3, function ()
      if instance then
        instance:hide()
        instance = nil
      else
        instance = awful.menu.clients({
            theme = { width = 250 }
        })
      end
  end),
  awful.button({ }, 4, function ()
      awful.client.focus.byidx(1)
      if client.focus then client.focus:raise() end
  end),
  awful.button({ }, 5, function ()
      awful.client.focus.byidx(-1)
      if client.focus then client.focus:raise() end
end))


awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)
    
    -- Each screen has its own tag table.
    -- awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, tags.layout)
    tags[s] = awful.tag(tags.names, s, tags.layout)

    local separator = wibox.widget.imagebox()
    separator:set_image(beautiful.get().spr2px)

    local separatorbig = wibox.widget.imagebox()
    separatorbig:set_image(beautiful.get().spr5px)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                            awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                            awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    --s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons, nil, tasklistupdate)
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create a systray widget
    local mysystray = wibox.widget.systray()
    local mysystraymargin = wibox.layout.margin()
    mysystraymargin:set_margins(6)
    mysystraymargin:set_widget(mysystray)

    -- Create the wibox
    s.mywibox = awful.wibox({ position = "top", height = 32, screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(s.mytaglist)
    left_layout:add(s.mypromptbox)
    left_layout:add(separator)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    
    right_layout:add(mysystraymargin)
    -- right_layout:add(foggyicon)

    right_layout:add(mymail.icon)
    right_layout:add(mymail.text)

    right_layout:add(separator)
    right_layout:add(myvolume.icon)
    right_layout:add(myvolume.text)

    right_layout:add(separator)
    right_layout:add(mybrightness.icon)
    right_layout:add(mybrightness.text)

    if mybattery.hasbattery then
      right_layout:add(separator)
      right_layout:add(mybattery.icon)
      right_layout:add(mybattery.text)
    end
    
    if mywifi.haswifi then
      right_layout:add(separator)
      right_layout:add(mywifi.icon)
      right_layout:add(mywifi.text)
    end

    right_layout:add(separatorbig)
    right_layout:add(mytextclock)
    right_layout:add(s.mylayoutbox)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    
    layout:set_middle(s.mytasklist)
    
    layout:set_right(right_layout)

    s.mywibox:set_widget(layout)
end)
  -- }}}

  -- {{{ Mouse bindings
  root.buttons(awful.util.table.join(
                 awful.button({ }, 3, function () mymainmenu:toggle() end),
                 awful.button({ }, 4, awful.tag.viewnext),
                 awful.button({ }, 5, awful.tag.viewprev)
  ))
  -- }}}

  -- {{{ Key binding functions
  function raisevolume()
    awful.spawn("amixer set Master 9%+", false)

    helpers:delay(myvolume.update, 0.1)
  end

  function lowervolume()
    awful.spawn("amixer set Master 9%-", false)

    helpers:delay(myvolume.update, 0.1)
  end

  function mutevolume()
    awful.spawn("amixer -D pulse set Master 1+ toggle", false)

    helpers:delay(myvolume.update, 0.1)
  end

  function raisebrightness()
    awful.spawn("xbacklight -inc 5", false)
    helpers:delay(mybrightness.update, 0.3)
  end

  function lowerbrightness()
    awful.spawn("xbacklight -dec 5", false)
    helpers:delay(mybrightness.update, 0.3)
  end
  -- }}}

  -- {{{ Key bindings
  globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
      function ()
        awful.client.focus.byidx( 1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "k",
      function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
      function ()
        awful.client.focus.history.previous()
        if client.focus then
          client.focus:raise()
        end
    end),

    -- Multiple monitors
    awful.key({ modkey, "Control"   }, "Left",
      function()
        for i = 1, screen.count() do
          awful.tag.viewprev(i)
        end
    end ),

    awful.key({ modkey, "Control"   }, "Right",
      function()
        for i = 1, screen.count() do
          awful.tag.viewnext(i)
        end
    end ),


    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- System volume
    awful.key({                   }, "XF86AudioRaiseVolume", raisevolume),
    awful.key({                   }, "XF86AudioLowerVolume", lowervolume),
    awful.key({                   }, "XF86AudioMute", mutevolume),
    awful.key({                   }, "XF86MonBrightnessUp", raisebrightness),
    awful.key({                   }, "XF86MonBrightnessDown", lowerbrightness),
    awful.key({ modkey,           }, "F6", raisebrightness),
    awful.key({ modkey,           }, "F5", lowerbrightness),
    awful.key({                   }, "XF86TouchpadToggle", function () awful.spawn("/usr/local/bin/touchpad.sh", false) end),
    
    awful.key({ modkey, "Shift"   }, "Up", raisevolume),
    awful.key({ modkey, "Shift"   }, "Down", lowervolume),

    -- System power
    awful.key({ modkey, "Control"   }, "q", function () awful.spawn("gksudo poweroff", false) end),

    -- Prompt
    --awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen.index]:run() end),
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end),

    awful.key({ modkey }, "x",
      function ()
        awful.prompt.run({ prompt = "Run Lua code: " },
          mypromptbox[mouse.screen.index].widget,
          awful.util.eval, nil,
          awful.util.getdir("cache") .. "/history_eval")
    end),

    -- -- Foggy keys
    -- awful.key({ modkey, "Control" }, "p",      foggy.menu),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),
    awful.key({ modkey,           }, "F2", function () awful.spawn("gmrun") end),
    awful.key({ modkey,           }, "e", function () awful.spawn("emacs") end),
    awful.key({ modkey,           }, "b", function () awful.spawn("firefox --no-remote -P") end))

  clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
      function (c)
        -- The client currently has the input focus, so it cannot be
        -- minimized, since minimized clients can't have the focus.
        c.minimized = true
    end),
    awful.key({ modkey,           }, "m",
      function (c)
        c.maximized_horizontal = not c.maximized_horizontal
        c.maximized_vertical   = not c.maximized_vertical
    end)
  )

  -- Bind all key numbers to tags.
  -- Be careful: we use keycodes to make it works on any keyboard layout.
  -- This should map on the top row of your keyboard, usually 1 to 9.
  for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
                                       -- View tag only.
                                       awful.key({ modkey }, "#" .. i + 9,
                                         function ()
                                           local screen = awful.screen.focused()
                                           local tag = screen.tags[i]
                                           if tag then
                                             tag:view_only()
                                           end
                                       end),
                                       -- Toggle tag display.
                                       awful.key({ modkey, "Control" }, "#" .. i + 9,
                                         function ()
                                           local screen = awful.screen.focused()
                                           local tag = screen.tags[i]

                                           if tag then
                                             awful.tag.viewtoggle(tag)
                                           end
                                       end),
                                       -- Move client to tag.
                                       awful.key({ modkey, "Shift" }, "#" .. i + 9,
                                         function ()
                                           if client.focus then
                                             local tag = client.focus.screen.tags[i]
                                             if tag then
                                               client.focus:move_to_tag(tag)
                                             end
                                           end
                                       end),
                                       -- Toggle tag on focused client.
                                       awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                                         function ()
                                           if client.focus then
                                             local tag = client.focus.screen.tags[i]
                                             if tag then
                                               client.focus:toggle_tag(tag)
                                             end
                                           end
                                       end))
  end

  clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

  -- Set keys
  root.keys(globalkeys)
  -- }}}

  -- {{{ Rules
  -- Rules to apply to new clients (through the "manage" signal).
  awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen} },
    { rule = { class = "Firefox" },
      properties = { screen = 1, tag = tags.names[1] } },
    { rule = { class = "Emacs" },
      properties = { screen = 1, tag = tags.names[2] } },
    { rule = { class = "Uzbl" },
      properties = { screen = 1, tag = tags.names[3] } },
    { rule = { class = "Chromium" },
      properties = { screen = 1, tag = tags.names[3] } },
    { rule = { class = "Thunderbird" },
      properties = { screen = 1, tag = tags.names[4] } },
    { rule = { class = "Zathura" },
      properties = { screen = 1, tag = tags.names[5] } },
    { rule = { class = "Okular" },
      properties = { screen = 1, tag = tags.names[5] } },
    { rule = { class = "libreoffice-writer" },
      properties = { screen = 1, tag = tags.names[5] } },
    { rule = { class = "Vlc" },
      properties = { screen = 1, tag = tags.names[6] } },
    { rule = { class = "MPlayer" },
      properties = { screen = 1, tag = tags.names[6] } },
    { rule = { class = "Sonata" },
      properties = { screen = 1, tag = tags.names[6] } },
    { rule = { class = "cantata" },
      properties = { screen = 1, tag = tags.names[6] } },
    { rule = { class = "Terminal" },
      properties = { screen = 1, tag = tags.names[7] } },
    { rule = { class = "Terminator" },
      properties = { screen = 1, tag = tags.names[7] } },
    { rule = { class = "konsole" },
      properties = { screen = 1, tag = tags.names[7] } },
    { rule = { class = "Gnome-terminal" },
      properties = { screen = 1, tag = tags.names[7] } },
    { rule = { class = "OSD Lyrics" },
      properties = { floating = true } },
    { rule = { class = "Osdlyrics" },
      properties = { floating = true } },
    { rule = { class = "yakuake" },
      properties = { floating = true } },
    { rule = { class = "Franz" },
      properties = { screen = 1, tag = tags.names[8] } },
    { rule = { class = "Telegram" },
      properties = { screen = 1, tag = tags.names[8] } },
    { rule = { class = "Slack" },
      properties = { screen = 1, tag = tags.names[8] } },
    { rule = { class = "Pidgin" },
      properties = { screen = 1, tag = tags.names[8] } },
    { rule = { class = "Skype" },
      properties = { screen = 1, tag = tags.names[8] } },
    { rule = { class = "xpad" },
      properties = { screen = 1, tag = tags.names[9], floating = true, sticky = true } },
    { rule = { class = "Tasque" },
      properties = { screen = 1, tag = tags.names[9] } },
    -- Set Firefox to always map on tags.names number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = tags.names[2] } },
  }
  -- }}}

  -- {{{ Signals
  -- Signal function to execute when a new client appears.
  client.connect_signal("manage", function (c, startup)
                          -- Enable sloppy focus
                          c:connect_signal("mouse::enter", function(c)
                                             if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
                                             and awful.client.focus.filter(c) then
                                               client.focus = c
                                             end
                          end)

                          if not startup then
                            -- Set the windows at the slave,
                            -- i.e. put it at the end of others instead of setting it master.
                            -- awful.client.setslave(c)

                            -- Put windows in a smart way, only if they does not set an initial position.
                            if not c.size_hints.user_position and not c.size_hints.program_position then
                              awful.placement.no_overlap(c)
                              awful.placement.no_offscreen(c)
                            end
                          end

                          local titlebars_enabled = false
                          if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
                            -- buttons for the titlebar
                            local buttons = awful.util.table.join(
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

                            -- Widgets that are aligned to the left
                            local left_layout = wibox.layout.fixed.horizontal()
                            left_layout:add(awful.titlebar.widget.iconwidget(c))
                            left_layout:buttons(buttons)

                            -- Widgets that are aligned to the right
                            local right_layout = wibox.layout.fixed.horizontal()
                            right_layout:add(awful.titlebar.widget.floatingbutton(c))
                            right_layout:add(awful.titlebar.widget.maximizedbutton(c))
                            right_layout:add(awful.titlebar.widget.stickybutton(c))
                            right_layout:add(awful.titlebar.widget.ontopbutton(c))
                            right_layout:add(awful.titlebar.widget.closebutton(c))

                            -- The title goes in the middle
                            local middle_layout = wibox.layout.flex.horizontal()
                            local title = awful.titlebar.widget.titlewidget(c)
                            title:set_align("center")
                            middle_layout:add(title)
                            middle_layout:buttons(buttons)

                            -- Now bring it all together
                            local layout = wibox.layout.align.horizontal()
                            layout:set_left(left_layout)
                            layout:set_right(right_layout)
                            layout:set_middle(middle_layout)

                            awful.titlebar(c):set_widget(layout)
                          end
  end)

  client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
  client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
  -- }}}

  -- {{{ Autorun apps
  awful.spawn("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1", false)
  awful.spawn("nm-applet --sm-disable", false)
  --awful.spawn("compton", false)
  -- awful.spawn("compton -c -r8 -l-12 -t-8  -b  -G  -f -D30 -I0.45 -O0.45 -o0.0 --unredir-if-possible  --backend glx --glx-no-stencil --glx-no-rebind-pixmap", false)
  -- awful.spawn("emc", false)
  -- awful.spawn("emacs", false)
  awful.spawn("albert", false)
  awful.spawn("emacsclient -a '' -c", false)
  awful.spawn("dropbox start", false)
  awful.spawn("telegram", false)
  awful.spawn("xpad", false)
  awful.spawn("indicator-kdeconnect", false)
  awful.spawn("konsole", false)
  awful.spawn("compton -c -r8 -l-12 -t-8  -b  -G  -f -D30 -I0.45 -O0.45 -o0.0 --unredir-if-possible  --backend glx --glx-no-stencil --glx-no-rebind-pixmap")
  -- }}}
