local function get_exchange_bg()
    return "size[10,10]bgcolor-[#2b2b2bff;true]" ..
           "label[3.5,0.2;=== CURRENCY EXCHANGE ===]" ..
           "label[1,0.8;--- SILVER COINS ---]label[6.5,0.8;--- GOLD COINS ---]"
end

minetest.register_node("mymoney:exchange", {
    description = "Currency Exchange Machine",
    tiles = {
        "mymoney_exchange.png"
    },
    drawtype = "mesh",
    mesh = "mymoney_exchange.obj",
    paramtype2 = "facedir",
    groups = {cracky=2},
	selection_box = {
		type = "fixed",
		fixed = {{-0.15,-0.5,-0.4,0.15,0.4,0.4}}
	},
    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local form = get_exchange_bg() ..
            
            "item_image[0.5,1.5;1,1;mymoney:coin_silver_10]" ..
            "button[1.5,1.8;3,0.8;s10_to_s1;Break 10 -> 1s]" ..
            
            "item_image[0.5,2.5;1,1;mymoney:coin_silver_5]" ..
            "button[1.5,2.8;3,0.8;s5_to_s1;Break 5 -> 1s]" ..

            "item_image[0.5,3.5;1,1;mymoney:coin_silver_1]" ..
            "button[1.5,3.8;3,0.8;s1_to_s10;10x 1s -> 1x 10]" ..

            "item_image[5.5,1.5;1,1;mymoney:coin_gold_10]" ..
            "button[6.5,1.8;3,0.8;g10_to_g1;Break 10 -> 1s]" ..
            
            "item_image[5.5,2.5;1,1;mymoney:coin_gold_5]" ..
            "button[6.5,2.8;3,0.8;g5_to_g1;Break 5 -> 1s]" ..

            "item_image[5.5,3.5;1,1;mymoney:coin_gold_1]" ..
            "button[6.5,3.8;3,0.8;g1_to_g10;10x 1s -> 1x 10]" ..

            "label[3.5,4.8;--- METAL UPGRADE ---]" ..
            "item_image[2.0,5.3;1,1;mymoney:coin_silver_10]" ..
            "button[3.0,5.6;4,0.8;s10_to_g1;10x Silver 10 -> 1x Gold 1]" ..

            "item_image[2.0,6.3;1,1;mymoney:coin_gold_1]" ..
            "button[3.0,6.6;4,0.8;g1_to_s10;1x Gold 1 -> 10x Silver 10]" ..

            "list[current_player;main;1,8.5;8,1;]"
            
        minetest.show_formspec(name, "mymoney:exchange_ui", form)
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "mymoney:exchange_ui" then return end
    local inv = player:get_inventory()
    local name = player:get_player_name()
    local sound = "default_place_node"

    local function swap(take_item, take_count, give_item, give_count)
        if inv:contains_item("main", take_item .. " " .. take_count) then
            if inv:room_for_item("main", give_item .. " " .. give_count) then
                inv:remove_item("main", take_item .. " " .. take_count)
                inv:add_item("main", give_item .. " " .. give_count)
                minetest.sound_play(sound, {to_player=name, gain=1.0})
            else
                minetest.chat_send_player(name, "Inventory full!")
            end
        else
            minetest.chat_send_player(name, "You don't have enough coins!")
        end
    end

    if fields.s10_to_s1 then swap("mymoney:coin_silver_10", 1, "mymoney:coin_silver_1", 10)
    elseif fields.s5_to_s1 then swap("mymoney:coin_silver_5", 1, "mymoney:coin_silver_1", 5)
    elseif fields.s1_to_s10 then swap("mymoney:coin_silver_1", 10, "mymoney:coin_silver_10", 1)
    
    elseif fields.g10_to_g1 then swap("mymoney:coin_gold_10", 1, "mymoney:coin_gold_1", 10)
    elseif fields.g5_to_g1 then swap("mymoney:coin_gold_5", 1, "mymoney:coin_gold_1", 5)
    elseif fields.g1_to_g10 then swap("mymoney:coin_gold_1", 10, "mymoney:coin_gold_10", 1)
    
    elseif fields.s10_to_g1 then swap("mymoney:coin_silver_10", 10, "mymoney:coin_gold_1", 1)
    elseif fields.g1_to_s10 then swap("mymoney:coin_gold_1", 1, "mymoney:coin_silver_10", 10)
    end
end)
minetest.register_craft({
    output = "mymoney:exchange",
    recipe = {
        {"default:steel_ingot", "mymoney:coin_gold_1", "default:steel_ingot"},
        {"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:steel_ingot",  "default:steel_ingot"},
    }
})
