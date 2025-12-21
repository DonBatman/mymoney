local function get_coin_maker_bg(width, height)
    return "size["..width..","..height.."]" ..
        "bgcolor-[#2b2b2bff;true]" ..
        "gui_bg[;listcolors[#444444ff;#555555ff;#222222ff;#33cc33ff;#cc3333ff]]"
end

core.register_node("mymoney:coin_maker", {
    description = "Industrial Coin Maker",
    tiles = {
        "mymoney_coin_maker.png"
    },
    drawtype = "mesh",
    mesh = "mymoney_coin_maker.obj",
    paramtype2 = "facedir",
    groups = {cracky=2, oddly_breakable_by_hand=1},

    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("input", 1)
        inv:set_size("output", 4)
        meta:set_int("timer", 0)
        meta:set_string("infotext", "Coin Maker (Idle)")
    end,

    can_dig = function(pos, player)
        local inv = core.get_meta(pos):get_inventory()
        if not inv:is_empty("input") or not inv:is_empty("output") then
            core.chat_send_player(player:get_player_name(), "Empty the machine before digging!")
            return false
        end
        return true
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local loc = "nodemeta:"..pos.x..","..pos.y..","..pos.z
        local meta = core.get_meta(pos)
        local timer = meta:get_int("timer")
        
        local status = "Status: Idle"
        if timer > 0 then
            status = "Status: Minting... (" .. timer .. "s left)"
        end

        core.show_formspec(name, "mymoney:coin_maker_fs",
            get_coin_maker_bg(10, 10) ..
            "label[1.5,0.5;COIN MINTING UNIT]" ..
            "label[1.5,1.2;Input (Ingots):]" ..
            "list["..loc..";input;1.5,1.7;1,1;]" ..
            "label[4.0,1.2;Output (Coins):]" ..
            "list["..loc..";output;4.0,1.7;4,1;]" ..
            "label[1.5,3.2;" .. status .. "]" ..
            "image[2.7,1.7;1,1;gui_furnace_arrow_bg.png^[lowpart:"..((300-timer)/300*100)..":gui_furnace_arrow_fg.png^[transformR270]" ..
            "label[1.5,5.5;YOUR INVENTORY:]" ..
            "list[current_player;main;1,5.5;8,4;]" ..
            "listring["..loc..";output]listring[current_player;main]" ..
            "listring["..loc..";input]listring[current_player;main]"
        )
    end,
})

core.register_abm({
    label = "Coin Minting Process",
    nodenames = {"mymoney:coin_maker"},
    interval = 1,
    chance = 1,
    action = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local input = inv:get_stack("input", 1)
        local timer = meta:get_int("timer")

        if timer > 0 then
            timer = timer - 1
            meta:set_int("timer", timer)
            meta:set_string("infotext", "Minting in progress: " .. timer .. "s left")
            
            if timer <= 0 then
                local res_item = meta:get_string("craft_result")
                inv:add_item("output", ItemStack(res_item .. " 10"))
                meta:set_string("infotext", "Minting Complete!")
                core.sound_play("default_cool_lava", {pos=pos, gain=0.5})
            end
        else
            if not input:is_empty() and inv:room_for_item("output", "mymoney:coin_gold_1 10") then
                local iname = input:get_name()
                local result = ""
                
                if iname == "default:gold_ingot" then
                    result = "mymoney:coin_gold_1"
                elseif iname == "default:silver_ingot" then
                    result = "mymoney:coin_silver_1"
                end
                
                if result ~= "" then
                    input:take_item(1)
                    inv:set_stack("input", 1, input)
                    meta:set_int("timer", 120)
                    meta:set_string("craft_result", result)
                    core.sound_play("default_place_node_metal", {pos=pos, gain=1.0})
                end
            end
        end
    end,
})
core.register_craft({
    output = "mymoney:coin_maker",
    recipe = {
        {"default:steel_ingot", "default:steel_ingot",  "default:steel_ingot"},
        {"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
        {"default:stonebrick",  "default:furnace",      "default:stonebrick"},
    }
})
