--=====================================================================================
-- BLU Collectibles Module
-- Plays the "Appearance Collected" sound (category "appearance") when a new transmog
-- appearance is added to the collection. Backed by RGXCollectibles:OnTransmog.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]
local CollectiblesModule = {}

CollectiblesModule.subscriptions = {}

function CollectiblesModule:Init()
    if #self.subscriptions > 0 then return end

    local RGX = _G.RGXFramework
    local Collectibles = RGX and RGX.GetCollectibles and RGX:GetCollectibles()
    if not (Collectibles and Collectibles.OnTransmog) then
        BLU:PrintDebug("[Collectibles] RGXCollectibles.OnTransmog is unavailable on this client")
        return
    end

    local unsubscribe = Collectibles:OnTransmog(function()
        BLU:PlayCategorySound("appearance")
    end)
    if type(unsubscribe) == "function" then
        self.subscriptions[#self.subscriptions + 1] = unsubscribe
    end

    BLU:PrintDebug("[Collectibles] Appearance collected trigger initialized")
end

function CollectiblesModule:Cleanup()
    for i = #self.subscriptions, 1, -1 do
        pcall(self.subscriptions[i])
    end
    self.subscriptions = {}
end

BLU.Modules = BLU.Modules or {}
BLU.Modules["collectibles"] = CollectiblesModule

if BLU.RegisterModule then
    BLU:RegisterModule(CollectiblesModule, "collectibles", "Collectibles Module")
end

return CollectiblesModule
