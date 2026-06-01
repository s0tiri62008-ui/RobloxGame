--[[
	SERVER ENTRY POINT — Crystal Bandits
	------------------------------------
	1. Cleans up any leftover instances from a previous run (so re-syncing in
	   Studio never produces duplicate maps / bases / remotes).
	2. Requires all services (this is when Notify recreates a fresh Remotes folder).
	3. Boots services in dependency order.

	IMPORTANT: cleanup() runs BEFORE the require lines, because requiring Notify
	(pulled in by BaseService/CrystalService/VaultService) recreates the Remotes
	folder — we must not destroy it afterwards.
]]

local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── 1. Cleanup previous instances ─────────────────────────────────────────────
local function cleanup()
	for _, name in ipairs({ "Map", "Lobby", "PlayerBases", "CrystalClusters", "CarriedCrystals" }) do
		local existing = Workspace:FindFirstChild(name)
		if existing then existing:Destroy() end
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then remotes:Destroy() end

	-- Clear tools so re-syncing in Studio doesn't stack duplicates
	local StarterPack = game:GetService("StarterPack")
	for _, child in StarterPack:GetChildren() do
		child:Destroy()
	end

	Workspace.Terrain:Clear()
end

cleanup()

-- ── 2. Require services ───────────────────────────────────────────────────────
local MapSetup           = require(script.MapSetup)
local LeaderboardService = require(script.LeaderboardService)
local BaseService        = require(script.BaseService)
local CrystalService     = require(script.CrystalService)
local VaultService       = require(script.VaultService)
local ToolService        = require(script.ToolService)

-- ── 3. Boot in order ──────────────────────────────────────────────────────────
MapSetup.init()            -- lobby, spawn pad, leaderboard sign, paths
LeaderboardService.init()  -- leaderstats (before income can pay out)
BaseService.init()         -- 8 claimable bases (+ vault blocks)
CrystalService.init()      -- mining clusters + carry loop
VaultService.init()        -- deposit / crack / income (needs bases + carry)
ToolService.init()         -- pickaxe + bat in StarterPack (after Remotes exist)

print("[Server] Crystal Bandits initialised!")
