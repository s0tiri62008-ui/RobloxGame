--[[
	GameConfig
	----------
	Top-level game settings shared by client and server.
	Crystal tiers live in CrystalConfig; base part sizes live in BaseConfig.
]]

return {

	-- ── Bases ────────────────────────────────────────────────────────────────
	-- Number of claimable bases in the world (also the server player cap).
	BASE_COUNT = 8,

	-- Outer ring: 8 bases evenly spaced around a circle of radius 200 studs.
	-- (x, y, z) — y = 1 so the floor sits just above the terrain surface (y = 0).
	BASE_POSITIONS = {
		Vector3.new( 200, 1,    0),  -- 1  E
		Vector3.new( 141, 1,  141),  -- 2  SE
		Vector3.new(   0, 1,  200),  -- 3  S
		Vector3.new(-141, 1,  141),  -- 4  SW
		Vector3.new(-200, 1,    0),  -- 5  W
		Vector3.new(-141, 1, -141),  -- 6  NW
		Vector3.new(   0, 1, -200),  -- 7  N
		Vector3.new( 141, 1, -141),  -- 8  NE
	},

	-- One distinct tint per base so players can tell them apart at a glance.
	BASE_COLORS = {
		Color3.fromRGB(220,  80,  80),  -- 1 Red
		Color3.fromRGB(230, 140,  50),  -- 2 Orange
		Color3.fromRGB(220, 200,  50),  -- 3 Yellow
		Color3.fromRGB( 90, 200,  90),  -- 4 Green
		Color3.fromRGB( 70, 200, 200),  -- 5 Teal
		Color3.fromRGB( 80, 130, 230),  -- 6 Blue
		Color3.fromRGB(150,  90, 220),  -- 7 Purple
		Color3.fromRGB(230, 110, 200),  -- 8 Pink
	},

	-- ── Lobby ────────────────────────────────────────────────────────────────
	LOBBY_SIZE     = Vector3.new(60, 2, 60),
	LOBBY_POSITION = Vector3.new(0,  1,  0),

	-- ── Income ───────────────────────────────────────────────────────────────
	-- The vault income loop pays out every INCOME_TICK_INTERVAL seconds.
	-- Each crystal in a vault contributes its tier income (see CrystalConfig).
	INCOME_TICK_INTERVAL = 1,
}
