if not mymoney then mymoney = {} end
mymoney.current_shop = {}

local function get_item_desc(itemname)
    if not itemname or itemname == "" then return "Empty" end
    local def = minetest.registered_items[itemname]
    if def and def.description then
        local desc = def.description:split("\n")[1]
        if #desc > 14 then return desc:sub(1, 12) .. ".." end
        return desc
    end
    local parts = itemname:split(":")
    return parts[2] or itemname
end

local function get_shop_bg(width, height)
    return "size["..width..","..height.."]" ..
        "bgcolor-[#2b2b2bff;true]" ..
        "gui_bg[;listcolors[#444444ff;#555555ff;#222222ff;#33cc33ff;#cc3333ff]]"
end

local function show_sales_log(name, pos)
    local meta = minetest.get_meta(pos)
    local log = meta:get_string("sales_log")
    if log == "" then log = "No sales recorded yet." end
    
    minetest.show_formspec(name, "mymoney:shop_log", get_shop_bg(7, 7.5) ..
        "label[0.5,0.5;RECENT SALES LOG:]" ..
        "textarea[0.5,1.2;5,5;log_text;;" .. minetest.formspec_escape(log) .. "]" ..
        "button[0.5,6.5;2,0.8;clear_log;Clear Log]" ..
        "button[3.5,6.5;2,0.8;back_to_shop;Back]")
end

minetest.register_node("mymoney:shop", {
    description = "Universal Shop",
    tiles = {
        "mymoney_shop.png"
    },
    paramtype2 = "facedir",
    groups = {cracky=2},

    after_place_node = function(pos, placer)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        meta:set_string("owner", placer:get_player_name())
        meta:set_string("infotext", "Shop (Owner: " .. placer:get_player_name() .. ")")
        meta:set_string("sales_log", "") 
        inv:set_size("stock", 10)    
        inv:set_size("prices", 10)   
        inv:set_size("earnings", 12) 
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local name = player:get_player_name()
        local owner = meta:get_string("owner")

        if name ~= owner and not minetest.check_player_privs(name, {protection_bypass=true}) then
            minetest.chat_send_player(name, "Only the owner ("..owner..") can dig this!")
            return false
        end

        if not inv:is_empty("stock") or not inv:is_empty("prices") or not inv:is_empty("earnings") then
            minetest.chat_send_player(name, "You must empty the Stock, Prices, and Earnings before digging!")
            return false
        end
        return true
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if player:get_player_name() == minetest.get_meta(pos):get_string("owner") then return stack:get_count() end
        return 0
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if player:get_player_name() == minetest.get_meta(pos):get_string("owner") then return stack:get_count() end
        return 0
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if player:get_player_name() == minetest.get_meta(pos):get_string("owner") then return count end
        return 0
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        local loc = "nodemeta:"..pos.x..","..pos.y..","..pos.z
        mymoney.current_shop[name] = pos 

        if name == owner and not clicker:get_player_control().aux1 then
            minetest.show_formspec(name, "mymoney:shop_owner", get_shop_bg(10, 11.5) ..
                "label[0.5,0.2;SHOP MANAGEMENT ("..owner..")]" ..
                "label[1.5,0.8;STOCK]list["..loc..";stock;0.5,1.2;5,2;]" ..
                "label[1.5,3.6;PRICES]list["..loc..";prices;0.5,4.0;5,2;]" ..
                "label[6.5,0.8;EARNINGS]list["..loc..";earnings;6.5,1.2;3,4;]" ..
                "button[6.5,5.5;3,0.8;view_log;VIEW SALES LOG]" ..
                "list[current_player;main;1,7.0;8,4;]" ..
                "listring["..loc..";stock]listring[current_player;main]")
        else
            local form = get_shop_bg(10, 11.5) ..
                "label[3.0,0.2;SHOP OWNER: " .. owner .. "]" ..
                "label[0.5,0.8;Item Name]label[2.0,0.8;Price]label[5.0,0.8;Item Name]label[6.5,0.8;Price]"

            local inv = meta:get_inventory()
            for i = 1, 10 do
                local row = math.floor((i-1) / 2)
                local col = (i-1) % 2
                local y = 1.3 + (row * 1)
                local x_off = col * 4.5
                local s_stack = inv:get_stack("stock", i)
                local p_stack = inv:get_stack("prices", i)
                form = form .. "item_image["..(0.5+x_off)..","..(y-0.2)..";1,1;"..s_stack:get_name().."]"
                form = form .. "item_image["..(2.0+x_off)..","..(y-0.2)..";1,1;"..p_stack:get_name().."]"
                form = form .. "label["..(0.5+x_off)..","..(y+0.6)..";" .. get_item_desc(s_stack:get_name()) .. "]"
                if not s_stack:is_empty() and not p_stack:is_empty() then
                    form = form .. "button["..(3.2+x_off)..","..(y+0.1)..";1.1,0.8;buy_"..i..";BUY]"
                else
                    form = form .. "button["..(3.2+x_off)..","..(y+0.1)..";1.1,0.8;disabled;---]"
                end
            end
            form = form .. "list[current_player;main;1,7.0;8,4;]"
            minetest.show_formspec(name, "mymoney:shop_customer", form)
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local pos = mymoney.current_shop[name]
    if not pos then return end

    if fields.view_log then
        show_sales_log(name, pos)
        return
    elseif fields.clear_log then
        minetest.get_meta(pos):set_string("sales_log", "")
        show_sales_log(name, pos)
        return
    elseif fields.back_to_shop then
        local node = minetest.get_node(pos)
        minetest.registered_nodes[node.name].on_rightclick(pos, node, player)
        return
    end

    if formname == "mymoney:shop_customer" then
        local index = nil
        for i = 1, 10 do if fields["buy_" .. i] then index = i break end end
        if not index then return end

        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local s_stack = inv:get_stack("stock", index)
        local p_stack = inv:get_stack("prices", index)
        local pinv = player:get_inventory()

        if s_stack:is_empty() or not pinv:contains_item("main", p_stack) or not pinv:room_for_item("main", s_stack:get_name()) then
            minetest.chat_send_player(name, "Purchase failed!")
            return
        end

        pinv:remove_item("main", p_stack) 
        inv:add_item("earnings", p_stack) 
        local item_to_give = s_stack:take_item(1)
        inv:set_stack("stock", index, s_stack) 
        pinv:add_item("main", item_to_give) 

        local time = os.date("%H:%M")
        local history = meta:get_string("sales_log")
        meta:set_string("sales_log", history .. "["..time.."] "..name.." bought "..get_item_desc(item_to_give:get_name()).."\n")

        minetest.sound_play("default_place_node", {pos=pos, gain=1.0})
        local node = minetest.get_node(pos)
        minetest.registered_nodes[node.name].on_rightclick(pos, node, player)
    end
end)
