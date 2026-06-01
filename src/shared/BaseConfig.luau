--[[
	BaseConfig
	----------
	Defines the physical layout of every player base and the upgrade ladder.

	HOW UPGRADES WORK
	-----------------
	UPGRADE_LEVELS is a table indexed by level number.
		Level 0 = unclaimed (grey, default state)
		Level 1 = claimed   (free — just touch the ClaimPad)
		Level 2+ = paid upgrades

	To add a new upgrade tier, append another entry to UPGRADE_LEVELS and
	raise MAX_UPGRADE_LEVEL.  Nothing else in the codebase needs to change.
--]]

return {

	-- ── Part sizes ────────────────────────────────────────────────────────────
	FLOOR_SIZE        = Vector3.new(60, 2, 60),   -- base floor footprint
	CLAIM_PAD_SIZE    = Vector3.new(14, 0.5, 14), -- glowing pad in the center
	DISPLAY_PAD_SIZE  = Vector3.new(20, 0.5, 20), -- where collectibles will sit
	INCOME_AREA_SIZE  = Vector3.new(10, 0.5, 10), -- where cash pools up (future)
	UPGRADE_BTN_SIZE  = Vector3.new( 8, 4,    8), -- tall block the player walks to

	WALL_HEIGHT    = 8,  -- how tall the surrounding walls are
	WALL_THICKNESS = 2,  -- wall depth

	-- ── Local offsets (added to basePos to place each part) ──────────────────
	-- basePos is the centre of the floor (e.g. Vector3(0,1,-180)).
	-- Y offset of 1.3 puts a 0.5-thick pad just above the floor surface.
	CLAIM_PAD_OFFSET    = Vector3.new(  0, 1.3,    0),  -- centre of base
	DISPLAY_PAD_OFFSET  = Vector3.new(  0, 1.3,  -14),  -- back of base
	INCOME_AREA_OFFSET  = Vector3.new( 14, 1.3,   14),  -- front-right corner
	UPGRADE_BTN_OFFSET  = Vector3.new(-14, 3,     14),  -- front-left corner
	--                                  ^  ^       ^
	--                                  X  Y       Z

	-- ── Upgrade ladder ────────────────────────────────────────────────────────
	--   cost      : cash required to reach this level (0 = free)
	--   floorSize : new Size for the floor Part after upgrading
	--   color     : floor color at this level; nil = keep the slot's unique tint
	--   label     : short string shown on the owner sign

	UPGRADE_LEVELS = {
		[0] = {   -- unclaimed — shown before anyone touches the pad
			cost      = 0,
			floorSize = Vector3.new(60, 2, 60),
			color     = Color3.fromRGB(140, 140, 140),  -- neutral grey
			label     = "Unclaimed",
		},
		[1] = {   -- claimed — free, just walk onto the ClaimPad
			cost      = 0,
			floorSize = Vector3.new(60, 2, 60),
			color     = nil,   -- nil → BaseService uses the slot's own color
			label     = "Claimed",
		},
		[2] = {   -- first paid upgrade
			cost      = 100,
			floorSize = Vector3.new(75, 2, 75),
			color     = Color3.fromRGB(255, 215,   0),  -- gold
			label     = "Level 2 ⭐",
		},
		[3] = {   -- second paid upgrade  (uncomment when ready to enable)
			cost      = 300,
			floorSize = Vector3.new(90, 2, 90),
			color     = Color3.fromRGB(255, 120,  20),  -- orange
			label     = "Level 3 🔥",
		},
		[4] = {   -- third paid upgrade
			cost      = 700,
			floorSize = Vector3.new(110, 2, 110),
			color     = Color3.fromRGB(100,  60, 255),  -- purple diamond
			label     = "Level 4 💎",
		},
	},

	MAX_UPGRADE_LEVEL = 4,  -- raise this when you add more tiers above
}
