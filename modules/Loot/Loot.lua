--=====================================================================================
-- BLU Loot Module
-- Plays the "Item Looted" sound (category "lootitem") when a new item reaches the bags.
-- Backed by RGXLoot:OnItemLooted (RGX-Framework 2.14.0+). "Looted" means newly acquired
-- into the bags, so drops, vendor buys, mail and crafting all count.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]
local LootModule = {}

LootModule.subscriptions = {}

function LootModule:Init()
    if #self.subscriptions > 0 then return end

    local RGX = _G.RGXFramework
    local Loot = RGX and RGX.GetLoot and RGX:GetLoot()
    if not (Loot and Loot.OnItemLooted) then
        BLU:PrintDebug("[Loot] RGXLoot.OnItemLooted is unavailable; it needs RGX-Framework 2.14.0 or newer")
        return
    end

    local unsubscribe = Loot:OnItemLooted(function()
        BLU:PlayCategorySound("lootitem")
    end)
    if type(unsubscribe) == "function" then
        self.subscriptions[#self.subscriptions + 1] = unsubscribe
    end

    BLU:PrintDebug("[Loot] Item looted trigger initialized")
end

function LootModule:Cleanup()
    for i = #self.subscriptions, 1, -1 do
        pcall(self.subscriptions[i])
    end
    self.subscriptions = {}
end

BLU.Modules = BLU.Modules or {}
BLU.Modules["loot"] = LootModule

if BLU.RegisterModule then
    BLU:RegisterModule(LootModule, "loot", "Loot Module")
end

return LootModule
