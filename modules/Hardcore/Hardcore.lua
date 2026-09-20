--=====================================================================================
-- BLU Hardcore Module
-- Death sound triggers for hardcore and self-found play: your own death,
-- party members, raid members, and other players.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]
local HardcoreModule = {}

local DEATH_EVENT_ID = "hardcore_player_dead"
local CLEU_EVENT_ID = "hardcore_combat_log"

local COMBATLOG_OBJECT_PLAYER = 0x400

function HardcoreModule:Init()
    BLU:PrintDebug("[Hardcore] Hardcore module initialized")

    BLU:RegisterEvent("PLAYER_DEAD", function(event, ...)
        HardcoreModule:OnUnitDied(nil, UnitName("player"), nil)
    end, DEATH_EVENT_ID)

    -- Combat-log driven deaths for everyone else. The framework's
    -- combatLogEvent capability gates clients that reject addon CLEU.
    local RGX = _G.RGXFramework
    local cleuAllowed = true
    if RGX and RGX.HasCapability and RGX:HasCapability("combatLogEvent") ~= nil then
        cleuAllowed = RGX:HasCapability("combatLogEvent")
    end

    if cleuAllowed then
        BLU:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(event, ...)
            HardcoreModule:OnCombatLog(...)
        end, CLEU_EVENT_ID)
    else
        BLU:PrintDebug("[Hardcore] Combat log events unavailable on this client; self-death trigger only")
    end
end

function HardcoreModule:OnCombatLog(...)
    local subevent = select(2, ...)
    if subevent ~= "UNIT_DIED" and subevent ~= "PARTY_KILL" then return end

    local destGUID = select(8, ...)
    local destName = select(9, ...)
    local destFlags = select(10, ...) or 0

    if not destName or destName == "" then return end

    -- Only player deaths; the self trigger is handled by PLAYER_DEAD.
    if destGUID == UnitGUID("player") then return end
    if bit.band(destFlags, COMBATLOG_OBJECT_PLAYER) == 0 then return end

    self:OnUnitDied(destGUID, destName, destFlags)
end

function HardcoreModule:OnUnitDied(guid, name, flags)
    if not BLU.db then return end

    local eventType
    if guid == nil and name == UnitName("player") then
        eventType = "death_self"
    elseif UnitInRaid(name) then
        eventType = "death_raid"
    elseif UnitInParty(name) then
        eventType = "death_party"
    else
        eventType = "death_other"
    end

    local modules = BLU.db.modules
    if modules and modules.hardcore == false then return end

    if BLU.Modules.registry and BLU.Modules.registry.PlaySound then
        pcall(function()
            BLU.Modules.registry:PlaySound(eventType)
        end)
    end
end

BLU.Modules = BLU.Modules or {}
BLU.Modules["hardcore"] = HardcoreModule

if BLU.RegisterModule then
    BLU:RegisterModule(HardcoreModule, "hardcore", "Hardcore Module")
end

return HardcoreModule
