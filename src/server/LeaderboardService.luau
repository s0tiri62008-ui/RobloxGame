--[[
	LeaderboardService
	------------------
	1. Gives every player a "leaderstats" folder (Cash + Crystals) so Roblox
	   shows the top-right player list.
	2. Refreshes the in-world "leaderboard sign" board (built by MapSetup) every
	   few seconds with the richest players.
]]

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LeaderboardService = {}

-- ── leaderstats ───────────────────────────────────────────────────────────────
local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name   = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name   = "Cash"
	cash.Value  = 0
	cash.Parent = leaderstats

	local crystals = Instance.new("IntValue")
	crystals.Name   = "Crystals"
	crystals.Value  = 0
	crystals.Parent = leaderstats
end

-- ── In-world board refresh ────────────────────────────────────────────────────
local function refreshBoard()
	local sign = Workspace:FindFirstChild("Lobby")
	sign = sign and sign:FindFirstChild("LeaderboardSign")
	local board = sign and sign:FindFirstChild("Board")
	local list = board and board:FindFirstChild("List")
	if not list then return end

	-- Collect and sort players by Cash (descending)
	local ranked = {}
	for _, player in Players:GetPlayers() do
		local leaderstats = player:FindFirstChild("leaderstats")
		local cash = leaderstats and leaderstats:FindFirstChild("Cash")
		ranked[#ranked + 1] = { name = player.Name, cash = cash and cash.Value or 0 }
	end
	table.sort(ranked, function(a, b) return a.cash > b.cash end)

	if #ranked == 0 then
		list.Text = "Waiting for players..."
		return
	end

	-- Build a top-5 string
	local lines = {}
	for i = 1, math.min(5, #ranked) do
		lines[i] = string.format("%d. %s  -  $%d", i, ranked[i].name, ranked[i].cash)
	end
	list.Text = table.concat(lines, "\n")
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function LeaderboardService.init()
	Players.PlayerAdded:Connect(setupLeaderstats)
	for _, player in Players:GetPlayers() do
		setupLeaderstats(player)  -- catch players already in (Studio test)
	end

	-- Refresh the in-world board on a loop
	task.spawn(function()
		while true do
			refreshBoard()
			task.wait(3)
		end
	end)

	print("[LeaderboardService] Ready.")
end

return LeaderboardService
