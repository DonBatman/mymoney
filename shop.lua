if not mymoney then mymoney = {} end
mymoney.current_shop = {}

-- Helper to get a clean, short item description
local function get_item_desc(itemname)
    if not itemname or itemname == "" then return "Empty" end
    local def = core.registered_items[itemname]
    if def and def.description then
        local desc = def.description:split("\n")[1]
        if #desc > 12 then return desc:sub(1, 10) .. ".." end
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
    local meta = core.get_meta(pos)
    local log = meta:get_string("sales_log")
    if log == "" then log = "No sales recorded yet." end
    
    core.show_formspec(name, "mymoney:shop_log", get_shop_bg(7, 7.5) ..
        "label[0.5,0.5;RECENT SALES LOG:]" ..
        "textarea[0.5,1.2;6,5;log_text;;" .. core.formspec_escape(log) .. "]" ..
        "button[0.5,6.5;2,0.8;clear_log;Clear Log]" ..
        "button[4.5,6.5;2,0.8;back_to_shop;Back]")
end

core.register_node("mymoney:shop", {
    description = "Universal Shop",
    drawtype = "mesh",
    mesh = "mymoney_shop.obj", 
    tiles = {"mymoney_shop.png"}, 
    paramtype = "light",
    paramtype2 = "facedir",
    selection_box = { type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5} },
    groups = {cracky=2},

    after_place_node = function(pos, placer)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        meta:set_string("owner", placer:get_player_name())
        meta:set_string("infotext", "Shop (Owner: " .. placer:get_player_name() .. ")")
        meta:set_string("sales_log", "") 
        inv:set_size("stock", 10)    
        inv:set_size("prices", 10)   
        inv:set_size("earnings", 12)  
    end,

    can_dig = function(pos, player)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        if not inv:is_empty("stock") or not inv:is_empty("prices") or not inv:is_empty("earnings") then
            core.chat_send_player(player:get_player_name(), "Empty the Shop before digging!")
            return false
        end
        return true
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        local loc = "nodemeta:"..pos.x..","..pos.y..","..pos.z
        mymoney.current_shop[name] = pos 

        if name == owner and not clicker:get_player_control().aux1 then
            core.show_formspec(name, "mymoney:shop_owner", get_shop_bg(10, 11.5) ..
                "label[0.5,0.2;SHOP MANAGEMENT (Owner: "..owner..")]" ..
                "label[1.5,0.8;STOCK]list["..loc..";stock;0.5,1.2;5,2;]" ..
                "label[1.5,3.6;PRICES]list["..loc..";prices;0.5,4.0;5,2;]" ..
                "label[6.5,0.8;EARNINGS]list["..loc..";earnings;6.5,1.2;3,4;]" ..
                "button[6.5,5.5;3,0.8;view_log;VIEW SALES LOG]" ..
                "list[current_player;main;1,7.0;8,4;]" ..
                "listring["..loc..";stock]listring[current_player;main]")
        else
            local form = get_shop_bg(10, 11.5) ..
                "label[3.0,0.2;SHOP OWNER: " .. owner .. "]" ..
                "label[0.5,0.8;Item]label[2.2,0.8;Price]label[5.0,0.8;Item]label[6.7,0.8;Price]"

            local inv = meta:get_inventory()
            for i = 1, 10 do
                local row = math.floor((i-1) / 2)
                local col = (i-1) % 2
                local y = 1.3 + (row * 1.1)
                local x_off = col * 4.5
                
                local s_stack = inv:get_stack("stock", i)
                local p_stack = inv:get_stack("prices", i)
                
                -- 1. Draw Item for sale
                form = form .. "item_image["..(0.5+x_off)..","..(y-0.2)..";1,1;"..s_stack:get_name().."]"
                form = form .. "label["..(0.5+x_off)..","..(y+0.6)..";" .. get_item_desc(s_stack:get_name()) .. "]"
                
                -- 2. Draw Price Coin and Count UNDER it
                form = form .. "item_image["..(2.2+x_off)..","..(y-0.2)..";1,1;"..p_stack:get_name().."]"
                if not p_stack:is_empty() then
                    -- Positioned count slightly right to center it under the 1x1 image
                    form = form .. "label["..(2.5+x_off)..","..(y+0.6)..";x" .. p_stack:get_count() .. "]"
                end
                
                -- 3. Buy Button
                if not s_stack:is_empty() and not p_stack:is_empty() then
                    form = form .. "button["..(3.4+x_off)..","..(y+0.1)..";1.0,0.8;buy_"..i..";BUY]"
                else
                    form = form .. "button["..(3.4+x_off)..","..(y+0.1)..";1.0,0.8;disabled;SOLD]"
                end
            end
            form = form .. "list[current_player;main;1,7.0;8,4;]"
            core.show_formspec(name, "mymoney:shop_customer", form)
        end
    end,
})

-- Purchase processing logic
core.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local pos = mymoney.current_shop[name]
    if not pos or formname ~= "mymoney:shop_customer" then 
        -- Handles log logic separately
        if fields.view_log then show_sales_log(name, pos) end
        if fields.clear_log then core.get_meta(pos):set_string("sales_log", "") show_sales_log(name, pos) end
        if fields.back_to_shop then 
            local node = core.get_node(pos)
            core.registered_nodes[node.name].on_rightclick(pos, node, player)
        end
        return 
    end

    local index = nil
    for i = 1, 10 do if fields["buy_" .. i] then index = i break end end
    if not index then return end

    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    local s_stack = inv:get_stack("stock", index)
    local p_stack = inv:get_stack("prices", index)
    local pinv = player:get_inventory()

    if s_stack:is_empty() or not pinv:contains_item("main", p_stack) or not pinv:room_for_item("main", ItemStack(s_stack:get_name())) then
        core.chat_send_player(name, "Purchase failed!")
        return
    end

    if s_stack:get_count() > 0 then
        pinv:remove_item("main", p_stack) 
        inv:add_item("earnings", p_stack) 
        local item_to_give = s_stack:take_item(1)
        inv:set_stack("stock", index, s_stack) 
        pinv:add_item("main", item_to_give) 

        local time = os.date("%H:%M")
        local history = meta:get_string("sales_log")
        meta:set_string("sales_log", "["..time.."] "..name.." bought "..get_item_desc(item_to_give:get_name()).."\n" .. history)
        core.sound_play("default_place_node", {pos=pos, gain=1.0})
    end

    local node = core.get_node(pos)
    core.registered_nodes[node.name].on_rightclick(pos, node, player)
end)
core.register_craft({
    output = "mymoney:shop",
    recipe = {
        {"default:obsidian",    "default:glass",         "default:obsidian"},
        {"default:steel_ingot", "mymoney:coin_gold_10",  "default:steel_ingot"},
        {"default:obsidian",    "default:obsidian",      "default:obsidian"},
    }
})
