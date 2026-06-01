--[[
	Notify
	------
	Tiny helper that owns the "BaseNotify" RemoteEvent used to send short
	toast messages from server → a specific client.

	The module body runs once (require caches it), so the Remotes folder and
	the RemoteEvent are created a single time no matter how many services
	require this.  The client (BaseUI) listens on ReplicatedStorage.Remotes.BaseNotify.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Notify = {}

-- Get-or-create the Remotes folder
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name   = "Remotes"
	remotes.Parent = ReplicatedStorage
end

-- Get-or-create the BaseNotify RemoteEvent
local notifyEvent = remotes:FindFirstChild("BaseNotify")
if not notifyEvent then
	notifyEvent = Instance.new("RemoteEvent")
	notifyEvent.Name   = "BaseNotify"
	notifyEvent.Parent = remotes
end

-- Send a toast message to one player.
function Notify.send(player, message)
	if player and player.Parent then
		notifyEvent:FireClient(player, message)
	end
end

return Notify
