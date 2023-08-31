--$$\        $$$$$$\  $$\   $$\  $$$$$$\  $$$$$$$$\ 
--$$ |      $$  __$$\ $$$\  $$ |$$  __$$\ $$  _____|
--$$ |      $$ /  $$ |$$$$\ $$ |$$ /  \__|$$ |      
--$$ |      $$$$$$$$ |$$ $$\$$ |$$ |      $$$$$\    
--$$ |      $$  __$$ |$$ \$$$$ |$$ |      $$  __|   
--$$ |      $$ |  $$ |$$ |\$$$ |$$ |  $$\ $$ |      
--$$$$$$$$\ $$ |  $$ |$$ | \$$ |\$$$$$$  |$$$$$$$$\ 
--\________|\__|  \__|\__|  \__| \______/ \________|
-- coded by Lance/stonerchrist on Discord

util.require_natives("2944a", "g")

local root = menu.my_root()
local insight_max_dist = 20
local hash_cache = {}
local ent_cache = {}
local insight_scale = 0.5
local insight_show_hp = true 
local insight_show_name = true
local insight_show_heading = true
local insight_show_speed = true 
local insight_show_owner = true 
local insight_show_invincible = true
local insight_show_language = true 
local insight_show_pid = true 
local insight_show_rank = true
local insight_show_money = true
local insight_on_vehicles = false
local insight_on_peds = true 
local insight_on_players = true 
local insight_show_kd = true
local insight_on_objects = false
local insight_show_wanted = true 
local insight_alignment = 4

local white = {r = 1.0, g = 1.0, b = 1, a = 0.6}
local green = {r = 0.0, g = 1.0 , b = 0,0, a = 0.6}
local cyan = {r = 0, g = 1, b = 1, a = 0.6}
local orange = {r = 0.7, g = 0.3, b = 0.0, a = 0.6}
local red = {r = 1.0, g = 0.0, b = 0.0, a = 0.6}

local function world_to_screen_coords(x, y, z)
    sc_x = memory.alloc(8)
    sc_y = memory.alloc(8)
    GET_SCREEN_COORD_FROM_WORLD_COORD(x, y, z, sc_x, sc_y)
    local ret = {
        x = memory.read_float(sc_x),
        y = memory.read_float(sc_y)
    }
    return ret
end

local function get_model_size(hash)
    local minptr = memory.alloc(24)
    local maxptr = memory.alloc(24)
    local min = {}
    local max = {}
    GET_MODEL_DIMENSIONS(hash, minptr, maxptr)
    min.x, min.y, min.z = v3.get(minptr)
    max.x, max.y, max.z = v3.get(maxptr)
    local size = {}
    size.x = max.x - min.x
    size.y = max.y - min.y
    size.z = max.z - min.z
    size['max'] = math.max(size.x, size.y, size.z)
    return size
end

function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  end

function lang_num_to_name(num) 
    local langs =
    {
        'English',
        'French', 
        'German',
        'Spanish',
        'Portuguese',
        'Polish',
        'Russian',
        'Korean',
        'Chinese (Traditional)',
        'Japanese', 
        'Mexican', 
        'Chinese (Simplified)'
    }

    if langs[num + 1] == nil then 
        return '???'
    else
        return langs[num + 1]
    end
end

function get_info_of_entity(ptr)
    if table.contains(ent_cache, ptr) then 
        return ent_cache[ptr] 
    end
    local ent = entities.pointer_to_handle(ptr)

    local info = {}
    info.health = GET_ENTITY_HEALTH(ent)
    info.hdl = ent
    info.max_health = GET_ENTITY_MAX_HEALTH(ent)
    info.heading = GET_ENTITY_HEADING(ent)
    info.size = get_model_size(GET_ENTITY_MODEL(ent))
    info.pos = v3.new(GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ent, 0.0, 0.0, info.size.z / 1.5))
    info.invincible = not GET_ENTITY_CAN_BE_DAMAGED(ent)
    info.speed = GET_ENTITY_SPEED(ent)
    info.owner = entities.get_owner(ent)

    if IS_PED_A_PLAYER(ent) then 
        local pid = NETWORK_GET_PLAYER_INDEX_FROM_PED(ent)
        info.name = players.get_name_with_tags(pid)
        info.pid = pid
        info.rank = players.get_rank(pid)
        info.money = players.get_money(pid)
        info.kd = math.floor(players.get_kd(pid) * 100)/100
        info.language = lang_num_to_name(players.get_language(pid))
        info.wanted_level = GET_PLAYER_WANTED_LEVEL(pid)
        info.invincible = players.is_godmode(pid)
    else
        local mdl = GET_ENTITY_MODEL(ent) 
        if table.contains(hash_cache, mdl) then 
            info.name = hash_cache[mdl] 
        else 
            info.name = util.reverse_joaat(mdl) 
            hash_cache[mdl] = info.name
        end
        if IS_ENTITY_A_PED(ent) then 
            info.money = GET_PED_MONEY(ent)
        end
    end
        
    ent_cache[ptr] = info
    return info 
