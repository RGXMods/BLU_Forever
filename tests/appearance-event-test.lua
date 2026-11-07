-- The Appearance Collected sound must not depend on the framework collectibles module.
local function check(c, m) if not c then error("CHECK FAILED: " .. m, 2) end end
local played, handlers, now = {}, {}, 10
_G.GetTime = function() return now end
_G.RGXFramework = { GetCollectibles = function() return nil end }
_G.BLU = {
    db = {}, Modules = {}, PrintDebug = function() end,
    RegisterEvent = function(_, ev, fn, id) handlers[ev] = fn end,
    UnregisterEvent = function(_, ev) handlers[ev] = nil end,
    PlayCategorySound = function(_, c) played[#played + 1] = c end,
}
local m = assert(loadfile("modules/Collectibles/Collectibles.lua"))("BLU_Forever")
m:Init()
check(handlers.TRANSMOG_COLLECTION_SOURCE_ADDED, "listens to TRANSMOG_COLLECTION_SOURCE_ADDED without the framework module")
handlers.TRANSMOG_COLLECTION_SOURCE_ADDED()
check(played[1] == "appearance", "plays the appearance category")
handlers.TRANSMOG_COSMETIC_COLLECTION_SOURCE_ADDED()
check(#played == 1, "a second report within a second is deduped")
now = 12
handlers.TRANSMOG_COLLECTION_SOURCE_ADDED()
check(#played == 2, "a later appearance plays again")
m:Cleanup()
check(handlers.TRANSMOG_COLLECTION_SOURCE_ADDED == nil, "Cleanup unregisters the events")
print("appearance-event-test OK")
