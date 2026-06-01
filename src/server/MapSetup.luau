-- Procedurally builds the entire map at server start.
-- No parts are stored in the project file — everything is created here
-- so it is easy to tweak positions/sizes in GameConfig.luau.

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")

local MapSetup = {}

-- Tracks which base slot (1-MAX_PLAYERS) belongs to which UserId
MapSetup.baseAssignments = {}  -- [slotIndex] = UserId
MapSetup.basesFolder     = nil

-- ── Helpers ──────────────────────────────────────────────────────────────────

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

local function addBillboard(part, text, textColor)
	local bb = Instance.new("BillboardGui")
	bb.Size         = UDim2.new(0, 220, 0, 55)
	bb.StudsOffset  = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop  = false
	bb.Parent       = part

	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
	lbl.BackgroundTransparency = 0.45
	lbl.Text                 = text
	lbl.TextColor3           = textColor or Color3.fromRGB(255, 255, 255)
	lbl.TextScaled           = true
	lbl.Font                 = Enum.Font.GothamBold
	lbl.Parent               = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent       = lbl

	return lbl  -- returned so the label text can be updated later
end

-- ── Map builder ──────────────────────────────────────────────────────────────

function MapSetup.init()

	-- Root folders keep the Explorer clean
	local mapFolder = Instance.new("Folder")
	mapFolder.Name   = "Map"
	mapFolder.Parent = Workspace

	local lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name   = "Lobby"
	lobbyFolder.Parent = Workspace

	local basesFolder = Instance.new("Folder")
	basesFolder.Name   = "PlayerBases"
	basesFolder.Parent = Workspace
	MapSetup.basesFolder = basesFolder

	-- ── Ground (green grass layer on top of the baseplate) ──────────────────
	makePart("Ground",
		Vector3.new(512, 2, 512),
		Vector3.new(0, 0, 0),
		Color3.fromRGB(106, 127, 63),
		mapFolder)

	-- ── Central Lobby ────────────────────────────────────────────────────────
	local lobby = makePart("LobbyPlatform",
		GameConfig.LOBBY_SIZE,
		GameConfig.LOBBY_POSITION,
		Color3.fromRGB(220, 220, 220),
		lobbyFolder)
	addBillboard(lobby, "⭐ LOBBY", Color3.fromRGB(255, 220, 50))

	-- Golden spawn pad in the centre of the lobby
	local spawnPad = makePart("SpawnPad",
		Vector3.new(12, 0.5, 12),
		Vector3.new(0, 2.25, 0),
		Color3.fromRGB(255, 215, 0),
		lobbyFolder)
	addBillboard(spawnPad, "SPAWN HERE", Color3.fromRGB(255, 255, 100))

	-- ── Paths from lobby to each base ────────────────────────────────────────
	-- Simple rectangular strips; direction is lobby→base midpoint
	local pathDefs = {
		{ pos = Vector3.new(  0, 1,  -90), size = Vector3.new(10, 1, 140) },
		{ pos = Vector3.new(  0, 1,   90), size = Vector3.new(10, 1, 140) },
		{ pos = Vector3.new( -90, 1,   0), size = Vector3.new(140, 1, 10) },
		{ pos = Vector3.new(  90, 1,   0), size = Vector3.new(140, 1, 10) },
		{ pos = Vector3.new( -65, 1,  -65), size = Vector3.new( 10, 1,  10) },
		{ pos = Vector3.new(  65, 1,   65), size = Vector3.new( 10, 1,  10) },
	}
	for i, pd in ipairs(pathDefs) do
		makePart("Path" .. i, pd.size, pd.pos,
			Color3.fromRGB(180, 160, 120), mapFolder)
	end

	-- ── Player Bases ─────────────────────────────────────────────────────────
	for slot = 1, GameConfig.MAX_PLAYERS do
		local basePos   = GameConfig.BASE_POSITIONS[slot]
		local baseColor = GameConfig.BASE_COLORS[slot]

		local baseFolder = Instance.new("Folder")
		baseFolder.Name   = "Base_" .. slot
		baseFolder.Parent = basesFolder

		-- Floor
		local floor = makePart("Floor",
			GameConfig.BASE_SIZE,
			basePos,
			baseColor,
			baseFolder)

		local floorLabel = addBillboard(floor, "BASE " .. slot,
			Color3.fromRGB(255, 255, 255))
		-- Store the label so assignBase can rename it
		floor:SetAttribute("SlotIndex", slot)
		floor:SetAttribute("LabelText", "BASE " .. slot)

		-- Display pad (where collected brainrots will be placed)
		local padPos = basePos + GameConfig.DISPLAY_PAD_OFFSET
		local pad = makePart("DisplayPad",
			GameConfig.DISPLAY_PAD_SIZE,
			padPos,
			Color3.fromRGB(240, 240, 255),
			baseFolder)
		pad.Material = Enum.Material.Neon
		pad.Color    = Color3.fromRGB(200, 200, 255)
		addBillboard(pad, "Collectibles Here", Color3.fromRGB(180, 180, 255))

		-- Invisible boundary walls (CAN be walked through by design for now;
		-- CanCollide = true means players bounce off — set false to remove walls)
		local halfX = GameConfig.BASE_SIZE.X / 2
		local halfZ = GameConfig.BASE_SIZE.Z / 2
		local wallH = 8
		local wallY = basePos.Y + wallH / 2

		local wallDefs = {
			{ name = "WallN", size = Vector3.new(GameConfig.BASE_SIZE.X, wallH, 2),
			  pos  = Vector3.new(basePos.X,        wallY, basePos.Z - halfZ) },
			{ name = "WallS", size = Vector3.new(GameConfig.BASE_SIZE.X, wallH, 2),
			  pos  = Vector3.new(basePos.X,        wallY, basePos.Z + halfZ) },
			{ name = "WallW", size = Vector3.new(2, wallH, GameConfig.BASE_SIZE.Z),
			  pos  = Vector3.new(basePos.X - halfX, wallY, basePos.Z) },
			{ name = "WallE", size = Vector3.new(2, wallH, GameConfig.BASE_SIZE.Z),
			  pos  = Vector3.new(basePos.X + halfX, wallY, basePos.Z) },
		}
		for _, wd in ipairs(wallDefs) do
			local wall = makePart(wd.name, wd.size, wd.pos, baseColor, baseFolder)
			wall.Transparency = 0.6
		end
	end

	print("[MapSetup] Map built with", GameConfig.MAX_PLAYERS, "player bases.")
