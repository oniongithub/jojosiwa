local screen_size = EngineClient.GetScreenSize()
local local_player = EntityList.GetLocalPlayer()
local global = {} global.__index = {}
local hud = {} hud.__index = {} hud.controls = {}
global.color = Color.RGBA(255, 159, 159)
global.color_picker = Menu.ColorEdit("Windows", "Highlight Color", global.color)

--[[
    Math Additions
--]]

function math.clamp(value, min, max)
    if (max) then if (value > max) then value = max end end
    if (min) then if (value < min) then value = min end end

    return value
end

function math.round(number, decimals)
	local power = 10^decimals
	return math.floor(number * power) / power
end

function math.time_to_ticks(time)
    return math.floor(time / GlobalVars.interval_per_tick + .5)
end

function math.get_circumference_point(radius, angle, radian)
    if (radius and angle) then
        if (not radian) then angle = angle * (math.pi / 180) end

        return Vector2.new(radius * math.cos(angle), radius * math.sin(angle))
    end

    return Vector2.new(0, 0)
end

-- adapted from https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
function math.hue_to_rgb(p, q, t)
    if t < 0   then t = t + 1 end
    if t > 1   then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
end

function math.hsb_to_rgb(h, s, l)
    local r, g, b
    s, l = s / 100, l / 100

    if (s == 0) then
        r, g, b = l, l, l
    else
        local q, p
        if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end

        p = 2 * l - q

        r = math.hue_to_rgb(p, q, h + 1/3)
        g = math.hue_to_rgb(p, q, h)
        b = math.hue_to_rgb(p, q, h - 1/3)
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

function math.num2num(number_1, number_2, percent)
    return math.clamp(number_1 + (number_2 - number_1) * percent, 0, 255)
end

--[[
    Input Library
--]]

local input = {} input.__index = {}

input.is_point_in_circle = function(point, radius, point_in)
    if (not point_in) then point_in = Cheat.GetMousePos() end
    local distance = math.sqrt((point.x - point_in.x)^2 + (point.y - point_in.y)^2)

    if (distance <= radius) then
        return true
    end

    return false
end

input.is_point_in_rectangle = function(pos, size, radius, point_in)
    local function check_bounds(pos, size, point)
        if (point.x >= pos.x and point.x <= pos.x + size.x) then
            if (point.y >= pos.y and point.y <= pos.y + size.y) then
                return true
            end
        end

        return false
    end

    if (not point_in) then point_in = Cheat.GetMousePos() end
    if (not radius or radius == 0) then return check_bounds(pos, size, point_in) end

    local points = {
        corners = {
            vec2_t(pos.x + radius, pos.y + radius), -- top left
            vec2_t(pos.x + size.x - radius, pos.y + radius), -- top right
            vec2_t(pos.x + radius, pos.y + size.y - radius), -- bottom left
            vec2_t(pos.x + size.x - radius, pos.y + size.y - radius), -- bottom right
        },
        body = {
            {
                pos = vec2_t(pos.x, pos.y + radius),
                size = vec2_t(size.x, size.y - radius * 2)
            },
            {
                pos = vec2_t(pos.x + radius, pos.y),
                size = vec2_t(size.x - radius * 2, size.y)
            }
        }
    }

    local in_bounds = false

    for i = 1, #points.corners do
        if (not in_bounds and input.is_point_in_circle(points.corners[i], radius, point_in)) then
            in_bounds = true
        end
    end

    if (not in_bounds) then
        if (check_bounds(points.body[1].pos, points.body[1].size, point_in) or check_bounds(points.body[2].pos, points.body[2].size, point_in)) then
            in_bounds = true
        end
    end

    return in_bounds
end

input.is_key_held = Cheat.IsKeyDown

input.key_presses = {}
input.is_key_pressed = function(key)
    local contains = function(key)
        for i = 1, #input.key_presses do
            if (input.key_presses[i][1] == key) then return input.key_presses[i] end
        end
    end

    local contained_key = contains(key)
    if (contained_key) then 
        return contained_key[2]
    else
        table.insert(input.key_presses, { key, false, false })
    end
end

input.run_key_presses = function()
    for i = 1, #input.key_presses do
        if (Cheat.IsKeyDown(input.key_presses[i][1])) then
            if (input.key_presses[i][2] == false and input.key_presses[i][3] == false) then
                input.key_presses[i][2] = true
            elseif (input.key_presses[i][2] == true) then
                input.key_presses[i][2], input.key_presses[i][3] = false, true
            end
        else
            input.key_presses[i][2], input.key_presses[i][3] = false, false
        end
    end
end

--[[
    Time Library
--]]

local unix_time = {} unix_time.__index = {}
unix_time.offset = Panorama.LoadString('return new Date().getTimezoneOffset();')() * 60000
unix_time.months = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

