local setup_timeout = 30

core.register_node("mymoney:admin_shop", {
	description = "Admin Shop (Protected)",
	tiles = {"mymoney_shop.png"},
	drawtype = "mesh",
	mesh = "mymoney_admin_shop.obj",
	groups = {choppy=2, oddly_breakable_by_hand=2, admin_shop=1},
	paramtype = "light",
	paramtype2 = "facedir",

	on_construct = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("input", 1)
		inv:set_size("output", 1)
		inv:set_size("setup_sell", 1)
		inv:set_size("setup_cost", 1)
		
		meta:set_int("is_new", 1)
		meta:set_string("infotext", "Admin Shop: RIGHT-CLICK TO SETUP\n(Self-destructs in 30s)")
		
		core.get_node_timer(pos):start(setup_timeout)
	end,

	can_dig = function(pos, player)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local name = player:get_player_name()
		local is_admin = core.check_player_privs(name, {server=true}) or core.check_player_privs(name, {give=true})

		if meta:get_int("is_new") == 1 then return true end

		if not is_admin then
			core.chat_send_player(name, "Only admins can remove active shops!")
			return false
		end

		if not inv:is_empty("input") or not inv:is_empty("output") then
			core.chat_send_player(name, "Clear the Pay/Take slots before digging!")
			return false
		end

		return true
	end,

	on_timer = function(pos, elapsed)
		local meta = core.get_meta(pos)
		if meta:get_int("is_new") == 1 then
			core.remove_node(pos)
		end
		return false 
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local name = clicker:get_player_name()
		local meta = core.get_meta(pos)
		local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
		local is_admin = core.check_player_privs(name, {server=true}) or core.check_player_privs(name, {give=true})

		if is_admin and (meta:get_int("is_new") == 1 or clicker:get_player_control().sneak) then
			local form = "size[9,8]" ..
				"label[1.5,0.5;Drag Item to SELL here:]" ..
				"list[nodemeta:" .. pos_str .. ";setup_sell;2,1;1,1;]" ..
				"label[5.5,0.5;Drag PRICE here:]" ..
				"list[nodemeta:" .. pos_str .. ";setup_cost;6,1;1,1;]" ..
				"button_exit[3,2;3,1;save;ACTIVATE SHOP]" ..
				"list[current_player;main;0.5,3.5;8,4;]" ..
				"listring[current_player;main]" ..
				"listring[nodemeta:" .. pos_str .. ";setup_sell]" ..
				"listring[nodemeta:" .. pos_str .. ";setup_cost]"
			
			core.show_formspec(name, "mymoney:setup:" .. pos_str, form)
		else
			local selling = meta:get_string("trade_sell")
			local cost = meta:get_string("trade_cost")
			if selling == "" then return end
			
			local form = "size[9,7]"..
				"label[0.5,0.5;Selling:]"..
				"label[0.5,1.5;    For:]"..
				"item_image[1.5,0.3;1,1;"..selling.."]"..
				"item_image[1.5,1.2;1,1;"..cost.."]"..
				"label[3.5,0.5;Pay here:]"..
				"label[3.5,1.5;Take your stuff:]"..
				"list[nodemeta:" .. pos_str .. ";input;5.5,0.5;1,1;]"..
				"list[nodemeta:" .. pos_str .. ";output;5.5,1.5;1,1;]"..
				"button[6.5,1;2,1;buy;Buy Now]"..
				"list[current_player;main;0.5,3;8,4;]" ..
				"listring[current_player;main]" ..
				"listring[nodemeta:" .. pos_str .. ";output]"

			core.show_formspec(name, "mymoney:shop:" .. pos_str, form)
		end
	end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:find("mymoney:setup:") and not formname:find("mymoney:shop:") then return end
	
	local parts = formname:split(":")
	local coords = parts[3]:split(",")
	local pos = {x=tonumber(coords[1]), y=tonumber(coords[2]), z=tonumber(coords[3])}
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()

	if fields.save then
		local sell_stack = inv:get_stack("setup_sell", 1)
		local cost_stack = inv:get_stack("setup_cost", 1)

		if sell_stack:is_empty() or cost_stack:is_empty() then
			core.chat_send_player(player:get_player_name(), "Setup Error: You must fill both slots!")
			return
		end

		meta:set_string("trade_sell", sell_stack:get_name())
		meta:set_string("trade_cost", cost_stack:get_name())
		
		local player_inv = player:get_inventory()
		if player_inv:room_for_item("main", sell_stack) then player_inv:add_item("main", sell_stack) end
		if player_inv:room_for_item("main", cost_stack) then player_inv:add_item("main", cost_stack) end
		
		inv:set_stack("setup_sell", 1, nil)
		inv:set_stack("setup_cost", 1, nil)

		meta:set_int("is_new", 0)
		core.get_node_timer(pos):stop()
		meta:set_string("infotext", "Admin Shop: Selling " .. meta:get_string("trade_sell"))
	end

	if fields.buy then
		local sell = meta:get_string("trade_sell")
		local cost = meta:get_string("trade_cost")
		local instack = inv:get_stack("input", 1)

		if instack:get_name() == cost and instack:get_count() >= 1 then
			if inv:room_for_item("output", sell) then
				instack:take_item(1)
				inv:set_stack("input", 1, instack)
				inv:add_item("output", sell)
			end
		end
	end
end)
