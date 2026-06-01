-- Gives every player a "leaderstats" folder so Roblox shows the leaderboard.
local Players = game:GetService("Players")

local LeaderboardService = {}

local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats

	local collectibles = Instance.new("IntValue")
	collectibles.Name = "Brainrots"
	collectibles.Value = 0
	collectibles.Parent = leaderstats
end

function LeaderboardService.init()
	Players.PlayerAdded:Connect(setupLeaderstats)

	-- Catch players already present when testing in Studio
	for _, player in Players:GetPlayers() do
		setupLeaderstats(player)
	end

	print("[LeaderboardService] Ready.")
end

return LeaderboardService