unix_time.get = function()
    local timestamp = Utils.UnixTime() - unix_time.offset;

    local global = { seconds = timestamp, 
        minutes = timestamp / 60000,  hours = timestamp / 3600000,  
        days = timestamp / 86400000, years = timestamp / 31556926080,
    }

    local time = {
        seconds = math.floor((global.minutes - math.floor(global.minutes)) * 60),
        minutes = math.floor((global.hours - math.floor(global.hours)) * 60),
        hours = math.floor((global.days - math.floor(global.days)) * 24),
        days = math.floor((global.years - math.floor(global.years)) * 365),
        day = 0, months = 0, years = 1970 + math.floor(global.years),
    }

    time.pm = math.clamp(math.floor(time.hours / 12), 0, 1) == 1
    time.hours_12 = time.hours - (12 * math.clamp(math.floor(time.hours / 12), 0, 1))

    local days_added = 0;
    for i = 1, #unix_time.months do
        if (days_added + unix_time.months[i] > time.days) then
            time.day = time.days - days_added
            time.months = i;
            goto break_loop;
        else
            days_added = days_added + unix_time.months[i];
        end
    end
    ::break_loop::

    return time
end

--[[
    Primordial Translation
--]]

local render, menu = {}, {} render.__index, menu.__index = {}, {}

menu.is_open = Cheat.IsMenuVisible

local vec2_t, vec3_t, color_t = Vector2.new, Vector.new, Color.RGBA

render.text = function(font, text, pos, color, size)
    Render.Text(text, pos, color, size, font)
end

render.get_text_size = function(font, text, size)
    return Render.CalcTextSize(text, size, font)
end

render.rect_filled = function(pos, size, ...)
    Render.BoxFilled(pos, pos + size, ...)
end

function render.circle_3d(pos, col, radius, angle, segments, percent)
    if (pos) then
        local step, last_pos = (360 * (percent / 100)) / segments

        for i = 1, 361 * (percent / 100), step do
            if (i > 360) then i = 360 end

            local point = math.get_circumference_point(radius, angle + i, false)
            local point_2d = Render.WorldToScreen(vec3_t(pos.x + point.x, pos.y + point.y, pos.z))
            if (point_2d ~= nil) then
                if (last_pos) then
                    Render.Line(last_pos, point_2d, Color.new(col.r, col.g, col.b, math.clamp(col.a - ((col.a / segments) * (i / step)), 0, 1)))
                end

                last_pos = point_2d
            end
        end
    end
end

function render.spiral_3d(pos, col, angle, additive, segments, strings, percent)
    local add, spiral_add = 0, 360 / strings

    if (pos) then
        local step, last_pos = (360 * (percent / 100)) / segments

        for f = 1, strings do
            last_pos, add = nil, 0

            for i = 1, 361 * (percent / 100), step do
                if (i > 360) then i = 360 end

                local point = math.get_circumference_point(add, (spiral_add * f) + angle + i, false)
                local point_2d = Render.WorldToScreen(vec3_t(pos.x + point.x, pos.y + point.y, pos.z))

                add = add + additive

                if (point_2d) then
                    if (last_pos) then
                        Render.Line(last_pos, point_2d, Color.new(col.r, col.g, col.b, math.clamp(col.a - ((col.a / segments) * (i / step)), 0, 1)))
                    end

                    last_pos = point_2d
                end
            end
        end
    end
end

function render.poly_circle(pos, col, radius, thickness, segments)
    if (pos) then
        local step, last_pos_1, last_pos_2, first_1, first_2 = 360 / segments

        for i = 1, 361, step do
            local angle = i
            if (i > 360) then angle = 0 end

            local point_1 = math.get_circumference_point(radius, i, false)
            local point_2 = math.get_circumference_point(radius + thickness, i, false)

            local point_2d_1 = Render.WorldToScreen(vec3_t(pos.x + point_1.x, pos.y + point_1.y, pos.z))
            local point_2d_2 = Render.WorldToScreen(vec3_t(pos.x + point_2.x, pos.y + point_2.y, pos.z))

            if (point_2d_1 ~= nil and point_2d_2 ~= nil) then
                if (last_pos_1 and last_pos_2) then
                    Render.PolyFilled(col, point_2d_1, point_2d_2, last_pos_2, last_pos_1, point_2d_1)
                end

                last_pos_1, last_pos_2 = point_2d_1, point_2d_2
            end
        end
    end
end

--[[
    Notifications Library
--]]

local notification = {} notification.__index = notification notification.list = {}
notification.font = Render.InitFont("Segoe UI", 15) notification.box_render = Render.BoxFilled

notification.controls = {
    enabled = Menu.Switch("Windows", "Notifications Toggle", true),
}

function notification.add(name, description, time)
    table.insert(notification.list, { name = name, description = description, time = time, start = Utils.UnixTime() })
