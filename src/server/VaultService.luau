--[[
	VaultService
	------------
	Attaches behaviour to the Vault block that BaseService builds for each base:

	  DEPOSIT — Owner walks into their own vault while carrying a crystal →
	            it drops into the vault (auto, debounced).  We use Touched rather
	            than a prompt so it never conflicts with the rival CRACK prompt
	            that shares the same E key on the same block.

	  CRACK   — A rival holds E for CRACK_HOLD seconds on someone else's vault →
	            one random crystal is stolen and handed to the rival to carry home.

	  INCOME  — Every INCOME_TICK_INTERVAL seconds, each owned vault pays its
	            owner the summed income of all crystals inside it.

	  DISPLAY — The vault's contents are visualised as small coloured spheres
	            stacked on top of the block, rebuilt on every change.

	Depends on BaseService (base data) and CrystalService (carry handoff).
]]

local Players = game:GetService("Players")

local GameConfig    = require(game.ReplicatedStorage.Shared.GameConfig)
local BaseConfig    = require(game.ReplicatedStorage.Shared.BaseConfig)
local CrystalConfig = require(game.ReplicatedStorage.Shared.CrystalConfig)
local BaseService   = require(script.Parent.BaseService)
local CrystalService = require(script.Parent.CrystalService)
local Notify        = require(script.Parent.Notify)

local VaultService = {}

-- ── Leaderstats helper ────────────────────────────────────────────────────────
local function updateCrystalStat(baseData)
	local owner = baseData.owner
	if not owner then return end
	local leaderstats = owner:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild("Crystals")
	if stat then
		stat.Value = #baseData.crystals
	end
end

-- ── Vault display ─────────────────────────────────────────────────────────────
-- Destroys and recreates the spheres on top of the vault from baseData.crystals.
local function rebuildVaultDisplay(baseData)
	for _, sphere in ipairs(baseData.vaultSpheres) do
		sphere:Destroy()
	end
	baseData.vaultSpheres = {}

	local vault   = baseData.vault
	local perRow  = BaseConfig.VAULT_SPHERES_PER_ROW
	local spacing = BaseConfig.VAULT_SPHERE_SPACING
	local baseY   = vault.Position.Y + BaseConfig.VAULT_SIZE.Y / 2 + BaseConfig.VAULT_SPHERE_SIZE

	for i, tierIndex in ipairs(baseData.crystals) do
		local col = (i - 1) % perRow
		local row = math.floor((i - 1) / perRow)

		local sphere = Instance.new("Part")
		sphere.Shape      = Enum.PartType.Ball
		sphere.Size       = Vector3.new(BaseConfig.VAULT_SPHERE_SIZE, BaseConfig.VAULT_SPHERE_SIZE, BaseConfig.VAULT_SPHERE_SIZE)
		sphere.Color      = CrystalConfig.getTier(tierIndex).color
		sphere.Material   = Enum.Material.Neon
		sphere.Anchored   = true
		sphere.CanCollide = false
		sphere.Position   = Vector3.new(
			vault.Position.X + (col - (perRow - 1) / 2) * spacing,
			baseY + row * spacing,
			vault.Position.Z
		)
		sphere.Parent = baseData.folder
		baseData.vaultSpheres[#baseData.vaultSpheres + 1] = sphere
	end

	-- A vault can only be cracked if it's owned AND has something inside
	if baseData.crackPrompt then
		baseData.crackPrompt.Enabled = (baseData.owner ~= nil and #baseData.crystals > 0)
	end
end

-- ── Deposit ───────────────────────────────────────────────────────────────────
local function deposit(player, baseData)
	local carried = CrystalService.getCarried(player)
	if not carried then return end

	table.insert(baseData.crystals, carried.tierIndex)
	CrystalService.clearCarried(player)

	rebuildVaultDisplay(baseData)
	updateCrystalStat(baseData)

	local name = CrystalConfig.getTier(carried.tierIndex).name
	Notify.send(player, "Deposited a " .. name .. " in your vault! 💎")
end

-- ── Crack (steal) ─────────────────────────────────────────────────────────────
local function crack(thief, baseData)
	local owner = baseData.owner
	if not owner then return end
	if thief == owner then
		Notify.send(thief, "That's your own vault!")
		return
	end
	if #baseData.crystals == 0 then
		Notify.send(thief, "That vault is empty!")
		return
	end

	-- Pick a random crystal to steal
	local idx = math.random(1, #baseData.crystals)
	local tierIndex = baseData.crystals[idx]

	-- Hand it to the thief to carry home (fails if their hands are full)
	if not CrystalService.giveCarried(thief, tierIndex) then
		Notify.send(thief, "Your hands are full — deposit first, then come back!")
		return
	end

	table.remove(baseData.crystals, idx)
	rebuildVaultDisplay(baseData)
	updateCrystalStat(baseData)

	local name = CrystalConfig.getTier(tierIndex).name
	Notify.send(thief, "You cracked the vault and stole a " .. name .. "! 🦹")
	Notify.send(owner, thief.Name .. " cracked your vault and stole a " .. name .. "! 😱")
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function VaultService.init()
	local bases = BaseService.getBases()

	for _, baseData in pairs(bases) do
		local vault = baseData.vault

		-- DEPOSIT: owner touches their own vault while carrying (debounced)
		local depositDebounce = {}
		vault.Touched:Connect(function(hit)
			local toucher = Players:GetPlayerFromCharacter(hit.Parent)
			if not toucher then return end
			if baseData.owner ~= toucher then return end        -- only the owner
			if depositDebounce[toucher.UserId] then return end
			depositDebounce[toucher.UserId] = true

			deposit(toucher, baseData)

			task.delay(0.5, function()
				depositDebounce[toucher.UserId] = nil
			end)
		end)

		-- CRACK: rival holds E on the vault
		local crackPrompt = Instance.new("ProximityPrompt")
		crackPrompt.ActionText            = "Crack Vault"
		crackPrompt.ObjectText            = "Steal a crystal"
		crackPrompt.HoldDuration          = CrystalConfig.CRACK_HOLD
		crackPrompt.MaxActivationDistance = 12
		crackPrompt.RequiresLineOfSight   = false
		crackPrompt.Enabled               = false  -- enabled when vault has loot
		crackPrompt.Parent                = vault
		baseData.crackPrompt = crackPrompt

		crackPrompt.Triggered:Connect(function(plr)
			crack(plr, baseData)
		end)
	end

	-- When a base is released (owner left), clear its vault display
	BaseService.onBaseReleased = function(baseData)
		baseData.crystals = {}
		rebuildVaultDisplay(baseData)
	end

	-- ── Income loop ──────────────────────────────────────────────────────────
	task.spawn(function()
		while true do
			task.wait(GameConfig.INCOME_TICK_INTERVAL)
			for _, baseData in pairs(bases) do
				local owner = baseData.owner
				if owner and #baseData.crystals > 0 then
					local leaderstats = owner:FindFirstChild("leaderstats")
					local cash = leaderstats and leaderstats:FindFirstChild("Cash")
					if cash then
						local income = 0
						for _, tierIndex in ipairs(baseData.crystals) do
							income += CrystalConfig.getTier(tierIndex).income
						end
						cash.Value += income
					end
				end
			end
		end
	end)

	print("[VaultService] Vault logic and income loop ready.")
end

return VaultService
