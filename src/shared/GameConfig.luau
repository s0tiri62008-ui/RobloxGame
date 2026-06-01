-- Central game config.  Tweak values here to balance the game.
-- Individual base structure/upgrades live in BaseConfig.luau.
return {

	-- ── Cash ─────────────────────────────────────────────────────────────────
	CASH_PER_TICK      = 5,   -- $ awarded to each player per tick
	CASH_TICK_INTERVAL = 1,   -- seconds between payouts

	-- ── Bases ────────────────────────────────────────────────────────────────
	-- Number of claimable bases in the world (also the server player cap).
	BASE_COUNT = 4,

	-- World positions for each base slot.  Add more slots here if you raise
	-- BASE_COUNT later; the rest of the code reads this table dynamically.
	BASE_POSITIONS = {
		Vector3.new(  0, 1, -180),  -- Slot 1 — North
		Vector3.new(  0, 1,  180),  -- Slot 2 — South
		Vector3.new(-180, 1,   0),  -- Slot 3 — West
		Vector3.new( 180, 1,   0),  -- Slot 4 — East
	},

	-- Unique tint per slot so players can tell bases apart at a glance.
	BASE_COLORS = {
		Color3.fromRGB(220,  80,  80),  -- Red
		Color3.fromRGB( 80, 120, 220),  -- Blue
		Color3.fromRGB( 80, 200,  80),  -- Green
		Color3.fromRGB(220, 180,  50),  -- Yellow
	},

	-- ── Lobby ────────────────────────────────────────────────────────────────
	LOBBY_SIZE     = Vector3.new(50, 2, 50),
	LOBBY_POSITION = Vector3.new(0,  1,  0),
}