end

function notification.run()
    local current_time, used_space = Utils.UnixTime(), Vector2.new(0, 0)

    for i = #notification.list, 1, -1 do
        if (Utils.UnixTime() - notification.list[i].start >= notification.list[i].time) then
            table.remove(notification.list, i)
        end
    end

    if (notification.controls.enabled:Get()) then
        for i = 1, (#notification.list <= 8) and #notification.list or 8 do
            local text_size, text_size_2 = Render.CalcTextSize(notification.list[i].name, 15, notification.font), Render.CalcTextSize(notification.list[i].description, 15, notification.font)
            local total_width = text_size.x + text_size_2.x + 61
            local percent = (Utils.UnixTime() - notification.list[i].start) / notification.list[i].time
            total_width = total_width * (percent^4)

            Render.Blur(Vector2.new(8 - total_width, 8 + used_space.y), Vector2.new(text_size.x + 16 - total_width + text_size_2.x + 20, 16 + used_space.y + text_size.y), Color.new(1, 1, 1), (text_size.y) / 2)

            render.rect_filled(Vector2.new(8 - total_width, 8 + used_space.y), Vector2.new(text_size.x + 20 - ((text_size.y) / 2), 8 + text_size.y), Color.RGBA(25, 25, 25, 255), (text_size.y) / 2)
            render.rect_filled(Vector2.new(8 - total_width + (text_size.x + 20 - ((text_size.y) / 2) * 2), 8 + used_space.y), Vector2.new(text_size.y / 4 * 3, 8 + text_size.y), Color.RGBA(25, 25, 25, 255))
            render.rect_filled(Vector2.new(text_size.x + 16 - total_width, 8 + used_space.y), Vector2.new(text_size_2.x + 20, 8 + text_size.y), Color.RGBA(25, 25, 25, 125), (text_size.y) / 2)
            render.rect_filled(Vector2.new(24 - total_width + text_size.x, 8 + used_space.y), Vector2.new(1, 8 + text_size.y), global.color, 0)

            Render.Text(notification.list[i].name, Vector2.new(16 - total_width, 12 + used_space.y), Color.RGBA(225, 225, 225), 15, notification.font)
            Render.Text(notification.list[i].description, Vector2.new(29 + text_size.x - total_width, 12 + used_space.y), Color.RGBA(225, 225, 225), 15, notification.font)
            
            used_space.y = used_space.y + text_size.y + 12
        end
    end
end

--[[
    Window Library
--]]

local window = {} window.__index = {} window.window_list = {}

window.fonts = {
    segoe_ui_15 = Render.InitFont("Segoe UI", 15),
    segoe_ui_18 = Render.InitFont("Segoe UI", 18),
}

window.flags = {
    FL_NODRAW = 1, FL_NOMOVE = 2, FL_NOTITLE = 3, FL_RESIZE_H = 4, FL_RESIZE_V = 5,
}

function window.add_window(size, name, control, ...)
    if (not size) then return end

    local flag_table = {...}

    local function contains(tbl, value)
        for i = 1, #tbl do
            if (tbl[i] == value) then return true end
        end
        
        return false
    end

    local x, y = Menu.SliderInt("Settings", name .. " - X", 0, 0, screen_size.x), Menu.SliderInt("Settings", name .. " - Y", 0, 0, screen_size.y)
    local w, h = Menu.SliderInt("Settings", name .. " - W", 0, 0, screen_size.x), Menu.SliderInt("Settings", name .. " - H", 0, 0, screen_size.y)

    table.insert(window.window_list, {name = name, pos = vec2_t(0, 0), control = control, size = size, x_control = x, y_control = y, w_control = w, h_control = h, disabled = false, tab_height = 0, flags = { 
                                      FL_NODRAW = contains(flag_table, window.flags.FL_NODRAW),
                                      FL_NOMOVE = contains(flag_table, window.flags.FL_NOMOVE),
                                      FL_NOTITLE = contains(flag_table, window.flags.FL_NOTITLE),
                                      FL_RESIZE_H = contains(flag_table, window.flags.FL_RESIZE_H),
                                      FL_RESIZE_V = contains(flag_table, window.flags.FL_RESIZE_V),
                                    }, input = { dragging = false, resizing = false, mouse_pos }, draw_fn})

    return #window.window_list
end

function window.remove_window(index) -- returning created window index to vars and I don't wanna update all vars index for every removed window
    if (#window.window_list >= index) then
        window.window_list[index].disabled = true
    end
end

function window.run_movement(index)
    local mouse_pos = Cheat.GetMousePos()

    if (menu.is_open()) then
        if (window.window_list[index].flags.FL_RESIZE_H and input.is_point_in_rectangle(vec2_t(window.window_list[index].pos.x + window.window_list[index].size.x - 10, window.window_list[index].pos.y), vec2_t(20, window.window_list[index].size.y))) then
            if (input.is_key_pressed(0x01)) then
                window.window_list[index].input.resizing = true
                window.window_list[index].input.mouse_pos = vec2_t(mouse_pos.x - window.window_list[index].pos.x, mouse_pos.y - window.window_list[index].pos.y)

                return true
            end
        elseif (window.window_list[index].flags.FL_RESIZE_V and input.is_point_in_rectangle(vec2_t(window.window_list[index].pos.x, window.window_list[index].pos.y + window.window_list[index].size.y - 10), vec2_t(window.window_list[index].size.x, 20))) then
            if (input.is_key_pressed(0x01)) then
                window.window_list[index].input.resizing = true
                window.window_list[index].input.mouse_pos = vec2_t(mouse_pos.x - window.window_list[index].pos.x, mouse_pos.y - window.window_list[index].pos.y)

                return true
            end
        elseif (not window.window_list[index].flags.FL_NOMOVE and input.is_point_in_rectangle(window.window_list[index].pos, window.window_list[index].size)) then
            if (input.is_key_pressed(0x01)) then
                window.window_list[index].input.dragging = true
                window.window_list[index].input.mouse_pos = vec2_t(mouse_pos.x - window.window_list[index].pos.x, mouse_pos.y - window.window_list[index].pos.y)

                return true
            end
        end
    end

    if (input.is_key_held(0x01) and menu.is_open()) then
        if (window.window_list[index].input.resizing) then
            local x, y = math.clamp(mouse_pos.x - window.window_list[index].pos.x, 0, screen_size.x), math.clamp(mouse_pos.y - window.window_list[index].pos.y, 0, screen_size.y)
            
            if (window.window_list[index].flags.FL_RESIZE_H) then
                window.window_list[index].size = vec2_t(x, window.window_list[index].size.y)
                window.window_list[index].w_control:Set(x)
            end

            if (window.window_list[index].flags.FL_RESIZE_V) then
                window.window_list[index].size = vec2_t(window.window_list[index].size.x, y)
                window.window_list[index].h_control:Set(y)
            end
        elseif (window.window_list[index].input.dragging) then
            local x, y = math.clamp(mouse_pos.x - window.window_list[index].input.mouse_pos.x, 0, screen_size.x - window.window_list[index].size.x), math.clamp(mouse_pos.y - window.window_list[index].input.mouse_pos.y, 0, screen_size.y - window.window_list[index].size.y)
            window.window_list[index].pos = vec2_t(x, y)
            window.window_list[index].x_control:Set(x)
            window.window_list[index].y_control:Set(y)
        end
    else
        window.window_list[index].input.dragging = false
        window.window_list[index].input.resizing = false
    end

    return false -- so we can return true and make movement only run on a single window
end

function window.run_paint(index)
    Render.Blur(window.window_list[index].pos, window.window_list[index].pos + window.window_list[index].size, color_t(255, 255, 255, 255), 6)
    render.rect_filled(window.window_list[index].pos, window.window_list[index].size, color_t(25, 25, 25, 125), 6)

    if (not window.window_list[index].flags.FL_NOTITLE) then
        local text_size = render.get_text_size(window.fonts.segoe_ui_18, window.window_list[index].name, 18)
        window.window_list[index].tab_height = text_size.y + 17
        render.rect_filled(window.window_list[index].pos, vec2_t(window.window_list[index].size.x, 8 + text_size.y), color_t(25, 25, 25, 255), 6)
        render.rect_filled(vec2_t(window.window_list[index].pos.x, window.window_list[index].pos.y + 6), vec2_t(window.window_list[index].size.x, 2 + text_size.y), color_t(25, 25, 25, 255), 0)
        render.rect_filled(vec2_t(window.window_list[index].pos.x, window.window_list[index].pos.y + 8 + text_size.y), vec2_t(window.window_list[index].size.x, 1), global.color, 0)
        render.text(window.fonts.segoe_ui_18, window.window_list[index].name, vec2_t(window.window_list[index].pos.x + (window.window_list[index].size.x / 2) - (text_size.x / 2), window.window_list[index].pos.y + 4), color_t(225, 225, 225), 18)
    else
        window.window_list[index].tab_height = 0
    end

    if (window.window_list[index].draw_fn) then
        window.window_list[index].draw_fn()
    end
end

window.init = false
function window.run_windows()
    local skip_move = false

    for i = 1, #window.window_list do
        if (window.window_list[i].control) then
            if (not hud.controls.windows:Get(window.window_list[i].control)) then goto hop_that_shit end
        end
        
        if (not window.window_list[i].disabled) then
            if (not window.window_list[i].flags.FL_NODRAW and not skip_move) then
                skip_move = window.run_movement(i)
            end

            if (not window.window_list[i].flags.FL_NODRAW) then
                window.run_paint(i)
            end
        end

        ::hop_that_shit::
    end

    if (not window.init) then
        window.init = true

        for i = 1, #window.window_list do
            window.window_list[i].pos = vec2_t(window.window_list[i].x_control:Get(), window.window_list[i].y_control:Get())
            if (window.window_list[i].w_control:Get() ~= 0) then
                window.window_list[i].size = vec2_t(window.window_list[i].w_control:Get(), window.window_list[i].size.y)
            end

            if (window.window_list[i].h_control:Get() ~= 0) then
                window.window_list[i].size = vec2_t(window.window_list[i].size.x, window.window_list[i].h_control:Get())
            end

            window.window_list[i].x_control:SetVisible(false)
            window.window_list[i].y_control:SetVisible(false)
            window.window_list[i].w_control:SetVisible(false)
            window.window_list[i].h_control:SetVisible(false)
        end
    end
end

function window.add_bar(used_space, name, index, percent, col)
    local color = global.color if (col) then color = col end
    local text_size = render.get_text_size(window.fonts.segoe_ui_15, name, 15)
    render.text(window.fonts.segoe_ui_15, name, vec2_t(window.window_list[index].pos.x + 8, window.window_list[index].pos.y + used_space.y + window.window_list[index].tab_height), color_t(225, 225, 225), 15)

    local bar_width = math.clamp((window.window_list[index].size.x - 16) * percent, 10, window.window_list[index].size.x - 16)

    render.rect_filled(vec2_t(window.window_list[index].pos.x + 8, used_space.y + window.window_list[index].pos.y + window.window_list[index].tab_height + 4 + text_size.y), vec2_t(window.window_list[index].size.x - 16, 10), color_t(25, 25, 25, 255), 5)
    
    if (percent > 0) then
        render.rect_filled(vec2_t(window.window_list[index].pos.x + 8, used_space.y + window.window_list[index].pos.y + window.window_list[index].tab_height + 4 + text_size.y), vec2_t(bar_width, 10), color, 5)
    end

    return text_size.y + 22
end

--[[
    Windows
--]]

hud.controls = {
    watermark = 1, keybinds = 2, spectator = 3, step_counter = 4, information = 5,
    windows = Menu.MultiCombo("Windows", "Elements", { "Watermark", "Keybind", "Spectators", "Step Counter", "Information" }, 0),
}

-- Watermark Window
local watermark = {
    window = window.add_window(vec2_t(150, 150), "Watermark", hud.controls.watermark, window.flags.FL_NOTITLE, window.flags.FL_NOMOVE),
    fps = 0, current_fps = 0, max_fps = 0, fps_time = Utils.UnixTime()
}

window.window_list[watermark.window].draw_fn = function()
    if (Utils.UnixTime() - watermark.fps_time >= 250) then
        watermark.current_fps, watermark.fps = watermark.fps * 4, 0
        watermark.fps_time = Utils.UnixTime()

        if (watermark.current_fps > watermark.max_fps) then watermark.max_fps = watermark.current_fps end
    else
        watermark.fps = watermark.fps + 1
    end

    local function watermark_add(text)
        if (text == "") then return "" else return " | " end
    end

    local unix = unix_time.get() local netChannelInfo = EngineClient.GetNetChannelInfo()
    local latency = ((EngineClient.IsInGame() == true) and (" | " .. tostring(math.floor(netChannelInfo:GetLatency(0) * 1000)) .. "ms") or (""))
    local time = " | " .. unix.hours_12 .. ":" .. ((unix.minutes > 9) and unix.minutes or ("0" .. unix.minutes)) .. ":" .. ((unix.seconds > 9) and unix.seconds or ("0" .. unix.seconds)) .. (unix.pm and " PM" or " AM")
    local watermark_text = "neverlose | " .. Cheat.GetCheatUserName() .. latency .. " | " .. tostring(watermark.current_fps) .. " fps" .. time

    local text_size = render.get_text_size(window.fonts.segoe_ui_15, watermark_text, 15)

    window.window_list[watermark.window].flags.FL_NOMOVE = true
    window.window_list[watermark.window].pos = vec2_t(screen_size.x - window.window_list[watermark.window].size.x - 8, 8)
    window.window_list[watermark.window].size = vec2_t(16 + text_size.x, 12 + text_size.y)

    render.text(window.fonts.segoe_ui_15, watermark_text, vec2_t(window.window_list[watermark.window].pos.x + 8, window.window_list[watermark.window].pos.y + 4), color_t(225, 225, 225), 15)
end

-- Keybind Window
local keybind = {
    window = window.add_window(vec2_t(150, 150), "Keybinds", hud.controls.keybinds, window.flags.FL_RESIZE_H),
}

window.window_list[keybind.window].draw_fn = function()
    local used_space = vec2_t(0, 0)

    local binds = Cheat.GetBinds()

    for i = 1, #binds do
        local name, active = binds[i]:GetName(), binds[i]:IsActive()

        if (active) then
            local text_size = render.get_text_size(window.fonts.segoe_ui_15, name, 15)
            local text_pos = vec2_t(window.window_list[keybind.window].pos.x + 8, 2 + window.window_list[keybind.window].pos.y + window.window_list[keybind.window].tab_height + used_space.y)

            render.text(window.fonts.segoe_ui_15, name, text_pos, color_t(225, 225, 225), 15)

            used_space = vec2_t(used_space.x, used_space.y + text_size.y + 8)
        end
    end

    window.window_list[keybind.window].size = vec2_t(window.window_list[keybind.window].size.x, window.window_list[keybind.window].tab_height + used_space.y + 8)
end

-- Spectator List Window
local spectator = {
    window = window.add_window(vec2_t(150, 200), "Spectators", hud.controls.spectator, window.flags.FL_RESIZE_H),
}

window.window_list[spectator.window].draw_fn = function()
    local cur_entity = EntityList.GetLocalPlayer()
    local spectators = {}

    if (cur_entity) then
        local player_tbl = EntityList.GetEntitiesByName("CCSPlayer")
        for i, ply in pairs(player_tbl) do
            if (ply and ply ~= cur_entity and ply:IsPlayer() and not ply:GetPlayer():IsAlive() and not ply:GetPlayer():IsDormant()) then
                local name = ply:GetPlayer():GetName()
                local target = EntityList.GetClientEntityFromHandle(ply:GetProp("m_hObserverTarget"))

                if (target and target:IsPlayer()) then
                    local target_index, local_index = target:EntIndex(), cur_entity:EntIndex()

                    if (cur_entity:IsPlayer() and cur_entity:GetPlayer():IsAlive() and local_index == target_index) then
                        table.insert(spectators, name)
                    end

                    ::skip::
                end
            end
        end
    end

    local used_space = vec2_t(0, 0)

    for i = 1, #spectators do
        local text_size = render.get_text_size(window.fonts.segoe_ui_15, spectators[i], 15)
        local text_pos = vec2_t(window.window_list[spectator.window].pos.x + 8, 2 + window.window_list[spectator.window].pos.y + window.window_list[spectator.window].tab_height + used_space.y)

        render.text(window.fonts.segoe_ui_15, spectators[i], text_pos, color_t(225, 225, 225), 15)

        used_space = vec2_t(used_space.x, used_space.y + text_size.y + 8)
    end

    window.window_list[spectator.window].size = vec2_t(window.window_list[spectator.window].size.x, window.window_list[spectator.window].tab_height + used_space.y + 8)
end

-- Step Counter Window
local step_counter = {
    window = window.add_window(vec2_t(150, 125), "Step Counter", hud.controls.step_counter, window.flags.FL_RESIZE_H),
    steps = 0
}

hud.steps = { count = 0 }
window.window_list[step_counter.window].draw_fn = function()
    local used_space = vec2_t(0, 0)

    if (local_player and local_player:IsPlayer()) then
        local text_size = render.get_text_size(window.fonts.segoe_ui_15, tostring(step_counter.steps), 15)
        render.text(window.fonts.segoe_ui_15, tostring(step_counter.steps), vec2_t(window.window_list[step_counter.window].pos.x + window.window_list[step_counter.window].size.x / 2 - text_size.x / 2, window.window_list[step_counter.window].pos.y + window.window_list[step_counter.window].tab_height + text_size.y / 4), color_t(225, 225, 225), 15)

        used_space.y = used_space.y + text_size.y + 8
    else
        step_counter.steps = 0
    end

    window.window_list[step_counter.window].size.y = window.window_list[step_counter.window].tab_height + 8 + used_space.y
end

Cheat.RegisterCallback("events", function(ctx)
    if (ctx:GetName() ~= "player_footstep") then return end

    local user_id = ctx:GetInt("userid")
    local ent = EntityList.GetPlayerForUserID(user_id)

    if (ent and ent:IsPlayer() and ent:IsAlive() and ent == local_player) then
        step_counter.steps = step_counter.steps + 1
    end
end)

-- Information Window fps = 0, current_fps = 0, max_fps = 0, fps_time = Utils.UnixTime()
local information = { 
    window = window.add_window(vec2_t(150, 150), "Information", hud.controls.information, window.flags.FL_RESIZE_H),
}

window.window_list[information.window].draw_fn = function()
    local used_space = vec2_t(0, 0)
    
    used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Tickbase Charge", information.window, Exploits.GetCharge()))
    used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Desync", information.window, math.abs(AntiAim.GetCurrentRealRotation() - AntiAim.GetFakeRotation()) / AntiAim.GetMaxDesyncDelta()))
    used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Fakelag", information.window, ClientState.m_choked_commands / 16))
    used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "FPS", information.window, watermark.current_fps / watermark.max_fps))

    window.window_list[information.window].size = vec2_t(window.window_list[information.window].size.x, window.window_list[information.window].tab_height + used_space.y + 8)
