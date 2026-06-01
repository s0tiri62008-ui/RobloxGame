-- CLIENT ENTRY POINT — Crystal Bandits
-- Boots client modules in order.
local HUD    = require(script.HUD)
local BaseUI = require(script.BaseUI)

HUD.init()      -- cash + crystal counter (top-left)
BaseUI.init()   -- toast notifications (claim / mine / deposit / crack)

print("[Client] Crystal Bandits client loaded!")
