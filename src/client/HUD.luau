-- Displays the player's Cash and Brainrot count on-screen.
-- Designed to be required by init.client.luau after leaderstats exist.
local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local HUD = {}

local function makeFrame(parent, size, position, bgColor)
	local frame = Instance.new("Frame")
	frame.Size                  = size
	frame.Position              = position
	frame.BackgroundColor3      = bgColor
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel       = 0
	frame.Parent                = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = frame

	return frame
end

local function makeLabel(parent, text, textColor)
	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.new(1, -10, 1, 0)
	lbl.Position             = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                 = text
	lbl.TextColor3           = textColor
	lbl.TextScaled           = true
	lbl.Font                 = Enum.Font.GothamBold
	lbl.TextXAlignment       = Enum.TextXAlignment.Left
	lbl.Parent               = parent
	return lbl
end

function HUD.init()
	local leaderstats  = player:WaitForChild("leaderstats", 15)
	if not leaderstats then
		warn("[HUD] leaderstats not found — skipping HUD setup.")
		return
	end

	local cash         = leaderstats:WaitForChild("Cash")
	local brainrots    = leaderstats:WaitForChild("Brainrots")

	-- Root ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name          = "HUD"
	gui.ResetOnSpawn  = false
	gui.IgnoreGuiInset = true
	gui.Parent        = player.PlayerGui

	-- Cash panel  (top-left)
	local cashFrame = makeFrame(gui,
		UDim2.new(0, 210, 0, 55),
		UDim2.new(0, 12, 0, 12),
		Color3.fromRGB(0, 0, 0))

	local cashLabel = makeLabel(cashFrame,
		"💰  $" .. cash.Value,
		Color3.fromRGB(255, 215, 0))

	-- Brainrot panel  (below cash)
	local brtFrame = makeFrame(gui,
		UDim2.new(0, 210, 0, 55),
		UDim2.new(0, 12, 0, 75),
		Color3.fromRGB(0, 0, 0))

	local brtLabel = makeLabel(brtFrame,
		"🧠  Brainrots: " .. brainrots.Value,
		Color3.fromRGB(150, 255, 150))

	-- Live updates
	cash.Changed:Connect(function(v)
		cashLabel.Text = "💰  $" .. v
	end)

	brainrots.Changed:Connect(function(v)
		brtLabel.Text = "🧠  Brainrots: " .. v
	end)

	print("[HUD] Loaded.")
end

return HUD
