--[[
	ToolHandler
	-----------
	Client-side tool input.  Runs in StarterPlayerScripts.

	Why this exists instead of a LocalScript inside the bat:
	  Roblox made LocalScript.Source read-only in running games (security fix),
	  so we cannot set script source programmatically on the server.  Instead,
	  this persistent client module watches for the bat being equipped and fires
	  the BatSwing RemoteEvent to the server on left-click.

	The pickaxe needs no client logic — the server checks equip state directly.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local ToolHandler = {}

function ToolHandler.init()
	-- Wait for the server to create the remote
	local remotes        = ReplicatedStorage:WaitForChild("Remotes", 15)
	local batSwingRemote = remotes and remotes:WaitForChild("BatSwing", 15)

	if not batSwingRemote then
		warn("[ToolHandler] BatSwing remote not found — bat will not fire.")
		return
	end

	-- When the bat is equipped it becomes a child of the Character.
	-- Connect Activated there; disconnect if the tool is unequipped.
	local function onCharacterAdded(character)
		character.ChildAdded:Connect(function(child)
			if child.Name == "VaultBat" and child:IsA("Tool") then
				child.Activated:Connect(function()
					batSwingRemote:FireServer()
				end)
			end
		end)
	end

	-- Handle the character that already exists (Studio "Play Here")
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	print("[ToolHandler] Bat input ready.")
end

return ToolHandler
