-- CLIENT ENTRY POINT
-- Boots all client-side modules in order.
local HUD    = require(script.HUD)
local BaseUI = require(script.BaseUI)

HUD.init()
BaseUI.init()

print("[Client] Brainrot Battleground client loaded!")
