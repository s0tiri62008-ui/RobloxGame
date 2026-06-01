--[[
	CrystalService
	--------------
	Owns the mining clusters and the "carry one crystal at a time" mechanic.

	  CLUSTERS  — 8 pads (CrystalConfig.CLUSTER_POSITIONS), each grows one crystal.
	  MINING    — Hold E (ProximityPrompt, MINE_HOLD seconds) to pick a crystal up.
	  CARRYING  — The crystal floats in front of the player, following their
	              HumanoidRootPart every frame.  One crystal per player.
	  RESPAWN   — A mined cluster regrows a fresh random crystal after RESPAWN_TIME.

	Other services interact through this public API:
	  CrystalService.getCarried(player)        → { tierIndex, part } or nil
	  CrystalService.clearCarried(player)      → destroys the carried crystal
	  CrystalService.giveCarried(player, tier) → hands a crystal to a player
	                                             (used by VaultService when a
	                                              rival cracks a vault). Returns
	                                              true on success, false if the
	                                              player's hands are already full.

	Everything here is server-authoritative — the client never moves crystals.
]]

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local CrystalConfig = require(game.ReplicatedStorage.Shared.CrystalConfig)
local Notify        = require(script.Parent.Notify)

local CrystalService = {}

-- carrying[userId] = { tierIndex = number, part = Part }
local carrying = {}

-- Folders created in init()
local clustersFolder
local carriedFolder

-- Where the carried crystal floats relative to the player (above + in front)
local CARRY_CFRAME = CFrame.new(0, 3, -3)

-- ── Crystal part factory ──────────────────────────────────────────────────────
local function makeCrystalBall(tierIndex, position, parent)
	local tier = CrystalConfig.getTier(tierIndex)

	local ball = Instance.new("Part")
	ball.Name         = "Crystal_" .. tier.name
	ball.Shape        = Enum.PartType.Ball
	ball.Size         = Vector3.new(3, 3, 3)
	ball.Position     = position
	ball.Color        = tier.color
	ball.Material     = Enum.Material.Neon
	ball.Anchored     = true
	ball.CanCollide   = false
	ball.Parent       = parent

	-- Floating name tag
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 110, 0, 30)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.Parent      = ball
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = tier.name
	lbl.TextColor3             = tier.color
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.Parent                 = bb

	-- Store the tier index on the part for convenience
	ball:SetAttribute("TierIndex", tierIndex)

	return ball
end

-- ── Cluster construction ──────────────────────────────────────────────────────
-- cluster = { pad, prompt, crystalPart, tierIndex, available }
local function buildCluster(index, position)
	-- Pad on the ground
	local pad = Instance.new("Part")
	pad.Name          = "ClusterPad_" .. index
	pad.Size          = Vector3.new(8, 1, 8)
	pad.Position      = position
	pad.Color         = Color3.fromRGB(70, 70, 80)
	pad.Material      = Enum.Material.Slate
	pad.Anchored      = true
	pad.TopSurface    = Enum.SurfaceType.Smooth
	pad.Parent        = clustersFolder

	local cluster = {
		pad        = pad,
		prompt     = nil,
		crystalPart = nil,
		tierIndex  = 1,
		available  = false,
	}

	-- Grows a fresh crystal of a random tier on the pad
	local function grow()
		cluster.tierIndex = CrystalConfig.rollTier()
		cluster.crystalPart = makeCrystalBall(
			cluster.tierIndex,
			position + Vector3.new(0, 4, 0),
			clustersFolder
		)

		-- Prompt lives on the crystal itself
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText            = "Mine"
		prompt.ObjectText            = CrystalConfig.getTier(cluster.tierIndex).name
		prompt.HoldDuration          = CrystalConfig.MINE_HOLD
		prompt.MaxActivationDistance = 10
		prompt.Parent                = cluster.crystalPart
		cluster.prompt = prompt
		cluster.available = true

		prompt.Triggered:Connect(function(player)
			CrystalService.tryMine(player, cluster)
		end)
	end

	cluster.grow = grow
	grow()
	return cluster
end

-- ── Mining ────────────────────────────────────────────────────────────────────
function CrystalService.tryMine(player, cluster)
	if not cluster.available then return end
	if carrying[player.UserId] then
		Notify.send(player, "Your hands are full — drop it in your vault first!")
		return
	end

	-- Consume the cluster crystal
	cluster.available = false
	local tierIndex = cluster.tierIndex
	if cluster.crystalPart then
		cluster.crystalPart:Destroy()
		cluster.crystalPart = nil
		cluster.prompt = nil
	end

	-- Spawn a carried crystal that will follow the player
	local startPos = Vector3.new(0, 50, 0)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		startPos = (hrp.CFrame * CARRY_CFRAME).Position
	end
	local part = makeCrystalBall(tierIndex, startPos, carriedFolder)
	carrying[player.UserId] = { tierIndex = tierIndex, part = part }

	Notify.send(player, "Mined a " .. CrystalConfig.getTier(tierIndex).name .. "! Take it to your vault.")

	-- Regrow the cluster after a delay
	task.delay(CrystalConfig.RESPAWN_TIME, function()
		if cluster.grow then
			cluster.grow()
		end
	end)
end

-- ── Public carry API ──────────────────────────────────────────────────────────
function CrystalService.getCarried(player)
	return carrying[player.UserId]
end

function CrystalService.clearCarried(player)
	local data = carrying[player.UserId]
	if data then
		if data.part then data.part:Destroy() end
		carrying[player.UserId] = nil
	end
end

-- Hands a crystal of `tierIndex` to a player (used when cracking a vault).
-- Returns false if the player is already carrying something.
function CrystalService.giveCarried(player, tierIndex)
	if carrying[player.UserId] then
		return false
	end
	local startPos = Vector3.new(0, 50, 0)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		startPos = (hrp.CFrame * CARRY_CFRAME).Position
	end
	local part = makeCrystalBall(tierIndex, startPos, carriedFolder)
	carrying[player.UserId] = { tierIndex = tierIndex, part = part }
	return true
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function CrystalService.init()
	clustersFolder = Instance.new("Folder")
	clustersFolder.Name   = "CrystalClusters"
	clustersFolder.Parent = Workspace

	carriedFolder = Instance.new("Folder")
	carriedFolder.Name   = "CarriedCrystals"
	carriedFolder.Parent = Workspace

	for index, pos in ipairs(CrystalConfig.CLUSTER_POSITIONS) do
		buildCluster(index, pos)
	end

	-- ONE Heartbeat connection drives every carried crystal.
	RunService.Heartbeat:Connect(function()
		for userId, data in pairs(carrying) do
			local player = Players:GetPlayerByUserId(userId)
			local char = player and player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and data.part and data.part.Parent then
				data.part.CFrame = hrp.CFrame * CARRY_CFRAME
			end
		end
	end)

	-- Clean up a player's carried crystal when they leave
	Players.PlayerRemoving:Connect(function(player)
		CrystalService.clearCarried(player)
	end)

	print("[CrystalService] Built", #CrystalConfig.CLUSTER_POSITIONS, "clusters.")
end

return CrystalService