end

--[[
    Auto-Peek
--]]

local auto_peek = {} auto_peek.__index = auto_peek
auto_peek.location = Vector.new(0, 0, 0)
auto_peek.reference = Menu.FindVar("Miscellaneous", "Main", "Movement", "Auto Peek")
auto_peek.time = Utils.UnixTime() auto_peek.controls = {
    control = Menu.Combo("Auto Peek", "Type", { "None", "Circle", "Spiral", "Primordial" }, 0),
    speed = Menu.SliderInt("Auto Peek", "Speed", 1000, 50, 2500),
    angle = Menu.SliderInt("Auto Peek", "Angle", 35, 1, 100),
    radius = Menu.SliderInt("Auto Peek", "Radius", 35, 1, 100),
    custom_color = Menu.Switch("Auto Peek", "Custom Color", true),
    color = Menu.ColorEdit("Auto Peek", "Peek Color", Color.new(1, 1, 1)),
}
auto_peek.anim_time, auto_peek.anim_step = Utils.UnixTime(), 0

auto_peek.reference:RegisterCallback(function(value)
    auto_peek.anim_time, auto_peek.anim_step = Utils.UnixTime(), 0

    if (value) then
        if (local_player and local_player:IsAlive()) then
            local origin = local_player:GetRenderOrigin()
            auto_peek.location = Vector.new(origin.x, origin.y, origin.z)
        else
            auto_peek.location = Vector.new(0, 0, 0)
        end
    end
end)

