--[[
	BaseService
	-----------
	Builds the 8 player bases and handles CLAIMING + RELEASING.

	Each base is a Folder under Workspace.PlayerBases containing:
	  Floor          — coloured platform (grey until claimed)
	  ClaimPad       — glowing pad; touch it to claim the base
	  Vault          — tall block where crystals are stored (logic in VaultService)
	  UpgradePodium  — pillar with a ProximityPrompt (stub for future upgrades)
	  WallN/S/W/E    — semi-transparent boundary walls

	This service owns the base DATA TABLES and exposes them so other services
	(VaultService, CrystalService) can read ownership and attach behaviour:
	  BaseService.getBases()           → array of baseData
	  BaseService.getBaseByOwner(plr)  → baseData or nil

	A player may own at most ONE base.  Bases free up automatically on leave.
]]

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local BaseConfig = require(game.ReplicatedStorage.Shared.BaseConfig)
local Notify     = require(script.Parent.Notify)

local BaseService = {}

local bases = {}  -- bases[slot] = baseData

-- ── Part / UI helpers ─────────────────────────────────────────────────────────
local function makePart(name, size, position, color, parent, transparency)
	local p = Instance.new("Part")
	p.Name          = name
	p.Size          = size
	p.Position      = position
	p.Color         = color
	p.Anchored      = true
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Transparency  = transparency or 0
	p.Parent        = parent
	return p
end

-- Creates (replacing any existing) a billboard label above a part.
-- Returns the TextLabel so its text can be updated later.
local function setBillboard(part, text, textColor, yOffset)
	local old = part:FindFirstChildOfClass("BillboardGui")
	if old then old:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 240, 0, 60)
	bb.StudsOffset = Vector3.new(0, yOffset or 4, 0)
	bb.Parent      = part

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	lbl.BackgroundTransparency = 0.4
	lbl.Text                   = text
	lbl.TextColor3             = textColor or Color3.new(1, 1, 1)
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.Parent                 = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent       = lbl

	return lbl
end

