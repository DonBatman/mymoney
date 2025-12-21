mymoney = {}
mymoney.shop = {}
mymoney.shop.current_shop = {}

dofile(core.get_modpath("mymoney").."/coin_maker.lua")
dofile(core.get_modpath("mymoney").."/shop.lua")
dofile(core.get_modpath("mymoney").."/wallet.lua")
dofile(core.get_modpath("mymoney").."/atm.lua")
dofile(core.get_modpath("mymoney").."/vending_machine.lua")
dofile(core.get_modpath("mymoney").."/treasure.lua")
dofile(core.get_modpath("mymoney").."/stats.lua")
dofile(core.get_modpath("mymoney").."/trade.lua")
dofile(core.get_modpath("mymoney").."/exchange.lua")
dofile(core.get_modpath("mymoney").."/jobs.lua")

minetest.register_on_newplayer(function(player)
    local inv = player:get_inventory()
    inv:add_item("main", "mymoney:atm_card")
    inv:add_item("main", "mymoney:coin_gold_10")
    minetest.chat_send_player(player:get_player_name(), "Welcome! You have been issued a Bank Card and 10 Gold startup capital.")
end)

core.register_node("mymoney:coin_gold_1",{
	description = "1 Gold Coin",
	tiles = {"mymoney_1_gold_coin.png"},
	drawtype = "mesh",
	mesh = "mymoney_small_coin.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	stack_max = 1000,
	groups = {oddly_breakable_by_hand = 1, falling_node = 1},
	selection_box = {
		type = "fixed",
		fixed = {{-0.2, -0.5, -0.2, 0.2, -0.4, 0.2}}},
	collision_box = {
		type = "fixed",
		fixed = {{-0.2, -0.5, -0.2, 0.2, -0.4, 0.2}}},
})
core.register_node("mymoney:coin_gold_5",{
	description = "5 Gold Coin",
	tiles = {"mymoney_5_gold_coin.png"},
	drawtype = "mesh",
	mesh = "mymoney_medium_coin.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	stack_max = 1000,
	groups = {oddly_breakable_by_hand = 1, falling_node = 1},
	selection_box = {
		type = "fixed",
		fixed = {{-0.3, -0.5, -0.3, 0.3, -0.4, 0.3}}},
	collision_box = {
		type = "fixed",
		fixed = {{-0.3, -0.5, -0.3, 0.3, -0.4, 0.3}}},
})
core.register_node("mymoney:coin_gold_10",{
	description = "10 Gold Coin",
	tiles = {"mymoney_10_gold_coin.png"},
	drawtype = "mesh",
	mesh = "mymoney_big_coin.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	stack_max = 1000,
	groups = {oddly_breakable_by_hand = 1, falling_node = 1},
	selection_box = {
		type = "fixed",
		fixed = {{-0.4, -0.5, -0.4, 0.4, -0.4, 0.4}}},
	collision_box = {
		type = "fixed",
		fixed = {{-0.4, -0.5, -0.4, 0.4, -0.4, 0.4}}},
})
core.register_node("mymoney:coin_silver_1",{
	description = "1 Silver Coin",
	tiles = {"mymoney_1_silver_coin.png"},
	drawtype = "mesh",
	mesh = "mymoney_small_coin.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	stack_max = 1000,
	groups = {oddly_breakable_by_hand = 1, falling_node = 1},
	selection_box = {
		type = "fixed",
		fixed = {{-0.2, -0.5, -0.2, 0.2, -0.4, 0.2}}},
	collision_box = {
		type = "fixed",
		fixed = {{-0.2, -0.5, -0.2, 0.2, -0.4, 0.2}}},
})
core.register_node("mymoney:coin_silver_5",{
	description = "5 Silver Coin",
	tiles = {"mymoney_5_silver_coin.png"},
	drawtype = "mesh",
	mesh = "mymoney_medium_coin.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	stack_max = 1000,
	groups = {oddly_breakable_by_hand = 1, falling_node = 1},
	selection_box = {
		type = "fixed",
		fixed = {{-0.3, -0.5, -0.3, 0.3, -0.4, 0.3}}},
	collision_box = {
		type = "fixed",
		fixed = {{-0.3, -0.5, -0.3, 0.3, -0.4, 0.3}}},
})
core.register_node("mymoney:coin_silver_10",{
	description = "10 Silver Coin",
	tiles = {"mymoney_10_silver_coin.png"},
	drawtype = "mesh",
	mesh = "mymoney_big_coin.obj",
	paramtype = "light",
	paramtype2 = "facedir",
	stack_max = 1000,
	groups = {oddly_breakable_by_hand = 1, falling_node = 1},
	selection_box = {
		type = "fixed",
		fixed = {{-0.4, -0.5, -0.4, 0.4, -0.4, 0.4}}},
	collision_box = {
		type = "fixed",
		fixed = {{-0.4, -0.5, -0.4, 0.4, -0.4, 0.4}}},
})
