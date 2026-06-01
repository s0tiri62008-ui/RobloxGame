--[[
	CrystalConfig
	-------------
	Defines the 5 crystal tiers and the world's mining clusters.

	TIERS
	-----
	Each tier has:
	  name   — display name
	  color  — Part colour (also used for the carried crystal + vault sphere)
	  income — cash per second this crystal adds while sitting in a vault
	  weight — relative spawn chance (all weights sum to 100 here)

	Tier index (1-5) is the canonical ID stored in vaults and save data.
	Higher index = rarer = more income.

	HOW TO ADD A TIER
	-----------------
	Append another entry to TIERS.  rollTier() automatically accounts for
	the new weight — nothing else needs to change.
]]

local CrystalConfig = {}

CrystalConfig.TIERS = {
	{ name = "Quartz",   color = Color3.fromRGB(235, 235, 235), income = 2,  weight = 55 },
	{ name = "Amethyst", color = Color3.fromRGB(160,  90, 220), income = 6,  weight = 25 },
	{ name = "Sapphire", color = Color3.fromRGB( 60, 110, 240), income = 15, weight = 12 },
	{ name = "Ruby",     color = Color3.fromRGB(225,  45,  60), income = 35, weight = 7  },
	{ name = "Diamond",  color = Color3.fromRGB(120, 230, 245), income = 80, weight = 1  },
}

-- ── Mining clusters ───────────────────────────────────────────────────────────
-- Inner ring: 8 clusters at radius 100, offset 22.5° so each sits BETWEEN two
-- bases.  y = 1 is the pad; the crystal floats slightly above it.
CrystalConfig.CLUSTER_POSITIONS = {
	Vector3.new(  92, 1,  38),
	Vector3.new(  38, 1,  92),
	Vector3.new( -38, 1,  92),
	Vector3.new( -92, 1,  38),
	Vector3.new( -92, 1, -38),
	Vector3.new( -38, 1, -92),
	Vector3.new(  38, 1, -92),
	Vector3.new(  92, 1, -38),
}

-- Seconds before a mined cluster grows a fresh crystal.
CrystalConfig.RESPAWN_TIME = 20

-- How long (seconds) a player must hold E to mine a crystal.
CrystalConfig.MINE_HOLD = 2

-- How long (seconds) a rival must hold E to crack a vault.
CrystalConfig.CRACK_HOLD = 5

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Returns a tier index (1-5) chosen by weighted random.
function CrystalConfig.rollTier()
	-- Sum all weights (so you don't have to keep them at exactly 100)
	local total = 0
	for _, tier in ipairs(CrystalConfig.TIERS) do
		total += tier.weight
	end

	-- Pick a random point in [0, total) and walk the cumulative weights
	local roll = math.random() * total
	local cumulative = 0
	for index, tier in ipairs(CrystalConfig.TIERS) do
		cumulative += tier.weight
		if roll < cumulative then
			return index
		end
	end

	return 1  -- fallback (should never hit this)
end

-- Safe lookup by index.
function CrystalConfig.getTier(index)
	return CrystalConfig.TIERS[index]
end

return CrystalConfig
