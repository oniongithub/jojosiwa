-- protect her well ducarii

--[[
    Globals
--]]

local global = {} global.__index = {}
global.whitelist = { 
    whitelisted = false,
    users = {
        { name = "onion", uid = 84 }, { name = "north", uid = 188 }, { name = "Arid", uid = 39 }, { name = "Ktown", uid = 125 },
        { name = "neplo", uid = 627 }, { name = "ghosted", uid = 872 }, { name = "Nelson", uid = 703 }, { name = "DucaRii", uid = 1 },
        { name = "morgue", uid = 2 }, { name = "Pagonia", uid = 3 }, { name = "riri", uid = 4 }, { name = "Classy", uid = 391 },
        { name = "jake", uid = 267 }, { name = "Astral", uid = 1152 }, { name = "Brfs", uid = 1395 }, { name = "thiocodin", uid = 368 },
        { name = "dve", uid = 1203 },
    }
}

for i = 1, #global.whitelist.users do
    if (user.name == global.whitelist.users[i].name and user.uid == global.whitelist.users[i].uid) then
        global.whitelist.whitelisted = true
    end
end

local hud = {} hud.__index = hud
hud.controls = menu.add_multi_selection("HUD", "HUD Elements", { "Keybinds", "Spectator List", "Watermark", "Information", "Health Info", "Weapon Info", "Scoreboard", "Chatbox", "Radar", "Step Counter", "Team Damage" })
local local_player, local_player_or_spectating, screen_size = entity_list.get_local_player(), entity_list.get_local_player_or_spectating(), render.get_screen_size()

if (global.whitelist.whitelisted) then
    hud.controls:add_item("Player List")
end

global.window_references = {
    double_tap = menu.find("aimbot", "general", "exploits", "doubletap", "enable"),
    hide_shots = menu.find("aimbot", "general", "exploits", "hideshots", "enable"),
    anti_aim = menu.find("antiaim", "main", "general", "enable"),
    fake_lag = menu.find("antiaim", "main", "fakelag", "amount"),
    thirdperson = menu.find("visuals", "other", "thirdperson", "enable"),
    auto_peek = menu.find("aimbot", "general", "misc", "autopeek"),
    body_lean = menu.find("aimbot", "general", "aimbot", "body lean resolver"),
    extended_angles = menu.find("antiaim", "main", "extended angles", "enable"),
    edge_jump = menu.find("misc", "main", "movement", "edge jump"),
    auto_peek_2 = menu.find("aimbot", "general", "misc", "autopeek")[2],
    menu_accent_2 = menu.find("misc", "main", "config", "accent color")[2],
    yaw_base = menu.find("antiaim", "main", "angles", "yaw base"),
    yaw_add = menu.find("antiaim", "main", "angles", "yaw add"),
    extended_type = menu.find("antiaim", "main", "extended angles", "type"),
    extended_offset = menu.find("antiaim", "main", "extended angles", "offset"),
}

global.color = global.window_references.menu_accent_2:get()

local e_keybind_modes = {
    TOGGLE = 0,
    HOLD_ON = 1,
    HOLD_OFF = 2,
    ALWAYS_ON = 3,
    ALWAYS_OFF = 4
}

