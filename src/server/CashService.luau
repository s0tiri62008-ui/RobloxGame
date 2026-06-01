-- Awards passive cash to every player on a fixed interval.
-- Later systems can add bonus cash per collectible owned.
local Players = game:GetService("Players")
local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)

local CashService = {}

function CashService.init()
	task.spawn(function()
		while true do
			task.wait(GameConfig.CASH_TICK_INTERVAL)

			for _, player in Players:GetPlayers() do
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local cash = leaderstats:FindFirstChild("Cash")
					if cash then
						cash.Value += GameConfig.CASH_PER_TICK
					end
				end
			end
		end
	end)

	print("[CashService] Ready. Paying $" .. GameConfig.CASH_PER_TICK
		.. " every " .. GameConfig.CASH_TICK_INTERVAL .. "s.")
end

return CashService
