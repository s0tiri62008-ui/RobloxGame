--[[
	SERVER ENTRY POINT
	------------------
	Boots all server-side services in the correct dependency order.

	Order matters:
	  1. MapSetup   — creates static world geometry (ground, lobby, paths)
	  2. Leaderboard— must exist before CashService starts ticking cash
	  3. CashService— starts the passive income loop
	  4. BaseService — builds bases and wires touch/prompt events
	                   (depends on ReplicatedStorage existing, not on the above)
]]

local TerrainSetup       = require(script.TerrainSetup)
local MapSetup           = require(script.MapSetup)
local LeaderboardService = require(script.LeaderboardService)
local CashService        = require(script.CashService)
local BaseService        = require(script.BaseService)

TerrainSetup.init()      -- terrain first so Parts sit naturally on the surface
MapSetup.init()
LeaderboardService.init()
CashService.init()
BaseService.init()

print("[Server] Brainrot Battleground initialised!")
