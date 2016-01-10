local helpers = {}

function helpers:set_draw_method(imagebox, setx, sety, setwidth, setheight)
    function imagebox:draw(wibox, cr)
        if not self._image then return end

        cr:save()

        local width = setwidth or 16
        local height = setheight or 16
        local offset_x = setx or 9
        local offset_y = sety or 9

        local w = self._image:get_width()
        local h = self._image:get_height()
        local aspect = width / w
        local aspect_h = height / h
        if aspect > aspect_h then aspect = aspect_h end

        cr:scale(aspect, aspect)
        cr:set_source_surface(self._image, offset_x, offset_y)
        cr:paint()

        cr:restore()
    end
end

function helpers:delay(func, time)
    local timer = timer({timeout = time or 0})

    timer:connect_signal("timeout", function()
        func()
        timer:stop()
    end)

    timer:start()
end

function helpers:listen(widget, interval)
    widget:update()

    -- Timer
    local timer = timer({timeout = interval or 30})

    timer:connect_signal("timeout", function()
        widget:update()
    end)

    timer:start()
end

function helpers:test(cmd)
    local test = io.popen(cmd)
    local result = test:read() ~= nil

    test:close()

    return result
end

return helpers
