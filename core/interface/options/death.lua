--=====================================================================================
-- BLU - interface/options/death.lua
-- Death tracking panel: lifetime death count, last death time, hardcore
-- status, reset, and the death sound selection.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]

function BLU.CreateDeathPanel(panel)
    BLU:PrintDebug("[Options/Death] Creating Death panel")
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", 1, -8)
    content:SetPoint("BOTTOMRIGHT", -7, 8)

    local contentBg = content:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.04, 0.06, 0.08, 0.35)

    local profile = BLU.db
    if not profile then
        local unavailable = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        unavailable:SetPoint("TOPLEFT", 0, -12)
        unavailable:SetText("|cffff6666Database not ready. Reopen this tab in a moment.|r")
        content:SetHeight(60)
        return
    end

    local trackerSection = BLU.Modules.design:CreateSection(content, "Death Tracker", "Interface\\Icons\\Ability_Rogue_ShadowStrike")
    trackerSection:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -2)
    trackerSection:SetPoint("TOPRIGHT", content, "TOP", -4, -2)
    trackerSection:SetHeight(150)

    local countLabel = trackerSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    countLabel:SetPoint("TOPLEFT", 8, -12)
    local countValue = trackerSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    countValue:SetPoint("LEFT", countLabel, "RIGHT", 10, 0)
    countValue:SetTextColor(1, 0.35, 0.35)

    local lastLabel = trackerSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lastLabel:SetPoint("TOPLEFT", 8, -44)
    lastLabel:SetText("Last death:")
    local lastValue = trackerSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lastValue:SetPoint("LEFT", lastLabel, "RIGHT", 8, 0)
    lastValue:SetTextColor(0.82, 0.88, 0.95)

    local hardcoreLabel = trackerSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hardcoreLabel:SetPoint("TOPLEFT", 8, -68)
    hardcoreLabel:SetText("Hardcore mode:")
    local hardcoreValue = trackerSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hardcoreValue:SetPoint("LEFT", hardcoreLabel, "RIGHT", 8, 0)

    local note = trackerSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 8, -94)
    note:SetPoint("RIGHT", -8, 0)
    note:SetJustifyH("LEFT")
    note:SetWordWrap(true)
    note:SetTextColor(0.6, 0.66, 0.72)
    note:SetText("Deaths are counted for the lifetime of this profile. For hardcore runs, one death is one too many.")

    local resetButton = BLU.Modules.design:CreateActionButton(
        trackerSection.content,
        "Reset counter",
        130,
        22,
        "Reset Death Counter",
        "Clears the death count and last death time for this profile."
    )
    resetButton:SetPoint("BOTTOMLEFT", 8, 10)

    -- Sound selection for the death trigger
    local soundSection = BLU.Modules.design:CreateSection(content, "Death Sound", "Interface\\Icons\\INV_Misc_Bell_01")
    soundSection:SetPoint("TOPLEFT", trackerSection, "BOTTOMLEFT", 0, -12)
    soundSection:SetPoint("TOPRIGHT", content, "TOP", -4, -164)
    soundSection:SetHeight(230)

    if BLU.CreateEventSoundPanel then
        local ok, err = pcall(function()
            BLU.CreateEventSoundPanel(soundSection.content, "death", "Death")
        end)
        if not ok then
            BLU:PrintError("[Options/Death] Failed to create sound panel: " .. tostring(err))
        end
    end

    local function Refresh()
        countLabel:SetText("Lifetime deaths:")
        countValue:SetText(tostring(profile.deathCount or 0))
        lastValue:SetText(BLU.Modules.death and BLU.Modules.death.GetLastDeathText and BLU.Modules.death:GetLastDeathText() or "Never")
        if BLU.Modules.death and BLU.Modules.death.IsHardcore then
            if BLU.Modules.death:IsHardcore() then
                hardcoreValue:SetText("|cff00ff00Active|r")
            else
                hardcoreValue:SetText("|cff9aa4b0Inactive|r")
            end
        else
            hardcoreValue:SetText("|cff9aa4b0Unknown on this client|r")
        end
    end

    resetButton:SetScript("OnClick", function()
        if BLU.Modules.death and BLU.Modules.death.ResetCount then
            BLU.Modules.death:ResetCount()
        end
        Refresh()
    end)

    if BLU.Modules.death then
        BLU.Modules.death.RefreshPanel = function() Refresh() end
    end

    Refresh()
    content:SetHeight(460)
end
