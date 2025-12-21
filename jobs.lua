core.register_node("mymoney:job_board", {
    description = "Job Board (Bounty Node)",
    tiles = {"mymoney_jobs.png"},
    drawtype = "mesh",
    mesh = "mymoney_jobs.obj",
    paramtype2 = "facedir",
    groups = {cracky=2},

    after_place_node = function(pos, placer)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        meta:set_string("owner", placer:get_player_name())
        meta:set_string("infotext", "Job Board (Owner: " .. placer:get_player_name() .. ")")
        inv:set_size("reward_pool", 8) 
        inv:set_size("request_slot", 1) 
        inv:set_size("delivery_bin", 8) 
    end,

    can_dig = function(pos, player)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local name = player:get_player_name()
        local owner = meta:get_string("owner")

        if name ~= owner and not core.check_player_privs(name, {protection_bypass=true}) then
            core.chat_send_player(name, "Only the owner ("..owner..") can dig this!")
            return false
        end

        if not inv:is_empty("reward_pool") or 
           not inv:is_empty("request_slot") or 
           not inv:is_empty("delivery_bin") then
            core.chat_send_player(name, "Clear the rewards, request, and delivery bin before digging!")
            return false
        end
        return true
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if player:get_player_name() == core.get_meta(pos):get_string("owner") then return stack:get_count() end
        return 0
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if player:get_player_name() == core.get_meta(pos):get_string("owner") then return stack:get_count() end
        return 0
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if player:get_player_name() == core.get_meta(pos):get_string("owner") then return count end
        return 0
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        local loc = "nodemeta:"..pos.x..","..pos.y..","..pos.z
        local inv = meta:get_inventory()

        if name == owner then
            core.show_formspec(name, "mymoney:job_setup", 
                "size[9,10.5]bgcolor-[#2b2b2bff;true]" ..
                "label[1,0.2;JOB SETUP (Owner View)]" ..
                "label[1,0.8;1. REWARD COINS (Payment)]" ..
                "list["..loc..";reward_pool;1,1.2;4,2;]" ..
                "label[6,0.8;2. WANTED ITEM]" ..
                "list["..loc..";request_slot;6,1.2;1,1;]" ..
                "label[1,3.4;3. COLLECTED ITEMS (Delivery Bin)]" ..
                "list["..loc..";delivery_bin;1,3.8;4,2;]" ..
                "label[1,5.8;YOUR INVENTORY]" ..
                "list[current_player;main;0.5,6.2;8,4;]" ..
                "listring["..loc..";reward_pool]listring[current_player;main]")
        else
            local wanted = inv:get_stack("request_slot", 1)
            local reward_pool = inv:get_list("reward_pool")
            local reward_display = "No Reward"
            for _, stack in ipairs(reward_pool) do
                if not stack:is_empty() then
                    reward_display = stack:get_count() .. "x " .. get_item_desc(stack:get_name())
                    break
                end
            end

            local form = "size[8,7]bgcolor-[#2b2b2bff;true]" ..
                "label[2.5,0.5;=== CURRENT JOB BOUNTY ===]" ..
                "label[1,1.5;WANTED:]" ..
                "item_image[1,2;1,1;"..wanted:get_name().."]" ..
                "label[2.2,2.2;1x "..get_item_desc(wanted:get_name()).."]" ..
                "label[4.5,1.5;REWARD:]" ..
                "label[4.5,2.2;"..reward_display.."]"

            if not wanted:is_empty() and reward_display ~= "No Reward" then
                form = form .. "button[2.5,3.5;3,1;complete_job;COMPLETE JOB]"
            else
                form = form .. "label[2.5,3.5;No jobs currently available.]"
            end
            
            form = form .. "list[current_player;main;0,4.5;8,1;]"
            core.show_formspec(name, "mymoney:job_worker", form)
        end
    end,
})
core.register_craft({
    output = "mymoney:job_board",
    recipe = {
        {"group:wood", "default:paper", "group:wood"},
        {"group:wood", "mymoney:coin_silver_1", "group:wood"},
        {"group:wood", "group:wood", "group:wood"},
    }
})
