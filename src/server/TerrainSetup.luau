--[[
	TerrainSetup
	------------
	Generates world terrain procedurally at server start.

	SURFACE LEVEL = Y 0
	-------------------
	Roblox terrain voxels are 4×4×4 studs, snapped to the grid at
	multiples of 4 (…-4, 0, 4, 8…).  If we fill "to Y=+1" the engine
	fills the entire 0→4 voxel, making the visible surface land at Y=4
	which buries the base floors (which run from Y=0 to Y=2).

	Fixing this: fill centre at Y=-10, height 20 → region Y=-20 to Y=0.
	Y=0 is exactly a voxel boundary, so the surface appears cleanly at
	Y=0 and the base floors (Y=0→2) sit visibly on top of the terrain.

	WORLD LAYOUT (radius from map centre in studs):
	  0 – 250   Flat play area     (lobby + 4 bases live here)
	  250 – 560  Grassy hills       (scenery, never overlaps bases)
	  560 – 800  Rocky mountains    (natural boundary ring)
	  800 – 900  Sandy beach        (island shore)
	  900 +      Ocean              (water to the horizon)
]]

local Workspace = game:GetService("Workspace")
local Terrain   = Workspace.Terrain

local TerrainSetup = {}

-- ── Helper: place a ring of FillBall calls around a given radius ──────────────
local function fillRing(count, radius, yCenter, ballRadius, material, radiusJitter, sizeJitter)
	radiusJitter = radiusJitter or 0
	sizeJitter   = sizeJitter   or 0
	for i = 0, count - 1 do
		local angle  = (i / count) * 2 * math.pi
		local jitter = (i % 3 - 1) * radiusJitter   -- -1×, 0×, +1× alternating
		local r      = radius + jitter
		local size   = ballRadius + (i % 4) * sizeJitter
		Terrain:FillBall(
			Vector3.new(math.cos(angle) * r, yCenter, math.sin(angle) * r),
			size,
			material
		)
	end
end

-- ── Public ────────────────────────────────────────────────────────────────────
function TerrainSetup.init()
	Terrain:Clear()

	-- ── 1. Ocean ──────────────────────────────────────────────────────────────
	-- Flood everything with water first; the grass island overwrites the centre.
	-- Centre Y=-10, height 20 → fills Y=-20 to Y=0 → surface at Y=0.
	Terrain:FillBlock(
		CFrame.new(0, -10, 0),
		Vector3.new(6000, 20, 6000),
		Enum.Material.Water
	)

	-- ── 2. Circular grass island (radius 900) ─────────────────────────────────
	-- Overwrites the water in the centre. Same Y centre and height as the ocean
	-- so surfaces are flush: land and water both appear at Y=0.
	Terrain:FillCylinder(
		CFrame.new(0, -10, 0),
		20,     -- height: fills Y=-20 to Y=0
		900,    -- island radius
		Enum.Material.Grass
	)

	-- ── 3. LeafyGrass accent patches (radius ~370) ───────────────────────────
	-- Placed well outside the base slots (±180 studs) so they never overlap.
	-- yCenter=8: bumps rise ~8 studs above terrain — gentle, not blocky.
	fillRing(12, 370, 8, 50, Enum.Material.LeafyGrass, 30, 8)

	-- ── 4. Rolling grass hills (radius 400 – 560) ────────────────────────────
	-- Two staggered rings for an organic look.  Closest possible edge
	-- of any ball: (400-35-80) = 285 studs from centre — safely clear of bases.
	fillRing(16, 420, 25, 80, Enum.Material.Grass,      35, 18)
	fillRing(16, 545, 20, 68, Enum.Material.LeafyGrass, 30, 14)

	-- A handful of taller lone hills for variety.
	-- Format: { x, z, yBallCentre } — FillBall is at Vector3(x, y, z)
	local loneHills = {
		{ 330,  290, 28 },
		{-300, -320, 24 },
		{ 340, -280, 26 },
		{-320, -275, 28 },
		{ 280,  320, 22 },
		{-350,  265, 26 },
	}
	for _, h in ipairs(loneHills) do
		-- h[1]=x, h[2]=z, h[3]=yBallCentre
		Terrain:FillBall(Vector3.new(h[1], h[3], h[2]), 85, Enum.Material.Grass)
	end

	-- ── 5. Rocky mountains (radius 640 – 760) ────────────────────────────────
	-- Two rings at slightly different radii create a dense mountain wall.
	fillRing(12, 760, 65, 165, Enum.Material.Rock, 35, 30)
	fillRing(12, 645, 45, 130, Enum.Material.Rock, 30, 22)

	-- ── 6. Sandy beach at the island shore (radius ~870) ─────────────────────
	-- Balls centred slightly below terrain so only the crown of each sphere
	-- pokes through — a low, muted sandy fringe where land meets water.
	fillRing(24, 870, -8, 52, Enum.Material.Sand, 18, 6)

	print("[TerrainSetup] Terrain generated.")
end

return TerrainSetup
