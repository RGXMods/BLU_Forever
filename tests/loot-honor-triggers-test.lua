-- Loot, collectibles and honor triggers: behaviour against a mocked framework, plus wiring checks
-- that every new sound type is registered everywhere the options panel and registry need it.
local function check(condition, message)
    if not condition then error("CHECK FAILED: " .. message, 2) end
end

local played = {}
local cbs = {}   -- captured framework callbacks, by name
local function capture(name)
    return function(_, fn)
        cbs[name] = fn
        return function() cbs[name] = nil end
    end
end

local frameworkAvailable = true
_G.RGXFramework = {
    GetLoot = function() if frameworkAvailable then return { OnItemLooted = capture("loot") } end return {} end,
    GetCollectibles = function() return { OnTransmog = capture("transmog") } end,
    GetHonor = function() if frameworkAvailable then return { OnHonorGain = capture("honorGain") } end return {} end,
    GetCombat = function() return { OnPvPVictory = capture("pvp") } end,
}
_G.GetTime = function() return 10 end
_G.C_Timer = { After = function() end }
_G.UnitHonorLevel = function() return 1 end

_G.BLU = {
    db = { enabled = true, modules = {}, selectedSounds = {} },
    Modules = {},
    PrintDebug = function() end,
    Print = function() end,
    Loc = function(_, key) return key end,
    RegisterEvent = function() end,
    UnregisterEvent = function() end,
    PlayCategorySound = function(_, category) played[#played + 1] = category end,
}

local function load(path)
    return assert(loadfile(path))("BLU_Forever")
end

-- 1. Loot
local loot = load("modules/Loot/Loot.lua")
loot:Init()
check(type(cbs.loot) == "function", "Loot subscribes to RGXLoot.OnItemLooted")
cbs.loot(0, 1, 2)
check(played[1] == "lootitem", "an item looted plays the lootitem category")
loot:Init()
check(#loot.subscriptions == 1, "a second Init does not subscribe again")
loot:Cleanup()
check(cbs.loot == nil, "Cleanup unsubscribes the loot callback")

-- 2. Collectibles
played = {}
local collectibles = load("modules/Collectibles/Collectibles.lua")
collectibles:Init()
check(type(cbs.transmog) == "function", "Collectibles subscribes to RGXCollectibles.OnTransmog")
cbs.transmog()
check(played[1] == "appearance", "a collected appearance plays the appearance category")
collectibles:Cleanup()
check(cbs.transmog == nil, "Cleanup unsubscribes the transmog callback")

-- 3. Honor: gain and PvP victory, without disturbing the existing module
played = {}
local honor = load("modules/Honor/Honor.lua")
honor:Init()
check(type(cbs.honorGain) == "function" and type(cbs.pvp) == "function", "Honor subscribes to honor gain and PvP victory")
cbs.honorGain(15, "msg")
cbs.pvp()
check(played[1] == "honorgain" and played[2] == "pvpvictory", "honor gain and PvP victory play their categories")
honor:Cleanup()
check(cbs.honorGain == nil and cbs.pvp == nil, "Honor Cleanup unsubscribes both framework callbacks")

-- 4. An older framework without the new methods must not break loading.
frameworkAvailable = false
cbs = {}
local loot2 = load("modules/Loot/Loot.lua")
check(pcall(function() loot2:Init() end), "Loot Init tolerates a framework without OnItemLooted")
local honor2 = load("modules/Honor/Honor.lua")
check(pcall(function() honor2:Init() end), "Honor Init tolerates a framework without OnHonorGain")

-- 5. Wiring: each new sound type is registered in config, registry, sound panel and loader.
local function read(path)
    local f = assert(io.open(path, "r")); local s = f:read("*a"); f:close(); return s
end
local config, registry = read("core/systems/config.lua"), read("core/systems/registry.lua")
local panel, loader = read("core/interface/options/sound_panel.lua"), read("core/systems/loader.lua")
local tabs, init, toc = read("core/interface/options/tabs.lua"), read("core/initialization.lua"), read("BLU_Forever.toc")
for _, id in ipairs({ "lootitem", "appearance", "honorgain", "pvpvictory" }) do
    check(config:find(id .. ' = "None"', 1, true), id .. " has a None default in selectedSounds")
    check(config:find(id .. ' = "medium"', 1, true), id .. " has a volume default")
    check(config:find(id .. ' = "Master"', 1, true), id .. " has a channel default")
    check(registry:find(id .. ' = "', 1, true), id .. " is mapped to a module in the registry")
    check(panel:find(id .. ' = "', 1, true), id .. " is mapped in the sound panel")
    check(loader:find(id .. ' = "', 1, true), id .. " is an alias in the loader")
    check(panel:find('"' .. id .. '"', 1, true), id .. " has a dropdown in the sound panel")
end
check(tabs:find('eventType = "loot"', 1, true), "the Loot tab is a data-driven event page")
check(init:find('"loot"', 1, true) and init:find('"collectibles"', 1, true), "loot and collectibles are initialised")
check(toc:find("X-RGX-Framework-MinVersion: 2.14.0", 1, true), "the TOC requires the framework that provides the callbacks")

print("LOOT HONOR TRIGGERS OK  (loot, appearance, honor gain, PvP victory, old-framework tolerance, wiring)")
