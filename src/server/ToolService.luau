--[[
	ToolService
	-----------
	Creates two tools and places them in StarterPack so every player spawns
	with both in their inventory.

	  CrystalPickaxe — must be EQUIPPED (held out) to mine a crystal cluster.
	                   No special activation logic; CrystalService checks for it.

	  VaultBat       — left-click while equipped knocks nearby players back and
	                   cancels any vault-crack hold they have in progress.

	BAT FLOW (server-authoritative)
	--------------------------------
	  1. Player equips bat, clicks.
	  2. LocalScript embedded in the bat fires RemoteEvent "BatSwing" → server.
	  3. Server validates (cooldown, range), applies knockback to nearby players,
	     and calls VaultService.interruptCrackBy(target) for each hit player.

	WHY LocalScript.Source?
	-----------------------
	The tools are created in code (no Roblox model files).  Setting
	LocalScript.Source on the server is the standard code-only pattern for
	tool scripts — it runs on the client when the cloned tool is loaded into
	the player's character.
]]

local Players    = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VaultService is required lazily (it isn't loaded yet when this module is
-- first required, but it IS loaded before any BatSwing remote fires).
local _vaultService = nil
local function getVaultService()
	if not _vaultService then
		_vaultService = require(script.Parent.VaultService)
	end
	return _vaultService
end

local ToolService = {}

-- ── Constants ─────────────────────────────────────────────────────────────────
local SWING_RANGE     = 14   -- studs — hit box radius around the swinger
local KNOCKBACK_SPEED = 65   -- studs/s applied to the target's root
local SWING_COOLDOWN  = 1.5  -- seconds between swings per player

-- Track per-player swing cooldown
local swingCooldown = {}     -- [userId] = true while on cooldown

-- ── Tool factories ────────────────────────────────────────────────────────────

local function makePickaxe()
	local tool = Instance.new("Tool")
	tool.Name             = "CrystalPickaxe"
	tool.ToolTip          = "Equip to mine crystal clusters"
	tool.CanBeDropped     = false
	tool.RequiresHandle   = true
	tool.GripPos          = Vector3.new(0, 0, 1.2)

	-- Handle: the wooden shaft (what the hand grips)
	local handle = Instance.new("Part")
	handle.Name     = "Handle"
	handle.Size     = Vector3.new(0.7, 0.7, 4)
	handle.Color    = Color3.fromRGB(106, 79, 52)  -- brown wood
	handle.Material = Enum.Material.Wood
	handle.Parent   = tool

	-- Pickaxe head welded to the top end of the shaft
	local head = Instance.new("Part")
	head.Name     = "Head"
	head.Size     = Vector3.new(2.8, 0.8, 0.8)
	head.Color    = Color3.fromRGB(163, 163, 168)  -- grey metal
	head.Material = Enum.Material.Metal
	head.Parent   = tool

	local headCF = handle.CFrame * CFrame.new(0, 0.4, -2)
	head.CFrame  = headCF

	local weld = Instance.new("WeldConstraint")
	weld.Part0  = handle
	weld.Part1  = head
	weld.Parent = handle

	return tool
end

local function makeBat()
	local tool = Instance.new("Tool")
	tool.Name             = "VaultBat"
	tool.ToolTip          = "Swing to defend your vault!"
	tool.CanBeDropped     = false
	tool.RequiresHandle   = true
	tool.GripPos          = Vector3.new(0, 0, 1.8)

	-- Handle: the grip end
	local handle = Instance.new("Part")
	handle.Name     = "Handle"
	handle.Size     = Vector3.new(0.9, 0.9, 3.5)
	handle.Color    = Color3.fromRGB(200, 155, 85)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent   = tool

	-- Barrel: the wide striking end
	local barrel = Instance.new("Part")
	barrel.Name     = "Barrel"
	barrel.Size     = Vector3.new(1.8, 1.8, 2.2)
	barrel.Color    = Color3.fromRGB(210, 165, 90)
	barrel.Material = Enum.Material.SmoothPlastic
	barrel.Parent   = tool

	barrel.CFrame = handle.CFrame * CFrame.new(0, 0, -2.8)

	local weld = Instance.new("WeldConstraint")
	weld.Part0  = handle
	weld.Part1  = barrel
	weld.Parent = handle

	-- NOTE: no LocalScript here — bat click is handled by ToolHandler.luau
	-- (a StarterPlayerScripts module). LocalScript.Source is read-only in
	-- running games, so we use a proper client module instead.

	return tool
end

-- ── Bat swing handler ─────────────────────────────────────────────────────────

local function handleSwing(swinger)
	if swingCooldown[swinger.UserId] then return end
	swingCooldown[swinger.UserId] = true

	local swingerChar = swinger.Character
	local swingerHRP  = swingerChar and swingerChar:FindFirstChild("HumanoidRootPart")
	if not swingerHRP then
		swingCooldown[swinger.UserId] = nil
		return
	end

	local vs = getVaultService()

	-- Check every other player for proximity
	for _, target in Players:GetPlayers() do
		if target == swinger then continue end
		local targetChar = target.Character
		local targetHRP  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		if not targetHRP then continue end

		local distance = (targetHRP.Position - swingerHRP.Position).Magnitude
		if distance > SWING_RANGE then continue end

		-- Knockback: push the target away from the swinger
		local direction = (targetHRP.Position - swingerHRP.Position).Unit
		-- Use AssemblyLinearVelocity for a clean instant impulse
		targetHRP.AssemblyLinearVelocity = direction * KNOCKBACK_SPEED + Vector3.new(0, 20, 0)

		-- Cancel any vault crack this player has in progress
		vs.interruptCrackBy(target)

		Notify.send(target, swinger.Name .. " knocked you back! 🏏")
	end

	task.delay(SWING_COOLDOWN, function()
		swingCooldown[swinger.UserId] = nil
	end)
end

-- Notify is needed for knockback messages — require lazily after init
local Notify

-- ── Init ──────────────────────────────────────────────────────────────────────
function ToolService.init()
	Notify = require(script.Parent.Notify)

	-- Create the BatSwing RemoteEvent in the shared Remotes folder
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	local batSwingEvent = Instance.new("RemoteEvent")
	batSwingEvent.Name   = "BatSwing"
	batSwingEvent.Parent = remotes

	-- Server listens for bat swings and validates them
	batSwingEvent.OnServerEvent:Connect(function(player)
		handleSwing(player)
	end)

	-- Build the tools and put them in StarterPack
	local pickaxe = makePickaxe()
	local bat     = makeBat()
	pickaxe.Parent = StarterPack
	bat.Parent     = StarterPack

	-- Give tools to any player already in the server (Studio "Play Here" case)
	for _, player in Players:GetPlayers() do
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			pickaxe:Clone().Parent = backpack
			bat:Clone().Parent     = backpack
		end
	end

	print("[ToolService] CrystalPickaxe and VaultBat added to StarterPack.")
end

return ToolService
