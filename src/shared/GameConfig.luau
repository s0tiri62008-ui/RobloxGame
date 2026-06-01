-- Central config: tweak these values to balance the game easily
return {

	-- Cash
	CASH_PER_TICK      = 5,   -- cash earned per interval
	CASH_TICK_INTERVAL = 1,   -- seconds between payouts

	-- How many player bases to pre-build (max players per server)
	MAX_PLAYERS = 6,

	-- Base floor size (X, Y, Z)
	BASE_SIZE = Vector3.new(60, 2, 60),

	-- Where each base sits in the world (one slot per player)
	BASE_POSITIONS = {
		Vector3.new(  0, 1, -180),  -- 1 North
		Vector3.new(  0, 1,  180),  -- 2 South
		Vector3.new(-180, 1,   0),  -- 3 West
		Vector3.new( 180, 1,   0),  -- 4 East
		Vector3.new(-130, 1, -130), -- 5 NW
		Vector3.new( 130, 1,  130), -- 6 SE
	},

	-- One distinct colour per base slot
	BASE_COLORS = {
		Color3.fromRGB(220,  80,  80),  -- Red
		Color3.fromRGB( 80, 120, 220),  -- Blue
		Color3.fromRGB( 80, 200,  80),  -- Green
		Color3.fromRGB(220, 180,  50),  -- Yellow
		Color3.fromRGB(180,  80, 220),  -- Purple
		Color3.fromRGB( 80, 200, 200),  -- Cyan
	},

	-- Central lobby platform
	LOBBY_SIZE     = Vector3.new(50, 2, 50),
	LOBBY_POSITION = Vector3.new(0, 1, 0),

	-- Display pad inside each base (relative offset from base centre)
	DISPLAY_PAD_SIZE   = Vector3.new(22, 0.5, 22),
	DISPLAY_PAD_OFFSET = Vector3.new(0, 1.5, -10),
}
