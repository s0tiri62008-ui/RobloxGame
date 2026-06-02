-- CLIENT ENTRY POINT — Crystal Bandits
-- Boots client modules in order.
local HUD         = require(script.HUD)
local BaseUI      = require(script.BaseUI)
local ToolHandler = require(script.ToolHandler)

HUD.init()          -- cash + crystal counter (top-left)
BaseUI.init()       -- toast notifications (claim / mine / deposit / crack)
ToolHandler.init()  -- bat left-click → BatSwing remote

print("[Client] Crystal Bandits client loaded!")
