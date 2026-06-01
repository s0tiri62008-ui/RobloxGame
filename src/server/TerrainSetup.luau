--[[
	TerrainSetup
	------------
	Generates the entire world terrain procedurally at server start.

	WORLD LAYOUT (top-down, distances from center in studs):
	  0 – 250   Flat playable area  (lobby + bases live here)
	  250 – 550  Grassy hills        (transition, nice scenery)
	  550 – 800  Rocky mountains     (natural map boundary)
	  800 – 900  Island shore/beach  (land meets water)
	  900 +      Ocean               (water, extends to horizon)

	All terrain uses Roblox's Terrain voxel API, which means it renders
	as smooth organic shapes rather than blocky Parts.

	Surface level = Y +1  (matches the lobby/base floor height).
]]

local Workspace = game:GetService("Workspace")
local Terrain   = Workspace.Terrain

local TerrainSetup = {}

-- ── Helper: place a ring of terrain balls at a given radius ───────────────────
-- count        : how many balls to place around the full circle
-- radius       : distance from world centre (studs)
-- yCenter      : Y position of each ball's centre
-- ballRadius   : base radius of each FillBall sphere
-- material     : Enum.Material for the fill
-- radiusJitter : optional ± variation in orbit radius per ball (organic look)
-- sizeJitter   : optional extra size added to every 3rd/4th ball
local function fillRing(count, radius, yCenter, ballRadius, material, radiusJitter, sizeJitter)
	radiusJitter = radiusJitter or 0
	sizeJitter   = sizeJitter   or 0
	for i = 0, count - 1 do
		local angle  = (i / count) * 2 * math.pi
		local jitter = (i % 3 - 1) * radiusJitter    -- -1×, 0×, +1× of jitter
		local r      = radius + jitter
		local x      = math.cos(angle) * r
		local z      = math.sin(angle) * r
		local size   = ballRadius + (i % 4) * sizeJitter
		Terrain:FillBall(Vector3.new(x, yCenter, z), size, material)
	end
end

-- ── Public: generate terrain ──────────────────────────────────────────────────
function TerrainSetup.init()
	-- Wipe any terrain left over from a previous Studio session
	Terrain:Clear()

	-- ── 1. Ocean base ─────────────────────────────────────────────────────────
	-- Fill a huge area with water first.  Everything else is layered on top.
	-- Surface at Y=+1 (same as the game's floor level) so water is flush with land.
	Terrain:FillBlock(
		CFrame.new(0, -9, 0),           -- centre at Y=-9 → top of fill at Y=+1
		Vector3.new(6000, 20, 6000),    -- 6 000×6 000 stud ocean
		Enum.Material.Water
	)

	-- ── 2. Circular grass island ──────────────────────────────────────────────
	-- Overwrites the water in the centre with a round grass island.
	-- Radius 900 → water begins 900 studs from the map centre.
	Terrain:FillCylinder(
		CFrame.new(0, -9, 0),           -- same surface height as the ocean
		20,                             -- cylinder height (fills Y -19 → +1)
		900,                            -- island radius in studs
		Enum.Material.Grass
	)

	-- ── 3. Leafy-grass texture patches (flat play zone) ──────────────────────
	-- Small low balls scattered at ~320 studs give the central area visual
	-- variety without creating obstacles.
	fillRing(
		12,                        -- 12 patches evenly around the ring
		320,                       -- radius: well outside the base areas (±180)
		3,                         -- centre Y: just a couple of studs above ground
		55,                        -- ball radius: gentle mounds
		Enum.Material.LeafyGrass,
		40,                        -- ±40 stud jitter → irregular ring
		10                         -- up to +30 studs bigger every 4th ball
	)

	-- ── 4. Rolling hills (250 – 560 studs) ───────────────────────────────────
	-- Two staggered rings create overlapping, organic-looking hillsides.

	-- Inner hill ring
	fillRing(16, 390, 22, 75, Enum.Material.Grass, 35, 20)

	-- Outer hill ring, offset by half a step so hills don't line up perfectly
	fillRing(16, 530, 18, 65, Enum.Material.LeafyGrass, 30, 15)

	-- A few taller lone hills scattered for character
	local loneHills = {
		{ 310,  40,  280}, { -290, 35, -330}, {  330, 38, -290},
		{-310,  42, -280}, {  270, 36,  310}, { -340, 40,  260},
	}
	for _, h in ipairs(loneHills) do
		Terrain:FillBall(Vector3.new(h[1], h[3], h[2]), 80, Enum.Material.Grass)
	end

	-- ── 5. Rocky mountains (600 – 800 studs) ─────────────────────────────────
	-- A ring of large rock spheres creates an imposing natural border.
	-- Centres are at Y=60 so they tower well above the terrain surface (Y=1).

	-- Outer mountain ring (taller, more dramatic)
	fillRing(12, 740, 65, 170, Enum.Material.Rock, 40, 35)

	-- Inner mountain ring (slightly smaller, fills gaps)
	fillRing(12, 640, 45, 130, Enum.Material.Rock, 35, 25)

	-- ── 6. Sandy beach at the island shore ───────────────────────────────────
	-- Low flat sand balls at the water's edge soften the grass → water transition.
	-- Centred at Y=-2 so they peek just above the waterline.
	fillRing(24, 870, -2, 55, Enum.Material.Sand, 20, 8)

	print("[TerrainSetup] Terrain generated — ocean island with hills and mountains.")
end

return TerrainSetup
