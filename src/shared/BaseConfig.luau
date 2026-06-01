--[[
	BaseConfig
	----------
	Physical layout of a single player base.  All positions are OFFSETS
	added to the base centre (basePos from GameConfig.BASE_POSITIONS).

	Top-down layout of one base (player walks in from the lobby side):

	          ┌──────── Vault ────────┐   ← back wall (crystals stored here)
	          │                        │
	          │      Claim Pad         │   ← centre (touch to claim)
	          │                        │
	          └──[Upgrade]─────────────┘   ← front-right podium
]]

return {

	-- ── Part sizes ────────────────────────────────────────────────────────────
	FLOOR_SIZE           = Vector3.new(50, 2, 50),
	CLAIM_PAD_SIZE       = Vector3.new(12, 0.5, 12),
	VAULT_SIZE           = Vector3.new(14, 10, 8),
	UPGRADE_PODIUM_SIZE  = Vector3.new(6, 5, 6),

	WALL_HEIGHT    = 8,
	WALL_THICKNESS = 1.5,

	-- ── Offsets from base centre ──────────────────────────────────────────────
	CLAIM_PAD_OFFSET      = Vector3.new(  0, 1.3,   0),  -- centre of the floor
	VAULT_OFFSET          = Vector3.new(  0, 6,   -18),  -- back of base, tall block
	UPGRADE_PODIUM_OFFSET = Vector3.new( 16, 3.5,  16),  -- front-right corner

	-- ── Vault crystal display ─────────────────────────────────────────────────
	-- Small spheres are arranged in a grid on TOP of the vault to visualise
	-- its contents.  PER_ROW controls wrapping; SPACING is the gap in studs.
	VAULT_SPHERE_SIZE    = 2,
	VAULT_SPHERE_SPACING = 2.6,
	VAULT_SPHERES_PER_ROW = 5,
}
