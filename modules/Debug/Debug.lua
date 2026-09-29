--=====================================================================================
-- BLU Debug Module
-- Dedicated debug options and scope filtering panel
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]
local DebugModule = {}

local DEBUG_SCOPES = {
    {key = "core",     label = "Core",              description = "Framework state and slash commands."},
    {key = "options",  label = "Options",           description = "Options panel creation and layout."},
    {key = "tabs",     label = "Tabs",              description = "Tab hover, clicks, and positioning."},
    {key = "registry", label = "Registry",          description = "Sound selection and playback."},
    {key = "loader",   label = "Loader / Init",     description = "Init and module loading flow."},
    {key = "database", label = "Database / Config", description = "Saved variables and config writes."},
    {key = "profiles", label = "Profiles",          description = "Profile switching and management."},
    {key = "modules",  label = "Modules",           description = "Module enable and disable state."},
    {key = "events",   label = "Events / Combat",   description = "Event registration and timers."},
    {key = "sounds",   label = "Sounds / Media",    description = "Sound UI and pack discovery."},
    {key = "features", label = "Feature Modules",   description = "Quest, event, and feature modules."},
}

BLU.DebugScopeDefinitions = DEBUG_SCOPES

local function EnsureDebugDefaults()
    if not (BLU and BLU.db) then
        return false
    end

    local profile = BLU.db
    profile.debugScopes = profile.debugScopes or {}
    for _, scopeInfo in ipairs(DEBUG_SCOPES) do
        if profile.debugScopes[scopeInfo.key] == nil then
            profile.debugScopes[scopeInfo.key] = true
        end
    end

    return true
end

BLU.EnsureDebugDefaults = EnsureDebugDefaults

local function CreateToggleState(parent, enabled)
    local switchFrame = CreateFrame("Frame", nil, parent)
    switchFrame:SetSize(44, 20)

    local switchBg = switchFrame:CreateTexture(nil, "BACKGROUND")
    switchBg:SetAllPoints()
    switchBg:SetTexture("Interface\\Buttons\\WHITE8x8")

    local toggle = CreateFrame("Button", nil, switchFrame)
    toggle:SetSize(18, 18)
    toggle:EnableMouse(true)

    local toggleBg = toggle:CreateTexture(nil, "ARTWORK")
    toggleBg:SetAllPoints()
    toggleBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    toggleBg:SetVertexColor(1, 1, 1, 1)

    local function update(newState)
        toggle:ClearAllPoints()
        if newState then
            toggle:SetPoint("RIGHT", switchFrame, "RIGHT", -1, 0)
            switchBg:SetVertexColor(unpack(BLU.Modules.design.Colors.Primary))
        else
            toggle:SetPoint("LEFT", switchFrame, "LEFT", 1, 0)
            switchBg:SetVertexColor(0.3, 0.3, 0.3, 1)
        end
    end

    update(enabled == true)

    return switchFrame, toggle, update
end

