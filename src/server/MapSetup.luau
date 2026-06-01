--[[
	MapSetup
	--------
	Builds the static map geometry that exists independently of any player:
		• Green grass ground layer
		• Central lobby platform + spawn pad
		• Dirt paths connecting lobby to each base slot

	NOTE: Player base geometry is intentionally NOT built here.
	      BaseService.luau handles all base construction and logic.
]]

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")

local MapSetup = {}

-- ── Helper: create an anchored, smooth Part ───────────────────────────────────
local function makePart(name, size, position, color, parent)
	local p = Instance.new("Part")
	p.Name          = name
	p.Size          = size
	p.Position      = position
	p.Color         = color
	p.Anchored      = true
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent        = parent
	return p
end

-- ── Helper: floating billboard label above a Part ────────────────────────────
local function addBillboard(part, text, textColor)
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 220, 0, 55)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = part

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	lbl.BackgroundTransparency = 0.45
	lbl.Text                   = text
	lbl.TextColor3             = textColor or Color3.fromRGB(255, 255, 255)
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.Parent                 = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent       = lbl
end

-- ── Public: build all static map objects ─────────────────────────────────────
function MapSetup.init()

	-- Folder keeps the Workspace Explorer tidy
	local mapFolder = Instance.new("Folder")
	mapFolder.Name   = "Map"
	mapFolder.Parent = Workspace

	local lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name   = "Lobby"
	lobbyFolder.Parent = Workspace

	-- Ground Part removed — TerrainSetup.luau generates the terrain surface.

	-- ── Lobby platform ───────────────────────────────────────────────────────
	local lobby = makePart("LobbyPlatform",
		GameConfig.LOBBY_SIZE,
		GameConfig.LOBBY_POSITION,
		Color3.fromRGB(220, 220, 220),
		lobbyFolder)
	addBillboard(lobby, "⭐  LOBBY", Color3.fromRGB(255, 220, 50))

	-- Golden spawn pad in the centre so players know where they'll appear.
	local spawnPad = makePart("SpawnPad",
		Vector3.new(12, 0.5, 12),
		Vector3.new(0, 2.25, 0),
		Color3.fromRGB(255, 215, 0),
		lobbyFolder)
	addBillboard(spawnPad, "SPAWN", Color3.fromRGB(255, 255, 100))

	-- ── Paths (lobby → each base slot) ───────────────────────────────────────
	-- Simple rectangular strips, one per BASE_COUNT slot.
	-- Each path centre is roughly halfway between lobby (0,0,0) and the base.
	local pathDefs = {
		{ pos = Vector3.new(   0, 1,  -90), size = Vector3.new(10, 1, 140) }, -- → North
		{ pos = Vector3.new(   0, 1,   90), size = Vector3.new(10, 1, 140) }, -- → South
		{ pos = Vector3.new( -90, 1,    0), size = Vector3.new(140, 1, 10) }, -- → West
		{ pos = Vector3.new(  90, 1,    0), size = Vector3.new(140, 1, 10) }, -- → East
	}

	for i = 1, GameConfig.BASE_COUNT do
		local pd = pathDefs[i]
		if pd then
			makePart("Path" .. i, pd.size, pd.pos,
				Color3.fromRGB(180, 160, 120), mapFolder)
		end
	end

	-- ── Cash Button ──────────────────────────────────────────────────────────
	-- Bright green pad offset from the spawn pad so players can't accidentally
	-- stand on both at once.  Gives $5000 per touch with a per-player debounce.
	local cashBtn = makePart("CashButton",
		Vector3.new(10, 0.5, 10),
		Vector3.new(16, 2.25, 0),   -- to the right of the spawn pad
		Color3.fromRGB(0, 200, 80),
		lobbyFolder)
	cashBtn.Material = Enum.Material.Neon
	addBillboard(cashBtn, "💰 +$5000", Color3.fromRGB(100, 255, 150))

	local touchDebounce = {}  -- [UserId] = true while on cooldown

	cashBtn.Touched:Connect(function(hit)
		local character = hit.Parent
		local player    = Players:GetPlayerFromCharacter(character)
		if not player then return end
		if touchDebounce[player.UserId] then return end

		touchDebounce[player.UserId] = true

		local leaderstats = player:FindFirstChild("leaderstats")
		local cash        = leaderstats and leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value += 5000
		end

		-- 2-second cooldown so stepping on it repeatedly doesn't spam cash
		task.delay(2, function()
			touchDebounce[player.UserId] = nil
		end)
	end)

	print("[MapSetup] Static map built.")
end

return MapSetup
