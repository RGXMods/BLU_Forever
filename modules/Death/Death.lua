--=====================================================================================
-- BLU Death Module
-- Tracks character deaths for hardcore and self-found play: lifetime count,
-- last death time, and an optional death sound trigger.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]
local DeathModule = {}

local DEATH_EVENT_ID = "death_player_dead"

function DeathModule:Init()
    BLU:PrintDebug("[Death] Death module initialized")

    local profile = BLU.db
    if not profile then return end

    profile.deathCount = profile.deathCount or 0
    profile.lastDeathTime = profile.lastDeathTime

    BLU:RegisterEvent("PLAYER_DEAD", function(event, ...)
        DeathModule:OnPlayerDead()
    end, DEATH_EVENT_ID)
end

function DeathModule:IsHardcore()
    if C_GameRules and C_GameRules.IsHardcoreActive then
        return C_GameRules.IsHardcoreActive() == true
    end
    return false
end

function DeathModule:GetCount()
    return (BLU.db and BLU.db.deathCount) or 0
end

function DeathModule:GetLastDeathText()
    if BLU.db and BLU.db.lastDeathTime and BLU.db.lastDeathTime ~= "" then
        return tostring(BLU.db.lastDeathTime)
    end
    return "Never"
end

function DeathModule:OnPlayerDead()
    local profile = BLU.db
    if not profile then return end

    profile.deathCount = (profile.deathCount or 0) + 1
    profile.lastDeathTime = date("%Y-%m-%d %H:%M")

    BLU:PrintDebug("[Death] Death recorded. Total: " .. tostring(profile.deathCount))

    if BLU.Modules.registry and BLU.Modules.registry.PlaySound then
        pcall(function()
            BLU.Modules.registry:PlaySound("death")
        end)
    end

    if BLU.Modules.death and BLU.Modules.death.RefreshPanel then
        BLU.Modules.death:RefreshPanel()
    end
end

function DeathModule:ResetCount()
    if not BLU.db then return end
    BLU.db.deathCount = 0
    BLU.db.lastDeathTime = nil
    BLU:Print("|cff05dffaBLU:|r Death counter reset.")
    if self.RefreshPanel then
        self:RefreshPanel()
    end
end

BLU.Modules = BLU.Modules or {}
BLU.Modules["death"] = DeathModule

if BLU.RegisterModule then
    BLU:RegisterModule(DeathModule, "death", "Death Module")
end

return DeathModule
