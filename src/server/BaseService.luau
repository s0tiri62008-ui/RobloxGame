--[[
	BaseService
	-----------
	Owns everything related to player bases:

	  BUILD      — Creates all base geometry at server start.
	  CLAIM      — Player steps on the ClaimPad → they own the base.
	  UPGRADE    — Player uses the ProximityPrompt → cash is deducted,
	               floor grows, walls grow, sign updates.
	  RELEASE    — Player leaves the game → base resets to unclaimed.

	DATA FLOW
	---------
	  Touched (ClaimPad)            →  claimBase(player, baseData)
	  ProximityPrompt.Triggered     →  upgradeBase(player, baseData)
	  Players.PlayerRemoving        →  releaseBase(player)

	Each base's live state is also written to Folder Attributes so the
	client can read OwnerName / UpgradeLevel without a remote call:
	  folder:GetAttribute("OwnerUserId")   — 0 = unclaimed
	  folder:GetAttribute("OwnerName")     — "Unclaimed" or player.Name
	  folder:GetAttribute("UpgradeLevel")  — integer 0-MAX
	  folder:GetAttribute("SlotIndex")     — 1-4
]]

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local BaseConfig = require(game.ReplicatedStorage.Shared.BaseConfig)

local BaseService = {}

-- Internal array:  bases[slotIndex] = baseData table (see buildBase)
local bases = {}

-- ── Remote setup ─────────────────────────────────────────────────────────────
-- Create the Remotes folder once here; the client WaitForChilds it.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name   = "Remotes"
remotesFolder.Parent = ReplicatedStorage

-- Server fires this to send a short message to a specific player.
-- The client displays it as a toast notification.
local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name   = "BaseNotify"
notifyEvent.Parent = remotesFolder

-- ── Part / UI helpers ─────────────────────────────────────────────────────────

-- Creates an anchored, smooth-surface Part.
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

