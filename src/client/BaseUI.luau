--[[
	BaseUI
	------
	Listens for server notifications (claim/upgrade messages) and shows
	them as brief toast pop-ups in the bottom-centre of the screen.

	The server fires the "BaseNotify" RemoteEvent with a plain string.
	This module receives it and displays a small animated panel that
	fades out automatically after a couple of seconds.

	No polling, no manual refresh — the server pushes updates as needed.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer

local BaseUI = {}

-- ── Toast factory ─────────────────────────────────────────────────────────────

-- Creates a temporary on-screen message that slides up and fades away.
local function showToast(message)
	-- Each toast gets its own ScreenGui so multiple can stack
	local gui = Instance.new("ScreenGui")
	gui.Name            = "BaseToast"
	gui.ResetOnSpawn    = false
	gui.IgnoreGuiInset  = true
	gui.Parent          = player.PlayerGui

	-- Dark pill-shaped background
	local frame = Instance.new("Frame")
	frame.Size                   = UDim2.new(0, 320, 0, 62)
	frame.Position               = UDim2.new(0.5, -160, 0.80, 0)   -- bottom-centre
	frame.AnchorPoint            = Vector2.new(0, 0)
	frame.BackgroundColor3       = Color3.fromRGB(15, 15, 15)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel        = 0
	frame.Parent                 = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent       = frame

	local lbl = Instance.new("TextLabel")
	lbl.Size                  = UDim2.new(1, -24, 1, 0)
	lbl.Position              = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                  = message
	lbl.TextColor3            = Color3.fromRGB(255, 255, 255)
	lbl.TextScaled            = true
	lbl.Font                  = Enum.Font.GothamBold
	lbl.Parent                = frame

	-- After 2 seconds: tween the frame up and fade it out, then destroy
	task.delay(2, function()
		local slideUp = TweenService:Create(
			frame,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position             = UDim2.new(0.5, -160, 0.74, 0),
				BackgroundTransparency = 1,
			}
		)
		local fadeText = TweenService:Create(
			lbl,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1 }
		)

		slideUp:Play()
		fadeText:Play()

		-- Clean up after tween finishes
		slideUp.Completed:Connect(function()
			gui:Destroy()
		end)
	end)
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function BaseUI.init()
	-- The server creates the Remotes folder and BaseNotify event during
	-- BaseService.init().  WaitForChild makes the client wait up to 15 s
	-- rather than erroring if the client loads before the server finishes.
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
	if not remotes then
		warn("[BaseUI] Remotes folder not found — toast notifications disabled.")
		return
	end

	local notifyEvent = remotes:WaitForChild("BaseNotify", 15)
	if not notifyEvent then
		warn("[BaseUI] BaseNotify event not found — toast notifications disabled.")
		return
	end

	-- Every time the server fires a notification to THIS player, show a toast
	notifyEvent.OnClientEvent:Connect(function(message)
		showToast(message)
	end)

	print("[BaseUI] Ready.")
end

return BaseUI
