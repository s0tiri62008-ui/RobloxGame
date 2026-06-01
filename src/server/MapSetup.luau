--[[
	MapSetup
	--------
	Builds the static, player-independent map geometry:
	  • Central lobby platform + golden spawn pad
	  • A physical "leaderboard sign" board in the lobby
	  • Dirt paths radiating out toward the bases

	Player bases are built by BaseService; crystal clusters by CrystalService.
	The leaderboard board is created here but its TEXT is refreshed live by
	LeaderboardService.
]]

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local Workspace  = game:GetService("Workspace")

local MapSetup = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────
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
	bb.Size        = UDim2.new(0, 220, 0, 55)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.Parent      = part

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	lbl.BackgroundTransparency = 0.45
	lbl.Text                   = text
	lbl.TextColor3             = textColor or Color3.new(1, 1, 1)
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.Parent                 = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent       = lbl
end

-- ── Public ────────────────────────────────────────────────────────────────────
function MapSetup.init()
	local lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name   = "Lobby"
	lobbyFolder.Parent = Workspace

	local mapFolder = Instance.new("Folder")
	mapFolder.Name   = "Map"
	mapFolder.Parent = Workspace

	-- ── Lobby platform ───────────────────────────────────────────────────────
	local lobby = makePart("LobbyPlatform",
		GameConfig.LOBBY_SIZE,
		GameConfig.LOBBY_POSITION,
		Color3.fromRGB(210, 210, 215),
		lobbyFolder)
	addBillboard(lobby, "💎 CRYSTAL BANDITS", Color3.fromRGB(120, 230, 245))

	-- Golden spawn pad in the centre
	makePart("SpawnPad",
		Vector3.new(14, 0.5, 14),
		GameConfig.LOBBY_POSITION + Vector3.new(0, 1.25, 0),
		Color3.fromRGB(255, 215, 0),
		lobbyFolder)

	-- ── Leaderboard sign ─────────────────────────────────────────────────────
	-- A tall board with a SurfaceGui that LeaderboardService refreshes.
	local board = makePart("LeaderboardSign",
		Vector3.new(16, 12, 1),
		GameConfig.LOBBY_POSITION + Vector3.new(0, 7, -28),
		Color3.fromRGB(30, 30, 35),
		lobbyFolder)

	local surface = Instance.new("SurfaceGui")
	surface.Name        = "Board"
	surface.Face        = Enum.NormalId.Front
	surface.CanvasSize  = Vector2.new(400, 300)
	surface.Parent      = board

	local title = Instance.new("TextLabel")
	title.Name                 = "Title"
	title.Size                 = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text                 = "🏆 RICHEST BANDITS"
	title.TextColor3           = Color3.fromRGB(255, 215, 0)
	title.TextScaled           = true
	title.Font                 = Enum.Font.GothamBold
	title.Parent               = surface

	-- LeaderboardService writes the ranking into this label
	local list = Instance.new("TextLabel")
	list.Name                  = "List"
	list.Position              = UDim2.new(0, 0, 0.15, 0)
	list.Size                  = UDim2.new(1, 0, 0.85, 0)
	list.BackgroundTransparency = 1
	list.Text                  = "Waiting for players..."
	list.TextColor3            = Color3.fromRGB(255, 255, 255)
	list.TextScaled            = false
	list.TextSize              = 28
	list.Font                  = Enum.Font.GothamMedium
	list.TextYAlignment        = Enum.TextYAlignment.Top
	list.TextXAlignment        = Enum.TextXAlignment.Left
	list.Parent                = surface

	-- ── Paths toward the 4 cardinal bases (visual guides) ────────────────────
	local pathDefs = {
		{ pos = Vector3.new( 110, 0.6,   0), size = Vector3.new(120, 1, 8) },
		{ pos = Vector3.new(-110, 0.6,   0), size = Vector3.new(120, 1, 8) },
		{ pos = Vector3.new(   0, 0.6, 110), size = Vector3.new(8, 1, 120) },
		{ pos = Vector3.new(   0, 0.6,-110), size = Vector3.new(8, 1, 120) },
	}
	for i, pd in ipairs(pathDefs) do
		makePart("Path" .. i, pd.size, pd.pos,
			Color3.fromRGB(180, 160, 120), mapFolder)
	end

	print("[MapSetup] Lobby and paths built.")
end

return MapSetup