--[[
    Misc Functions
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
    return math.floor(time / global_vars.interval_per_tick() + .5)
end

function math.get_circumference_point(radius, angle, radian)
    if (radius and angle) then
        if (not radian) then angle = angle * (math.pi / 180) end

        return vec2_t(radius * math.cos(angle), radius * math.sin(angle))
    end

    return vec2_t(0, 0)
end

function angle_t:from_angle()
    return vec3_t(math.cos(math.rad(self.x)) * math.cos(math.rad(self.y)), math.cos(math.rad(self.x)) * math.sin(math.rad(self.y)), -1 * math.sin(math.rad(self.x)))
end

function angle_t:to_vector()
    local pitch_rad, yaw_rad = (math.pi / 180) * self.x, (math.pi / 180) * self.y
    local sp, cp, sy, cy = math.sin(pitch_rad), math.cos(pitch_rad), math.sin(yaw_rad), math.cos(yaw_rad)
    return vec3_t(cp * cy, cp * sy, -sp)
end

function vec2_t:normalize()
    local len = self:length()

    if (len ~= 0) then 
        self = self / vec2_t(len, len) 
    else 
        self.x, self.y = 0, 0 
    end

    return self
end

function vec2_t:rotate_point(center, angle, radians)
    if (radians == nil) then radians = false end
    if (not radians) then angle = angle * (math.pi / 180) end

    local c, s = math.cos(angle), math.sin(angle)
    local return_vec = vec2_t(c * (self.x - center.x) + s * (self.y - center.y), s * (self.x - center.x) - c * (self.y - center.y))

    return_vec = vec2_t(return_vec.x + center.x, return_vec.y + center.y)

    return return_vec
end

function vec3_t:dist_to(vec)
    return math.sqrt((self.x - vec.x)^2 + (self.y - vec.y)^2 + (self.z - vec.z)^2)
end

function vec3_t:normalize()
    local len = math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)

    if (len == 0) then
        return vec3_t(0, 0, 0)
    end

    local r = 1 / len

    return vec3_t(self.x * r, self.y * r, self.z * r)
end

function angle_t:normalize()
    if self.y ~= self.y or self.y == INF then
        self.y = 0
        self.y = self.y
    elseif not (self.y > -180 and self.y <= 180) then
        self.y = math.fmod(math.fmod(self.y + 360, 360), 360)
        self.y = self.y > 180 and self.y - 360 or self.y
    end

    return angle_t(math.max(-89, math.min(89, self.x)), self.y, 0)
end

function angle_t:length()
    return math.sqrt(self.x^2 + self.y^2 + self.z^2)
end

function vec3_t:dot(vec)
    return self.x * vec.x + self.y * vec.y + self.z * vec.z
end

function vec3_t:to_angle(vec2)
    local x = vec2.x - self.x
    local z = vec2.y - self.y
    local y = self.z - vec2.z

    return angle_t(-math.deg(math.atan2(y, math.sqrt(x * x + z * z))), math.deg(math.atan2(z, x)) + 180, 0)
end

function render.circle_3d(pos, col, radius, angle, segments, percent)
    if (pos) then
        local step, last_pos = (360 * (percent / 100)) / segments

        for i = 1, 361 * (percent / 100), step do
            if (i > 360) then i = 360 end

            local point = math.get_circumference_point(radius, angle + i, false)
            local point_2d = render.world_to_screen(vec3_t(pos.x + point.x, pos.y + point.y, pos.z))
            if (point_2d ~= nil) then
                if (last_pos) then
                    render.line(last_pos, point_2d, color_t(col.r, col.g, col.b, math.clamp(math.floor(col.a - ((col.a / segments) * (i / step))), 0, 255)))
                end

                last_pos = point_2d
            end
        end
    end
end

function engine.trace_crosshair(distance)
    local local_player = entity_list.get_local_player()

    if (local_player and local_player:is_player() and local_player:is_alive()) then
        local camera_angles, eye_position = engine.get_view_angles(), local_player:get_eye_position()

        if (camera_angles and eye_position) then
            local camera = camera_angles:from_angle()

            local crosshair_position = vec3_t(eye_position.x + camera.x * distance, eye_position.y + camera.y * distance, eye_position.z + camera.z * distance)
            local camera_trace = trace.line(eye_position, crosshair_position, local_player) distance = distance * camera_trace.fraction

            return vec3_t(eye_position.x + camera.x * distance, eye_position.y + camera.y * distance, eye_position.z + camera.z * distance)
        end
    end
end

function engine.get_local_fov(ent, point)
    local local_player = entity_list.get_local_player()

    if (local_player and local_player:is_player() and local_player:is_alive()) then
        local camera_angles, local_position, ply_position, normalized = engine.get_view_angles(), local_player:get_eye_position(), ent:get_render_origin()
        if (point) then
            normalized = vec3_t(point.x - local_position.x, point.y - local_position.y, point.z - local_position.z):normalize()
        else
            normalized = vec3_t(ply_position.x - local_position.x, ply_position.y - local_position.y, local_position.z - local_position.z):normalize()
        end

        local dot_product = normalized:dot(camera_angles:to_vector())
        local cos_inverse = math.acos(dot_product)

        if (cos_inverse ~= cos_inverse or cos_inverse == INF) then
            return 0
        end

        return (180.0 / math.pi) * cos_inverse
    end
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

--[[
    Filesystem Library
--]]

local filesystem = {} filesystem.__index = filesystem filesystem.char_buffer = ffi.typeof("char[?]")
filesystem.table = ffi.cast(ffi.typeof("void***"), memory.create_interface("filesystem_stdio.dll", "VBaseFileSystem011"))

filesystem.v_funcs = {
    file_open = ffi.cast(ffi.typeof("void*(__thiscall*)(void*, const char*, const char*, const char*)"), filesystem.table[0][2]),
    file_read = ffi.cast(ffi.typeof("int(__thiscall*)(void*, void*, int, void*)"), filesystem.table[0][0]),
    file_size = ffi.cast(ffi.typeof("unsigned int(__thiscall*)(void*, void*)"), filesystem.table[0][7]),
}

function filesystem.read_file(path)
	local handle = filesystem.v_funcs.file_open(filesystem.table, path, "r", "MOD")
	if (handle == nil) then return end

	local filesize = filesystem.v_funcs.file_size(filesystem.table, handle)
	if (filesize == nil or filesize < 0) then return end

	local buffer = filesystem.char_buffer(filesize + 1)
	if (buffer == nil) then return end

	if (not filesystem.v_funcs.file_read(filesystem.table, buffer, filesize, handle)) then return end

	return ffi.string(buffer, filesize)
end

filesystem.weapon_icons = {}
function filesystem.load_icon(weap)
    local function contains(tbl, text)
        for i = 1, #tbl do
            if (tbl[i][2] == text) then return i end
        end

        return
    end

    if (weap and weap:is_weapon()) then
        local weapon_data = weap:get_weapon_data()
        local item = weapon_data.console_name:gsub("^weapon_", ""):gsub("^item_", "")
        local contained = contains(filesystem.weapon_icons, item)

        if (contained) then
            return filesystem.weapon_icons[contained][1]
        else
            local file_text = filesystem.read_file("materials/panorama/images/icons/equipment/" .. item .. ".svg")

            if (file_text) then
                local img = render.load_image_buffer(file_text)

                if (img) then
                    table.insert(filesystem.weapon_icons, {img, item})
                    return img
                end
            end
        end
    end
    
    return
end

--[[
    Window Library
--]]

local window = {} window.__index = window

window.fonts = {
    segoe_ui_13 = render.create_font("Segoe UI", 13, 100, e_font_flags.ANTIALIAS),
    segoe_ui_18 = render.create_font("Segoe UI", 18, 100, e_font_flags.ANTIALIAS)
}

window.flags = {
    FL_NODRAW = 1, FL_NOMOVE = 2, FL_NOTITLE = 3, FL_RESIZE_H = 4, FL_RESIZE_V = 5,
}

window.window_list = {}

function window.add_window(size, name, control, ...)
    if (not size) then return end

    local flag_table = {...}

    local function contains(tbl, value)
        for i = 1, #tbl do
            if (tbl[i] == value) then return true end
        end
        
        return false
    end

    local x, y = menu.add_slider("Settings", name .. " - X", 0, screen_size.x), menu.add_slider("Settings", name .. " - Y", 0, screen_size.y)
    local w, h = menu.add_slider("Settings", name .. " - W", 0, screen_size.x), menu.add_slider("Settings", name .. " - H", 0, screen_size.x)

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
    local mouse_pos = input.get_mouse_pos()

    if (menu.is_open()) then
        if (window.window_list[index].flags.FL_RESIZE_H and input.is_mouse_in_bounds(vec2_t(window.window_list[index].pos.x + window.window_list[index].size.x - 10, window.window_list[index].pos.y), vec2_t(20, window.window_list[index].size.y))) then
            if (input.is_key_pressed(e_keys.MOUSE_LEFT)) then
                window.window_list[index].input.resizing = true
                window.window_list[index].input.mouse_pos = vec2_t(mouse_pos.x - window.window_list[index].pos.x, mouse_pos.y - window.window_list[index].pos.y)

                return true
            end
        elseif (window.window_list[index].flags.FL_RESIZE_V and input.is_mouse_in_bounds(vec2_t(window.window_list[index].pos.x, window.window_list[index].pos.y + window.window_list[index].size.y - 10), vec2_t(window.window_list[index].size.x, 20))) then
            if (input.is_key_pressed(e_keys.MOUSE_LEFT)) then
                window.window_list[index].input.resizing = true
                window.window_list[index].input.mouse_pos = vec2_t(mouse_pos.x - window.window_list[index].pos.x, mouse_pos.y - window.window_list[index].pos.y)

                return true
            end
        elseif (not window.window_list[index].flags.FL_NOMOVE and input.is_mouse_in_bounds(window.window_list[index].pos, window.window_list[index].size)) then
            if (input.is_key_pressed(e_keys.MOUSE_LEFT)) then
                window.window_list[index].input.dragging = true
                window.window_list[index].input.mouse_pos = vec2_t(mouse_pos.x - window.window_list[index].pos.x, mouse_pos.y - window.window_list[index].pos.y)

                return true
            end
        end
    end

    if (input.is_key_held(e_keys.MOUSE_LEFT) and menu.is_open()) then
        if (window.window_list[index].input.resizing) then
            local x, y = math.clamp(mouse_pos.x - window.window_list[index].pos.x, 0, screen_size.x), math.clamp(mouse_pos.y - window.window_list[index].pos.y, 0, screen_size.y)
            
            if (window.window_list[index].flags.FL_RESIZE_H) then
                window.window_list[index].size = vec2_t(x, window.window_list[index].size.y)
                window.window_list[index].w_control:set(x)
            end

            if (window.window_list[index].flags.FL_RESIZE_V) then
                window.window_list[index].size = vec2_t(window.window_list[index].size.x, y)
                window.window_list[index].h_control:set(y)
            end
        elseif (window.window_list[index].input.dragging) then
            local x, y = math.clamp(mouse_pos.x - window.window_list[index].input.mouse_pos.x, 0, screen_size.x - window.window_list[index].size.x), math.clamp(mouse_pos.y - window.window_list[index].input.mouse_pos.y, 0, screen_size.y - window.window_list[index].size.y)
            window.window_list[index].pos = vec2_t(x, y)
            window.window_list[index].x_control:set(x)
            window.window_list[index].y_control:set(y)
        end
    else
        window.window_list[index].input.dragging = false
        window.window_list[index].input.resizing = false
    end

    return false -- so we can return true and make movement only run on a single window
end

function window.run_paint(index)
    render.rect_filled(window.window_list[index].pos, window.window_list[index].size, color_t(25, 25, 25, 125), 6)

    if (not window.window_list[index].flags.FL_NOTITLE) then
        local text_size = render.get_text_size(window.fonts.segoe_ui_18, window.window_list[index].name)
        window.window_list[index].tab_height = text_size.y + 17
        render.rect_filled(window.window_list[index].pos, vec2_t(window.window_list[index].size.x, 8 + text_size.y), color_t(25, 25, 25, 255), 6)
        render.rect_filled(vec2_t(window.window_list[index].pos.x, window.window_list[index].pos.y + 6), vec2_t(window.window_list[index].size.x, 2 + text_size.y), color_t(25, 25, 25, 255), 0)
        render.rect_filled(vec2_t(window.window_list[index].pos.x, window.window_list[index].pos.y + 8 + text_size.y), vec2_t(window.window_list[index].size.x, 1), global.color, 0)
        render.text(window.fonts.segoe_ui_18, window.window_list[index].name, vec2_t(window.window_list[index].pos.x + (window.window_list[index].size.x / 2) - (text_size.x / 2), window.window_list[index].pos.y + 4), color_t(225, 225, 225))
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
            if (not hud.controls:get(window.window_list[i].control)) then goto hop_that_shit end
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
            window.window_list[i].pos = vec2_t(window.window_list[i].x_control:get(), window.window_list[i].y_control:get())
            if (window.window_list[i].w_control:get() ~= 0) then
                window.window_list[i].size = vec2_t(window.window_list[i].w_control:get(), window.window_list[i].size.y)
            end

            if (window.window_list[i].h_control:get() ~= 0) then
                window.window_list[i].size = vec2_t(window.window_list[i].size.x, window.window_list[i].h_control:get())
            end

            window.window_list[i].x_control:set_visible(false)
            window.window_list[i].y_control:set_visible(false)
            window.window_list[i].w_control:set_visible(false)
            window.window_list[i].h_control:set_visible(false)
        end
    end
end

function window.add_bar(used_space, name, index, percent, col)
    local color = global.color if (col) then color = col end
    local text_size = render.get_text_size(window.fonts.segoe_ui_13, name)
    render.text(window.fonts.segoe_ui_13, name, vec2_t(window.window_list[index].pos.x + 8, window.window_list[index].pos.y + used_space.y + window.window_list[index].tab_height), color_t(225, 225, 225))

    local bar_width = math.clamp((window.window_list[index].size.x - 16) * percent, 10, window.window_list[index].size.x - 16)

    render.rect_filled(vec2_t(window.window_list[index].pos.x + 8, used_space.y + window.window_list[index].pos.y + window.window_list[index].tab_height + 4 + text_size.y), vec2_t(window.window_list[index].size.x - 16, 10), color_t(25, 25, 25, 255), 5)
    
    if (percent > 0) then
        render.rect_filled(vec2_t(window.window_list[index].pos.x + 8, used_space.y + window.window_list[index].pos.y + window.window_list[index].tab_height + 4 + text_size.y), vec2_t(bar_width, 10), color, 5)
    end

    return text_size.y + 22
end

--[[
    Callback Library
--]]

local callback = {} callback.__index = callback
callback.functions = {}

function menu.add_callback(control, fn)
    for i = 1, #callback.functions do
        if (callback.functions[i].control == control) then
            callback.functions[i].fn = fn
            return
        end
    end

    local value, type = 0, 0
    local status = pcall(function() value = control:get() end)
    if (not status) then 
        type = 1 status = pcall(function() value = control:get_items() end)
    end
    if (not status) then type = 2 end

    if (type == 1) then
        local val = { items = control:get_items(), table = {} }

        for i = 1, #val.items do
            table.insert(val.table, control:get(i))
        end

        value = val.table
    end

    table.insert(callback.functions, { control = control, fn = fn, value = value, type = type })
end

function callback.run_paint()
    if (menu.is_open()) then
        for i = 1, #callback.functions do
            if (callback.functions[i].type ~= 1 and callback.functions[i].type ~= 2 and callback.functions[i].control:get() ~= callback.functions[i].value) then
                callback.functions[i].value = callback.functions[i].control:get()
                callback.functions[i].fn()
            elseif (callback.functions[i].type == 1) then
                local val = { items = callback.functions[i].control:get_items(), table = {} }

                for f = 1, #val.items do
                    table.insert(val.table, callback.functions[i].control:get(f))
                end

                for f = 1, #val.table do
                    if (val.table[f] ~= callback.functions[i].value[f]) then
                        callback.functions[i].value = val.table
                        callback.functions[i].fn()
                    end
                end
            end
        end
    end
end

--[[
    Notification Library
--]]

local notification = {} notification.__index = notification notification.list = {}

function notification.add(name, description, time)
    table.insert(notification.list, { name = name, description = description, time = time, start = global_vars.real_time() })
end

function notification.easing(width, percent)
    return width * (percent^4)
end

function notification.run()
    local current_time, used_space = global_vars.real_time(), vec2_t(0, 0)

    for i = #notification.list, 1, -1 do
        if (global_vars.real_time() - notification.list[i].start >= notification.list[i].time) then
            table.remove(notification.list, i)
        end
    end

    for i = 1, (#notification.list <= 8) and #notification.list or 8 do
        local text_size, text_size_2 = render.get_text_size(window.fonts.segoe_ui_13, notification.list[i].name), render.get_text_size(window.fonts.segoe_ui_13, notification.list[i].description)
        local total_width = text_size.x + text_size_2.x + 61 -- 16 px pad, 1 px line, 16 px pad, 8 px from side, 20 px outside
        local percent = (global_vars.real_time() - notification.list[i].start) / notification.list[i].time
        total_width = notification.easing(total_width, percent)

        render.push_clip(vec2_t(8 - total_width, 8 + used_space.y), vec2_t(text_size.x + 16, 8 + text_size.y))
        render.rect_filled(vec2_t(8 - total_width, 8 + used_space.y), vec2_t(text_size.x + 20, 8 + text_size.y), color_t(25, 25, 25, 255), (text_size.y) / 2)
        render.pop_clip()

        render.push_clip(vec2_t(24 - total_width + text_size.x, 8 + used_space.y), vec2_t(text_size_2.x + 16, 8 + text_size.y))
        render.rect_filled(vec2_t(text_size.x + 16 - total_width, 8 + used_space.y), vec2_t(text_size_2.x + 20, 8 + text_size.y), color_t(25, 25, 25, 125), (text_size.y) / 2)
        render.pop_clip()

        render.rect_filled(vec2_t(24 - total_width + text_size.x, 8 + used_space.y), vec2_t(1, 8 + text_size.y), global.color, 0)

        render.text(window.fonts.segoe_ui_13, notification.list[i].name, vec2_t(16 - total_width, 12 + used_space.y), color_t(225, 225, 225))
        render.text(window.fonts.segoe_ui_13, notification.list[i].description, vec2_t(29 + text_size.x - total_width, 12 + used_space.y), color_t(225, 225, 225))
        
        used_space.y = used_space.y + text_size.y + 12
    end
end

--[[
    HUD Functions
--]]

hud.keys = { {60, "/", "?"}, {65, " "}, {1, "0", ")"}, {2, "1", "!"}, {3, "2", "@"}, 
               {4, "3", "#"}, {5, "4", "$"}, {6, "5", "%"}, {7, "6", "^"}, {8, "7", "&"},
               {9, "8", "*"}, {10, "9", "("}, {11, "A"}, {12, "B"}, {13, "C"},
               {14, "D"}, {15, "E"}, {16, "F"}, {17, "G"}, {18, "H"},
               {19, "I"}, {20, "J"}, {21, "K"}, {22, "L"}, {23, "M"},
               {24, "N"}, {25, "O"}, {26, "P"}, {27, "Q"}, {28, "R"},
               {29, "S"}, {30, "T"}, {31, "U"}, {32, "V"}, {33, "W"},
               {34, "X"}, {35, "Y"}, {36, "Z"}, {59, ".", ">"}, {58, ",", "<"},
               {61, "\\", "|"}, {62, "-", "_"}, {63, "=", "+"}, {67, "    "} };

hud.toggles = {
    notifications = menu.add_checkbox("HUD", "Notifications", true),
    keybind = 1,
    spectator = 2,
    watermark = 3,
    information = 4,
    health = 5,
    weapon = 6,
    score = 7,
    chat = 8,
    radar = 9,
    steps = 10,
    team_damage = 11,
    player_list = 12,
}

hud.override_hud = menu.add_checkbox("HUD", "Override HUD", false)
hud.override_primordial = menu.add_checkbox("HUD", "Override Default HUD", true)

hud.windows = {
    keybind = window.add_window(vec2_t(150, 150), "Keybinds", hud.toggles.keybind, window.flags.FL_RESIZE_H),
    spectator = window.add_window(vec2_t(150, 200), "Spectators", hud.toggles.spectator, window.flags.FL_RESIZE_H),
    information = window.add_window(vec2_t(150, 150), "Information", hud.toggles.information, window.flags.FL_RESIZE_H),
    watermark = window.add_window(vec2_t(150, 150), "Watermark", hud.toggles.watermark, window.flags.FL_NOTITLE, window.flags.FL_NOMOVE),
    health = window.add_window(vec2_t(275, 125), "Health Info", hud.toggles.health, window.flags.FL_RESIZE_H),
    weapon = window.add_window(vec2_t(175, 125), "Weapon Info", hud.toggles.weapon, window.flags.FL_RESIZE_H),
    score = window.add_window(vec2_t(275, 125), "Scoreboard", hud.toggles.score, window.flags.FL_NOMOVE, window.flags.FL_RESIZE_H),
    chat = window.add_window(vec2_t(400, 175), "Chatbox", hud.toggles.chat, window.flags.FL_RESIZE_H),
    radar = window.add_window(vec2_t(200, 220), "Radar", hud.toggles.radar, window.flags.FL_RESIZE_H, window.flags.FL_RESIZE_V),
    steps = window.add_window(vec2_t(150, 125), "Step Counter", hud.toggles.steps),
    team_damage = window.add_window(vec2_t(250, 100), "Team Damage", hud.toggles.team_damage, window.flags.FL_RESIZE_H),
    player_list = global.whitelist.whitelisted and window.add_window(vec2_t(450, 300), "Player List", hud.toggles.player_list, window.flags.FL_RESIZE_H, window.flags.FL_RESIZE_V) or nil,
}

hud.context_control = menu.add_selection("HUD Controls", "Element Controls", {"None", "Watermark", "Spectators", "Keybinds"})
menu.add_separator("HUD Controls")

hud.context_menus = {
    context_strings = { "Watermark", "Spectators", "Keybinds" },
    ["Watermark"] = {
        menu.add_selection("HUD Controls", "Watermark Style", { "Minimal", "Default Style" }),
        menu.add_multi_selection("HUD Controls", "Information", { "Cheat Name", "Username", "UID", "Ping", "FPS" }),
    },
    ["Spectators"] = {
        menu.add_selection("HUD Controls", "Spectators Shown", { "Enemies", "Teammates", "Both" }),
        menu.add_checkbox("HUD Controls", "Show Local", false),
    },
    ["Keybinds"] = {
        menu.add_checkbox("HUD Controls", "Show Mode", false),
    }
}

hud.context_visiblity = function(name)
    if (not name) then name = "" end

    for i = 1, #hud.context_menus.context_strings do
        for f = 1, #hud.context_menus[hud.context_menus.context_strings[i]] do
            if (name ~= hud.context_menus.context_strings[i]) then
                hud.context_menus[hud.context_menus.context_strings[i]][f]:set_visible(false)
            else
                hud.context_menus[hud.context_menus.context_strings[i]][f]:set_visible(true)
            end
        end
    end
end
hud.context_visiblity()

menu.add_callback(hud.context_control, function() hud.context_visiblity(hud.context_control:get_item_name(hud.context_control:get())) end)

-- Team Damage's Window
hud.team_damage = { 
    damage = 0,
    kills = 0,
}
window.window_list[hud.windows.team_damage].draw_fn = function()
    local used_space = vec2_t(0, 0)
    render.push_clip(window.window_list[hud.windows.team_damage].pos, window.window_list[hud.windows.team_damage].size)

    used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Damage", hud.windows.team_damage, hud.team_damage.damage / 300))
    used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Kills", hud.windows.team_damage, hud.team_damage.kills / 3))

    render.pop_clip()
    window.window_list[hud.windows.team_damage].size.y = window.window_list[hud.windows.team_damage].tab_height + 8 + used_space.y
end

-- Step Counter's Window
hud.steps = { count = 0 }
window.window_list[hud.windows.steps].draw_fn = function()
    local used_space = vec2_t(0, 0)

    render.push_clip(window.window_list[hud.windows.steps].pos, window.window_list[hud.windows.steps].size)

    if (local_player and local_player:is_player()) then
        local text_size = render.get_text_size(window.fonts.segoe_ui_13, tostring(hud.steps.count))
        render.text(window.fonts.segoe_ui_13, tostring(hud.steps.count), vec2_t(window.window_list[hud.windows.steps].pos.x + window.window_list[hud.windows.steps].size.x / 2 - text_size.x / 2, window.window_list[hud.windows.steps].pos.y + window.window_list[hud.windows.steps].tab_height + text_size.y / 4), color_t(225, 225, 225))

        used_space.y = used_space.y + text_size.y + 8
    else
        hud.steps.count = 0
    end

    render.pop_clip()
    window.window_list[hud.windows.steps].size.y = window.window_list[hud.windows.steps].tab_height + 8 + used_space.y
end

-- Radar's Window
window.window_list[hud.windows.radar].draw_fn = function()
    local lp_or_spec = entity_list.get_local_player_or_spectating()

    local function scale_to_radar(ent, lp, center)
        local local_origin, ent_origin = lp:get_render_origin(), ent:get_render_origin()
        local screen_pos = vec2_t(local_origin.x - ent_origin.x, local_origin.y - ent_origin.y)
        local distance = screen_pos:length() * 0.055
        screen_pos = screen_pos:normalize()
        screen_pos = vec2_t(screen_pos.x * distance, screen_pos.y * distance)
        screen_pos = vec2_t(screen_pos.x + center.x, screen_pos.y + center.y)

        local local_angles = engine.get_view_angles()
        screen_pos = screen_pos:rotate_point(center, local_angles.y + 90)

        return screen_pos
    end

    if (lp_or_spec and lp_or_spec:is_player() and lp_or_spec:is_alive()) then
        local center = vec2_t(window.window_list[hud.windows.radar].pos.x + window.window_list[hud.windows.radar].size.x / 2, window.window_list[hud.windows.radar].pos.y + window.window_list[hud.windows.radar].tab_height + 79)

        render.push_clip(vec2_t(window.window_list[hud.windows.radar].pos.x + 8, window.window_list[hud.windows.radar].pos.y + window.window_list[hud.windows.radar].tab_height - 1), vec2_t(window.window_list[hud.windows.radar].size.x - 16, window.window_list[hud.windows.radar].size.y - window.window_list[hud.windows.radar].tab_height - 9))
        local players = entity_list.get_players(true)
        for i, ply in pairs(players) do
            if (ply:is_player() and ply:is_alive()) then
                local point = scale_to_radar(ply, lp_or_spec, center)
                render.circle_filled(point, 5, global.color)
            end

        end
        render.pop_clip()
    end
end

-- Chatbox's Window
hud.chatbox = { logs = {}, last_message = 0, chatting = 0,
                    keys = {}, chat_message = ""
                }

window.window_list[hud.windows.chat].draw_fn = function()
    local used_space = vec2_t(0, 0)
    render.push_clip(window.window_list[hud.windows.chat].pos, window.window_list[hud.windows.chat].size)

    if (local_player and local_player:is_player()) then
        for i = 1, #hud.chatbox.logs do
            local text = (hud.chatbox.logs[i].dead and "*DEAD* " or "") .. (hud.chatbox.logs[i].teamchat and "*TEAM* " or "") .. hud.chatbox.logs[i].name .. " - " .. hud.chatbox.logs[i].text
            local text_size = render.get_text_size(window.fonts.segoe_ui_13, text)
            local col = hud.chatbox.logs[i].team == 2 and color_t(255, 128, 132) or hud.chatbox.logs[i].team == 3 and color_t(128, 181, 255) or color_t(255, 255, 255)

            render.text(window.fonts.segoe_ui_13, text, vec2_t(window.window_list[hud.windows.chat].pos.x + 16, window.window_list[hud.windows.chat].pos.y + used_space.y + window.window_list[hud.windows.chat].tab_height), col)
            used_space.y = used_space.y + text_size.y + 6
        end
    else
        hud.chatbox.logs = {}
    end

    local save_space = used_space
    if (hud.chatbox.chatting ~= 0) then
        for i = 1, #hud.keys do
            if (input.is_key_pressed(hud.keys[i][1])) then
                if (input.is_key_held(e_keys.KEY_LSHIFT) or input.is_key_held(e_keys.KEY_RSHIFT)) then
                    if (hud.keys[i][3]) then
                        hud.chatbox.chat_message = hud.chatbox.chat_message .. hud.keys[i][3]
                    else
                        hud.chatbox.chat_message = hud.chatbox.chat_message .. hud.keys[i][2]
                    end
                else
                    hud.chatbox.chat_message = hud.chatbox.chat_message .. string.lower(hud.keys[i][2])
                end
            end
        end

        if (input.is_key_pressed(e_keys.KEY_BACKSPACE)) then hud.chatbox.chat_message = hud.chatbox.chat_message:sub(1, -2) end
        if (input.is_key_pressed(e_keys.KEY_ENTER)) then
            if (hud.chatbox.chat_message ~= "") then
                if (hud.chatbox.chatting == 1) then
                    engine.execute_cmd("say " .. hud.chatbox.chat_message)
                else
                    engine.execute_cmd("say_team " .. hud.chatbox.chat_message)
                end
            end

            hud.chatbox.chat_message, hud.chatbox.chatting = "", 0
        end

        local text_size = render.get_text_size(window.fonts.segoe_ui_13, (hud.chatbox.chatting == 2 and "TEAM - " or "") .. hud.chatbox.chat_message)

        render.text(window.fonts.segoe_ui_13, (hud.chatbox.chatting == 2 and "TEAM - " or "") .. hud.chatbox.chat_message, vec2_t(window.window_list[hud.windows.chat].pos.x + 16, window.window_list[hud.windows.chat].pos.y + used_space.y + window.window_list[hud.windows.chat].tab_height + 6), color_t(225, 225, 225))
        render.rect_filled(vec2_t(window.window_list[hud.windows.chat].pos.x + 16 + text_size.x, window.window_list[hud.windows.chat].pos.y + used_space.y + window.window_list[hud.windows.chat].tab_height + 6), vec2_t(2, text_size.y), color_t(255, 255, 255))

        used_space.y = used_space.y + text_size.y + 12
    end

    render.pop_clip()
    window.window_list[hud.windows.chat].size.y = window.window_list[hud.windows.chat].tab_height + 8 + used_space.y
end

-- Scoreboard's Window
window.window_list[hud.windows.score].draw_fn = function()
    local used_space = vec2_t(0, 0)
    render.push_clip(window.window_list[hud.windows.score].pos, window.window_list[hud.windows.score].size)

    if (local_player and local_player:is_player()) then
        local start_time, round_time, freeze_period, time_text = game_rules.get_prop("m_fRoundStartTime"), game_rules.get_prop("m_iRoundTime"), game_rules.get_prop("m_bFreezePeriod"), "0:00"

        if (freeze_period ~= 1) then
            local current_time = math.clamp(math.floor((round_time - (global_vars.cur_time() - start_time)), 2), 0, nil)
            
            local current_time_seconds, current_time_minutes = math.round(math.clamp((current_time / 60 - math.floor(current_time / 60)) * 60, 0, 60), 0), math.round(math.clamp(math.floor(current_time / 60), 0, 59), 0)
            time_text = current_time_minutes time_text = (current_time_seconds < 10) and (time_text .. ":0" .. current_time_seconds) or (time_text .. ":" .. current_time_seconds )
        end

        local t_wins, ct_wins = 0, 0

        for i, ent in pairs(entity_list.get_entities_by_name("CCSTeam")) do
            if (ent:get_prop("m_iTeamNum") == 2) then t_wins = ent:get_prop("m_scoreTotal") else ct_wins = ent:get_prop("m_scoreTotal") end
        end

        local text_size, mid_point = render.get_text_size(window.fonts.segoe_ui_18, "CT - " .. ct_wins), 0
        render.text(window.fonts.segoe_ui_18, "CT - " .. ct_wins, vec2_t(window.window_list[hud.windows.score].pos.x + 16, window.window_list[hud.windows.score].pos.y + window.window_list[hud.windows.score].tab_height), color_t(225, 225, 225))
        mid_point = window.window_list[hud.windows.score].pos.x + 16 + text_size.x text_size = render.get_text_size(window.fonts.segoe_ui_18, "T - " .. t_wins) mid_point = (mid_point + window.window_list[hud.windows.score].pos.x + window.window_list[hud.windows.score].size.x - 16 - text_size.x) / 2
        render.text(window.fonts.segoe_ui_18, "T - " .. t_wins, vec2_t(window.window_list[hud.windows.score].pos.x + window.window_list[hud.windows.score].size.x - 16 - text_size.x, window.window_list[hud.windows.score].pos.y + window.window_list[hud.windows.score].tab_height), color_t(225, 225, 225))

        text_size = render.get_text_size(window.fonts.segoe_ui_18, time_text)
        render.text(window.fonts.segoe_ui_18, time_text, vec2_t(mid_point - text_size.x / 2, window.window_list[hud.windows.score].pos.y + window.window_list[hud.windows.score].tab_height), color_t(225, 225, 225))

        used_space.y = used_space.y + text_size.y + 4

        local t_percentage, ct_percentage, score_total = 0, 0, t_wins + ct_wins

        if (t_wins > ct_wins) then
            t_percentage = t_wins / score_total ct_percentage = 1 - t_percentage
        else
            ct_percentage = ct_wins / score_total t_percentage = 1 - ct_percentage
        end

        if (ct_wins > t_wins) then
            render.rect_filled(vec2_t(window.window_list[hud.windows.score].pos.x + 8, used_space.y + window.window_list[hud.windows.score].pos.y + window.window_list[hud.windows.score].tab_height + 8), vec2_t(window.window_list[hud.windows.score].size.x - 16, 10), color_t(128, 181, 255), 5)
        elseif (t_wins > ct_wins) then
            render.rect_filled(vec2_t(window.window_list[hud.windows.score].pos.x + 8, used_space.y + window.window_list[hud.windows.score].pos.y + window.window_list[hud.windows.score].tab_height + 8), vec2_t(window.window_list[hud.windows.score].size.x - 16, 10), color_t(255, 128, 132), 5)
        else
            render.rect_filled(vec2_t(window.window_list[hud.windows.score].pos.x + 8, used_space.y + window.window_list[hud.windows.score].pos.y + window.window_list[hud.windows.score].tab_height + 8), vec2_t(window.window_list[hud.windows.score].size.x - 16, 10), color_t(25, 25, 25), 5)
        end

        if (t_percentage > 0 and ct_percentage > 0) then
            render.rect_filled(vec2_t(window.window_list[hud.windows.score].pos.x + 8 + (window.window_list[hud.windows.score].size.x - 16) * ct_percentage, used_space.y + window.window_list[hud.windows.score].pos.y + window.window_list[hud.windows.score].tab_height + 8), vec2_t(2, 10), color_t(25, 25, 25, 255), 0)
        end

        used_space.y = used_space.y + 22
    end

    render.pop_clip()
    window.window_list[hud.windows.score].pos = vec2_t(screen_size.x / 2 - window.window_list[hud.windows.score].size.x / 2, 8)
    window.window_list[hud.windows.score].size.y = window.window_list[hud.windows.score].tab_height + 8 + used_space.y
end

-- Weapon's Window
window.window_list[hud.windows.weapon].draw_fn = function()
    local used_space = vec2_t(0, 0)
    render.push_clip(window.window_list[hud.windows.weapon].pos, window.window_list[hud.windows.weapon].size)

    if (local_player_or_spectating and local_player_or_spectating:is_player() and local_player_or_spectating:is_alive()) then
        local weaps = {} local local_weapon = local_player_or_spectating:get_active_weapon()
        for i = 0, 16 do
            local wep = local_player_or_spectating:get_prop("m_hMyWeapons", i)

            if (wep and wep > 0) then
                local ent = entity_list.get_entity(wep)

                if (ent and ent:is_weapon()) then
                    table.insert(weaps, ent)
                end
            end
        end

        local sort_weap = {}
        for i = 1, #weaps do
            local ent = weaps[i]

            if (ent and ent:is_weapon()) then
                local data = ent:get_weapon_data()

                if (not sort_weap[data.inventory_slot]) then sort_weap[data.inventory_slot] = {} end
                if (not sort_weap[data.inventory_slot][data.inventory_slot_position]) then sort_weap[data.inventory_slot][data.inventory_slot_position] = {} end
                sort_weap[data.inventory_slot][data.inventory_slot_position][1] = string.lower(ent:get_name()):gsub("^%l", string.upper)
                sort_weap[data.inventory_slot][data.inventory_slot_position][2] = ent
            end
        end

        for i = 0, 10 do
            if (sort_weap[i]) then
                for f = 0, 20 do -- length is unusable because of use of dynamic tables above so static size and just check if it's nil cause I'm too lazy
                    if (sort_weap[i][f]) then
                        local text_size = render.get_text_size(window.fonts.segoe_ui_13, sort_weap[i][f][1])
                        local ico = filesystem.load_icon(sort_weap[i][f][2])
                        local percent = (ico.size.y - text_size.y) / ico.size.y
                        local size = vec2_t(math.floor(ico.size.x * percent), math.floor(ico.size.y * percent))

                        if (local_weapon and string.lower(local_weapon:get_name()):gsub("^%l", string.upper) == sort_weap[i][f][1]) then
                            render.texture(ico.id, vec2_t(window.window_list[hud.windows.weapon].pos.x + window.window_list[hud.windows.weapon].size.x / 2 - size.x / 2, window.window_list[hud.windows.weapon].pos.y + used_space.y + window.window_list[hud.windows.weapon].tab_height), size, global.color)
                        else
                            render.texture(ico.id, vec2_t(window.window_list[hud.windows.weapon].pos.x + window.window_list[hud.windows.weapon].size.x / 2 - size.x / 2, window.window_list[hud.windows.weapon].pos.y + used_space.y + window.window_list[hud.windows.weapon].tab_height), size, color_t(225, 225, 225))
                        end
                        used_space.y = used_space.y + text_size.y + 8
                    end
                end
            end
        end
    end

    render.pop_clip()
    window.window_list[hud.windows.weapon].size.y = window.window_list[hud.windows.weapon].tab_height + 8 + used_space.y
end

-- Health Window
window.window_list[hud.windows.health].draw_fn = function()
    local used_space = vec2_t(0, 0)
    
    if (local_player_or_spectating and local_player_or_spectating:is_player() and local_player_or_spectating:is_alive()) then
        render.push_clip(window.window_list[hud.windows.health].pos, window.window_list[hud.windows.health].size)

        local health, armor = local_player_or_spectating:get_prop("m_iHealth"), local_player_or_spectating:get_prop("m_ArmorValue")

        if (armor and health) then
            used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Health - " .. health, hud.windows.health, math.clamp(health, 0, 100) / 100, color_t(255, 128, 132)))
            used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Armor - " .. armor, hud.windows.health, math.clamp(armor, 0, 100) / 100, color_t(128, 181, 255)))
        end

        render.pop_clip()
    end

    window.window_list[hud.windows.health].size = vec2_t(window.window_list[hud.windows.health].size.x, window.window_list[hud.windows.health].tab_height + used_space.y + 8)
end

-- Watermark Window
window.window_list[hud.windows.watermark].draw_fn = function()
    local function watermark_add(text)
        if (text == "") then return "" else return " | " end
    end

    local watermark_text = (hud.context_menus["Watermark"][2]:get(1) and "primordial" or "")
    watermark_text = watermark_text .. (hud.context_menus["Watermark"][2]:get(2) and (watermark_add(watermark_text) .. user.name) or "")
    watermark_text = watermark_text .. (hud.context_menus["Watermark"][2]:get(3) and (watermark_add(watermark_text) .. "uid " .. user.uid) or "")
    watermark_text = watermark_text .. (hud.context_menus["Watermark"][2]:get(4) and (watermark_add(watermark_text) .. math.floor(engine.get_latency(e_latency_flows.OUTGOING) * 1000) .. "ms") or "")
    watermark_text = watermark_text .. (hud.context_menus["Watermark"][2]:get(5) and (watermark_add(watermark_text) .. client.get_fps() .. " fps") or "")

    local text_size = render.get_text_size(window.fonts.segoe_ui_13, watermark_text)

    window.window_list[hud.windows.watermark].pos = vec2_t(screen_size.x - window.window_list[hud.windows.watermark].size.x - 8, 8)

    if (hud.context_menus["Watermark"][1]:get() == 2) then
        window.window_list[hud.windows.watermark].size = vec2_t(16 + text_size.x, 16 + text_size.y)

        render.push_clip(window.window_list[hud.windows.watermark].pos, vec2_t(window.window_list[hud.windows.watermark].size.x, text_size.y + 9))
        render.rect_filled(window.window_list[hud.windows.watermark].pos, window.window_list[hud.windows.watermark].size, color_t(25, 25, 25, 255), 6)
        render.rect_filled(vec2_t(window.window_list[hud.windows.watermark].pos.x, window.window_list[hud.windows.watermark].pos.y + text_size.y + 8), vec2_t(window.window_list[hud.windows.watermark].size.x, 1), global.color, 0)
        render.pop_clip()
    else
        window.window_list[hud.windows.watermark].size = vec2_t(16 + text_size.x, 12 + text_size.y)
    end

    render.push_clip(window.window_list[hud.windows.watermark].pos, window.window_list[hud.windows.watermark].size)
    render.text(window.fonts.segoe_ui_13, watermark_text, vec2_t(window.window_list[hud.windows.watermark].pos.x + 8, window.window_list[hud.windows.watermark].pos.y + 4), color_t(225, 225, 225))
    render.pop_clip()
end

-- Information Window
local information = { max_fps = 0 }

window.window_list[hud.windows.information].draw_fn = function()
    local used_space = vec2_t(0, 0)
    
    render.push_clip(window.window_list[hud.windows.information].pos, window.window_list[hud.windows.information].size)

    if (global.window_references.double_tap[2]:get() or global.window_references.hide_shots[2]:get()) then
        used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Tickbase Charge", hud.windows.information, exploits.get_charge() / exploits.get_max_charge()))
    end

    if (global.window_references.anti_aim[2]:get()) then
        used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Desync", hud.windows.information, math.abs(antiaim.get_real_angle() - antiaim.get_fake_angle()) / antiaim.get_max_desync_range()))
    end

    if (global.window_references.fake_lag:get() > 0) then
        used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Fakelag", hud.windows.information, engine.get_choked_commands() / global.window_references.fake_lag:get()))
    end

    used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "FPS", hud.windows.information, client.get_fps() / information.max_fps))

    if (local_player and local_player:is_player() and local_player:is_alive()) then
        local velocity_modifier = local_player:get_prop("m_flVelocityModifier")

        if (velocity_modifier < 1) then
            used_space = vec2_t(used_space.x, used_space.y + window.add_bar(used_space, "Slowdown", hud.windows.information, math.clamp(1 - velocity_modifier, 0, 1)))
        end
    end

    render.pop_clip()

    window.window_list[hud.windows.information].size = vec2_t(window.window_list[hud.windows.information].size.x, window.window_list[hud.windows.information].tab_height + used_space.y + 8)
