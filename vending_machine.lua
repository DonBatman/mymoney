if not mymoney then mymoney = {} end
if not mymoney.shop then mymoney.shop = {} end
if not mymoney.shop.current_shop then mymoney.shop.current_shop = {} end

local function get_vending_bg(width, height)
    return "size["..width..","..height.."]" ..
        "bgcolor-[#2b2b2bff;true]" ..
        "gui_bg[;listcolors[#444444ff;#555555ff;#222222ff;#33cc33ff;#cc3333ff]]"
end

core.register_node("mymoney:vending", {
    description = "Vending Machine",
    tiles = {
        "mymoney_vending_machine.png"
    },
    drawtype = "mesh",
    mesh = "mymoney_vending_machine.obj",
    paramtype2 = "facedir",
    groups = {cracky=2, oddly_breakable_by_hand=1},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.2,0.5,1,0.5}
		}
	},
    after_place_node = function(pos, placer)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        meta:set_string("owner", placer:get_player_name())
        meta:set_string("infotext", "Vending Machine (Owner: " .. placer:get_player_name() .. ")")
        
        inv:set_size("stock", 8)      
        inv:set_size("price", 1)      
        inv:set_size("earnings", 8)   
    end,

    can_dig = function(pos, player)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local name = player:get_player_name()

        if name ~= meta:get_string("owner") then
            core.chat_send_player(name, "Only the owner can dig this machine!")
            return false
        end

        if not inv:is_empty("stock") or not inv:is_empty("earnings") or not inv:is_empty("price") then
            core.chat_send_player(name, "Machine must be empty before digging!")
            return false
        end
        return true
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        local loc = "nodemeta:"..pos.x..","..pos.y..","..pos.z

        mymoney.shop.current_shop[name] = pos

        if name == owner and not clicker:get_player_control().aux1 then
            core.show_formspec(name, "mymoney:vending_owner",
                get_vending_bg(9, 11) ..
                "label[0.5,0.5;VENDING SETUP (Owner)]" ..
                "label[1,1.2;1. Price (Single Coin):]" ..
                "list["..loc..";price;1.5,1.7;1,1;]" ..
                "label[4,1.2;2. Stock (Items to Sell):]" ..
                "list["..loc..";stock;4,1.7;4,2;]" ..
                "label[2.5,3.9;3. Collected Profits:]" ..
                "list["..loc..";earnings;2.5,4.4;4,1;]" ..
                "label[0.5,6.2;YOUR INVENTORY:]" ..
                "list[current_player;main;0.5,6.7;8,4;]" ..
                "listring["..loc..";stock]listring[current_player;main]"
            )
        else
            local inv = meta:get_inventory()
            local price_stack = inv:get_stack("price", 1)
            local stock_stack = inv:get_stack("stock", 1)
            
            local item_desc = "Empty"
            local stock_count = 0
            if not stock_stack:is_empty() then
                item_desc = stock_stack:get_definition().description or stock_stack:get_name()
                item_desc = item_desc:split("\n")[1]
                for i=1, inv:get_size("stock") do
                    stock_count = stock_count + inv:get_stack("stock", i):get_count()
                end
            end

            local price_desc = "FREE"
            if not price_stack:is_empty() then
                price_desc = price_stack:get_count() .. "x " .. (price_stack:get_definition().description or price_stack:get_name())
            end

            core.show_formspec(name, "mymoney:vending_customer",
                get_vending_bg(9, 10.5) ..
                "label[3.0,0.5;VENDING MACHINE]" ..
                "box[0.8,1.2;3.2,2.4;#444444ff]" ..
                "label[1.0,1.3;Item for Sale:]" ..
                "item_image[1.9,1.8;1.2,1.2;"..stock_stack:get_name().."]" ..
                "label[0.9,3.1;"..core.formspec_escape(item_desc).."]" ..
                
                "box[4.5,1.2;3.7,2.4;#444444ff]" ..
                "label[4.7,1.3;Price:]" ..
                "label[4.7,2.2;"..price_desc.."]" ..
                "label[4.7,3.0;In Stock: "..stock_count.."]" ..
                
                "button[2.5,4.0;4,0.8;buy;PURCHASE ITEM]" ..
                
                "label[0.5,5.7;YOUR INVENTORY:]" ..
                "list[current_player;main;0.5,6.2;8,4;]"
            )
        end
    end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "mymoney:vending_customer" then return end
    if fields.quit then return end

    if fields.buy then
        local name = player:get_player_name()
        local pos = mymoney.shop.current_shop[name]
        
        if not pos then 
            core.chat_send_player(name, "Error: Vending machine position lost. Re-open it.")
            return 
        end
        
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local pinv = player:get_inventory()
        
        local price_stack = inv:get_stack("price", 1)
        local stock_inv = inv:get_list("stock")

        local first_stock_idx = 0
        for i, stack in ipairs(stock_inv) do
            if not stack:is_empty() then
                first_stock_idx = i
                break
            end
        end

        if first_stock_idx == 0 then
            core.chat_send_player(name, "Machine is out of stock!")
            return
        end

        local stock_stack = inv:get_stack("stock", first_stock_idx)

        if not pinv:contains_item("main", price_stack) then
            core.chat_send_player(name, "Insufficient funds! You need " .. price_stack:get_count() .. " coins.")
            return
        end

        if not inv:room_for_item("earnings", price_stack) then
            core.chat_send_player(name, "Machine is full of money!")
            return
        end

        local purchase_item = ItemStack(stock_stack:get_name())
        if not pinv:room_for_item("main", purchase_item) then
            core.chat_send_player(name, "Your inventory is full!")
            return
        end

        pinv:remove_item("main", price_stack)
        inv:add_item("earnings", price_stack)
        
        stock_stack:take_item(1)
        inv:set_stack("stock", first_stock_idx, stock_stack)
        pinv:add_item("main", purchase_item)

        if mymoney.log_transaction then
            mymoney.log_transaction(purchase_item:get_name())
        end

        core.sound_play("default_place_node_metal", {pos=pos, gain=1.0})
        core.chat_send_player(name, "Purchase successful!")
        
        local node = core.get_node(pos)
        core.registered_nodes[node.name].on_rightclick(pos, node, player)
    end
end)
core.register_craft({
    output = "mymoney:vending_machine",
    recipe = {
        {"default:steel_ingot", "default:glass",       "default:steel_ingot"},
        {"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:tin_ingot",    "default:steel_ingot"},
    }
})
