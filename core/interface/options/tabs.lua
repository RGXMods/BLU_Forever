--=====================================================================================
-- BLU - interface/options/tabs.lua
-- Tab system for options panel
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]

-- Create tabs module
local Tabs = {}
BLU.Modules = BLU.Modules or {}
BLU.Modules["tabs"] = Tabs

local TAB_BUTTON_WIDTH_CORE = 94
local TAB_BUTTON_WIDTH_WIDE = 100
local TAB_BUTTON_HEIGHT = 22
local TAB_SPACING = 6
local TAB_ROW_PADDING = 8
local TAB_ROW_SPACING = 3
local TAB_COLUMNS_PER_ROW = 6
-- Section gap: event columns (col >= 3) shift right so the 1px divider
-- has symmetric breathing room on both sides (settings | pipe | events).
local TAB_SECTION_GAP = 6

local function GetTabRowWidth()
    -- 1 core column + 5 wide columns + spacing + 16px gutter
    return TAB_BUTTON_WIDTH_CORE + (5 * TAB_BUTTON_WIDTH_WIDE) + (5 * TAB_SPACING) + 16
end

-- Dynamic tab strip layout ---------------------------------------------------
-- The strip derives its geometry from the live spec table and the container's
-- actual width instead of the legacy fixed col-based xOffset math. Buttons are
-- laid out left-to-right at fixed widths/spacing and wrap onto a new row
-- (aligned to the same left edge) when the next button would not fit at the
-- container's current width. The legacy per-tab `row`/`col` spec fields are
-- kept for compatibility but are hints only; positions come from this
-- layout pass.
--
-- Layout model (matches the legacy single-row rendering when everything fits
-- on one row):
--   * first button of the strip: x = TAB_ROW_PADDING, width = CORE (94)
--   * every other button:        x = prev right edge + TAB_SPACING (6),
--                                width = WIDE (100)
--   * every button:             y = -6 - (row-1) * (22 + 3)
--
-- The legacy per-button math in UpdatePosition was:
--   col 1: x = 8,  width 94
--   col>1: x = 8 + 94 + 6 + (col-2)*(100+6) = 108 + (col-2)*106, width 100
-- so buttons sit at x = 8, 118, 224, 330, ... The gap after the CORE button
-- is a 16px gutter; every later WIDE button is 6px after the previous one.
-- The dynamic pass reproduces exactly this sequence and wraps to the next
-- row (same left edge and spacing) when the next button would not fit at
-- the container's current width.

-- Compute the layout for the live spec. The spec's row/col fields are the
-- authoritative fixed-grid geometry (operator review 2026-09-28 rev 3: BLU's
-- original column/row alignment, with rows subtracted to two and tabs
-- shifted — no custom flow, no adaptive widths):
--   col 1: x = 8,    width = CORE (94)
--   col>1: x = 118 + (col-2) * 106, width = WIDE (100)
--   row r: y = -6 - (r-1) * 25
-- Buttons hidden by the flavors hook (hidden = true) are skipped.
local function ComputeTabLayout(containerWidth)
    local layout = { buttons = {}, rows = 1 }
    if not BLU.OptionsTabs then
        return layout
    end
    local maxRow = 1
    for index, tabInfo in ipairs(BLU.OptionsTabs) do
        if not tabInfo.hidden then
            local col = tonumber(tabInfo.col) or 1
            local row = tonumber(tabInfo.row) or 1
            local x, width
            if col <= 1 then
                x = TAB_ROW_PADDING
                width = TAB_BUTTON_WIDTH_CORE
            else
                x = TAB_ROW_PADDING + TAB_BUTTON_WIDTH_CORE + TAB_SPACING + (col - 2) * (TAB_BUTTON_WIDTH_WIDE + TAB_SPACING)
                if col >= 3 then
                    x = x + TAB_SECTION_GAP
                end
                width = TAB_BUTTON_WIDTH_WIDE
            end
            local y = -6 - (row - 1) * (TAB_BUTTON_HEIGHT + TAB_ROW_SPACING)
            layout.buttons[#layout.buttons + 1] = {
                index = index,
                x = x,
                y = y,
                width = width,
                row = row,
            }
            if row > maxRow then
                maxRow = row
            end
        end
    end
    layout.rows = maxRow
    return layout
end

-- Generic "coming soon" placeholder panel — used by Combat, Collectibles, Loot, and Prey
local PLACEHOLDER_CONFIG = {
    Combat = {
        icon = "Interface\\Icons\\Ability_Warrior_Charge",
        body = "Combat-related sound triggers are planned for a future update. Likely coverage includes combat milestone triggers, proc-style notifications, and high-signal event moments.",
    },
    Collectibles = {
        icon = "Interface\\Icons\\INV_Misc_Toy_07",
        body = "Sound triggers for collectible milestones — mounts, pets, toys, transmog, and more — are planned for a future update. This placeholder tab reserves the category.",
    },
    Loot = {
        icon = "Interface\\Icons\\INV_Misc_Coin_02",
        body = "Loot-related sound triggers are planned for a future update. Likely coverage includes rare drops, boss loot, and other item acquisition events.",
    },
}