end

-- Spectator List Window
window.window_list[hud.windows.spectator].draw_fn = function()
    local cur_entity = entity_list.get_local_player_or_spectating()
    local spectators = {}

    if (cur_entity) then
        local player_tbl = entity_list.get_entities_by_name("CCSPlayer")
        for i, ply in pairs(player_tbl) do
            if (ply and ply ~= cur_entity and ply:is_player() and not ply:is_alive()) then
                local name = ply:get_name()

                if (name ~= "GOTV") then
                    local target = entity_list.get_entity(ply:get_prop("m_hObserverTarget"))
                    if (target and target:is_player()) then
                        local target_index, local_index = target:get_index(), cur_entity:get_index()

                        local shown = hud.context_menus["Spectators"][1]:get()
                        if (shown == 1 and not ply:is_enemy()) then goto skip
                        elseif (shown == 2 and ply:is_enemy()) then goto skip end

                        if (not hud.context_menus["Spectators"][2]:get() and ply == local_player) then goto skip end

                        if (cur_entity:is_player() and cur_entity:is_alive() and local_index == target_index) then
                            table.insert(spectators, name)
                        end

                        ::skip::
                    end
                end
            end
        end
    end

    local used_space = vec2_t(0, 0)
    render.push_clip(window.window_list[hud.windows.spectator].pos, window.window_list[hud.windows.spectator].size)

    for i = 1, #spectators do
        local text_size = render.get_text_size(window.fonts.segoe_ui_13, spectators[i])
        local text_pos = vec2_t(window.window_list[hud.windows.spectator].pos.x + 8, 2 + window.window_list[hud.windows.spectator].pos.y + window.window_list[hud.windows.spectator].tab_height + used_space.y)

        render.text(window.fonts.segoe_ui_13, spectators[i], text_pos, color_t(225, 225, 225))

        used_space = vec2_t(used_space.x, used_space.y + text_size.y + 8)
    end

    render.pop_clip()

    window.window_list[hud.windows.spectator].size = vec2_t(window.window_list[hud.windows.spectator].size.x, window.window_list[hud.windows.spectator].tab_height + used_space.y + 8)