end


root:slider("Max distance", {'insightmaxdist'}, '', 1, 200, 20, 1, function(dist)
    insight_max_dist = dist
end)

root:slider_float("Scale", {'insightscale'}, '', 1, 1000, 5, 1, function(scale)
    insight_scale = scale * 0.1
end)


root:divider("Display ")
root:toggle('HP', {'insighthp'}, '', function(on)
    insight_show_hp = on
end, true)

root:toggle('Name', {'insightname'}, '', function(on)
    insight_show_name = on
end, true)

root:toggle('Heading', {'insightheading'}, '', function(on)
    insight_show_heading = on
end, true)

root:toggle('Speed', {'insightspeed'}, '', function(on)
    insight_show_speed = on
end, true)


root:toggle('Owner', {'insightowner'}, '', function(on)
    insight_show_owner = on
end, true)

root:toggle('Money', {'insightmoney'}, '', function(on)
    insight_show_money = on
end, true)

root:toggle('Language', {'insightlanguage'}, '', function(on)
    insight_show_language = on
end, true)

root:toggle('Wanted level', {'insightwanted'}, '', function(on)
    insight_show_wanted = on
end, true)


root:toggle('If invincible', {'insightinvincible'}, '', function(on)
    insight_show_invincible = on
end, true)

root:toggle('PID', {'insightpid'}, '', function(on)
    insight_show_pid = on
end, true)

root:toggle('K/D', {'insightkd'}, '', function(on)
    insight_show_kd = on
end, true)


root:toggle('Rank', {'insightrank'}, '', function(on)
    insight_show_rank = on
end, true)

root:divider("Display info about..")

root:toggle('Vehicles', {'insightvehicles'}, '', function(on)
    insight_on_vehicles = on 
end, false)

root:toggle('Peds', {'insightpeds'}, '', function(on)
    insight_on_peds = on    
end, true)

root:toggle('Players', {'insightpeds'}, '', function(on)
    insight_on_players = on    
end, true)

root:toggle('Objects', {'insightobjects'}, '', function(on)
    insight_on_objects = on    
end, false)

function get_hp_color(hp, max_hp) 
    local perc = math.ceil((hp / max_hp)*100)
    if perc >= 100 then
        return green 
    elseif perc < 100 and perc >= 50 then 
        return orange
    else
        return red 
    end
end 

-- credit to https://stackoverflow.com/questions/10989788/format-integer-in-lua
function format_int(number)

    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  
    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1,")
  
    -- reverse the int-string back remove an optional comma and put the 
    -- optional minus and fractional part back
    return minus .. int:reverse():gsub("^,", "") .. fraction
  end