local COMBAT_TRIGGER_PAGES = {
    {
        {
            title = "Combat Start",
            sound = "BLU Defaults",
            volume = "Medium",
        },
        {
            title = "Combat End",
            sound = "Final Fantasy",
            volume = "Low",
        },
        {
            title = "Low Health",
            sound = "Alarm Bell",
            volume = "High",
        },
        {
            title = "Execute Window",
            sound = "Warcraft 3",
            volume = "Medium",
        },
        {
            title = "Interrupt Ready",
            sound = "SharedMedia Pack",
            volume = "Medium",
        },
        {
            title = "Rare Enemy Tagged",
            sound = "Elden Ring",
            volume = "High",
        },
        {
            title = "Target Kill",
            sound = "User Custom",
            volume = "Medium",
        },
        {
            title = "Major Cooldown Ready",
            sound = "Pokemon",
            volume = "Low",
        },
    },
    {
        {
            title = "Proc Trigger",
            sound = "BLU Defaults",
            volume = "Medium",
        },
        {
            title = "Defensive Ready",
            sound = "Zelda",
            volume = "Low",
        },
        {
            title = "Enemy Cast Started",
            sound = "Kirby",
            volume = "Medium",
        },
        {
            title = "Enemy Cast Interruptible",
            sound = "Diablo 2",
            volume = "High",
        },
        {
            title = "Boss Engage",
            sound = "SharedMedia Pack",
            volume = "High",
        },
        {
            title = "Boss Defeated",
            sound = "Final Fantasy",
            volume = "Medium",
        },
        {
            title = "Add Spawn",
            sound = "Mario",
            volume = "Medium",
        },
        {
            title = "Execute Refresh",
            sound = "User Custom",
            volume = "Low",
        },
    },
}

local function CreateComingSoonPanel(panel, tabName)
    local cfg = PLACEHOLDER_CONFIG[tabName] or {
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        body = "This module is planned for a future update. This placeholder tab reserves the category.",
    }

    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", 10, -10)
    content:SetPoint("BOTTOMRIGHT", -10, 10)

	local pageBg = content:CreateTexture(nil, "BACKGROUND")
	pageBg:SetAllPoints()
	pageBg:SetColorTexture(0.04, 0.06, 0.08, 0.35)

    local titleBar = CreateFrame("Frame", nil, content, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetHeight(44)
    titleBar:SetBackdrop(BLU.Modules.design.Backdrops.Solid)
    titleBar:SetBackdropColor(0.06, 0.10, 0.16, 0.95)
    titleBar:SetBackdropBorderColor(0.10, 0.20, 0.28, 1)

    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexture(cfg.icon)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetText("|cff05dffa" .. tabName .. " Sounds|r")

    if tabName == "Loot" then
        local switchFrame = CreateFrame("Frame", nil, titleBar)
        switchFrame:SetSize(44, 20)
        switchFrame:SetPoint("RIGHT", -10, 0)

        local switchBg = switchFrame:CreateTexture(nil, "BACKGROUND")
        switchBg:SetAllPoints()
        switchBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        switchBg:SetVertexColor(0.3, 0.3, 0.3, 1)

        local toggle = CreateFrame("Button", nil, switchFrame)
        toggle:SetSize(18, 18)
        toggle:SetPoint("LEFT", switchFrame, "LEFT", 1, 0)
        local toggleBg = toggle:CreateTexture(nil, "ARTWORK")
        toggleBg:SetAllPoints()
        toggleBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        toggleBg:SetVertexColor(0.6, 0.6, 0.6, 1)
        toggle:Disable()

        local status = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        status:SetPoint("RIGHT", switchFrame, "LEFT", -6, 0)
        status:SetText("|cffaaaaaaSOON|r")
    end

    local intro = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 0, -64)
    intro:SetPoint("TOPRIGHT", 0, -64)
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    intro:SetTextColor(0.6, 0.66, 0.72)
    intro:SetText(tabName == "Loot"
        and "Preview the planned loot triggers. Sound selection is not available yet."
        or cfg.body)

    if tabName == "Loot" then
        local labels = { "Rare Drop Sound", "Boss Loot Sound", "Item Pickup Sound" }
        for index, label in ipairs(labels) do
            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            local y = -102 - ((index - 1) * 80)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, y)
            row:SetHeight(68)
            row:SetBackdrop(BLU.Modules.design.Backdrops.Solid)
            row:SetBackdropColor(0.08, 0.11, 0.15, 0.92)
            row:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)

            local rowTitle = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rowTitle:SetPoint("TOPLEFT", 10, -6)
            rowTitle:SetTextColor(1.0, 0.82, 0.18)
            rowTitle:SetText(label)

            local rowStatus = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            rowStatus:SetPoint("TOPLEFT", rowTitle, "BOTTOMLEFT", 0, -2)
            rowStatus:SetPoint("TOPRIGHT", rowTitle, "BOTTOMRIGHT", 0, -2)
            rowStatus:SetJustifyH("LEFT")
            rowStatus:SetTextColor(0.02, 0.87, 0.98)
            rowStatus:SetText("Coming soon")

            local selectButton = CreateFrame("Button", nil, row, "BackdropTemplate")
            selectButton:SetPoint("LEFT", row, "LEFT", 10, 0)
            selectButton:SetPoint("TOP", rowStatus, "BOTTOM", 0, -5)
            selectButton:SetSize(220, 22)
            selectButton:SetBackdrop(BLU.Modules.design.Backdrops.Button)
            selectButton:SetBackdropColor(0.10, 0.14, 0.19, 0.96)
            selectButton:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)
            selectButton:EnableMouse(false)

            local buttonText = selectButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            buttonText:SetPoint("LEFT", 8, 0)
            buttonText:SetTextColor(0.6, 0.66, 0.72)
            buttonText:SetText("Not available yet")

            local testBtn = BLU.Modules.design:CreateButton(row, "Test", 60, 22)
            testBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            testBtn:SetPoint("TOP", rowStatus, "BOTTOM", 0, -5)
            testBtn:Disable()
            if testBtn.label then testBtn.label:SetTextColor(0.6, 0.66, 0.72) end
        end
        return
    end

    local section = BLU.Modules.design:CreateSection(content, "Coming Soon", "Interface\\Icons\\INV_Misc_Note_05")
    section:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -58)
    section:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -10, -58)
    section:SetHeight(100)

    local body = section.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", 4, -4)
    body:SetPoint("RIGHT", -8, 0)
    body:SetJustifyH("LEFT")
    body:SetTextColor(0.82, 0.82, 0.82)
    body:SetText(cfg.body)
