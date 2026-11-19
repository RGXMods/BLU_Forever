-- Real framework event/achievement owners and BLU loader/category selection.
-- Audio output is captured at the registry's PlaySound boundary.
local FW = os.getenv("RGXFW_PATH") or "../RGX-Framework"
local function read(p)
    local f = assert(io.open(p)); local s = f:read("*a"); f:close(); return s
end
local function noop() end
local frame = setmetatable({}, { __index = function() return noop end })
CreateFrame = function() return frame end
local modules, errors = {}, {}
GetTimePreciseSec = function() return 0 end
geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
RGXFramework = {
    eventFrame = frame,
    API = { CanAccessValue = function() return true end, CanAccessTable = function() return true end },
    RegisterModule = function(_, name, module) modules[name] = module end,
    GetAchievement = function() return modules.achievement end,
    Debug = function(_, err) errors[#errors + 1] = err end,
}
for _, file in ipairs({ "core/systems/runtime.lua", "core/systems/events.lua", "modules/achievement/achievement.lua" }) do
    assert(loadfile(FW .. "/" .. file))("RGX-Framework", RGXFramework)
end
modules.achievement:Init()
local now, played = 10, {}
GetTime = function() return now end
InCombatLockdown = function() return false end
BLU = {
    Modules = {}, LoadedModules = {},
    db = { enabled = true, modules = { achievement = true }, selectedSounds = {
        achievement = "chosen-completion", achievementprogress = "chosen-progress",
    } },
    PrintDebug = noop, Print = noop,
    Loc = function(_, key) return key end,
    RegisterEvent = function(_, event, callback, id) RGXFramework:RegisterEvent(event, callback, id) end,
    UnregisterEvent = function(_, event, id) RGXFramework:UnregisterEvent(event, id) end,
}
assert(loadfile("core/systems/registry.lua"))("BLU_Forever")
BLU.Registry:Init()
function BLU.Registry:PlaySound(id, _, opts)
    played[#played + 1] = { id = id, category = opts.categoryOverride }; return true
end
assert(loadfile("core/systems/loader.lua"))("BLU_Forever")
assert(loadfile("core/initialization.lua"))("BLU_Forever")
local xml = read("BLU_Forever.xml")
for path in xml:gmatch('<Script file="([^"]+)"') do
    if path:find("/Achievement/", 1, true) then assert(loadfile(path))("BLU_Forever") end
end
assert(BLU:LoadModule("features", "achievement"), "Legacy options require a loaded runtime adapter")
local function fire(event, ...)
    now = now + 1
    RGXFramework:FireEvent(event, ...)
end
fire("ACHIEVEMENT_EARNED", 100, false)
assert(#played == 1 and played[1].id == "chosen-completion" and played[1].category == "achievement",
    "Legacy task completion plays the selected category sound")
fire("CRITERIA_EARNED", 100, "Progress", false)
assert(#played == 2 and played[2].id == "chosen-progress" and played[2].category == "achievementprogress",
    "Legacy task progress has its own sound category")
fire("ACHIEVEMENT_EARNED", 100, true); fire("CRITERIA_EARNED", 100, "old", true)
assert(#played == 2, "framework filters already-earned/account repeats")
BLU.db.modules.achievement = false
fire("ACHIEVEMENT_EARNED", 101, false); fire("CRITERIA_EARNED", 101, "new", false)
assert(#played == 2, "module switch silences both task categories")
BLU.db.modules.achievement = true; BLU.db.enabled = false
fire("ACHIEVEMENT_EARNED", 102, false)
assert(#played == 2, "global disable silences Legacy events")
BLU.db.enabled = true; BLU.db.modules.achievement = nil; BLU.db.enableAchievement = false
fire("ACHIEVEMENT_EARNED", 102, false)
assert(#played == 2, "legacy enableAchievement=false is preserved")
BLU.db.enableAchievement = nil
BLU.db.modules.achievement = true
BLU.db.enabled = true; BLU.db.selectedSounds.achievement = "None"
fire("ACHIEVEMENT_EARNED", 103, false)
assert(#played == 2, "None is honored by the actual category registry")
BLU.db.selectedSounds.achievement = "default"
fire("ACHIEVEMENT_EARNED", 104, false)
assert(#played == 3 and played[3].id == "quest_default", "default task completion reuses a shipped completion asset")
BLU.db.selectedSounds.achievementprogress = "None"
fire("CRITERIA_EARNED", 104, "ignored", false)
assert(#played == 3, "progress None stays silent")
BLU.db.selectedSounds.achievementprogress = "default"
fire("CRITERIA_EARNED", 104, "progress", false)
assert(#played == 4 and played[4].id == "quest_progress_default", "default progress is connected to a shipped asset too")
BLU:UnloadModule("achievement")
fire("ACHIEVEMENT_EARNED", 105, false)
assert(#played == 4, "cleanup unsubscribes from shared achievement callbacks")
assert(BLU:LoadModule("features", "achievement"))
BLU.Modules.achievement:Init()
fire("ACHIEVEMENT_EARNED", 106, false)
assert(#played == 5, "re-enable and duplicate Init do not duplicate sounds")
BLU.db.enableAchievement = false
fire("ACHIEVEMENT_EARNED", 107, false)
assert(#played == 6, "visible module switch wins over a stale legacy flag")
assert(BLU:IsFeatureModuleEnabled("achievement"), "reload initialization agrees with the visible module switch")
assert(#errors == 0, table.concat(errors, "\n"))
print("legacy-task-triggers-test OK")
