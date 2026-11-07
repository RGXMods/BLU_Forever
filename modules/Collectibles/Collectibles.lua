--=====================================================================================
-- BLU Collectibles Module
-- Plays the "Appearance Collected" sound (category "appearance") when a new transmog
-- appearance is added to the collection. Backed by RGXCollectibles:OnTransmog.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]
local CollectiblesModule = {}

CollectiblesModule.subscriptions = {}

local EVENT_IDS = {
    TRANSMOG_COLLECTION_SOURCE_ADDED = "blu_collect_source_added",
    TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED = "blu_collect_cosmetic_added",
}
local DEDUPE_SECONDS = 1.0

-- The framework callback and BLU's own event listener can both report the same appearance;
-- play it once.
function CollectiblesModule:OnAppearance(source)
    local now = GetTime and GetTime() or 0
    if self.lastAppearanceAt and (now - self.lastAppearanceAt) < DEDUPE_SECONDS then
        BLU:PrintDebug("[Collectibles] Appearance from " .. tostring(source) .. " ignored (duplicate)")
        return
    end
    self.lastAppearanceAt = now
    BLU:PrintDebug("[Collectibles] Appearance collected (" .. tostring(source) .. ")")
    BLU:PlayCategorySound("appearance")
end

function CollectiblesModule:Init()
    if #self.subscriptions > 0 or self.eventsRegistered then return end

    local RGX = _G.RGXFramework
    local Collectibles = RGX and RGX.GetCollectibles and RGX:GetCollectibles()
    if Collectibles and Collectibles.OnTransmog then
        local unsubscribe = Collectibles:OnTransmog(function()
            self:OnAppearance("framework")
        end)
        if type(unsubscribe) == "function" then
            self.subscriptions[#self.subscriptions + 1] = unsubscribe
        end
    else
        BLU:PrintDebug("[Collectibles] RGXCollectibles.OnTransmog is unavailable on this client; using game events only")
    end

    -- Listen to the game directly as well, so the sound does not depend on the framework
    -- collectibles module being loaded on this client.
    self.registeredEvents = {}
    for event, id in pairs(EVENT_IDS) do
        local ok = pcall(BLU.RegisterEvent, BLU, event, function() self:OnAppearance(event) end, id)
        if ok then
            self.registeredEvents[#self.registeredEvents + 1] = { event = event, id = id }
        else
            BLU:PrintDebug("[Collectibles] Event " .. event .. " is not available on this client")
        end
    end
    self.eventsRegistered = true

    BLU:PrintDebug("[Collectibles] Appearance collected trigger initialized")
end

function CollectiblesModule:Cleanup()
    for i = #self.subscriptions, 1, -1 do
        pcall(self.subscriptions[i])
    end
    self.subscriptions = {}
    for _, reg in ipairs(self.registeredEvents or {}) do
        pcall(BLU.UnregisterEvent, BLU, reg.event, reg.id)
    end
    self.registeredEvents = nil
    self.eventsRegistered = nil
end

BLU.Modules = BLU.Modules or {}
BLU.Modules["collectibles"] = CollectiblesModule

if BLU.RegisterModule then
    BLU:RegisterModule(CollectiblesModule, "collectibles", "Collectibles Module")
end

return CollectiblesModule