end

-- Inactive layout prototype. The Combat tab below uses BLU.CreateCombatPanel
-- from combat.lua; make live Combat layout changes there.
local function CreateCombatPrototypePanel(panel)
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", 10, -10)
    content:SetPoint("BOTTOMRIGHT", -10, 10)

	local pageBg = content:CreateTexture(nil, "BACKGROUND")
	pageBg:SetAllPoints()
	pageBg:SetColorTexture(0.04, 0.06, 0.08, 0.35)

    BLU._combatTabState = BLU._combatTabState or {page = 1}
    local state = BLU._combatTabState
    local totalPages = #COMBAT_TRIGGER_PAGES

    local titleBar = CreateFrame("Frame", nil, content, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetHeight(44)
    titleBar:SetBackdrop(BLU.Modules.design.Backdrops.Solid)
    titleBar:SetBackdropColor(0.06, 0.10, 0.16, 0.95)
    titleBar:SetBackdropBorderColor(0.10, 0.20, 0.28, 1)

    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexture("Interface\\Icons\\Ability_Warrior_Charge")

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetText("|cff05dffaCombat|r")

    local introSection = BLU.Modules.design:CreateSection(content, "Combat Prototype", "Interface\\Icons\\INV_Misc_Note_05")
    introSection:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -20)
    introSection:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -20)
    introSection:SetHeight(78)

    local intro = introSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 4, -4)
    intro:SetPoint("RIGHT", -8, 0)
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    intro:SetTextColor(0.82, 0.82, 0.82)
    intro:SetText("This tab is a visual test bed for future combat settings. The goal here is to compare direct combat cue options, dedicated combat music controls, and a compact paged trigger layout before module logic is built.")

    local function CreateCompactMockRow(parent, x, y, titleText, soundText, volumeText, tooltipText)
        local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        row:SetPoint("TOPLEFT", x, y)
        row:SetHeight(74)
        row:SetBackdrop(BLU.Modules.design.Backdrops.Solid)
        row:SetBackdropColor(0.08, 0.11, 0.15, 0.92)
        row:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)

        local rowTitle = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowTitle:SetPoint("TOPLEFT", 10, -8)
        rowTitle:SetPoint("RIGHT", -10, 0)
        rowTitle:SetJustifyH("LEFT")
        rowTitle:SetText(titleText)

        local fakeDropdown = CreateFrame("Button", nil, row, "BackdropTemplate")
        fakeDropdown:SetPoint("TOPLEFT", rowTitle, "BOTTOMLEFT", 0, -8)
        fakeDropdown:SetSize(146, 22)
        fakeDropdown:SetBackdrop(BLU.Modules.design.Backdrops.Button)
        fakeDropdown:SetBackdropColor(0.10, 0.14, 0.19, 0.96)
        fakeDropdown:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)
        fakeDropdown:RegisterForClicks("LeftButtonUp")

        local dropdownText = fakeDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dropdownText:SetPoint("LEFT", 8, 0)
        dropdownText:SetPoint("RIGHT", -18, 0)
        dropdownText:SetJustifyH("LEFT")
        dropdownText:SetTextColor(0.84, 0.84, 0.84, 1)
        dropdownText:SetText(soundText or "Select Sound")

        local dropdownArrow = fakeDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dropdownArrow:SetPoint("RIGHT", -6, 0)
        dropdownArrow:SetText("v")
        dropdownArrow:SetTextColor(0.70, 0.78, 0.86, 1)

        local soundChoices = {
            "BLU Defaults",
            "Final Fantasy",
            "Warcraft 3",
            "SharedMedia Pack",
            "User Custom",
            "Pokemon",
            "Elden Ring",
            "Zelda",
            "Kirby",
            "Diablo 2",
            "Mario",
        }
        local selectedSound = soundText or soundChoices[1]

        local volumeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        volumeLabel:SetPoint("BOTTOMLEFT", row, "TOPLEFT", 170, -28)
        volumeLabel:SetTextColor(0.70, 0.78, 0.86)
        volumeLabel:SetText(volumeText or "Medium")

        local slider = CreateFrame("Slider", nil, row)
        slider:SetPoint("LEFT", fakeDropdown, "RIGHT", 16, 0)
        slider:SetSize(64, 16)
        slider:SetMinMaxValues(1, 3)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)

        local sliderTrack = row:CreateTexture(nil, "ARTWORK")
        sliderTrack:SetSize(64, 4)
        sliderTrack:SetPoint("CENTER", slider, "CENTER", 0, 0)
        sliderTrack:SetColorTexture(0.14, 0.20, 0.28, 1)

        local sliderFill = row:CreateTexture(nil, "ARTWORK")
        sliderFill:SetHeight(4)
        sliderFill:SetPoint("LEFT", sliderTrack, "LEFT", 0, 0)
        sliderFill:SetColorTexture(unpack(BLU.Modules.design.Colors.Primary))

        local fillWidth = 28
        if volumeText == "Low" then
            fillWidth = 18
        elseif volumeText == "High" then
            fillWidth = 56
        end
        sliderFill:SetWidth(fillWidth)

        local sliderThumb = row:CreateTexture(nil, "ARTWORK")
        sliderThumb:SetSize(8, 8)
        sliderThumb:SetTexture("Interface\\Buttons\\WHITE8x8")
        sliderThumb:SetVertexColor(1, 1, 1, 1)

        local testButton = BLU.Modules.design:CreateActionButton(
            row,
            "Test",
            46,
            20,
            "Prototype Test Button",
            tooltipText or "Visual placeholder only. This row is for layout testing."
        )
        testButton:SetPoint("LEFT", slider, "RIGHT", 16, 0)

        local function applyVolume(step)
            local normalized = math.max(1, math.min(3, math.floor((step or 2) + 0.5)))
            local label = "Medium"
            local width = 28
            if normalized == 1 then
                label = "Low"
                width = 18
            elseif normalized == 3 then
                label = "High"
                width = 56
            end

            sliderFill:SetWidth(width)
            sliderThumb:ClearAllPoints()
            sliderThumb:SetPoint("CENTER", sliderTrack, "LEFT", width, 0)
            volumeLabel:SetText(label)
            slider:SetValue(normalized)
        end

        local dropdownMenu = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
        dropdownMenu.displayMode = "MENU"
        dropdownMenu.initialize = function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for _, choice in ipairs(soundChoices) do
                info = UIDropDownMenu_CreateInfo()
                info.text = choice
                info.checked = (choice == selectedSound)
                info.func = function()
                    selectedSound = choice
                    dropdownText:SetText(choice)
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end

        fakeDropdown:SetScript("OnClick", function(self)
            ToggleDropDownMenu(1, nil, dropdownMenu, self, 0, 0)
        end)

        fakeDropdown:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(BLU.Modules.design.Colors.Primary))
        end)
        fakeDropdown:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)
        end)

        slider:SetScript("OnMouseDown", function(self)
            local minVal, maxVal = self:GetMinMaxValues()
            local cursorX = GetCursorPosition()
            local effectiveScale = self:GetEffectiveScale()
            local left = self:GetLeft() * effectiveScale
            local width = self:GetWidth() * effectiveScale
            local percent = 0
            if width > 0 then
                percent = (cursorX - left) / width
            end
            local value = minVal + ((maxVal - minVal) * percent)
            applyVolume(value)
        end)
        slider:SetScript("OnMouseWheel", function(self, delta)
            applyVolume((self:GetValue() or 2) + delta)
        end)
        slider:EnableMouseWheel(true)

        applyVolume((volumeText == "Low" and 1) or (volumeText == "High" and 3) or 2)

        function row:SetMockData(trigger)
            trigger = trigger or {}
            rowTitle:SetText(trigger.title or titleText or "")
            selectedSound = trigger.sound or soundText or soundChoices[1]
            dropdownText:SetText(selectedSound)
            applyVolume((trigger.volume == "Low" and 1) or (trigger.volume == "High" and 3) or 2)
        end

        row:SetMockData({
            title = titleText,
            sound = soundText,
            volume = volumeText,
        })

        return row
    end

    local topGrid = CreateFrame("Frame", nil, content)
    topGrid:SetPoint("TOPLEFT", introSection, "BOTTOMLEFT", 0, -10)
    topGrid:SetPoint("TOPRIGHT", introSection, "BOTTOMRIGHT", 0, -10)
    -- Single-column stack (operator 2026-09-28): Cues on top, Music below.
    topGrid:SetHeight(378)

    local cuesSection = BLU.Modules.design:CreateSection(topGrid, "Combat Cues", "Interface\\Icons\\Ability_Rogue_Sprint")
    --[[
    -- Former side-by-side anchors (preserved, not active):
    cuesSection:SetPoint("TOPLEFT", 0, 0)
    cuesSection:SetPoint("BOTTOMLEFT", 0, 0)
    cuesSection:SetPoint("RIGHT", topGrid, "CENTER", -5, 0)
    ]]
    cuesSection:SetPoint("TOPLEFT", 0, 0)
    cuesSection:SetPoint("TOPRIGHT", 0, 0)
    cuesSection:SetHeight(208)

    local cuesNote = cuesSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cuesNote:SetPoint("TOPLEFT", 4, -4)
    cuesNote:SetPoint("RIGHT", -8, 0)
    cuesNote:SetJustifyH("LEFT")
    cuesNote:SetWordWrap(true)
    cuesNote:SetTextColor(0.78, 0.82, 0.88)
    cuesNote:SetText("One-shot sounds that fire at a combat boundary. This is the clearest place for separate start and end cues.")

    local cueStartRow = CreateCompactMockRow(
        cuesSection.content,
        4,
        -44,
        "Combat Start Sound",
        "BLU Defaults",
        "Medium",
        "Placeholder for a one-shot sound that plays once when combat starts."
    )
    cueStartRow:SetPoint("RIGHT", cuesSection.content, "RIGHT", -4, 0)

    local cueEndRow = CreateCompactMockRow(
        cuesSection.content,
        4,
        -126,
        "Combat End Sound",
        "Final Fantasy",
        "Low",
        "Placeholder for a one-shot sound that plays once when combat ends."
    )
    cueEndRow:SetPoint("RIGHT", cuesSection.content, "RIGHT", -4, 0)

    local musicSection = BLU.Modules.design:CreateSection(topGrid, "Combat Music", "Interface\\Icons\\INV_Misc_Bag_10_Black")
    --[[
    -- Former side-by-side anchors (preserved, not active):
    musicSection:SetPoint("TOPLEFT", topGrid, "TOP", 5, 0)
    musicSection:SetPoint("BOTTOMRIGHT", topGrid, "BOTTOMRIGHT", 0, 0)
    ]]
    musicSection:SetPoint("TOPLEFT", cuesSection, "BOTTOMLEFT", 0, -10)
    musicSection:SetPoint("TOPRIGHT", cuesSection, "BOTTOMRIGHT", 0, -10)
    musicSection:SetHeight(160)

    local musicNote = musicSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    musicNote:SetPoint("TOPLEFT", 4, -4)
    musicNote:SetPoint("RIGHT", -8, 0)
    musicNote:SetJustifyH("LEFT")
    musicNote:SetWordWrap(true)
    musicNote:SetTextColor(0.78, 0.82, 0.88)
    musicNote:SetText("Persistent combat music should likely live as its own system instead of being mixed into normal one-shot triggers.")

    local musicTrackRow = CreateCompactMockRow(
        musicSection.content,
        4,
        -44,
        "Combat Music Track",
        "SharedMedia Pack",
        "Medium",
        "Placeholder for selecting the looping combat music track."
    )
    musicTrackRow:SetPoint("RIGHT", musicSection.content, "RIGHT", -4, 0)

    local musicState = musicSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    musicState:SetPoint("TOPLEFT", musicTrackRow, "BOTTOMLEFT", 2, -8)
    musicState:SetPoint("RIGHT", musicSection.content, "RIGHT", -8, 0)
    musicState:SetJustifyH("LEFT")
    musicState:SetTextColor(0.70, 0.78, 0.86)
    musicState:SetText("Placeholder behavior: start on combat begin, stop on combat end, with room later for fades, boss-only filters, or instance-only rules.")

    local futureSection = BLU.Modules.design:CreateSection(content, "Future Trigger Paging", "Interface\\Icons\\Ability_Warrior_Charge")
    futureSection:SetPoint("TOPLEFT", topGrid, "BOTTOMLEFT", 0, -10)
    futureSection:SetPoint("TOPRIGHT", topGrid, "BOTTOMRIGHT", 0, -10)
    futureSection:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    futureSection:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    local futureNote = futureSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    futureNote:SetPoint("TOPLEFT", 4, -4)
    futureNote:SetPoint("RIGHT", -190, 0)
    futureNote:SetJustifyH("LEFT")
    futureNote:SetWordWrap(true)
    futureNote:SetTextColor(0.78, 0.82, 0.88)
    futureNote:SetText("This area is for the broader combat-trigger catalog, laid out as a single column so each option gets the full row.")

    local pageLabel = futureSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageLabel:SetPoint("TOPRIGHT", -126, -6)
    pageLabel:SetTextColor(0.70, 0.78, 0.86)

    local prevButton = BLU.Modules.design:CreateActionButton(
        futureSection.content,
        "Prev",
        56,
        20,
        "Previous Page",
        "Show the previous set of combat trigger options."
    )
    prevButton:SetPoint("TOPRIGHT", -66, -2)

    local nextButton = BLU.Modules.design:CreateActionButton(
        futureSection.content,
        "Next",
        56,
        20,
        "Next Page",
        "Show the next set of combat trigger options."
    )
    nextButton:SetPoint("TOPRIGHT", -6, -2)

    local triggerRows = {}
    local rowAnchorParent = futureSection.content
    local rowStartY = -74
    local rowHeight = 74
    local rowGap = 10
    local columnGap = 10
    local columnWidth = 0

    -- Single-column page (operator 2026-09-28). The former 2-column mock
    -- grid is preserved below as comments for future use.
    for index = 1, 8 do
        --[[
        local visualRow = math.floor((index - 1) / 2)
        ]]
        local row = CreateCompactMockRow(
            rowAnchorParent,
            0,
            rowStartY - ((index - 1) * (rowHeight + rowGap)),
            "",
            "BLU Defaults",
            "Medium",
            "Visual placeholder for how a compact event-row test button would fit in this layout."
        )

        triggerRows[index] = {
            frame = row,
        }
    end

    local function updateRowWidths()
        local availableWidth = rowAnchorParent:GetWidth()
        if not availableWidth or availableWidth <= 0 then
            availableWidth = panel:GetWidth() or 640
        end

        -- Two-column mode (preserved, not active; operator 2026-09-28):
        --[[
        columnWidth = math.floor((availableWidth - columnGap) / 2)
        if columnWidth < 260 then
            columnWidth = 260
        end
        for index, row in ipairs(triggerRows) do
            local column = ((index - 1) % 2)
            local xOffset = column == 0 and 0 or (columnWidth + columnGap)
            row.frame:ClearAllPoints()
            row.frame:SetPoint("TOPLEFT", xOffset, rowStartY - (math.floor((index - 1) / 2) * (rowHeight + rowGap)))
            row.frame:SetWidth(columnWidth)
        end
        ]]
        columnWidth = availableWidth
        if columnWidth < 260 then
            columnWidth = 260
        end
        for index, row in ipairs(triggerRows) do
            row.frame:ClearAllPoints()
            row.frame:SetPoint("TOPLEFT", 0, rowStartY - ((index - 1) * (rowHeight + rowGap)))
            row.frame:SetWidth(columnWidth)
        end
    end

    local function renderPage()
        if state.page < 1 then
            state.page = 1
        elseif state.page > totalPages then
            state.page = totalPages
        end

        local page = COMBAT_TRIGGER_PAGES[state.page] or {}
        pageLabel:SetText(string.format("Page %d of %d", state.page, totalPages))

        for index, row in ipairs(triggerRows) do
            local trigger = page[index]
            if trigger then
                row.frame:Show()
                row.frame:SetMockData(trigger)
            else
                row.frame:Hide()
            end
        end

        if state.page <= 1 then
            prevButton:Disable()
            if prevButton.label then
                prevButton.label:SetTextColor(0.45, 0.45, 0.45, 1)
            end
        else
            prevButton:Enable()
            if prevButton.label then
                prevButton.label:SetTextColor(0.80, 0.80, 0.80, 1)
            end
        end

        if state.page >= totalPages then
            nextButton:Disable()
            if nextButton.label then
                nextButton.label:SetTextColor(0.45, 0.45, 0.45, 1)
            end
        else
            nextButton:Enable()
            if nextButton.label then
                nextButton.label:SetTextColor(0.80, 0.80, 0.80, 1)
            end
        end
    end

    prevButton:SetScript("OnClick", function()
        state.page = math.max(1, state.page - 1)
        renderPage()
    end)

    nextButton:SetScript("OnClick", function()
        state.page = math.min(totalPages, state.page + 1)
        renderPage()
    end)

    renderPage()
    updateRowWidths()
    rowAnchorParent:HookScript("OnSizeChanged", updateRowWidths)
