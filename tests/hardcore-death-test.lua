-- Death triggers play the category the user picked on the Hardcore page: your own death from
-- PLAYER_DEAD, other players from the combat log, once per death, and nothing while the module is off.
local function check(condition, message)
    if not condition then error("CHECK FAILED: " .. message, 2) end
end

local played = {}
local handlers = {}
local combatLog

_G.bit = _G.bit or { band = function(a, b)
    local r, p = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then r = r + p end
        a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2
    end
    return r
end }
_G.UnitName = function(unit) if unit == "player" then return "Me" end end
_G.UnitGUID = function(unit) if unit == "player" then return "Player-1" end end
_G.UnitInRaid = function(name) return name == "RaidMate" and 1 or nil end
_G.UnitInParty = function(name) return name == "PartyMate" end
_G.RGXFramework = { HasCapability = function() return true end }

_G.BLU = {
    db = { enabled = true, modules = {}, selectedSounds = { death_self = "elden_ring_6" } },
    Modules = {
        -- The registry's PlaySound takes a sound id, not a category: calling it with a category plays nothing.
        registry = { PlaySound = function() error("PlaySound was called with a category") end },
    },
    PrintDebug = function() end,
    RegisterEvent = function(_, event, fn) handlers[event] = fn end,
    PlayCategorySound = function(_, category) played[#played + 1] = category end,
}

local Hardcore = assert(loadfile("modules/Hardcore/Hardcore.lua"))("BLU_Forever")
Hardcore:Init()
check(type(handlers.PLAYER_DEAD) == "function", "your death is watched")
check(type(handlers.COMBAT_LOG_EVENT_UNFILTERED) == "function", "other deaths are watched")

local function died(subevent, guid, name, flags)
    -- CLEU payload: timestamp, subevent, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName, destFlags
    handlers.COMBAT_LOG_EVENT_UNFILTERED("COMBAT_LOG_EVENT_UNFILTERED", 0, subevent, false, "x", "x", 0, 0, guid, name, flags)
end

handlers.PLAYER_DEAD("PLAYER_DEAD")
check(played[1] == "death_self", "your death plays the death_self category")

died("UNIT_DIED", "Player-2", "PartyMate", 0x400)
check(played[2] == "death_party", "a party member's death plays death_party")
died("UNIT_DIED", "Player-3", "RaidMate", 0x400)
check(played[3] == "death_raid", "a raid member's death plays death_raid")
died("UNIT_DIED", "Player-4", "Stranger", 0x400)
check(played[4] == "death_other", "another player's death plays death_other")

died("PARTY_KILL", "Player-5", "Stranger", 0x400)
check(#played == 4, "a kill credit is not a second death sound (UNIT_DIED reports the death)")
died("UNIT_DIED", "Creature-1", "Wolf", 0)
check(#played == 4, "non-player deaths play nothing")
died("UNIT_DIED", "Player-1", "Me", 0x400)
check(#played == 4, "your own combat-log death is not played twice")

BLU.db.modules.hardcore = false
handlers.PLAYER_DEAD("PLAYER_DEAD")
check(#played == 4, "nothing plays while the Hardcore module is off")

-- The registry's module switch for death categories is the Hardcore module's own key.
local registry = io.open("core/systems/registry.lua"):read("*a")
check(not registry:find('death_self%s*=%s*"death"'), "death categories are gated by the hardcore module key")

print("hardcore-death-test: ok")
