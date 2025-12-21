local trading_sessions = {}

local function get_partner(name)
    local s = trading_sessions[name]
    if not s then return nil end
    return (s.p1 == name) and s.p2 or s.p1
end

local function abort_trade(p1_name, p2_name)
    local names = {p1_name, p2_name}
    for _, name in ipairs(names) do
        local inv = minetest.get_inventory({type="detached", name="trade_"..name})
        local player = minetest.get_player_by_name(name)
        if inv and player then
            for i=1, inv:get_size("main") do
                local stack = inv:get_stack("main", i)
                if not stack:is_empty() then
                    player:get_inventory():add_item("main", stack)
                end
            end
        end
        minetest.close_formspec(name, "mymoney:trade_ui")
        trading_sessions[name] = nil
    end
end

local function update_trade_formspec(player_name)
    local s = trading_sessions[player_name]
    if not s then return end
    
    local p1_lock = s.p1_locked and "#00FF00[LOCKED]" or "#FFCC00[EDITING...]"
    local p2_lock = s.p2_locked and "#00FF00[LOCKED]" or "#FFCC00[EDITING...]"

    local function get_form(me, him, my_locked, his_locked)
        return "size[10,10]bgcolor-[#2b2b2bff;true]" ..
            "label[0.5,0.2;YOUR OFFER ("..me..")]" ..
            "list[detached:trade_"..me..";main;0.5,0.7;4,4;]" ..
            "button[0.5,4.8;4,0.8;lock;"..my_locked.."]" ..
            "label[5.5,0.2;"..him.."'S OFFER]" ..
            "list[detached:trade_"..him..";main;5.5,0.7;4,4;]" ..
            "label[5.5,4.8;"..his_locked.."]" ..
            "button[2.5,5.8;2,0.8;cancel;#FF0000CANCEL]" ..
            "list[current_player;main;1,6.5;8,4;]" ..
            ((s.p1_locked and s.p2_locked) and "button[5.5,5.8;2,0.8;confirm;#00FF00CONFIRM]" or "")
    end

    minetest.show_formspec(s.p1, "mymoney:trade_ui", get_form(s.p1, s.p2, p1_lock, p2_lock))
    minetest.show_formspec(s.p2, "mymoney:trade_ui", get_form(s.p2, s.p1, p2_lock, p1_lock))
end

minetest.register_node("mymoney:trade_table", {
    description = "Secure Trading Table",
    tiles = {"mymoney_trade_table.png"},
    drawtype = "mesh",
    mesh = "mymoney_trade_table.obj",
    paramtype2 = "facedir",
    groups = {cracky=2},
	selection_box = {
		type = "fixed",
		fixed = {{-0.5,-0.5,-0.5,0.5,0.1,0.5}}
	},
    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        
        if trading_sessions[name] then return end

        local objs = minetest.get_objects_inside_radius(pos, 3)
        local target = nil
        
        for _, obj in pairs(objs) do
            local n = obj:get_player_name()
            if n ~= "" and n ~= name then target = n break end
        end

        if not target then
            minetest.chat_send_player(name, "You need a partner nearby to trade!")
            return
        end

        local function setup_inv(pname)
            local inv = minetest.create_detached_inventory("trade_"..pname, {
                allow_put = function(inv, listname, index, stack, player)
                    local sess = trading_sessions[pname]
                    if sess and (sess.p1_locked or sess.p2_locked) then return 0 end
                    return stack:get_count()
                end,
                on_put = function() update_trade_formspec(pname) end,
                on_take = function() update_trade_formspec(pname) end,
            })
            inv:set_size("main", 16)
            inv:set_list("main", {})
        end

        setup_inv(name)
        setup_inv(target)
        
        trading_sessions[name] = {p1=name, p2=target, p1_locked=false, p2_locked=false, pos=pos}
        trading_sessions[target] = trading_sessions[name]
        
        minetest.chat_send_player(target, name .. " wants to trade with you!")
        update_trade_formspec(name)
    end,
})

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 1 then return end
    timer = 0
    for name, s in pairs(trading_sessions) do
        if s.p1 == name then
            local p1 = minetest.get_player_by_name(s.p1)
            local p2 = minetest.get_player_by_name(s.p2)
            if not p1 or not p2 or p1:get_pos():distance(s.pos) > 5 or p2:get_pos():distance(s.pos) > 5 then
                abort_trade(s.p1, s.p2)
            end
        end
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "mymoney:trade_ui" then return end
    local name = player:get_player_name()
    local s = trading_sessions[name]
    if not s then return end

    if fields.cancel then
        abort_trade(s.p1, s.p2)
    elseif fields.lock then
        minetest.sound_play("default_click", {to_player=name, gain=0.5})
        if s.p1 == name then s.p1_locked = not s.p1_locked else s.p2_locked = not s.p2_locked end
        update_trade_formspec(name)
    elseif fields.confirm then
        local inv1 = minetest.get_inventory({type="detached", name="trade_"..s.p1})
        local inv2 = minetest.get_inventory({type="detached", name="trade_"..s.p2})
        local p1o = minetest.get_player_by_name(s.p1)
        local p2o = minetest.get_player_by_name(s.p2)

        for i=1,16 do
            p1o:get_inventory():add_item("main", inv2:get_stack("main", i))
            p2o:get_inventory():add_item("main", inv1:get_stack("main", i))
        end
        
        trading_sessions[s.p1] = nil
        trading_sessions[s.p2] = nil
        minetest.close_formspec(s.p1, "")
        minetest.close_formspec(s.p2, "")
        
        minetest.sound_play("default_place_node", {pos=s.pos, gain=1.0})
        minetest.chat_send_player(s.p1, "Trade completed successfully!")
        minetest.chat_send_player(s.p2, "Trade completed successfully!")
    end
end)
minetest.register_craft({
    output = "mymoney:trade_table",
    recipe = {
        {"group:wood", "group:wood",          "group:wood"},
        {"group:wood", "default:steel_ingot", "group:wood"},
        {"default:fence_wood", "",            "default:fence_wood"},
    }
})