end

function Tabs:GetRowCount()
    -- Dynamic layout: row count comes from the wrapped layout for the live
    -- spec at the tab container's current width. Falls back to the legacy
    -- spec `row` hints when no container has been wired yet (so callers that
    -- run before CreateOptionsPanel still get a sane height).
    if self.container and self.container.GetWidth then
        local ok, width = pcall(self.container.GetWidth, self.container)
        if ok and type(width) == "number" and width > 0 then
            return ComputeTabLayout(width).rows
        end
    end
    local maxRow = 1
    if BLU.OptionsTabs then
        for _, tabInfo in ipairs(BLU.OptionsTabs) do
            if tabInfo.row and tabInfo.row > maxRow and not tabInfo.hidden then
                maxRow = tabInfo.row
            end
        end
    end
    return maxRow
end

function Tabs:GetContainerHeight()
    return 10 + (self:GetRowCount() * TAB_BUTTON_HEIGHT) + ((self:GetRowCount() - 1) * TAB_ROW_SPACING) + 6
end

-- Wire the strip's container frame. Called by CreateOptionsPanel after the
-- tabContainer exists; GetRowCount then reflects the wrapped layout at the
-- container's live width.
function Tabs:SetContainer(container)
    self.container = container
end

-- Recompute the dynamic layout for the live spec at the container's current
-- width and apply it to every tab button. Idempotent; safe to call on every
-- OnSizeChanged and after any spec change (tab add/remove). Buttons whose
-- spec entry is hidden are hidden; all others are shown and repositioned.
-- Returns the computed row count.
function Tabs:RefreshLayout()
    if not self.container then return nil end
    local width = self.container:GetWidth()
    if not width or width <= 0 then return nil end

    local layout = ComputeTabLayout(width)
    local applied = {}
    for _, entry in ipairs(layout.buttons) do
        local button = self.buttons and self.buttons[entry.index]
        if button then
            button.tabX = entry.x
            button.tabLayoutRow = entry.row
            button.tabWidth = entry.width
            button:UpdatePosition()
            button:Show()
            applied[entry.index] = true
        end
    end
    -- Buttons whose spec entry is hidden (flavor-gated out) stay hidden.
    if self.buttons then
        for index, button in ipairs(self.buttons) do
            if not applied[index] then
                button:Hide()
            end
        end
    end
    self.layoutRows = layout.rows
    return layout.rows
