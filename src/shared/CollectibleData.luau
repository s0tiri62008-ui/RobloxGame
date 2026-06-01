-- All collectible "brainrot" characters.
-- Each entry is a stub for now; future systems will spawn and steal these.
--
-- Fields:
--   id         unique key used in save data
--   name       display name shown in UI
--   cashBonus  extra cash/sec added to owner while held
--   color      part colour used when rendering the collectible in the world
--   rarity     "Common" | "Rare" | "Epic" | "Legendary"

return {
	{
		id        = "skibidi",
		name      = "Skibidi Guy",
		cashBonus = 1,
		color     = Color3.fromRGB(255, 200,  50),
		rarity    = "Common",
	},
	{
		id        = "npc_drone",
		name      = "NPC Drone",
		cashBonus = 1,
		color     = Color3.fromRGB(180, 180, 180),
		rarity    = "Common",
	},
	{
		id        = "rizz_lord",
		name      = "Rizz Lord",
		cashBonus = 2,
		color     = Color3.fromRGB(100, 200, 255),
		rarity    = "Rare",
	},
	{
		id        = "mewing_king",
		name      = "Mewing King",
		cashBonus = 3,
		color     = Color3.fromRGB( 50, 255, 150),
		rarity    = "Rare",
	},
	{
		id        = "gyatt_master",
		name      = "Gyatt Master",
		cashBonus = 4,
		color     = Color3.fromRGB(255, 100, 200),
		rarity    = "Epic",
	},
	{
		id        = "sigma_male",
		name      = "Sigma Male",
		cashBonus = 6,
		color     = Color3.fromRGB(150,  50, 255),
		rarity    = "Legendary",
	},
}