-- Replaces (or creates) a floating BillboardGui label above a Part.
-- Returns the TextLabel so callers can update its text later.
local function setBillboard(part, text, textColor, yOffset)
	-- Remove any old billboard first so we never stack duplicates
	local old = part:FindFirstChildOfClass("BillboardGui")
	if old then old:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 240, 0, 60)
	bb.StudsOffset = Vector3.new(0, yOffset or 4, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = part

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	lbl.BackgroundTransparency = 0.40
	lbl.Text                   = text
	lbl.TextColor3             = textColor or Color3.new(1, 1, 1)
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.Parent                 = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent       = lbl

	return lbl   -- caller may store this to change text later
end

-- ── Base builder ─────────────────────────────────────────────────────────────

--[[
	Constructs one base at `basePos` with slot colour `baseColor`.
	Returns a baseData table that tracks both the Part references and
	the mutable runtime state (owner, upgradeLevel, etc.).

	Layout (all positions are offsets from basePos / floor centre):

	      [ Display Pad ]   ← back of base (Z−)
	      [  Claim Pad  ]   ← centre (Z 0)
	  [Upgrade]   [Income]  ← front corners (Z+)
]]
local function buildBase(slot, basePos, baseColor)

	-- Create (or find) the shared PlayerBases folder
	local basesFolder = Workspace:FindFirstChild("PlayerBases")
	if not basesFolder then
		basesFolder = Instance.new("Folder")
		basesFolder.Name   = "PlayerBases"
		basesFolder.Parent = Workspace
	end

	local folder = Instance.new("Folder")
	folder.Name   = "Base_" .. slot
	folder.Parent = basesFolder

	-- Attributes replicate to all clients automatically —
	-- no RemoteEvent needed just to read ownership state.
	folder:SetAttribute("SlotIndex",    slot)
	folder:SetAttribute("OwnerUserId",  0)
	folder:SetAttribute("OwnerName",    "Unclaimed")
	folder:SetAttribute("UpgradeLevel", 0)

	-- ── Floor ────────────────────────────────────────────────────────────────
	-- Starts grey (unclaimed) and recolours when claimed/upgraded.
	local floor = makePart("Floor",
		BaseConfig.FLOOR_SIZE,
		basePos,
		BaseConfig.UPGRADE_LEVELS[0].color,   -- grey
		folder)

	-- ── Claim Pad ────────────────────────────────────────────────────────────
	-- Glowing white pad in the centre.  Player touches this to claim.
	local claimPos = basePos + BaseConfig.CLAIM_PAD_OFFSET
	local claimPad = makePart("ClaimPad",
		BaseConfig.CLAIM_PAD_SIZE,
		claimPos,
		Color3.fromRGB(255, 255, 255),
		folder)
	claimPad.Material = Enum.Material.Neon

	-- This label is the "owner sign" — updated on claim/upgrade/release.
	local claimLabel = setBillboard(claimPad, "Touch to Claim!", Color3.fromRGB(255, 255, 100), 3)

	-- ── Display Pad ──────────────────────────────────────────────────────────
	-- Reserved area where collected characters will be placed (future system).
	local dispPos = basePos + BaseConfig.DISPLAY_PAD_OFFSET
	local displayPad = makePart("DisplayPad",
		BaseConfig.DISPLAY_PAD_SIZE,
		dispPos,
		Color3.fromRGB(200, 200, 255),
		folder)
	displayPad.Material = Enum.Material.Neon
	setBillboard(displayPad, "Collectibles", Color3.fromRGB(180, 180, 255), 3)

	-- ── Income Area ──────────────────────────────────────────────────────────
	-- Future: cash piles appear here so the player must collect them manually.
	local incomePos = basePos + BaseConfig.INCOME_AREA_OFFSET
	local incomeArea = makePart("IncomeArea",
		BaseConfig.INCOME_AREA_SIZE,
		incomePos,
		Color3.fromRGB(255, 215, 0),
		folder)
	incomeArea.Material = Enum.Material.Neon
	setBillboard(incomeArea, "Income", Color3.fromRGB(255, 215, 0), 3)

	-- ── Upgrade Button ───────────────────────────────────────────────────────
	-- Tall block the player walks up to.  A ProximityPrompt pops up ("E to upgrade").
	-- The prompt is DISABLED until the base is claimed, preventing strangers from
	-- triggering it on an unclaimed base.
	local upgradePos = basePos + BaseConfig.UPGRADE_BTN_OFFSET
	local upgradeBtn = makePart("UpgradeButton",
		BaseConfig.UPGRADE_BTN_SIZE,
		upgradePos,
		Color3.fromRGB(80, 200, 80),
		folder)
	upgradeBtn.Material = Enum.Material.SmoothPlastic

	local upgradePrompt = Instance.new("ProximityPrompt")
	upgradePrompt.ActionText             = "Upgrade"
	upgradePrompt.ObjectText             = "Base ($100)"   -- overwritten by applyUpgradeVisuals
	upgradePrompt.HoldDuration           = 0               -- instant (no hold needed)
	upgradePrompt.MaxActivationDistance  = 12
	upgradePrompt.Enabled                = false           -- enabled after claiming
	upgradePrompt.Parent                 = upgradeBtn
	setBillboard(upgradeBtn, "UPGRADE\n($100)", Color3.fromRGB(100, 255, 100), 5)

	-- ── Boundary Walls ───────────────────────────────────────────────────────
	-- Semi-transparent walls outline the base.  They resize when the floor grows.
	local halfX  = BaseConfig.FLOOR_SIZE.X / 2
	local halfZ  = BaseConfig.FLOOR_SIZE.Z / 2
	local wallH  = BaseConfig.WALL_HEIGHT
	local wallT  = BaseConfig.WALL_THICKNESS
	local wallY  = basePos.Y + wallH / 2  -- wall centre (base is at Y=1, walls go up)

	-- Ordered N, S, W, E — this order is relied upon in resizeWalls()
	local wallDefs = {
		{ "WallN", Vector3.new(BaseConfig.FLOOR_SIZE.X, wallH, wallT), Vector3.new(basePos.X,         wallY, basePos.Z - halfZ) },
		{ "WallS", Vector3.new(BaseConfig.FLOOR_SIZE.X, wallH, wallT), Vector3.new(basePos.X,         wallY, basePos.Z + halfZ) },
		{ "WallW", Vector3.new(wallT, wallH, BaseConfig.FLOOR_SIZE.Z), Vector3.new(basePos.X - halfX, wallY, basePos.Z        ) },
		{ "WallE", Vector3.new(wallT, wallH, BaseConfig.FLOOR_SIZE.Z), Vector3.new(basePos.X + halfX, wallY, basePos.Z        ) },
	}

	local walls = {}
	for _, wd in ipairs(wallDefs) do
		local wall = makePart(wd[1], wd[2], wd[3],
			Color3.fromRGB(140, 140, 140),   -- grey until claimed
			folder, 0.5)
		table.insert(walls, wall)
	end

	-- ── baseData: the single source of truth for this base ───────────────────
	return {
		-- Part references
		slot          = slot,
		folder        = folder,
		floor         = floor,
		claimPad      = claimPad,
		claimLabel    = claimLabel,    -- TextLabel (stored so text can change)
		displayPad    = displayPad,
		incomeArea    = incomeArea,
		upgradeBtn    = upgradeBtn,
		upgradePrompt = upgradePrompt,
		walls         = walls,         -- {N, S, W, E} — index order matters

		-- World info (needed when resizing walls)
		basePos       = basePos,
		baseColor     = baseColor,     -- unique tint for this slot

		-- Runtime state
		owner         = nil,           -- Player instance, nil = unclaimed
		upgradeLevel  = 0,             -- matches UPGRADE_LEVELS index
		claiming      = false,         -- debounce flag (prevents double-claim)
	}
end

-- ── Visual helpers (called after any state change) ────────────────────────────

-- Resizes and repositions the 4 walls to fit a new floor footprint.
local function resizeWalls(baseData, newFloorSize)
	local halfX  = newFloorSize.X / 2
	local halfZ  = newFloorSize.Z / 2
	local bp     = baseData.basePos
	local wallH  = BaseConfig.WALL_HEIGHT
	local wallT  = BaseConfig.WALL_THICKNESS
	local wallY  = bp.Y + wallH / 2

	-- New sizes and positions for walls in the same N,S,W,E order as buildBase
	local newDefs = {
		{ size = Vector3.new(newFloorSize.X, wallH, wallT), pos = Vector3.new(bp.X,        wallY, bp.Z - halfZ) }, -- N
		{ size = Vector3.new(newFloorSize.X, wallH, wallT), pos = Vector3.new(bp.X,        wallY, bp.Z + halfZ) }, -- S
		{ size = Vector3.new(wallT, wallH, newFloorSize.Z), pos = Vector3.new(bp.X - halfX, wallY, bp.Z       ) }, -- W
		{ size = Vector3.new(wallT, wallH, newFloorSize.Z), pos = Vector3.new(bp.X + halfX, wallY, bp.Z       ) }, -- E
	}

	for i, wall in ipairs(baseData.walls) do
		wall.Size     = newDefs[i].size
		wall.Position = newDefs[i].pos
	end
end

-- Applies floor size, colors, wall size, and upgrade-button text for the
-- current upgradeLevel.  Call this whenever upgradeLevel changes.
local function applyUpgradeVisuals(baseData)
	local level    = baseData.upgradeLevel
	local levelCfg = BaseConfig.UPGRADE_LEVELS[level]
	if not levelCfg then return end

	-- Floor size grows with each upgrade
	baseData.floor.Size = levelCfg.floorSize

	-- Floor color: use the level's color, or fall back to the slot tint
	baseData.floor.Color = levelCfg.color or baseData.baseColor

	-- Walls: resize to match the new floor, and tint them if base is claimed
	resizeWalls(baseData, levelCfg.floorSize)
	local wallColor = (level >= 1) and baseData.baseColor or Color3.fromRGB(140, 140, 140)
	for _, wall in ipairs(baseData.walls) do
		wall.Color = wallColor
	end

	-- Update the upgrade button to advertise the NEXT level's cost
	local nextLevel = level + 1
	local nextCfg   = BaseConfig.UPGRADE_LEVELS[nextLevel]

	if nextCfg and nextLevel <= BaseConfig.MAX_UPGRADE_LEVEL then
		-- There is a next tier — show its cost
		local costText = "$" .. nextCfg.cost
		baseData.upgradePrompt.ObjectText = "Base (" .. costText .. ")"
		baseData.upgradeBtn.Color         = Color3.fromRGB(80, 200, 80)  -- green
		setBillboard(baseData.upgradeBtn, "UPGRADE\n(" .. costText .. ")", Color3.fromRGB(100, 255, 100), 5)
	else
		-- Max level — disable the prompt and celebrate
		baseData.upgradePrompt.Enabled = false
		baseData.upgradeBtn.Color      = Color3.fromRGB(255, 215, 0)     -- gold
		setBillboard(baseData.upgradeBtn, "MAX LEVEL 💎", Color3.fromRGB(255, 215, 0), 5)
	end
end

-- Updates the owner sign (ClaimPad billboard) and writes Attributes.
local function updateOwnerSign(baseData)
	local levelCfg = BaseConfig.UPGRADE_LEVELS[baseData.upgradeLevel]
	local levelLabel = levelCfg and levelCfg.label or "?"

	if baseData.owner then
		-- Show who owns it and what level it's at
		baseData.claimLabel.Text = baseData.owner.Name .. "\n" .. levelLabel
		baseData.claimPad.Color    = baseData.baseColor
		baseData.claimPad.Material = Enum.Material.SmoothPlastic
	else
		-- Invite the next player to claim
		baseData.claimLabel.Text = "Touch to Claim!"
		baseData.claimPad.Color    = Color3.fromRGB(255, 255, 255)
		baseData.claimPad.Material = Enum.Material.Neon
	end

	-- Write state to Attributes (client can read these without a remote)
	baseData.folder:SetAttribute("OwnerUserId",  baseData.owner and baseData.owner.UserId or 0)
	baseData.folder:SetAttribute("OwnerName",    baseData.owner and baseData.owner.Name   or "Unclaimed")
	baseData.folder:SetAttribute("UpgradeLevel", baseData.upgradeLevel)
end

-- ── Claiming ──────────────────────────────────────────────────────────────────

local function claimBase(player, baseData)
	-- Guard 1: already claimed by someone, or in the middle of processing
	if baseData.owner or baseData.claiming then return end

	-- Guard 2: this player already owns a different base (one base per player)
	for _, bd in pairs(bases) do
		if bd.owner == player then return end
	end

	-- Lock immediately to prevent a second touch firing before we finish
	-- (Two body parts of the same player can fire Touched in the same frame)
	baseData.claiming = true

	-- Assign ownership and set to level 1 (claimed, no paid upgrades yet)
	baseData.owner        = player
	baseData.upgradeLevel = 1
	baseData.claiming     = false

	-- Enable the upgrade prompt now that the base has an owner
	baseData.upgradePrompt.Enabled = true

	updateOwnerSign(baseData)
	applyUpgradeVisuals(baseData)

	-- Tell the owner via toast notification
	notifyEvent:FireClient(player, "You claimed Base " .. baseData.slot .. "! 🎉")
	print("[BaseService]", player.Name, "claimed Base", baseData.slot)
end

-- ── Upgrading ─────────────────────────────────────────────────────────────────

local function upgradeBase(player, baseData)
	-- Only the owner may upgrade their own base
	if baseData.owner ~= player then
		notifyEvent:FireClient(player, "You don't own this base!")
		return
	end

	local nextLevel = baseData.upgradeLevel + 1
	local nextCfg   = BaseConfig.UPGRADE_LEVELS[nextLevel]

	-- Check we haven't already hit the ceiling
	if not nextCfg or nextLevel > BaseConfig.MAX_UPGRADE_LEVEL then
		notifyEvent:FireClient(player, "Your base is already at max level! 💎")
		return
	end

	-- Check the player has enough cash
	local leaderstats = player:FindFirstChild("leaderstats")
	local cashStat    = leaderstats and leaderstats:FindFirstChild("Cash")
	if not cashStat or cashStat.Value < nextCfg.cost then
		notifyEvent:FireClient(player, "Not enough cash! Need $" .. nextCfg.cost)
		return
	end

	-- Deduct cash atomically then apply the upgrade
	cashStat.Value        = cashStat.Value - nextCfg.cost
	baseData.upgradeLevel = nextLevel

	updateOwnerSign(baseData)
	applyUpgradeVisuals(baseData)

	notifyEvent:FireClient(player, "Base upgraded to " .. nextCfg.label .. "! 🚀")
	print("[BaseService]", player.Name, "upgraded Base", baseData.slot, "→ level", nextLevel)
end

-- ── Releasing ─────────────────────────────────────────────────────────────────

-- Called when the owning player leaves (or can be called explicitly later).
local function releaseBase(player)
	for _, baseData in pairs(bases) do
		if baseData.owner == player then

			-- Reset all state back to unclaimed defaults
			baseData.owner        = nil
			baseData.upgradeLevel = 0
			baseData.upgradePrompt.Enabled = false

			updateOwnerSign(baseData)
			applyUpgradeVisuals(baseData)

			print("[BaseService]", player.Name, "released Base", baseData.slot)
			return  -- a player can only own one base, so stop searching
		end
	end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function BaseService.init()

	-- Build all bases defined in GameConfig
	for slot = 1, GameConfig.BASE_COUNT do
		local basePos   = GameConfig.BASE_POSITIONS[slot]
		local baseColor = GameConfig.BASE_COLORS[slot]
		local baseData  = buildBase(slot, basePos, baseColor)
		bases[slot]     = baseData

		-- ── Wire ClaimPad touch detection ────────────────────────────────────
		-- We use a per-player debounce table to prevent the same player
		-- triggering the claim multiple times in quick succession
		-- (a character has many body parts, each of which fires Touched).
		local touchDebounce = {}   -- [UserId] = true while on cooldown

		baseData.claimPad.Touched:Connect(function(hit)
			-- hit.Parent is the character model; look up the player from it
			local character = hit.Parent
			local toucher   = Players:GetPlayerFromCharacter(character)
			if not toucher then return end  -- not a player (e.g. a ball)

			-- Skip if this player is still in debounce window
			if touchDebounce[toucher.UserId] then return end
			touchDebounce[toucher.UserId] = true

			claimBase(toucher, baseData)

			-- Release debounce after a short pause so they can re-touch
			-- after a round-trip (useful in edge cases)
			task.delay(1.5, function()
				touchDebounce[toucher.UserId] = nil
			end)
		end)

		-- ── Wire Upgrade ProximityPrompt ──────────────────────────────────────
		-- ProximityPrompt.Triggered fires on the SERVER with the player who
		-- pressed the key — no RemoteEvent needed.
		baseData.upgradePrompt.Triggered:Connect(function(triggeringPlayer)
			upgradeBase(triggeringPlayer, baseData)
		end)
	end

	-- ── Release base when the player disconnects ──────────────────────────────
	Players.PlayerRemoving:Connect(function(player)
		releaseBase(player)
	end)

	print("[BaseService] Initialised", GameConfig.BASE_COUNT, "bases.")
end

-- Expose releaseBase so init.server.luau (or future systems) can call it
BaseService.releaseBase = releaseBase

return BaseService
