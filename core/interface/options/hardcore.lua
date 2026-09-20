--=====================================================================================
-- BLU - interface/options/hardcore.lua
-- Hardcore panel: death sound triggers for yourself, party members, raid
-- members, and other players.
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]

function BLU.CreateHardcorePanel(panel)
    BLU:PrintDebug("[Options/Hardcore] Creating Hardcore panel")
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", 1, -8)
    content:SetPoint("BOTTOMRIGHT", -7, 8)

    local contentBg = content:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.04, 0.06, 0.08, 0.35)

    if not BLU.db then
        local unavailable = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        unavailable:SetPoint("TOPLEFT", 0, -12)
        unavailable:SetText("|cffff6666Database not ready. Reopen this tab in a moment.|r")
        content:SetHeight(60)
        return
    end

    local intro = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 10, -10)
    intro:SetPoint("RIGHT", -14, 0)
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    intro:SetTextColor(0.6, 0.66, 0.72)
    intro:SetText("Pick a sound for each death trigger. Made for hardcore and self-found runs, where every death is a story.")

    if BLU.CreateSoundDropdown then
        BLU.CreateSoundDropdown(content, "death_self",  "Your death",      -58, nil)
        BLU.CreateSoundDropdown(content, "death_party", "Party member death",  -138, nil)
        BLU.CreateSoundDropdown(content, "death_raid",  "Raid member death",   -218, nil)
        BLU.CreateSoundDropdown(content, "death_other", "Other player death",  -298, nil)
    else
        BLU:PrintError("[Options/Hardcore] BLU.CreateSoundDropdown unavailable")
    end

    content:SetHeight(460)
end
