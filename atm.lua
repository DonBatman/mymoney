local function get_atm_bg(width, height)
    return "size["..width..","..height.."]" ..
        "bgcolor-[#2b2b2bff;true]" ..
        "gui_bg[;listcolors[#444444ff;#555555ff;#222222ff;#33cc33ff;#cc3333ff]]"
end

local function update_atm_formspec(player, pos)
    local name = player:get_player_name()
    local p_meta = player:get_meta()
    local gold_bal = p_meta:get_int("mymoney:gold_bal") or 0
    local silver_bal = p_meta:get_int("mymoney:silver_bal") or 0

    local slot_loc = "nodemeta:"..pos.x..","..pos.y..","..pos.z

    return get_atm_bg(10, 10) ..
        "label[1,0.5;PERSONAL BANK ACCOUNT]" ..
        "label[1,1.2;Gold Balance: " .. gold_bal .. " cents]" ..
        "label[1,1.7;Silver Balance: " .. silver_bal .. " cents]" ..
        
        "box[2,2.5;2,2;#444444ff]" ..
        "label[2.1,2.6;DROP COINS:]" ..
        "list["..slot_loc..";deposit;2.5,3.2;1,1;]" ..
        
        "label[5,2;WITHDRAW GOLD:]" ..
        "button[5,2.5;1.2,0.8;get_g1;1c]" ..
        "button[6.3,2.5;1.2,0.8;get_g5;5c]" ..
        "button[7.6,2.5;1.2,0.8;get_g10;10c]" ..

        "label[5,3.5;WITHDRAW SILVER:]" ..
        "button[5,4;1.2,0.8;get_s1;1c]" ..
        "button[6.3,4;1.2,0.8;get_s5;5c]" ..
        "button[7.6,4;1.2,0.8;get_s10;10c]" ..

        "label[1,5;YOUR INVENTORY:]" ..
        "list[current_player;main;1,5.5;8,4;]" ..
        "listring["..slot_loc..";deposit]listring[current_player;main]"
end

