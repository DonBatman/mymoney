core.register_node("mymoney:treasure_chest", {
    description = "Ancient Treasure Chest",
    tiles = {
        "default_chest_top.png", "default_chest_top.png",
        "default_chest_side.png", "default_chest_side.png",
        "default_chest_side.png", "default_chest_front.png"
    },
    groups = {choppy=2, oddly_breakable_by_hand=2},
    
    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local reward = ItemStack("mymoney:coin_gold_10 10")
        local inv = clicker:get_inventory()
        
        if inv:room_for_item("main", reward) then
            inv:add_item("main", reward)

            core.sound_play("default_coins", {pos=pos, gain=1.5})
            core.chat_send_all("*** " .. name .. " found an Ancient Treasure Chest containing 100 Gold! ***")

            core.add_particlespawner({
                amount = 40,
                time = 0.5,
                minpos = pos, maxpos = pos,
                minvel = {x=-2, y=2, z=-2}, maxvel = {x=2, y=5, z=2},
                minacc = {x=0, y=-9, z=0}, maxacc = {x=0, y=-9, z=0},
                minexptime = 1, maxexptime = 2,
                minsize = 1, maxsize = 3,
                texture = "mymoney_coin_gold_1.png",
            })

            core.remove_node(pos)
        else
            core.chat_send_player(name, "Your inventory is too full to take the treasure!")
        end
    end,
})

core.register_decoration({
    deco_type = "simple",
    place_on = {"default:sand", "default:dirt_with_grass", "default:desert_sand"},
    sidelen = 16,
    noise_params = {
        offset = 0.0001,
        scale = 0.001,
        spread = {x=200, y=200, z=200},
        seed = 543,
        octaves = 3,
        persist = 0.6
    },
    biomes = {"desert", "sand", "grassland", "ocean"},
    y_max = 30,
    y_min = -150,
    decoration = "mymoney:treasure_chest",
})
