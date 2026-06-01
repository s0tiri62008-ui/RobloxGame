--[[
	HUD
	---
	Top-left on-screen panels showing the local player's Cash and Crystal count.
	Reads the leaderstats values created by LeaderboardService and updates live.
]]

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local HUD = {}

local function makePanel(parent, position, bgColor)
	local frame = Instance.new("Frame")
	frame.Size                   = UDim2.new(0, 220, 0, 56)
	frame.Position               = position
	frame.BackgroundColor3       = bgColor
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel        = 0
	frame.Parent                 = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = frame

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, -16, 1, 0)
	lbl.Position               = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.Parent                 = frame

	return lbl
end

function HUD.init()
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if not leaderstats then
		warn("[HUD] leaderstats not found — HUD disabled.")
		return
	end

	local cash     = leaderstats:WaitForChild("Cash")
	local crystals = leaderstats:WaitForChild("Crystals")

	local gui = Instance.new("ScreenGui")
	gui.Name           = "HUD"
	gui.ResetOnSpawn   = false
	gui.IgnoreGuiInset = true
	gui.Parent         = player.PlayerGui

	local cashLabel = makePanel(gui, UDim2.new(0, 12, 0, 12), Color3.fromRGB(0, 0, 0))
	cashLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	cashLabel.Text       = "💰  $" .. cash.Value

	local crystalLabel = makePanel(gui, UDim2.new(0, 12, 0, 76), Color3.fromRGB(0, 0, 0))
	crystalLabel.TextColor3 = Color3.fromRGB(120, 230, 245)
	crystalLabel.Text       = "💎  Crystals: " .. crystals.Value

	cash.Changed:Connect(function(v)
		cashLabel.Text = "💰  $" .. v
	end)
	crystals.Changed:Connect(function(v)
		crystalLabel.Text = "💎  Crystals: " .. v
	end)

	print("[HUD] Loaded.")
end

return HUD