end

-- Create a tab button (alpha.3 style)
function BLU.CreateTabButton(parent, text, index, row, col, panel, icon)
    local buttonName = "BLUTab" .. tostring(index) .. text:gsub("%W", "")
    local button = CreateFrame("Button", buttonName, parent)
    button:SetSize(TAB_BUTTON_WIDTH_CORE, TAB_BUTTON_HEIGHT)
    -- Legacy spec hints, kept for compatibility; the dynamic layout pass
    -- (Tabs:RefreshLayout) owns the actual geometry.
    button.tabRow = row
    button.tabCol = col
    button.isPlaceholder = false

    -- Dynamic position/width for this button, computed from the live spec
    -- and the container's actual width by ComputeTabLayout. Until the first
    -- strip-level layout pass runs (Tabs:RefreshLayout), fall back to the
    -- legacy fixed row/col math so the button renders exactly where the old
    -- code put it; once the dynamic pass has run, tabX/tabLayoutRow/tabWidth
    -- own the geometry.
    local function legacyPosition(self)
        if self.tabCol == 1 then
            return TAB_ROW_PADDING, TAB_BUTTON_WIDTH_CORE
        end
        return TAB_ROW_PADDING + TAB_BUTTON_WIDTH_CORE + TAB_SPACING + (self.tabCol - 2) * (TAB_BUTTON_WIDTH_WIDE + TAB_SPACING),
            TAB_BUTTON_WIDTH_WIDE
    end

    function button:UpdatePosition()
        local xOffset, width
        if self.tabX ~= nil then
            xOffset, width = self.tabX, (self.tabWidth or TAB_BUTTON_WIDTH_CORE)
        else
            xOffset, width = legacyPosition(self)
        end
        local layoutRow = self.tabLayoutRow or self.tabRow or 1
        local yOffset = -10 - (layoutRow - 1) * (TAB_BUTTON_HEIGHT + TAB_ROW_SPACING)
        self:SetWidth(width)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    end

    button:UpdatePosition()
    button:HookScript("OnShow", function(self)
        self:UpdatePosition()
    end)
    -- Container width changes re-wrap the whole strip; the strip-level
    -- RefreshLayout hook below triggers this button's reposition too.

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.11, 0.15, 0.90)
    button.bg = bg

    local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)
    button.border = border

    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if icon then
        local iconTexture = button:CreateTexture(nil, "ARTWORK")
        iconTexture:SetSize(14, 14)
        iconTexture:SetPoint("LEFT", 6, 0)
        iconTexture:SetTexture(icon)
        button.icon = iconTexture

        buttonText:SetPoint("LEFT", iconTexture, "RIGHT", 4, 0)
        buttonText:SetPoint("RIGHT", -4, 0)
        buttonText:SetJustifyH("LEFT")
    else
        buttonText:SetPoint("CENTER", 0, 0)
    end
    buttonText:SetText(text)
    buttonText:SetTextColor(0.8, 0.8, 0.8, 1)
    button.text = buttonText

    button:SetScript("OnClick", function(self)
        BLU:PrintDebug("[Tabs] Clicked tab '" .. tostring(text) .. "' (" .. tostring(self.tabIndex) .. ")")
        panel:SelectTab(self.tabIndex)
    end)

    button:SetScript("OnEnter", function(self)
        BLU:PrintDebug("[Tabs] Hover enter on tab '" .. tostring(text) .. "'")
        if self.greyed or self.isPlaceholder then return end
        if not self.isActive then
            self.border:SetBackdropBorderColor(unpack(BLU.Modules.design.Colors.Primary))
            self.text:SetTextColor(unpack(BLU.Modules.design.Colors.Primary))
        end
    end)

    button:SetScript("OnLeave", function(self)
        BLU:PrintDebug("[Tabs] Hover leave on tab '" .. tostring(text) .. "'")
        if self.greyed or self.isPlaceholder then return end
        if not self.isActive then
            self.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            self.text:SetTextColor(0.7, 0.7, 0.7, 1)
        end
    end)

    button.tabIndex = index

    function button:SetActive(active)
        self.isActive = active
        if self.isPlaceholder then
            if active then
                self.bg:SetColorTexture(0.07, 0.08, 0.10, 0.90)
                self.text:SetTextColor(0.65, 0.72, 0.78, 1)
                self.border:SetBackdropBorderColor(unpack(BLU.Modules.design.Colors.Primary))
            else
                self.bg:SetColorTexture(0.05, 0.06, 0.08, 0.55)
                self.text:SetTextColor(0.42, 0.48, 0.52, 1)
                self.border:SetBackdropBorderColor(0.10, 0.14, 0.18, 1)
            end
            if self.icon then
                self.icon:SetDesaturated(true)
                self.icon:SetAlpha(active and 0.75 or 0.45)
            end
            return
        end
        if active then
            self.bg:SetColorTexture(0.11, 0.18, 0.24, 1)
            self.text:SetTextColor(unpack(BLU.Modules.design.Colors.Primary))
            self.border:SetBackdropBorderColor(unpack(BLU.Modules.design.Colors.Primary))
            if self.icon then
                self.icon:SetDesaturated(false)
                self.icon:SetAlpha(1)
            end
        else
            self.bg:SetColorTexture(0.08, 0.11, 0.15, 0.90)
            self.text:SetTextColor(0.7, 0.7, 0.7, 1)
            self.border:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)
            if self.icon then
                self.icon:SetDesaturated(false)
                self.icon:SetAlpha(0.95)
            end
        end
    end

    function button:SetPlaceholder(placeholder)
        self.isPlaceholder = placeholder == true
        self:SetEnabled(true)
        self:SetActive(false)
    end

    return button