minetest.register_node("mymoney:atm", {
    description = "Bank ATM",
    tiles = {
        "mymoney_atm.png"
    },
    drawtype = "mesh",
    mesh = "mymoney_atm.obj",
    paramtype2 = "facedir",
	selection_box = {
		type = "fixed",
		fixed = {{-0.3,-0.5,-0.3,0.3,0.8,0.3}}
	},
    groups = {cracky=3, oddly_breakable_by_hand=1},
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("deposit", 1)
        meta:set_string("infotext", "ATM (Personal Bank)")
    end,

    on_rightclick = function(pos, node, clicker)
        minetest.show_formspec(clicker:get_player_name(), "mymoney:atm_fs", update_atm_formspec(clicker, pos))
        mymoney.shop.current_shop[clicker:get_player_name()] = pos 
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "deposit" and stack:get_name():find("mymoney:coin_") then
            return stack:get_count()
        end
        return 0
    end,

    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "deposit" then
            local item_name = stack:get_name()
            local count = stack:get_count()
            local p_meta = player:get_meta()
            local value = 0
            
            if item_name == "mymoney:coin_gold_1" then value = 1 * count
            elseif item_name == "mymoney:coin_gold_5" then value = 5 * count
            elseif item_name == "mymoney:coin_gold_10" then value = 10 * count
            elseif item_name == "mymoney:coin_silver_1" then value = 1 * count
            elseif item_name == "mymoney:coin_silver_5" then value = 5 * count
            elseif item_name == "mymoney:coin_silver_10" then value = 10 * count
            end

            if value > 0 then
                local is_gold = item_name:find("gold")
                local bal_key = is_gold and "mymoney:gold_bal" or "mymoney:silver_bal"
                local bal = p_meta:get_int(bal_key)
                p_meta:set_int(bal_key, bal + value)
                
                minetest.get_meta(pos):get_inventory():set_stack("deposit", 1, nil)
                
                minetest.sound_play("default_coins", {to_player=player:get_player_name(), gain=1.0})
                minetest.show_formspec(player:get_player_name(), "mymoney:atm_fs", update_atm_formspec(player, pos))
            end
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "mymoney:atm_fs" or fields.quit then return end

    local name = player:get_player_name()
    local pos = mymoney.shop.current_shop[name]
    if not pos then return end

    local p_meta = player:get_meta()
    local pinv = player:get_inventory()
    local action_taken = false

    local withdraw = function(type, cost, item)
        local bal_key = "mymoney:" .. type .. "_bal"
        local current_bal = p_meta:get_int(bal_key)
        
        if current_bal >= cost then
            if pinv:room_for_item("main", item) then
                p_meta:set_int(bal_key, current_bal - cost)
                pinv:add_item("main", item)
                minetest.sound_play("default_place_node_metal", {to_player=name, gain=0.5})
                action_taken = true
            else
                minetest.chat_send_player(name, "Inventory full!")
            end
        else
            minetest.chat_send_player(name, "Insufficient " .. type .. " funds!")
        end
    end

    if fields.get_g1 then withdraw("gold", 1, "mymoney:coin_gold_1") end
    if fields.get_g5 then withdraw("gold", 5, "mymoney:coin_gold_5") end
    if fields.get_g10 then withdraw("gold", 10, "mymoney:coin_gold_10") end
    if fields.get_s1 then withdraw("silver", 1, "mymoney:coin_silver_1") end
    if fields.get_s5 then withdraw("silver", 5, "mymoney:coin_silver_5") end
    if fields.get_s10 then withdraw("silver", 10, "mymoney:coin_silver_10") end

    if action_taken then
        minetest.show_formspec(name, "mymoney:atm_fs", update_atm_formspec(player, pos))
    end
end)

minetest.register_craftitem("mymoney:atm_card", {
	description = "Bank ATM Card\nRequired to access ATM machines",
	inventory_image = "mymoney_debit_card.png",
})

minetest.register_craft({
	output = "mymoney:atm_card",
	recipe = {
		{"default:steel_ingot", "mymoney:coin_gold_1", "default:steel_ingot"},
	}
})

local old_on_rightclick = minetest.registered_nodes["mymoney:atm"].on_rightclick

minetest.override_item("mymoney:atm", {
	on_rightclick = function(pos, node, clicker, itemstack)
		local name = clicker:get_player_name()
		local inv = clicker:get_inventory()

		if not inv:contains_item("main", "mymoney:atm_card") then
			minetest.chat_send_player(name, "Error: You need an ATM Card in your inventory to use this machine!")
			return
		end

		local held_item = clicker:get_wielded_item()
		if held_item:get_name() == "mymoney:wallet" then
			local w_meta = held_item:get_meta()
			local w_inv_raw = w_meta:get_string("inventory")
			
			if w_inv_raw ~= "" then
				local w_list = minetest.deserialize(w_inv_raw) or {}
				local p_meta = clicker:get_meta()
				local gold_added = 0
				local silver_added = 0
				local new_w_list = {}

				for _, itemstring in ipairs(w_list) do
					local stack = ItemStack(itemstring)
					local iname = stack:get_name()
					local count = stack:get_count()

					if iname:find("mymoney:coin_") then

						local val = 0
						if iname:find("_1") then val = 1 * count
						elseif iname:find("_5") then val = 5 * count
						elseif iname:find("_10") then val = 10 * count
						end

						if iname:find("gold") then
							gold_added = gold_added + val
						else
							silver_added = silver_added + val
						end
					else
						table.insert(new_w_list, itemstring)
					end
				end

				if gold_added > 0 or silver_added > 0 then
					p_meta:set_int("mymoney:gold_bal", p_meta:get_int("mymoney:gold_bal") + gold_added)
					p_meta:set_int("mymoney:silver_bal", p_meta:get_int("mymoney:silver_bal") + silver_added)
					
					w_meta:set_string("inventory", minetest.serialize(new_w_list))
					clicker:set_wielded_item(held_item)
					
					minetest.chat_send_player(name, "Wallet emptied! Deposited " .. gold_added .. "g and " .. silver_added .. "s.")
					minetest.sound_play("default_coins", {to_player=name, gain=1.0})
				end
			end
		end

		minetest.show_formspec(name, "mymoney:atm_fs", update_atm_formspec(clicker, pos))
		mymoney.shop.current_shop[name] = pos
	end,
})
minetest.register_craft({
    output = "mymoney:exchange",
    recipe = {
        {"default:steel_ingot", "default:glass",       "default:steel_ingot"},
        {"default:steel_ingot", "mymoney:coin_silver_1", "default:steel_ingot"},
        {"default:copper_ingot", "default:steel_ingot", "default:copper_ingot"},
    }
})
minetest.register_craft({
    output = "mymoney:atm_card",
    recipe = {
        {"", "default:paper", ""},
        {"default:paper", "default:copper_ingot", "default:paper"},
        {"", "default:paper", "default:blue_dye"},
    }
})