function auto_peek.run_paint()
    local color = auto_peek.controls.custom_color:Get() and auto_peek.controls.color:Get() or global.color
    local type = auto_peek.controls.control:Get()
    if (auto_peek.reference:Get() and type ~= 0) then
        if (type == 1) then
            render.circle_3d(auto_peek.location, color, 50 * (auto_peek.controls.radius:Get() / 100), 360 * ((auto_peek.time - Utils.UnixTime()) / (auto_peek.controls.speed:Get())), 72, auto_peek.controls.angle:Get())
        elseif (type == 2) then
            render.spiral_3d(auto_peek.location, color, 360 * ((auto_peek.time - Utils.UnixTime()) / (auto_peek.controls.speed:Get())), 2 * (auto_peek.controls.radius:Get() / 100), 72, 3, auto_peek.controls.angle:Get())
        else
            local speed = 2500 - auto_peek.controls.speed:Get()
            if (Utils.UnixTime() - auto_peek.anim_time >= speed) then auto_peek.anim_time = Utils.UnixTime() auto_peek.anim_step = auto_peek.anim_step == 1 and 0 or 1 end
            local percent = math.clamp((Utils.UnixTime() - auto_peek.anim_time) / speed, 0, 1)
            percent = percent * (percent^4)

            render.poly_circle(auto_peek.location, Color.new(color.r, color.g, color.b, color.a / 5 * 4), 20, 6, 8)

            if (auto_peek.anim_step == 1) then
                render.poly_circle(auto_peek.location, Color.new(color.r, color.g, color.b, (color.a / 5 * 3) * (1 - percent)), 30 + 10 * percent, 2, 8)
                render.poly_circle(auto_peek.location, Color.new(color.r, color.g, color.b, (color.a / 5 * 3) * (1 - percent)), 35 + 10 * percent, 2, 8)
            else
                render.poly_circle(auto_peek.location, Color.new(color.r, color.g, color.b, (color.a / 5 * 3) * percent), 20 + 10 * percent, 2, 8)
                render.poly_circle(auto_peek.location, Color.new(color.r, color.g, color.b, (color.a / 5 * 3) * percent), 20 + 15 * percent, 2, 8)
            end
        end
    end