-- ── Build one base ────────────────────────────────────────────────────────────
local function buildBase(slot, basePos, baseColor, basesFolder)
	local folder = Instance.new("Folder")
	folder.Name   = "Base_" .. slot
	folder.Parent = basesFolder

	-- Replicated state so the client can read ownership without a remote
	folder:SetAttribute("SlotIndex",   slot)
	folder:SetAttribute("OwnerUserId", 0)
	folder:SetAttribute("OwnerName",   "Unclaimed")

	-- Floor (grey until claimed)
	local floor = makePart("Floor",
		BaseConfig.FLOOR_SIZE, basePos,
		Color3.fromRGB(140, 140, 140), folder)

	-- Claim pad (glowing, centre)
	local claimPad = makePart("ClaimPad",
		BaseConfig.CLAIM_PAD_SIZE,
		basePos + BaseConfig.CLAIM_PAD_OFFSET,
		Color3.fromRGB(255, 255, 255), folder)
	claimPad.Material = Enum.Material.Neon
	local claimLabel = setBillboard(claimPad, "Touch to Claim!", Color3.fromRGB(255, 255, 120), 3)

	-- Vault (tall block at the back; VaultService wires its behaviour)
	local vault = makePart("Vault",
		BaseConfig.VAULT_SIZE,
		basePos + BaseConfig.VAULT_OFFSET,
		Color3.fromRGB(90, 90, 100), folder)
	vault.Material = Enum.Material.Metal
	setBillboard(vault, "🔒 Vault", Color3.fromRGB(200, 200, 255), BaseConfig.VAULT_SIZE.Y / 2 + 2)

	-- Upgrade podium (stub — prompt notifies "coming soon")
	local podium = makePart("UpgradePodium",
		BaseConfig.UPGRADE_PODIUM_SIZE,
		basePos + BaseConfig.UPGRADE_PODIUM_OFFSET,
		Color3.fromRGB(90, 200, 90), folder)
	local upgradePrompt = Instance.new("ProximityPrompt")
	upgradePrompt.ActionText            = "Upgrade"
	upgradePrompt.ObjectText            = "Coming Soon"
	upgradePrompt.HoldDuration          = 0
	upgradePrompt.MaxActivationDistance = 10
	upgradePrompt.Enabled               = false  -- enabled after claim
	upgradePrompt.Parent                = podium
	setBillboard(podium, "⬆ Upgrade", Color3.fromRGB(150, 255, 150), 4)

	-- Boundary walls (semi-transparent)
	local halfX, halfZ = BaseConfig.FLOOR_SIZE.X / 2, BaseConfig.FLOOR_SIZE.Z / 2
	local wallH, wallT = BaseConfig.WALL_HEIGHT, BaseConfig.WALL_THICKNESS
	local wallY = basePos.Y + wallH / 2
	local wallDefs = {
		{ "WallN", Vector3.new(BaseConfig.FLOOR_SIZE.X, wallH, wallT), Vector3.new(basePos.X,         wallY, basePos.Z - halfZ) },
		{ "WallS", Vector3.new(BaseConfig.FLOOR_SIZE.X, wallH, wallT), Vector3.new(basePos.X,         wallY, basePos.Z + halfZ) },
		{ "WallW", Vector3.new(wallT, wallH, BaseConfig.FLOOR_SIZE.Z), Vector3.new(basePos.X - halfX, wallY, basePos.Z        ) },
		{ "WallE", Vector3.new(wallT, wallH, BaseConfig.FLOOR_SIZE.Z), Vector3.new(basePos.X + halfX, wallY, basePos.Z        ) },
	}
	local walls = {}
	for _, wd in ipairs(wallDefs) do
		walls[#walls + 1] = makePart(wd[1], wd[2], wd[3], Color3.fromRGB(140, 140, 140), folder, 0.6)
	end

	return {
		-- references
		slot          = slot,
		folder        = folder,
		floor         = floor,
		claimPad      = claimPad,
		claimLabel    = claimLabel,
		vault         = vault,
		podium        = podium,
		upgradePrompt = upgradePrompt,
		walls         = walls,
		-- world info
		basePos       = basePos,
		baseColor     = baseColor,
		-- runtime state
		owner         = nil,         -- Player or nil
		claiming      = false,       -- debounce
		crystals      = {},          -- array of tier indices (VaultService manages)
		vaultSpheres  = {},          -- display sphere Parts (VaultService manages)
		crackPrompt   = nil,         -- set by VaultService
	}
end

-- ── Visual state ──────────────────────────────────────────────────────────────
local function refreshBaseVisual(baseData)
	if baseData.owner then
		baseData.floor.Color    = baseData.baseColor
		baseData.claimPad.Color = baseData.baseColor
		baseData.claimPad.Material = Enum.Material.SmoothPlastic
		baseData.claimLabel.Text = baseData.owner.Name .. "'s Base"
		for _, wall in ipairs(baseData.walls) do
			wall.Color = baseData.baseColor
		end
		baseData.folder:SetAttribute("OwnerUserId", baseData.owner.UserId)
		baseData.folder:SetAttribute("OwnerName",   baseData.owner.Name)
	else
		local grey = Color3.fromRGB(140, 140, 140)
		baseData.floor.Color    = grey
		baseData.claimPad.Color = Color3.fromRGB(255, 255, 255)
		baseData.claimPad.Material = Enum.Material.Neon
		baseData.claimLabel.Text = "Touch to Claim!"
		for _, wall in ipairs(baseData.walls) do
			wall.Color = grey
		end
		baseData.folder:SetAttribute("OwnerUserId", 0)
		baseData.folder:SetAttribute("OwnerName",   "Unclaimed")
	end
end

-- ── Claiming ──────────────────────────────────────────────────────────────────
local function claimBase(player, baseData)
	-- Already owned, or mid-claim → ignore
	if baseData.owner or baseData.claiming then return end
	-- One base per player
	for _, bd in pairs(bases) do
		if bd.owner == player then return end
	end

	baseData.claiming = true
	baseData.owner    = player
	baseData.claiming = false

	baseData.upgradePrompt.Enabled = true
	refreshBaseVisual(baseData)

	Notify.send(player, "You claimed a base! 💎 Go mine some crystals.")
	print("[BaseService]", player.Name, "claimed base", baseData.slot)
end

-- ── Releasing ─────────────────────────────────────────────────────────────────
local function releaseBase(player)
	for _, baseData in pairs(bases) do
		if baseData.owner == player then
			baseData.owner = nil
			baseData.upgradePrompt.Enabled = false

			-- Wipe vault contents (display spheres are destroyed by VaultService
			-- via the clearVault hook if present; clear data here regardless)
			if BaseService.onBaseReleased then
				BaseService.onBaseReleased(baseData)
			end
			baseData.crystals = {}

			refreshBaseVisual(baseData)
			print("[BaseService]", player.Name, "released base", baseData.slot)
			return
		end
	end
end

-- ── Public API ────────────────────────────────────────────────────────────────
function BaseService.getBases()
	return bases
end

function BaseService.getBaseByOwner(player)
	for _, baseData in pairs(bases) do
		if baseData.owner == player then
			return baseData
		end
	end
	return nil
end

function BaseService.init()
	local basesFolder = Instance.new("Folder")
	basesFolder.Name   = "PlayerBases"
	basesFolder.Parent = Workspace

	for slot = 1, GameConfig.BASE_COUNT do
		local baseData = buildBase(
			slot,
			GameConfig.BASE_POSITIONS[slot],
			GameConfig.BASE_COLORS[slot],
			basesFolder
		)
		bases[slot] = baseData

		-- Claim on touch (debounced per player — a character has many parts,
		-- each of which can fire Touched in the same frame)
		local touchDebounce = {}
		baseData.claimPad.Touched:Connect(function(hit)
			local toucher = Players:GetPlayerFromCharacter(hit.Parent)
			if not toucher then return end
			if touchDebounce[toucher.UserId] then return end
			touchDebounce[toucher.UserId] = true

			claimBase(toucher, baseData)

			task.delay(1, function()
				touchDebounce[toucher.UserId] = nil
			end)
		end)

		-- Upgrade podium stub
		baseData.upgradePrompt.Triggered:Connect(function(plr)
			if baseData.owner == plr then
				Notify.send(plr, "Upgrades are coming soon! 🛠️")
			end
		end)
	end

	Players.PlayerRemoving:Connect(releaseBase)

	print("[BaseService] Built", GameConfig.BASE_COUNT, "bases.")
end

BaseService.releaseBase = releaseBase

return BaseService
