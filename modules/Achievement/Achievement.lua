-- Forever calls these Legacy tasks; RGX owns their achievement/criteria events.
local BLU = assert(_G.BLU, "BLU must load before its Legacy adapter")
local RGX = assert(_G.RGXFramework, "RGX-Framework is required")
local Achievement = { subscriptions = {} }

local function Enabled()
    local db = BLU.db
    if not (db and db.enabled) then return false end
    -- The visible module switch is authoritative; an old flag is fallback only.
    if db.modules and db.modules.achievement ~= nil then
        return db.modules.achievement ~= false
    end
    return db.enableAchievement ~= false
end

function Achievement:Init()
    if #self.subscriptions > 0 then return end
    local domain = assert(RGX:GetAchievement(), "RGX achievement module is required for Legacy tasks")
    self.subscriptions = {
        domain:OnEarned(function()
            if Enabled() then BLU:PlayCategorySound("achievement") end
        end),
        domain:OnCriteriaEarned(function()
            if Enabled() then BLU:PlayCategorySound("achievementprogress") end
        end),
    }
end

function Achievement:Cleanup()
    for i = #self.subscriptions, 1, -1 do self.subscriptions[i]() end
    self.subscriptions = {}
end

BLU.Modules = BLU.Modules or {}
BLU.Modules.achievement = Achievement
return Achievement
