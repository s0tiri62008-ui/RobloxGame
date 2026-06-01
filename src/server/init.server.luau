-- SERVER ENTRY POINT
-- Boots every service in the correct order.
local Players = game:GetService("Players")

local MapSetup           = require(script.MapSetup)
local LeaderboardService = require(script.LeaderboardService)
local CashService        = require(script.CashService)

-- 1. Build the map first (other systems may reference map objects)
MapSetup.init()

-- 2. Give players a leaderboard (must run before CashService ticks)
LeaderboardService.init()

-- 3. Start passive cash income loop
CashService.init()

-- 4. Assign a base to each player as they join / leave
Players.PlayerAdded:Connect(function(player)
	MapSetup.assignBase(player)
end)

Players.PlayerRemoving:Connect(function(player)
	MapSetup.releaseBase(player)
end)

print("[Server] Brainrot Battleground initialised!")