util.create_tick_handler(function()
    local ent_collection = {}

    if insight_on_peds or insight_on_players then 
        for _, ped in pairs(entities.get_all_peds_as_pointers()) do
            local c1 = players.get_cam_pos(players.user())
            local c2 = v3.new(entities.get_position(ped))
            if v3.distance(c1, c2) < insight_max_dist then
                if insight_on_players and not insight_on_peds then 
                    if IS_PED_A_PLAYER(entities.pointer_to_handle(ped)) then  
                        ent_collection[#ent_collection+1] = get_info_of_entity(ped)
                    end
                elseif insight_on_peds and not insight_on_players then 
                    if not IS_PED_A_PLAYER(entities.pointer_to_handle(ped)) then 
                        ent_collection[#ent_collection+1] = get_info_of_entity(ped)
                    end
                else
                    ent_collection[#ent_collection+1] = get_info_of_entity(ped)
                end
            end
        end
    end

    if insight_on_vehicles then 
        for _, veh in pairs(entities.get_all_vehicles_as_pointers()) do
            local c1 =  players.get_cam_pos(players.user())
            local c2 = v3.new(entities.get_position(veh))
            if v3.distance(c1, c2) < insight_max_dist then
                ent_collection[#ent_collection+1] = get_info_of_entity(veh)
            end
        end
    end

    if insight_on_objects then 
        for _, obj in pairs(entities.get_all_objects_as_pointers()) do
            local c1 =  players.get_cam_pos(players.user())
            local c2 = v3.new(entities.get_position(obj))
            if v3.distance(c1, c2) < insight_max_dist then
                ent_collection[#ent_collection+1] = get_info_of_entity(obj)
            end
        end
    end

    for _, info in pairs(ent_collection) do 
        local line_spacing = insight_scale /  30
        local cur_y_off = line_spacing
        if info.hdl ~= players.user_ped() then 
            local info_pos = world_to_screen_coords(info.pos.x, info.pos.y, info.pos.z)
            if insight_show_name then 
                directx.draw_text(info_pos.x, info_pos.y + cur_y_off, tostring(info.name), insight_alignment, insight_scale, white, false, nil)
                cur_y_off += line_spacing
            end

            if insight_show_hp then 
                local hp_color = get_hp_color(info.health, info.max_health)
                directx.draw_text(info_pos.x, info_pos.y + cur_y_off, tostring(info.health) .. '/' .. tostring(info.max_health) .. ' HP', insight_alignment, insight_scale, hp_color, false, nil)
                cur_y_off += line_spacing
            end

            if insight_show_heading then 
                directx.draw_text(info_pos.x, info_pos.y + cur_y_off, tostring(math.ceil(info.heading)) .. '°', insight_alignment, insight_scale, white, false, nil)
                cur_y_off += line_spacing
            end

            if insight_show_invincible then 
                if info.invincible then 
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, 'Invincible', insight_alignment, insight_scale, green, false, nil)
                    cur_y_off += line_spacing
                end
            end

            if insight_show_speed then 
                if info.speed > 0 then 
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, tostring(math.ceil(info.speed)) .. ' m/s', insight_alignment, insight_scale, cyan, false, nil)
                    cur_y_off += line_spacing
                end
            end

            if IS_PED_A_PLAYER(info.hdl) then 
                if insight_show_pid then 
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, 'PID: ' .. tostring(info.pid), insight_alignment, insight_scale, white, false, nil)
                    cur_y_off += line_spacing
                end

                if insight_show_rank then 
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, 'Rank: ' .. tostring(info.rank), insight_alignment, insight_scale, white, false, nil)
                    cur_y_off += line_spacing
                end

                if insight_show_kd then 
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, tostring(info.kd) .. ' KD', insight_alignment, insight_scale, white, false, nil)
                    cur_y_off += line_spacing
                end

                if insight_show_language then
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, 'Speaks ' ..  info.language, insight_alignment, insight_scale, cyan, false, nil)
                    cur_y_off += line_spacing
                end 
                
                if insight_show_wanted then 
                    if info.wanted_level > 0 then 
                        directx.draw_text(info_pos.x, info_pos.y + cur_y_off, tostring(info.wanted_level) .. ' stars', insight_alignment, insight_scale, red, false, nil)
                        cur_y_off += line_spacing
                    end
                end
            else 
                if insight_show_owner then 
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, 'Owner: ' .. players.get_name(info.owner), insight_alignment, insight_scale, white, false, nil)
                    cur_y_off += line_spacing
                end
            end
            
            if IS_ENTITY_A_PED(info.hdl) then 
                if insight_show_money then 
                    directx.draw_text(info_pos.x, info_pos.y + cur_y_off, '$' .. format_int(info.money), insight_alignment, insight_scale, green, false, nil)
                    cur_y_off += line_spacing
                end
            end

        end
    end
end)

menu.my_root():divider('')
menu.my_root():hyperlink('Join Discord', 'https://discord.gg/zZ2eEjj88v', '')