end

function Tabs:Init()
    BLU:PrintDebug("[Tabs] Initializing tab system (alpha.3 style)")
    
    -- Tab configuration - defined here so panel creation functions are available
    -- Helpers for coming-soon panels so each tab gets the same styled placeholder
    local function combatPanel(p)
        if BLU.CreateCombatPanel then
            BLU.CreateCombatPanel(p)
        else
            CreateComingSoonPanel(p, "Combat")
        end
    end
    local function collectiblesPanel(p) CreateComingSoonPanel(p, "Collectibles") end
    local function lootPanel(p)         CreateComingSoonPanel(p, "Loot")         end
    local function preyPanel(p)         CreateComingSoonPanel(p, "Prey")         end

    BLU.OptionsTabs = {
        -- Operator manual sorting (2026-09-28, rev 4): fixed grid, rows
        -- subtracted to 2. Column 1: General/Profiles. Column 2:
        -- Debug (row 1) with Sounds directly below (row 2). Events in
        -- columns 3-6 with Legacy (the API achievement system) in row 1
        -- column 6, Loot before Honor in row 2. No box; divider after
        -- column 2.
        -- Row 1
        {text = "General",     create = BLU.CreateGeneralPanel,  row = 1, col = 1, icon = "Interface\\Icons\\INV_Misc_Gear_08"},
        {text = "Profiles",    create = BLU.CreateProfilesPanel, row = 1, col = 2, icon = "Interface\\Icons\\Ability_Marksmanship"},
        {text = "Level Up",    eventType = "levelup",            row = 1, col = 3, feature = "levelup",     icon = "Interface\\Icons\\Achievement_Level_100"},
        {text = "Quest",       eventType = "quest",              row = 1, col = 4, feature = "quest",       icon = "Interface\\Icons\\INV_Misc_Note_01"},
        {text = "Combat",      create = combatPanel,             row = 1, col = 5, feature = "combat",      icon = "Interface\\Icons\\Ability_Warrior_Charge"},
        {text = "Legacy",      eventType = "achievement",        row = 1, col = 6, feature = "achievement",  icon = "Interface\\Icons\\Achievement_Quests_Completed_08"},
        -- Row 2
        {text = "Debug",        create = BLU.CreateDebugPanel,    row = 2, col = 1, icon = "Interface\\Icons\\INV_Misc_Gear_03"},
        {text = "Sounds",      create = BLU.CreateSoundsPanel,   row = 2, col = 2, icon = "Interface\\Icons\\INV_Misc_Bell_01"},
        {text = "Reputation",  eventType = "reputation",         row = 2, col = 3, feature = "reputation",  icon = "Interface\\Icons\\Achievement_Reputation_01"},
        {text = "Loot",         create = lootPanel,               row = 2, col = 4, feature = "loot",        icon = "Interface\\Icons\\INV_Misc_Coin_02"},
        {text = "Honor",        eventType = "honorrank",          row = 2, col = 5, feature = "honorrank",   icon = "Interface\\Icons\\PVPCurrency-Honor-Horde"},
        {text = "Hardcore",    create = BLU.CreateHardcorePanel, row = 2, col = 6, feature = "hardcore",    icon = "Interface\\Icons\\Spell_Shadow_AnimateDead"},
    }

    if BLU.Modules.flavors and BLU.Modules.flavors.ApplyToTabSpec then
        BLU.Modules.flavors:ApplyToTabSpec(BLU.OptionsTabs)
    end
    
    BLU:PrintDebug("[Tabs] Registered " .. #BLU.OptionsTabs .. " tabs")
end

-- Register module
if BLU.RegisterModule then
    BLU:RegisterModule(Tabs, "tabs", "Tab System")
end