end

-- Keybind Window
local keybind = {
    mode_table = {
        { name = "[Toggle] ", enum = e_keybind_modes.TOGGLE },
        { name = "[Hold] ", enum = e_keybind_modes.HOLD_ON },
        { name = "[Always] ", enum = e_keybind_modes.ALWAYS_ON },
    }
}

window.window_list[hud.windows.keybind].draw_fn = function()
    local used_space, binds, show_mode = vec2_t(0, 0), {}, hud.context_menus["Keybinds"][1]:get()

    local function has_bind(binds, name, index, control, show_mode)
        if (control and control[index]) then
            local value = control[index]:get()

            if (show_mode) then
                for i = 1, #keybind.mode_table do
                    if (keybind.mode_table[i].enum == control[index]:get_mode()) then
                        name = keybind.mode_table[i].name .. name
                    end
                end
            end

            if (value == true) then table.insert(binds, name) end
        end

        return binds
    end

    binds = has_bind(binds, "Double Tap", 2, global.window_references.double_tap, show_mode)
    binds = has_bind(binds, "Hide Shots", 2, global.window_references.hide_shots, show_mode)
    binds = has_bind(binds, "Thirdperson", 2, global.window_references.thirdperson, show_mode)
    binds = has_bind(binds, "Auto Peek", 2, global.window_references.auto_peek, show_mode)
    binds = has_bind(binds, "Body Lean Resolver", 2, global.window_references.body_lean, show_mode)
    binds = has_bind(binds, "Extended Angles", 2, global.window_references.extended_angles, show_mode)
    binds = has_bind(binds, "Edge Jump", 2, global.window_references.edge_jump, show_mode)

    render.push_clip(window.window_list[hud.windows.keybind].pos, window.window_list[hud.windows.keybind].size)

    for i = 1, #binds do
        local text_size = render.get_text_size(window.fonts.segoe_ui_13, binds[i])
        local text_pos = vec2_t(window.window_list[hud.windows.keybind].pos.x + 8, 2 + window.window_list[hud.windows.keybind].pos.y + window.window_list[hud.windows.keybind].tab_height + used_space.y)

        render.text(window.fonts.segoe_ui_13, binds[i], text_pos, color_t(225, 225, 225))

        used_space = vec2_t(used_space.x, used_space.y + text_size.y + 8)
    end
    render.pop_clip()

    window.window_list[hud.windows.keybind].size = vec2_t(window.window_list[hud.windows.keybind].size.x, window.window_list[hud.windows.keybind].tab_height + used_space.y + 8)
