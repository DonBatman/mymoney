local function get_wallet_bg(width, height)
    return "size["..width..","..height.."]" ..
        "bgcolor-[#2b2b2bff;true]" ..
        "gui_bg[;listcolors[#444444ff;#555555ff;#222222ff;#33cc33ff;#cc3333ff]]" ..
        "background[0,0;"..width..","..height..";mymoney_background.png;true]"
end

core.register_tool("mymoney:wallet", {
    description = "Leather Wallet\n(Right-click to open)",
    inventory_image = "mymoney_wallet.png",
    stack_max = 1,
   on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        local meta = itemstack:get_meta()
    if pointed_thing.type == "node" then
        local node = core.get_node(pointed_thing.under)
        if node.name == "mymoney:atm" then
            local name = placer:get_player_name()
            local meta = itemstack:get_meta()
            local inv_raw = meta:get_string("inventory")
            
            if inv_raw ~= "" then
                local list = core.deserialize(inv_raw) or {}
                local p_meta = placer:get_meta()
                local gold_added = 0
                local silver_added = 0
                local new_list = {}

                for _, itemstring in ipairs(list) do
                    local stack = ItemStack(itemstring)
                    local iname = stack:get_name()
                    local count = stack:get_count()

                    if iname:find("mymoney:coin_") then
                        local val = 0
                        if iname:find("_1") then val = 1 * count
                        elseif iname:find("_5") then val = 5 * count
                        elseif iname:find("_10") then val = 10 * count
                        end

                        if iname:find("gold") then gold_added = gold_added + val
                        else silver_added = silver_added + val end
                    else
                        table.insert(new_list, itemstring)
                    end
                end

                if gold_added > 0 or silver_added > 0 then
                    p_meta:set_int("mymoney:gold_bal", p_meta:get_int("mymoney:gold_bal") + gold_added)
                    p_meta:set_int("mymoney:silver_bal", p_meta:get_int("mymoney:silver_bal") + silver_added)
                    
                    meta:set_string("inventory", core.serialize(new_list))
                    core.chat_send_player(name, "ATM: Wallet emptied! Gold: +"..gold_added.." Silver: +"..silver_added)
                    core.sound_play("default_coins", {to_player=name, gain=1.0})
                    return itemstack
                end
            end
        end
    end

    local name = placer:get_player_name()
        if meta:get_string("wallet_id") == "" then
            meta:set_string("wallet_id", name .. os.time() .. math.random(100, 999))
        end

        local wallet_id = meta:get_string("wallet_id")
        local inv_name = "detached:wallet_" .. wallet_id

        local inv = core.create_detached_inventory("wallet_" .. wallet_id, {
            allow_put = function(inv, listname, index, stack, player)
                if stack:get_name():find("mymoney:coin_") then
                    return stack:get_count()
                end
                return 0
            end,
            on_put = function(inv, listname, index, stack, player)
                local list = inv:get_list("main")
                local serialized = {}
                for _, s in ipairs(list) do table.insert(serialized, s:to_string()) end
                meta:set_string("inventory", core.serialize(serialized))
                placer:set_wielded_item(itemstack)
            end,
            on_take = function(inv, listname, index, stack, player)
                local list = inv:get_list("main")
                local serialized = {}
                for _, s in ipairs(list) do table.insert(serialized, s:to_string()) end
                meta:set_string("inventory", core.serialize(serialized))
                placer:set_wielded_item(itemstack)
            end,
        })

        inv:set_size("main", 16)

        local saved_inv = core.deserialize(meta:get_string("inventory")) or {}
        for i, itemstring in ipairs(saved_inv) do
            inv:set_stack("main", i, ItemStack(itemstring))
        end

        core.show_formspec(name, "mymoney:wallet_fs",
            get_wallet_bg(9, 10) ..
            "label[0.5,0.5;WALLET (16 Slots - Coins Only):]" ..
            "list[" .. inv_name .. ";main;0.5,1;8,2;]"..
            "label[0.5,3.5;INVENTORY:]" ..
            "list[current_player;main;0.5,4;8,4;]" ..
            "listring[" .. inv_name .. ";main]listring[current_player;main]"
        )
        
        return itemstack
    end,
})
core.register_craft({
    output = "mymoney:wallet",
    recipe = {
        {"wool:brown", "default:string", "wool:brown"},
        {"wool:brown", "mymoney:coin_silver_1", "wool:brown"},
        {"wool:brown", "wool:brown", "wool:brown"},
    }
})
