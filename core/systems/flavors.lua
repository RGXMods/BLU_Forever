--=====================================================================================
-- BLU - systems/flavors.lua
-- Flavor detection and feature compatibility gating across the four WoW
-- versions BLU supports: Retail, Mists Classic, Classic Era, and WoW
-- Forever. Tabs for features the current client cannot fire render
-- greyed-out instead of hidden.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]

local Flavors = {}
BLU.Modules["flavors"] = Flavors

-- Feature availability per client flavor. The WoW Forever beta exposes a
-- retail-like API surface, so API presence alone cannot decide feature
-- support; the detected flavor is the source of truth here.
local FEATURE_COMPAT = {
    levelup      = { retail = true, mists = true, era = true, forever = true },
    quest        = { retail = true, mists = true, era = true, forever = true },
    reputation   = { retail = true, mists = true, era = true, forever = true },
    honorrank    = { retail = true, mists = true, era = true, forever = true },
    combat       = { retail = true, mists = true, era = true, forever = true },
    loot         = { retail = true, mists = true, era = true, forever = true },
    collectibles = { retail = true, mists = true, era = true, forever = true },
    hardcore    = { retail = true, mists = true, era = true, forever = true },

    achievement  = { retail = true, mists = true, forever = true },
    battlepet    = { retail = true, mists = true },
    delve        = { retail = true },
    housing      = { retail = true },
    prey         = { retail = true },
    renown       = { retail = true },
    tradingpost  = { retail = true },
}

local FEATURE_SOURCE_LABEL = {
    achievement  = "BLU (Retail)",
    battlepet    = "BLU (Retail) and BLU (Classic)",
    delve        = "BLU (Retail)",
    housing      = "BLU (Retail)",
    prey         = "BLU (Retail)",
    renown       = "BLU (Retail)",
    tradingpost  = "BLU (Retail)",
}

function Flavors:DetectFlavor()
    if self._flavor then return self._flavor end

    local RGX = _G.RGXFramework
    local flavor = "era"

    if RGX then
        if RGX.isForever then
            flavor = "forever"
        elseif RGX.isRetail then
            flavor = "retail"
        elseif RGX.isMists then
            flavor = "mists"
        elseif RGX.isClassicEra or RGX.isTBC then
            flavor = "era"
        elseif RGX.isWrath or RGX.isCata then
            flavor = "mists"
        end
    end

    self._flavor = flavor
    return flavor
end

function Flavors:GetFlavorLabel(flavor)
    local labels = {
        retail = "Retail WoW",
        mists = "Mists of Pandaria Classic",
        era = "Classic Era",
        forever = "WoW Forever",
    }
    return labels[flavor] or flavor
end

function Flavors:Supports(feature)
    if not feature then return true end

    local flavor = self:DetectFlavor()
    local compat = FEATURE_COMPAT[feature]
    if not compat then
        return true
    end

    return compat[flavor] == true
end

--- Resolves tab spec entries against the current flavor. Unsupported
--- features keep their grid slot but render greyed-out with a pointer to
--- the build that supports them.
function Flavors:ApplyToTabSpec(tabs)
    for _, tabInfo in ipairs(tabs) do
        if tabInfo.feature and not self:Supports(tabInfo.feature) then
            tabInfo.greyed = true
            tabInfo.placeholder = true
            tabInfo.greyedMessage = string.format(
                "|cff778899This feature doesn't exist on %s.|r|n|cff778899It is available in |cff05dffa%s|r.",
                self:GetFlavorLabel(self:DetectFlavor()),
                FEATURE_SOURCE_LABEL[tabInfo.feature] or "another BLU build"
            )
        end
    end
    return tabs
end