end

-- ── Base assignment ───────────────────────────────────────────────────────────

-- Call when a player joins to give them a colour-coded base.
-- Returns the slot index (1–MAX_PLAYERS), or nil if the server is full.
function MapSetup.assignBase(player)
	-- Already assigned? Return existing slot.
	for slot, uid in pairs(MapSetup.baseAssignments) do
		if uid == player.UserId then
			return slot
		end
	end

	-- Find a free slot
	for slot = 1, GameConfig.MAX_PLAYERS do
		if not MapSetup.baseAssignments[slot] then
			MapSetup.baseAssignments[slot] = player.UserId

			-- Rename the billboard on the base floor
			local baseFolder = MapSetup.basesFolder:FindFirstChild("Base_" .. slot)
			if baseFolder then
				local floor = baseFolder:FindFirstChild("Floor")
				if floor then
					local bb = floor:FindFirstChildOfClass("BillboardGui")
					if bb then
						local lbl = bb:FindFirstChildOfClass("TextLabel")
						if lbl then
							lbl.Text = player.Name .. "'s Base"
						end
					end
				end
			end

			print("[MapSetup]", player.Name, "→ Base slot", slot)
			return slot
		end
	end

	warn("[MapSetup] No free base slots for", player.Name)
	return nil
end

-- Call when a player leaves to free their slot.
function MapSetup.releaseBase(player)
	for slot, uid in pairs(MapSetup.baseAssignments) do
		if uid == player.UserId then
			MapSetup.baseAssignments[slot] = nil

			-- Reset the billboard text
			local baseFolder = MapSetup.basesFolder:FindFirstChild("Base_" .. slot)
			if baseFolder then
				local floor = baseFolder:FindFirstChild("Floor")
				if floor then
					local bb = floor:FindFirstChildOfClass("BillboardGui")
					if bb then
						local lbl = bb:FindFirstChildOfClass("TextLabel")
						if lbl then
							lbl.Text = "BASE " .. slot
						end
					end
				end
			end

			print("[MapSetup]", player.Name, "released Base slot", slot)
			return
		end
	end
end

return MapSetup