end

-- Playerlist Window
local player_list = {} player_list.__index = player_list local selected_ent
player_list.scroll, player_list.scroll_max, player_list.table = vec2_t(0, 0), vec2_t(0, 0), {}
player_list.contains = function(ply)
    for i = 1, #player_list.table do
        if (player_list.table[i].entity == ply) then return true, i end
    end

    return false
end

player_list.repeat_text = {
    blacklist = { "rs", "rank", "top", "ban", "admin", "kick", "addban", "banip", "cancelvote",
                            "cvar", "execcfg", "help", "map", "rcon", "reloadadmins", "unban", "who", "beacon",
                            "burn", "chat", "csay", "gag", "hsay", "msay", "mute", "play", "psay", "rename",
                            "resetcvar", "say", "silence", "slap", "slay", "tsay", "ungag", "unmute", "unsilence",
                            "vote", "votealltalk", "voteban", "voteburn", "voteff", "votegravity", "votekick", "votemap", "voteslay" }
}

function player_list.run_repeat_text(chat, ent)
    local text = chat:gsub(";", "")
    if (string.sub(text, 1, 1) == "/" or string.sub(text, 1, 1) == "!") then
        text = string.sub(text, 2, #text)
    end

    for i = 1, #player_list.repeat_text.blacklist do
        if (string.sub(text, 1, #player_list.repeat_text.blacklist[i]) == player_list.repeat_text.blacklist[i]) then
            text = string.sub(text, #player_list.repeat_text.blacklist[i] + 1, #text)
        end
    end

    engine.execute_cmd("say " .. text)
end

if (global.whitelist.whitelisted) then
    window.window_list[hud.windows.player_list].draw_fn = function()
        window.window_list[hud.windows.player_list].flags.FL_NOMOVE = false
        local valve = game_rules.get_prop("m_bIsValveDS")

        for i = #player_list.table, 1, -1 do
            if (not player_list.table[i].entity or not player_list.table[i].entity:is_player()) then
                table.remove(player_list.table, i)
            end
        end

        if (local_player_or_spectating and local_player_or_spectating:is_player()) then
            render.push_clip(window.window_list[hud.windows.player_list].pos, window.window_list[hud.windows.player_list].size)

            local collumn_size = vec2_t((window.window_list[hud.windows.player_list].size.x - 24) / 4, window.window_list[hud.windows.player_list].size.y - window.window_list[hud.windows.player_list].tab_height - 8)
            render.rect_filled(vec2_t(window.window_list[hud.windows.player_list].pos.x + 8, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2, collumn_size.y), color_t(25, 25, 25, 255), 6)
            render.rect_filled(vec2_t(window.window_list[hud.windows.player_list].pos.x + 16 + collumn_size.x * 2, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2, collumn_size.y), color_t(25, 25, 25, 255), 6)
            render.pop_clip()

            if (input.is_mouse_in_bounds(vec2_t(window.window_list[hud.windows.player_list].pos.x + 8, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2, collumn_size.y))) then
                player_list.scroll.y = math.clamp(player_list.scroll.y + input.get_scroll_delta() * 10, -player_list.scroll_max.y, 0)
            elseif (input.is_mouse_in_bounds(vec2_t(window.window_list[hud.windows.player_list].pos.x + 16 + collumn_size.x * 2, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2, collumn_size.y))) then
                player_list.scroll.x = math.clamp(player_list.scroll.x + input.get_scroll_delta() * 10, -player_list.scroll_max.x, 0)
            end

            local function add_control(name, button, is_enabled, used_space, fn)
                local collumn_size = vec2_t((window.window_list[hud.windows.player_list].size.x - 24) / 4, window.window_list[hud.windows.player_list].size.y - window.window_list[hud.windows.player_list].tab_height - 8)
                local pos = vec2_t(window.window_list[hud.windows.player_list].pos.x + 16 + collumn_size.x * 2, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height + player_list.scroll.x)
                local size = vec2_t(collumn_size.x * 2, collumn_size.y)

                render.push_clip(vec2_t(window.window_list[hud.windows.player_list].pos.x + 16 + collumn_size.x * 2, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2, collumn_size.y))
                local text_size, text_pos = render.get_text_size(window.fonts.segoe_ui_13, name)
                if (button) then
                    text_pos = vec2_t(pos.x + size.x / 2 - text_size.x / 2, pos.y + used_space.x + text_size.y / 4 + 8)
                    render.rect_filled(vec2_t(pos.x + 8, pos.y + used_space.x + 8), vec2_t(size.x - 16, text_size.y + 8), color_t(35, 35, 35, 255), 6)
                else
                    text_pos = vec2_t(pos.x + size.x / 2 - text_size.x / 2, pos.y + used_space.x + text_size.y / 4 + 8)
                    render.rect_filled(vec2_t(pos.x + 8, pos.y + used_space.x + 8), vec2_t(text_size.y + 8, text_size.y + 8), color_t(35, 35, 35, 255), 6)

                    if (is_enabled) then
                        render.rect_filled(vec2_t(pos.x + 12, pos.y + used_space.x + 12), vec2_t(text_size.y, text_size.y), global.color, 6)
                    end
                end

                if (input.is_mouse_in_bounds(vec2_t(window.window_list[hud.windows.player_list].pos.x + 16 + collumn_size.x * 2, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2, collumn_size.y))
                    and input.is_mouse_in_bounds(vec2_t(pos.x + 8, pos.y + used_space.x + 8), vec2_t(size.x - 16, text_size.y + 8))) then
                    window.window_list[hud.windows.player_list].flags.FL_NOMOVE = true
                    render.text(window.fonts.segoe_ui_13, name, text_pos, global.color)

                    if (input.is_key_pressed(e_keys.MOUSE_LEFT) and ply ~= selected_ent) then
                        if (button) then
                            fn()
                        else
                            is_enabled = not is_enabled
                        end
                    end
                else
                    render.text(window.fonts.segoe_ui_13, name, text_pos, color_t(225, 225, 225))
                end
                render.pop_clip()

                used_space.x = used_space.x + text_size.y + 12
                return used_space, is_enabled
            end

            local players, used_space = entity_list.get_players(false), vec2_t(0, 0)
            for _, ply in pairs(players) do
                if (ply ~= local_player) then
                    local text_size = render.get_text_size(window.fonts.segoe_ui_13, ply:has_player_flag(e_player_flags.FAKE_CLIENT) and "BOT - " .. ply:get_name() or ply:get_name())
                    local text_pos = vec2_t(window.window_list[hud.windows.player_list].pos.x + 14, window.window_list[hud.windows.player_list].pos.y + used_space.y + player_list.scroll.y + window.window_list[hud.windows.player_list].tab_height + 6)
                    
                    render.push_clip(vec2_t(window.window_list[hud.windows.player_list].pos.x + 12, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2 - 20, collumn_size.y - 12))
                    if (input.is_mouse_in_bounds(vec2_t(window.window_list[hud.windows.player_list].pos.x + 12, window.window_list[hud.windows.player_list].pos.y + window.window_list[hud.windows.player_list].tab_height), vec2_t(collumn_size.x * 2 - 20, collumn_size.y - 12))
                        and input.is_mouse_in_bounds(vec2_t(text_pos.x, text_pos.y - 2), vec2_t(collumn_size.x * 2 - 20, text_size.y + 4)) or ply == selected_ent) then
                        render.text(window.fonts.segoe_ui_13, ply:has_player_flag(e_player_flags.FAKE_CLIENT) and "BOT - " .. ply:get_name() or ply:get_name(), text_pos, global.color)
                        if (ply ~= selected_ent) then window.window_list[hud.windows.player_list].flags.FL_NOMOVE = true end

                        if (input.is_key_pressed(e_keys.MOUSE_LEFT) and ply ~= selected_ent) then
                            selected_ent = ply
                        end
                    else
                        render.text(window.fonts.segoe_ui_13, ply:has_player_flag(e_player_flags.FAKE_CLIENT) and "BOT - " .. ply:get_name() or ply:get_name(), text_pos, color_t(225, 225, 225))
                    end
                    render.pop_clip()

                    if (ply == selected_ent) then
                        local contained, ind = player_list.contains(ply)
                        if (not contained) then
                            table.insert(player_list.table, {entity = ply, checks = { repeat_chat = false, priority = false, whitelist = false, baim = false, steal_clantag = false }})
                            ind = #player_list.table
                        end

                        used_space, player_list.table[ind].checks.whitelist = add_control("Whitelist", false, player_list.table[ind].checks.whitelist, used_space)
                        used_space, player_list.table[ind].checks.priority = add_control("Priority", false, player_list.table[ind].checks.priority, used_space)
                        used_space, player_list.table[ind].checks.baim = add_control("Force Bodyaim", false, player_list.table[ind].checks.baim, used_space)

                        used_space = add_control("Steal Username", true, nil, used_space, function() cvars.name:set_string(ply:get_name()) end)

                        if (not ply:has_player_flag(e_player_flags.FAKE_CLIENT)) then
                            used_space, player_list.table[ind].checks.steal_clantag = add_control("Steal Clantag", false, player_list.table[ind].checks.steal_clantag, used_space)
                            used_space, player_list.table[ind].checks.repeat_chat = add_control("Repeat Chat", false, player_list.table[ind].checks.repeat_chat, used_space)
                        else
                            used_space = add_control("Kick Bot", true, nil, used_space, function() engine.execute_cmd("kick " .. ply:get_name()) end)
                            used_space = add_control("Kill Bot", true, nil, used_space, function() engine.execute_cmd("kill " .. ply:get_name()) end)
                        end
                    end
                    
                    used_space.y = used_space.y + text_size.y + 4
                end
            end

            player_list.scroll_max = used_space
        end
    end
end

--[[
    Auto Peek Functions
--]]

local auto_peek = {} auto_peek.__index = auto_peek
auto_peek.time = global_vars.real_time() auto_peek.controls = {
    speed = menu.add_slider("Auto Peek", "Speed", 50, 2500, 50, 1, "ms"),
    angle = menu.add_slider("Auto Peek", "Angle", 1, 100, 1, 1, "%"),
}

function auto_peek.run_paint()
    if (global.window_references.auto_peek_2:get()) then
        render.circle_3d(ragebot.get_autopeek_pos(), global.color, 25, 360 * ((auto_peek.time - global_vars.real_time()) / (auto_peek.controls.speed:get() / 1000)), 72, auto_peek.controls.angle:get())
    end
end

--[[
    Logging Functions
--]]

local logging = {} logging.__index = logging
logging.control = menu.add_multi_selection("Logs", "Logged Events", { "Damage", "Bomb", "Item Pickup", "Votes" })
logging.functions = { damage = 1, bomb = 2, item_pickup = 3, votes = 4 }
menu.set_group_column("Logs", 1)

--[[
    Clantag Functions
--]]

local clantag = {} clantag.__index = clantag
clantag.controls = {
    enabled_control = menu.add_checkbox("Clantag", "Enabled", false),
    tag_control = menu.add_text_input("Clantag", "Clantag Text"),
    speed_control = menu.add_slider("Clantag", "Speed", 0.01, 0.99, 0.05, 2),
    hold_control = menu.add_slider("Clantag", "Hold Time", 1, 15),
}
menu.set_group_column("Clantag", 1)

function clantag.animation()
    local tag = clantag.controls.tag_control:get()

    if (tag ~= "" and clantag.controls.enabled_control:get()) then
        local function set_tag(text, ind)
            local spaces = "" for i = 0, string.len(text) do spaces = spaces .. " " end

            local anim = spaces .. text .. spaces
            local i = (global_vars.tick_count() + math.time_to_ticks(engine.get_latency(e_latency_flows.INCOMING))) / math.time_to_ticks(clantag.controls.speed_control:get())
            i = math.floor(i % #ind) i = ind[i + 1] + 1
        
            return string.sub(anim, i, i + string.len(text))
        end

        local indicies, hold_time = {}, clantag.controls.hold_control:get()
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
        if (clan_tag ~= clantag.previous) then client.set_clantag(clan_tag) end
        clantag.previous = clan_tag
    end
end

function clantag.run_paint()
    if (local_player and local_player:is_player() and (not local_player:is_alive()) and global_vars.tick_count() % 2 == 0) then
        clantag.animation()
    end
end

function clantag.run_setup_commands()
    if (engine.get_choked_commands() == 0) then
        clantag.animation()
    end
end

function clantag.run_shutdown()
    client.set_clantag("") 
end

--[[
    Dump API
--]]

local api_dump = {
    table = {}
}

api_dump.dump = function(tbl, ind)
    api_dump.table[tbl] = true
    local s = {}
    local n = 0
    for k in pairs(tbl) do
        n = n + 1
        s[n] = k
    end

    for k, v in ipairs(s) do
        if (not tostring(v):find("weapons")) then
            print(ind, v)
            v = tbl[v]
            if type(v) == "table" and not api_dump.table[v] then
                api_dump.dump(v, ind .. "\t")
            end
        end
    end
end

menu.add_button("General", "Dump API",function() api_dump.dump(_G, "") end)

--[[
    Ragebot FOV
--]]

local rage_fov = {
    control = menu.add_slider("Ragebot", "Aimbot FOV", 0, 180, 1, 0, "°"),
    display = menu.add_checkbox("General", "FOV Flag", false),
}
menu.set_group_column("Ragebot", 2)

rage_fov.run_player_selection = function(ctx)
    local players = entity_list.get_players(true)
    for _, ply in pairs(players) do
        local fov = engine.get_local_fov(ply)

        if (fov > rage_fov.control:get()) then
            ctx:ignore_target(ply:get_index())
        end
    end
end

rage_fov.run_esp = function(ctx)
    if (rage_fov.display:get()) then
        if (not ctx.dormant) then
            ctx:add_flag(tostring(math.floor(engine.get_local_fov(ctx.player))) .. "°")
        end
    end
end

--[[
    Anti-AFK (im too fucking lazy to switch between negative and positive myself)
--]]

local anti_afk = {
    control = menu.add_checkbox("General", "Anti-AFK", false),
}

anti_afk.run_setup_command = function(ctx)
    if (anti_afk.control:get()) then
        ctx:add_button(e_cmd_buttons.RIGHT)
        ctx:add_button(e_cmd_buttons.LEFT)
    end
end

--[[
    Jojosiwa AA
--]]

local jojosiwa_aa = {
    control = menu.add_checkbox("Anti-Aim", "Jojosiwayaw Toggle", false),
    yaw = menu.add_slider("Anti-Aim", "Jojosiwayaw Yaw", -180, 180),
    flip = menu.add_text("Anti-Aim", "Invert Side"),
    init = { initialized = false, yaw_base = 0, yaw_add = 0, extended_offset, extended_type },
}
menu.set_group_column("Anti-Aim", 2)

jojosiwa_aa.flip_keybind = jojosiwa_aa.flip:add_keybind("Penis")

if (global.whitelist.whitelisted) then
    jojosiwa_aa.run_setup_command = function()
        if (local_player and local_player:is_player() and local_player:is_alive()) then
            if (jojosiwa_aa.control:get()) then
                if (not jojosiwa_aa.init.initialized) then
                    jojosiwa_aa.init = { initialized = true, yaw_base = global.window_references.yaw_base:get(), yaw_add = global.window_references.yaw_add:get(),
                                        extended_type = global.window_references.extended_type:get(), extended_offset = global.window_references.extended_offset:get() }
                end

                global.window_references.yaw_base:set(2)
                global.window_references.yaw_add:set(jojosiwa_aa.flip_keybind:get() and 90 or -90)
                global.window_references.extended_type:set(1)
                global.window_references.extended_offset:set(jojosiwa_aa.yaw:get())
            else
                if (jojosiwa_aa.init.initialized) then
                    jojosiwa_aa.init.initialized = false
        
                    global.window_references.yaw_base:set(jojosiwa_aa.init.yaw_base)
                    global.window_references.yaw_add:set(jojosiwa_aa.init.yaw_add)
                    global.window_references.extended_type:set(jojosiwa_aa.init.extended_type)
                    global.window_references.extended_offset:set(jojosiwa_aa.init.extended_offset)
                end
            end
        end
    end
end

--[[
    Game Management Functions
--]]

menu.add_button("Game Management", "Set sv_cheats", function() engine.execute_cmd("sv_cheats 1") end)

menu.add_text("Game Management", "Round Options")
menu.add_button("Game Management", "End Warmup", function() engine.execute_cmd("mp_warmup_end") end)
menu.add_button("Game Management", "Restart Game", function() engine.execute_cmd("mp_restartgame 1") end)
menu.add_button("Game Management", "Max Roundtime", function() engine.execute_cmd("mp_roundtime 60; mp_roundtime_defuse 60; mp_roundtime_deployment 60; mp_roundtime_hostage 60") end)
menu.add_button("Game Management", "Max Starting Money", function() engine.execute_cmd("mp_startmoney 16000") end)

menu.add_text("Game Management", "Bot Options")
menu.add_button("Game Management", "Add CT Bot", function() engine.execute_cmd("bot_add_ct") end)
menu.add_button("Game Management", "Add T Bot", function() engine.execute_cmd("bot_add_t") end)
menu.add_button("Game Management", "Kick Bots", function() engine.execute_cmd("bot_kick") end)
menu.add_button("Game Management", "Toggle Movement", function() engine.execute_cmd("bot_zombie " .. tostring(cvars.bot_zombie:get_int() == 1 and 0 or 1)) end)
menu.set_group_column("Game Management", 2)

--[[
    Anti Advertisement
--]]

local ad_removal = {
    control = menu.add_checkbox("General", "Remove Advertisements", false),
    materials = {
        "decals/custom/uwujka/uwujkapl_logo_01", "decals/custom/14club/logo_decal",
        "decals/liberty/libertymaster", "/brokencore", "decals/intensity/intensity",
    }
}

ad_removal.join_match = function()
    if (ad_removal.control:get()) then
        local removed_materials = 0

        for i = 1, #ad_removal.materials do
            local mat = materials.find(ad_removal.materials[i])

            if (mat) then
                mat:set_flag(e_material_flags.NO_DRAW, true)
                removed_materials = removed_materials + 1
            end
        end

        notification.add("Materials", "Removed " .. removed_materials .. " material advertisements.", 2.5)
    end
end

--[[
    Rainbow HUD
--]]

local rainbow = {
    control = menu.add_checkbox("Rainbow", "Rainbow Colors", false),
    speed = menu.add_slider("Rainbow", "Speed", 0, 100),
    saturation = menu.add_slider("Rainbow", "Saturation", 0, 100),
    brightness = menu.add_slider("Rainbow", "Brightness", 0, 100),
}

menu.set_group_column("Rainbow", 1)

rainbow.run_paint = function()
    local speed = 10 * ((100 - rainbow.speed:get()) / 100)
    local hue = math.clamp(1 * ((global_vars.real_time() - speed * math.floor(global_vars.real_time() / speed)) / speed), 0, 1)

    if (not rainbow.control:get()) then
        global.color = global.window_references.menu_accent_2:get()
    else
        local col = global.window_references.menu_accent_2:get()
        local r, g, b = math.hsb_to_rgb(hue, rainbow.saturation:get(), rainbow.brightness:get())

        global.color = color_t(r, g, b, col.a)
    end
end

--[[
    Legitbot
--]]

local legitbot = {}
if (global.whitelist.whitelisted) then
    legitbot = {
        enabled = menu.add_checkbox("Legitbot", "Master Toggle", false),
        on_key = menu.add_checkbox("Legitbot", "Fire on Key", true),
        visible_check = menu.add_checkbox("Legitbot", "Visible Check", true),
        hitbox_selection = menu.add_multi_selection("Legitbot", "Hitboxes", { "Head", "Body", "Pelvis" }),
        hitbox_priority = menu.add_selection("Legitbot", "Hitboxes", { "Nearest", "Head", "Body", "Pelvis" }),
        minimum_damage = menu.add_slider("Legitbot", "Minimum Damage", 0, 100, 1, 0, "hp"),
        fov = menu.add_slider("Legitbot", "FOV", 0, 45, 0.1, 1, "°"),
        smoothing = menu.add_slider("Legitbot", "Smoothing", 0, 100, 1, 0, "%"),
        smoothing_type = menu.add_selection("Legitbot", "Smoothing Type", { "Linear", "Accelerating" }),
        retarget_time = menu.add_slider("Legitbot", "Retarget Time", 0, 2000, 50, 0, "ms"),
        anti_recoil = menu.add_checkbox("Legitbot", "Anti-Recoil", false),
        anti_recoil_pitch = menu.add_slider("Legitbot", "Anti-Recoil Pitch", 0, 100, 1, 0, "%"),
        anti_recoil_yaw = menu.add_slider("Legitbot", "Anti-Recoil Yaw", 0, 100, 1, 0, "%"),
    }

    local hotkey = legitbot.on_key:add_keybind("Aimbot Key")
    menu.set_group_column("Legitbot", 2)

    legitbot.hitbox_enum = {
        { name = "Head", enum = e_hitboxes.HEAD },
        { name = "Body", enum = e_hitboxes.BODY },
        { name = "Pelvis", enum = e_hitboxes.PELVIS },
    }

    legitbot.target = { target_time = 0, entity = nil }

    legitbot.run_target_selection = function(cmd)
        local enemies, best_fov, hitboxes, visible = entity_list.get_players(true), { ent = nil, fov = 6969 }, legitbot.hitbox_selection:get_items(), legitbot.visible_check:get()
        local priority, max_fov, retarget, minimum_damage = legitbot.hitbox_priority:get(), legitbot.fov:get(), legitbot.retarget_time:get(), legitbot.minimum_damage:get()

        if (global_vars.real_time() - legitbot.target.target_time > retarget / 1000) then
            for _, ply in pairs(enemies) do
                if (ply:is_player() and ply:is_alive() and not ply:is_dormant()) then
                    for i = 1, #legitbot.hitbox_enum do
                        local hitbox_pos = ply:get_hitbox_pos(legitbot.hitbox_enum[i].enum)
                        local fov = engine.get_local_fov(ply, hitbox_pos)
                        local bullet_trace = trace.bullet(local_player:get_eye_position(), hitbox_pos, local_player, ply)

                        if (bullet_trace.damage >= minimum_damage and bullet_trace.damage > 0) then
                            if (not visible or (visible and bullet_trace.pen_count <= 0)) then
                                if (fov <= max_fov) then
                                    if (best_fov.fov > fov) then
                                        best_fov.fov, best_fov.ent, legitbot.target.target_time, legitbot.target.entity = fov, ply, global_vars.real_time(), ply
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            best_fov.ent = legitbot.target.entity
        end

        local best_bone = { pos = nil, fov = 6969, enum = 0 }

        if (best_fov.ent and best_fov.ent:is_player()) then
            if (priority ~= 1) then
                local bone_pos = best_fov.ent:get_hitbox_pos(legitbot.hitbox_enum[priority - 1].enum)
                local fov = engine.get_local_fov(best_fov.ent, bone_pos)
                local bullet_trace = trace.bullet(local_player:get_eye_position(), bone_pos, local_player, best_fov.ent)
                
                if (bullet_trace.damage >= minimum_damage and bullet_trace.damage > 0) then
                    if (not visible or (visible and bullet_trace.pen_count <= 0)) then
                        if (fov <= max_fov) then
                            best_bone.fov, best_bone.pos, best_bone.enum = fov, bone_pos, i
                            goto hop
                        end
                    end
                end
            end

            function contains_hitbox(hitboxes, hitbox)
                for i = 1, #hitboxes do
                    if (hitboxes[i] == hitbox) then
                        if (legitbot.hitbox_selection:get(i)) then
                            return true
                        end
                    end
                end

                return false
            end

            for i = 1, #legitbot.hitbox_enum do
                if (contains_hitbox(hitboxes, legitbot.hitbox_enum[i].name)) then
                    local bone_pos = best_fov.ent:get_hitbox_pos(legitbot.hitbox_enum[i].enum)
                    local fov = engine.get_local_fov(best_fov.ent, bone_pos)
                    local bullet_trace = trace.bullet(local_player:get_eye_position(), bone_pos, local_player, best_fov.ent)

                    if (bullet_trace.damage >= minimum_damage and bullet_trace.damage > 0) then
                        if (not visible or (visible and bullet_trace.pen_count <= 0)) then
                            if (fov <= max_fov) then
                                if (best_bone.fov > fov) then
                                    best_bone.fov, best_bone.pos, best_bone.enum = fov, bone_pos, i
                                end
                            end
                        end
                    end
                end
            end

            ::hop::

            if (best_bone.enum and best_bone.pos and best_bone.fov and best_fov.fov and best_fov.ent) then
                return { bone = best_bone.enum, pos = best_bone.pos, bone_fov = best_bone.fov, player_fov = best_fov.fov, entity = best_fov.ent }
            end
        end
    end

    legitbot.run = function(cmd)
        if (legitbot.enabled:get() and (not legitbot.on_key:get() or (legitbot.on_key:get() and hotkey:get()))) then
            local target = legitbot.run_target_selection(cmd)

            if (target and target.entity and target.entity:is_player() and target.entity:is_alive()) then
                local local_head = local_player:get_eye_position()
                local aim_angle = target.pos:to_angle(local_head)

                local punch_angle = local_player:get_prop("m_aimPunchAngle")
                punch_angle = angle_t(punch_angle.x * (legitbot.anti_recoil_pitch:get() / 100) * 2, punch_angle.y * (legitbot.anti_recoil_pitch:get() / 100) * 2, 0)

                local relative_angle = cmd.viewangles - (legitbot.anti_recoil:get() == true and (aim_angle - punch_angle):normalize() or aim_angle:normalize())
                local angle = angle_t(relative_angle.x / relative_angle:length(), relative_angle.y / relative_angle:length(), 0)

                if (legitbot.smoothing_type:get() == 1) then
                    angle = angle_t(angle.x * (1 - (legitbot.smoothing:get() / 100)), angle.y * (1 - (legitbot.smoothing:get() / 100)), 0)
                else
                    angle = angle_t(angle.x / legitbot.smoothing:get() / (target.bone_fov / legitbot.fov:get()), angle.y / legitbot.smoothing:get() / (target.bone_fov / legitbot.fov:get()), 0)
                end

                if (angle:length() > relative_angle:length()) then
                    angle = relative_angle
                end

                if (angle.x ~= INF and angle.y ~= INF and angle.x == angle.x and angle.y == angle.y) then
                    engine.set_view_angles((cmd.viewangles - angle):normalize())
                end
            end
        end
    end
end

--[[
    Callbacks
--]]

if (global.whitelist.whitelisted) then
    notification.add("Whitelisted User", "Welcome " .. user.name .. ", you are included in the jojosiwa whitelist and have access to all features.", 10)
    client.log(global.color, "jojosiwa.lua | ", color_t(255, 255, 255), "Welcome " .. user.name .. ", you are included in the jojosiwa whitelist and have access to all features.")
end

callbacks.add(e_callbacks.PAINT, function()
    local_player, local_player_or_spectating, screen_size = entity_list.get_local_player(), entity_list.get_local_player_or_spectating(), render.get_screen_size()
    callback.run_paint()
    auto_peek.run_paint()
    clantag.run_paint()
    rainbow.run_paint()

    if (client.get_fps() > information.max_fps) then information.max_fps = client.get_fps() end

    render.pop_clip()
    window.run_windows()
    if (hud.toggles.notifications:get()) then notification.run() end

    local mm, mm2 = input.find_key_bound_to_binding("messagemode"), input.find_key_bound_to_binding("messagemode2")
    if (mm and mm2 and hud.chatbox.chatting == 0) then if (input.is_key_pressed(mm)) then hud.chatbox.chatting = 1 elseif (input.is_key_pressed(mm2)) then hud.chatbox.chatting = 2 end end
    if (input.is_key_pressed(e_keys.KEY_ESCAPE) or not engine.is_app_active() or menu.is_open() or not hud.controls:get(hud.toggles.chat)) then hud.chatbox.chatting = 0 hud.chatbox.chat_message = "" end

    window.window_list[hud.windows.chat].flags.FL_NODRAW = (client.get_unix_time() - hud.chatbox.last_message >= 5 and not menu.is_open() and (hud.chatbox.chatting == 0)) and true or false

    if (hud.override_hud:get()) then cvars.cl_draw_only_deathnotices:set_int(1) else cvars.cl_draw_only_deathnotices:set_int(0) end

    if (global.whitelist.whitelisted) then window.window_list[hud.windows.player_list].flags.FL_NODRAW = not menu.is_open() end

    if (not local_player or not local_player_or_spectating) then
        player_list.table = {}
        hud.team_damage.damage, hud.team_damage.kills = 0, 0
    end
end)

callbacks.add(e_callbacks.SETUP_COMMAND, function(cmd)
    clantag.run_setup_commands()
    if (global.whitelist.whitelisted) then jojosiwa_aa.run_setup_command() end
    anti_afk.run_setup_command(cmd)
    if (global.whitelist.whitelisted) then legitbot.run(cmd) end

    if (hud.chatbox.chatting ~= 0) then
        cmd.move.x, cmd.move.y = 0, 0
        cmd:clear_buttons(0)
    end
end)

callbacks.add(e_callbacks.RUN_COMMAND, function(cmd)
    
end)

callbacks.add(e_callbacks.SHUTDOWN, function()
    clantag.run_shutdown()
end)

callbacks.add(e_callbacks.DRAW_WATERMARK, function(ctx) if (hud.override_primordial:get()) then return "" else return ctx end end)

callbacks.add(e_callbacks.EVENT, function(e)
    if (e.userid and type(e.userid) == "number") then
        local ent = entity_list.get_player_from_userid(e.userid)

        if (ent and ent:is_player()) then
            if (e.name == "player_say" or e.name == "player_chat") then
                local dead, text, teamchat, name, team = not ent:is_alive(), e.text, e.teamonly, ent:get_name(), ent:get_prop("m_iTeamNum")

                if (#hud.chatbox.logs >= 6) then
                    for i = 1, #hud.chatbox.logs - 5 do
                        table.remove(hud.chatbox.logs, 1)
                    end
                end
            
                hud.chatbox.last_message = client.get_unix_time()
                table.insert(hud.chatbox.logs, { text = text, dead = dead, teamchat = teamchat, team = team, name = name})

                if (ent ~= local_player) then
                    local contains, ind = player_list.contains(ent)

                    if (contains and player_list.table[ind].checks.repeat_chat) then
                        player_list.run_repeat_text(e.text)
                    end
                end
            elseif (e.name == "player_hurt") then
                local attacker, name, damage, health = entity_list.get_player_from_userid(e.attacker), "", e.dmg_health, e.health

                if (damage and health and local_player and local_player:is_player() and attacker == local_player) then
                    if (not ent:is_enemy()) then
                        hud.team_damage.damage = hud.team_damage.damage + damage
                    end

                    if (logging.control:get(logging.functions.damage)) then
                        name = ent:get_name()

                        if (health > 0) then
                            notification.add("Hurt", "You hit " .. name .. " for " .. damage .. " health.", 3.5)
                        else
                            notification.add("Killed", "You killed " .. name .. ".", 5)
                        end
                    end
                end
            elseif (e.name == "player_death") then
                local attacker = entity_list.get_player_from_userid(e.attacker)

                if (local_player and local_player:is_player() and attacker == local_player) then
                    if (not ent:is_enemy()) then
                        hud.team_damage.kills = hud.team_damage.kills + 1
                    end
                end
            elseif (e.name == "player_footstep") then
                if (ent == local_player) then
                    hud.steps.count = hud.steps.count + 1
                end
            elseif (e.name == "bomb_planted") then
                if (logging.control:get(logging.functions.bomb) and local_player and local_player:is_player()) then
                    local name = ent:get_name()
                    notification.add("Planted", name .. " planted the bomb.", 5)
                end
            elseif (e.name == "bomb_defused") then
                if (logging.control:get(logging.functions.bomb) and local_player and local_player:is_player()) then
                    local name = ent:get_name()
                    notification.add("Defused", name .. " defused the bomb.", 5)
                end
            elseif (e.name == "item_pickup") then
                local item = e.item

                if (logging.control:get(logging.functions.item_pickup) and local_player and local_player:is_player() and ent == local_player) then
                    notification.add("Picked Up", "You just picked up " .. item .. ".", 5)
                end
            elseif (e.name == "vote_cast") then
                local name = ent:get_name()

                if (logging.control:get(logging.functions.votes)) then
                    if (e.vote_option == 0) then
                        notification.add("Vote", name ..  "Just voted YES in a vote.", 7.5)
                    else
                        notification.add("Vote", name ..  "Just voted NO in a vote.", 7.5)
                    end
                end
            elseif (e.name == "player_connect_full") then
                ad_removal.join_match()
            end
        end
    end
end)

callbacks.add(e_callbacks.TARGET_SELECTION, function(ctx, cmd, unpredicted_data)
    for i = 1, #player_list.table do
        if (player_list.table[i].entity and player_list.table[i].entity:is_player()) then
            if (player_list.table[i].checks.whitelist) then
                ctx:ignore_target(player_list.table[i].entity:get_index())
            else
                if (player_list.table[i].checks.priority) then
                    ctx:force_target(player_list.table[i].entity:get_index(), 1000)
                end
            end
        end
    end

    rage_fov.run_player_selection(ctx)
end)

callbacks.add(e_callbacks.HITSCAN, function(ctx, cmd, unpredicted_data)
    local contained, ind = player_list.contains(ctx.player)

    if (contained) then
        if (player_list.table[ind].checks.baim) then
            ctx:set_hitscan_group_state(e_hitscan_groups.HEAD, false)
            ctx:set_hitscan_group_state(e_hitscan_groups.ARMS, false)
            ctx:set_hitscan_group_state(e_hitscan_groups.LEGS, false)
            ctx:set_hitscan_group_state(e_hitscan_groups.FEET, false)
        end
    end
end)

callbacks.add(e_callbacks.PLAYER_ESP, function(ctx)
    rage_fov.run_esp(ctx)
end)