local function CreateDebugControls(parent, options)
    if not EnsureDebugDefaults() then
        local unavailable = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        unavailable:SetPoint("TOPLEFT", 0, -12)
        unavailable:SetText("|cffff6666Database not ready. Reopen this tab in a moment.|r")
        return nil
    end

    options = options or {}

    local profile = BLU.db
    local section = BLU.Modules.design:CreateSection(parent, options.title, options.icon)
    if options.point then
        section:SetPoint(unpack(options.point))
    end
    if options.setAllPointsTo then
        section:SetAllPoints(options.setAllPointsTo)
    end
    if options.topLeft and options.bottomRight then
        section:SetPoint("TOPLEFT", unpack(options.topLeft))
        section:SetPoint("BOTTOMRIGHT", unpack(options.bottomRight))
    end
    if options.height then
        section:SetHeight(options.height)
    end

    local content = section.content

    if options.includeMasterToggle ~= false then
        local toggleParent = (options.masterToggleInHeader and section.header) or content

        local status = toggleParent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if options.masterToggleInHeader and section.header then
            status:SetPoint("RIGHT", toggleParent, "RIGHT", -58, 0)
        else
            local masterLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            masterLabel:SetPoint("TOPLEFT", 0, -2)
            masterLabel:SetText("|cff05dffaDebug Mode|r")
            status:SetPoint("RIGHT", content, "TOPRIGHT", -54, -2)
        end

        local switchFrame, toggle, updateToggle = CreateToggleState(toggleParent, profile.debugMode == true)
        if options.masterToggleInHeader and section.header then
            switchFrame:SetPoint("RIGHT", toggleParent, "RIGHT", -8, 0)
        else
            switchFrame:SetPoint("TOPRIGHT", 0, -2)
        end

        local function RefreshMasterToggle()
            local enabled = profile.debugMode == true
            updateToggle(enabled)
            status:SetText(enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r")
        end

        toggle:SetScript("OnClick", function()
            profile.debugMode = not (profile.debugMode == true)
            BLU.debugMode = profile.debugMode
            RefreshMasterToggle()
            BLU:PrintDebug("[Options/Debug] Debug mode set to " .. tostring(profile.debugMode))
        end)

        RefreshMasterToggle()
    end

    local startY = options.startY
    if startY == nil then
        if options.includeMasterToggle == false then
            startY = -2
        elseif options.masterToggleInHeader then
            startY = -4
        else
            startY = -30
        end
    end
    local rowStep = options.rowStep or 38
    local detailWidth = options.detailWidth or 200
    local showDescriptions = options.showDescriptions ~= false
    local centered = options.centerColumns == true
    local columnGap = options.columnGap or 24
    local leftColumnX = centered and -(detailWidth + 26 + columnGap / 2) or (options.leftColumnX or 0)
    local rightColumnX = centered and (columnGap / 2) or (options.rightColumnX or 260)

    for index, scopeInfo in ipairs(DEBUG_SCOPES) do
        local column = ((index - 1) % 2)
        local row = math.floor((index - 1) / 2)
        local x = column == 0 and leftColumnX or rightColumnX
        local y = startY - (row * rowStep)

        local tooltipText = showDescriptions and nil or scopeInfo.description
        local checkbox = BLU.Modules.design:CreateCheckbox(content, scopeInfo.label, tooltipText)
        if centered then
            checkbox:SetPoint("TOPLEFT", content, "TOP", x, y)
            checkbox:SetWidth(detailWidth + 26)
        else
            checkbox:SetPoint("TOPLEFT", x, y)
        end
        checkbox.check:SetChecked(profile.debugScopes[scopeInfo.key] ~= false)
        checkbox.check:SetScript("OnClick", function(self)
            profile.debugScopes[scopeInfo.key] = self:GetChecked()
            BLU:PrintDebug("[Options/Debug] Debug scope '" .. tostring(scopeInfo.key) .. "' set to " .. tostring(profile.debugScopes[scopeInfo.key]))
        end)

        if showDescriptions then
            local detail = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            detail:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 26, -1)
            detail:SetWidth(detailWidth)
            detail:SetJustifyH("LEFT")
            detail:SetTextColor(0.72, 0.72, 0.72)
            detail:SetText(scopeInfo.description)
        end
    end

    return section
end

BLU.CreateDebugControls = CreateDebugControls

function BLU.CreateDebugPanel(panel)
    BLU:PrintDebug("[Options/Debug] Creating Debug panel")

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
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_03")

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetText("|cff05dffaDebug Options|r")

    local intro = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 0, -64)
    intro:SetPoint("TOPRIGHT", 0, -64)
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    intro:SetTextColor(0.6, 0.66, 0.72)
    intro:SetText("Choose which diagnostic messages BLU prints to chat.")

    local status = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("RIGHT", titleBar, "RIGHT", -60, 0)

    if not EnsureDebugDefaults() then
        local unavailable = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        unavailable:SetPoint("TOPLEFT", 0, -102)
        unavailable:SetText("|cffff6666Database not ready. Reopen this tab in a moment.|r")
        return
    end

    local profile = BLU.db
    local switchFrame, toggle, updateToggle = CreateToggleState(titleBar, profile.debugMode == true)
    switchFrame:SetPoint("RIGHT", -10, 0)

    local function RefreshMasterToggle()
        local enabled = profile.debugMode == true
        updateToggle(enabled)
        if enabled then
            status:SetText("|cff00ff00ON|r")
        else
            status:SetText("|cffff0000OFF|r")
        end
    end

    toggle:SetScript("OnClick", function()
        profile.debugMode = not (profile.debugMode == true)
        BLU.debugMode = profile.debugMode
        RefreshMasterToggle()
        BLU:PrintDebug("[Options/Debug] Debug mode set to " .. tostring(profile.debugMode))
    end)

    RefreshMasterToggle()

    local scopesSection = CreateDebugControls(content, {
        includeMasterToggle = false,
        height = 304,
        startY = -10,
        title = "Debug Scopes",
        icon = "Interface\\Icons\\INV_Misc_Gear_03",
        rowStep = 40,
        centerColumns = true,
    })
    scopesSection:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -48)
    scopesSection:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -10, -48)
end

function DebugModule:Init()
    BLU:PrintDebug("[DebugModule] Debug module initialized")
end

BLU.Modules = BLU.Modules or {}
BLU.Modules["debug"] = DebugModule

if BLU.RegisterModule then
    BLU:RegisterModule(DebugModule, "debug", "Debug Module")
end

return DebugModule