end

--[[
    Color Animation
--]]

local rainbow = {
    control = Menu.Combo("Colors", "Animation Type", { "None", "Rainbow", "Custom" }, 0),
    color_1 = Menu.ColorEdit("Colors", "Custom Color 1", Color.new(1, 1, 1)),
    color_2 = Menu.ColorEdit("Colors", "Custom Color 2", Color.new(1, 1, 1)),
    speed = Menu.SliderInt("Colors", "Speed", 25, 0, 100),
    saturation = Menu.SliderInt("Colors", "Saturation", 50, 0, 100),
    brightness = Menu.SliderInt("Colors", "Brightness", 75, 0, 100),
}

rainbow.run_paint = function()
    if (rainbow.control:Get() == 0) then
        global.color = global.color_picker:Get()
    else
        if (rainbow.control:Get() == 1) then
            local speed = 10 * ((100 - rainbow.speed:Get()) / 100)
            local hue = math.clamp(1 * ((GlobalVars.realtime - speed * math.floor(GlobalVars.realtime / speed)) / speed), 0, 1)
            local col = global.color_picker:Get()
            local r, g, b = math.hsb_to_rgb(hue, rainbow.saturation:Get(), rainbow.brightness:Get())

            global.color = Color.RGBA(r, g, b, math.floor(col.a * 255))
        else
            local speed, switch = 6.66 * ((100 - rainbow.speed:Get()) / 100), false
            local percent = math.clamp(1 * ((GlobalVars.realtime - speed * math.floor(GlobalVars.realtime / speed)) / speed), 0, 1)
            local col_1, col_2, end_color = rainbow.color_1:Get(), rainbow.color_2:Get(), Color.RGBA(255, 255, 255)
            if (percent >= 0.5) then percent = 0.5 - math.abs(0.5 - percent) end

            if (col_1 and col_2) then
                if (switch) then
                    end_color = Color.new(math.num2num(col_1.r, col_2.r, percent * 2), math.num2num(col_1.g, col_2.g, percent * 2), math.num2num(col_1.b, col_2.b, percent * 2), 255)
                else
                    end_color = Color.new(math.num2num(col_2.r, col_1.r, percent * 2), math.num2num(col_2.g, col_1.g, percent * 2), math.num2num(col_2.b, col_1.b, percent * 2), 255)
                end
            end

            global.color = end_color
        end
    end
