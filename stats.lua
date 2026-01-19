local stats_file = minetest.get_worldpath() .. "/mymoney_stats.txt"
mymoney.stats = {
    total_sales = 0,
    total_bank_wealth = 0,
    most_sold_item = "None",
    items_sold_count = {},
}

local function save_stats()
    local f = io.open(stats_file, "w")
    if f then
        f:write(minetest.serialize(mymoney.stats))
        f:close()
    end
end

local function load_stats()
    local f = io.open(stats_file, "r")
    if f then
        local data = f:read("*all")
        f:close()
        if data then
            mymoney.stats = minetest.deserialize(data) or mymoney.stats
        end
    end
end

load_stats()

function mymoney.log_transaction(item_name)
    mymoney.stats.total_sales = mymoney.stats.total_sales + 1
    
    local count = mymoney.stats.items_sold_count[item_name] or 0
    mymoney.stats.items_sold_count[item_name] = count + 1
    
    local top_item = "None"
    local top_val = 0
    for name, val in pairs(mymoney.stats.items_sold_count) do
        if val > top_val then
            top_val = val
            top_item = name
        end
    end
    mymoney.stats.most_sold_item = top_item
    
    save_stats()
end

minetest.register_chatcommand("money_stats", {
    privs = {server = true},
    description = "Show server economic statistics",
    func = function(name)
        local total_wealth = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            local meta = player:get_meta()
            total_wealth = total_wealth + meta:get_int("mymoney:gold_bal")
            total_wealth = total_wealth + meta:get_int("mymoney:silver_bal")
        end

        local output = "\n--- SERVER ECONOMY STATS ---\n" ..
            "Total Sales: " .. mymoney.stats.total_sales .. "\n" ..
            "Most Popular Item: " .. mymoney.stats.most_sold_item .. "\n" ..
            "Active Players' Wealth: " .. total_wealth .. " cents\n" ..
            "----------------------------"
        return true, output
    end,
})