end

--[[
    Clantag Functions
--]]

Utils.clantag = ffi.cast('int(__fastcall*)(const char*, const char*)', Utils.PatternScan('engine.dll', '53 56 57 8B DA 8B F9 FF 15'))
Utils.set_clantag = function(text) Utils.clantag(text, text) end

local clantag = {} clantag.__index = clantag
clantag.controls = {
    enabled = Menu.Switch("Clantag", "Enabled", false),
    tag = Menu.TextBox("Clantag", "Clantag Text", 100, ""),
    speed = Menu.SliderFloat("Clantag", "Speed", 0.3, 0.01, 0.99),
    hold = Menu.SliderInt("Clantag", "Hold Time", 4, 1, 15),
}

function clantag.animation()
    local tag = clantag.controls.tag:Get()

    if (tag ~= "" and clantag.controls.enabled:Get()) then
        local function set_tag(text, ind)
            local net_channel_info = EngineClient.GetNetChannelInfo()
            local spaces = "" for i = 0, string.len(text) do spaces = spaces .. " " end

            local anim = spaces .. text .. spaces
            local i = (GlobalVars.tickcount + math.time_to_ticks(net_channel_info:GetLatency(1))) / math.time_to_ticks(clantag.controls.speed:Get())
            i = math.floor(i % #ind) i = ind[i + 1] + 1
        
            return string.sub(anim, i, i + string.len(text))
        end

        local indicies, hold_time = {}, clantag.controls.hold:Get()
        for i = 0, string.len(tag) * 2 + hold_time * 2 do
            if (i <= string.len(tag)) then
                table.insert(indicies, i)
            elseif (i > string.len(tag) and i < string.len(tag) + hold_time) then
                table.insert(indicies, string.len(tag))
            elseif (i > string.len(tag) * 2 + hold_time and i <= string.len(tag) * 2 + hold_time * 2) then
                table.insert(indicies, 0)
            else
                table.insert(indicies, i - hold_time)
            end
        end

        local clan_tag = set_tag(tag, indicies)
        if (clan_tag ~= clantag.previous) then Utils.set_clantag(clan_tag) end
        clantag.previous = clan_tag
    end
end

function clantag.run_paint()
    if (local_player and local_player:IsPlayer() and (not local_player:IsAlive()) and GlobalVars.tickcount % 2 == 0) then
        clantag.animation()
    end
end

function clantag.run_createmove()
    if (ClientState.m_choked_commands == 0) then
        clantag.animation()
    end
end

function clantag.run_shutdown()
    Utils.set_clantag("") 
end

--[[
    Main
--]]

Cheat.RegisterCallback("draw", function()
    local_player = EntityList.GetLocalPlayer()
    screen_size = EngineClient.GetScreenSize()

    rainbow.run_paint()
    input.run_key_presses()
    window.run_windows()
    notification.run()

    auto_peek.run_paint()
    clantag.run_paint()
end)

Cheat.RegisterCallback("createmove", function(cmd)
    clantag.run_createmove()
end)

Cheat.RegisterCallback("destroy", function(cmd)
    clantag.run_shutdown()
end)
