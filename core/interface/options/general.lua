--=====================================================================================
-- BLU - interface/options/general.lua
-- General options panel
--=====================================================================================

local addonName = ...
local BLU = _G["BLU"]

local function IsProfileReady()
    return BLU and BLU.db
end

local function EnsureProfileDefaults()
    if not BLU or not BLU.db then
        return false 
    end

    local profile = BLU.db
    profile.soundVolume = tonumber(profile.soundVolume) or 100
    profile.soundChannel = profile.soundChannel or "Master"
    profile.maxQueueSize = tonumber(profile.maxQueueSize) or 3
    profile.queueSounds = profile.queueSounds ~= false
    profile.muteInInstances = profile.muteInInstances == true
    profile.muteInCombat = profile.muteInCombat == true
    profile.modules = profile.modules or {}
    return true
end

local function CreateCheckbox(parent, text, x, y, checked, onClick, tooltip)
    local checkbox = BLU.Modules.design:CreateCheckbox(parent, text, tooltip)
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox.check:SetChecked(checked)
    checkbox.check:SetScript("OnClick", onClick)
    return checkbox
end

local SOUND_CHANNELS = {
    "Master",
    "SFX",
    "Music",
    "Ambience",
    "Dialog",
}


local CHANNEL_CVARS = {
    Master   = "Sound_MasterVolume",
    SFX      = "Sound_SFXVolume",
    Music    = "Sound_MusicVolume",
    Ambience = "Sound_AmbienceVolume",
    Dialog   = "Sound_DialogVolume",
}

local function GetChannelVolume(profile)
    local cvar = CHANNEL_CVARS[profile.soundChannel or "Master"] or "Sound_MasterVolume"
    return math.floor((tonumber(GetCVar(cvar)) or 1) * 100)
end

local function SetChannelVolume(profile, val)
    local cvar = CHANNEL_CVARS[profile.soundChannel or "Master"] or "Sound_MasterVolume"
    SetCVar(cvar, val / 100)
end

function BLU.CreateGeneralPanel(panel)
    BLU:PrintDebug("[Options/General] Creating General panel")
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", 10, -10)
    content:SetPoint("BOTTOMRIGHT", -10, 10)

    local contentBg = content:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.04, 0.06, 0.08, 0.35)

	local titleBar = CreateFrame("Frame", nil, content, "BackdropTemplate")
	titleBar:SetPoint("TOPLEFT", 0, 0)
	titleBar:SetPoint("TOPRIGHT", 0, 0)
	titleBar:SetHeight(44)
	titleBar:SetBackdrop(BLU.Modules.design.Backdrops.Solid)
	titleBar:SetBackdropColor(0.06, 0.10, 0.16, 0.95)
	titleBar:SetBackdropBorderColor(0.10, 0.20, 0.28, 1)

	local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
	titleIcon:SetSize(24, 24)
	titleIcon:SetPoint("LEFT", 10, 0)
	titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_08")

	local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleLabel:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
	titleLabel:SetText("|cff05dffaGeneral|r")

    local intro = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 0, -64)
    intro:SetPoint("TOPRIGHT", 0, -64)
    intro:SetJustifyH("LEFT")
    intro:SetWordWrap(true)
    intro:SetTextColor(0.6, 0.66, 0.72)
    intro:SetText("Configure BLU's core behavior and sound output.")

    if not EnsureProfileDefaults() then
        local unavailable = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        unavailable:SetPoint("TOPLEFT", 0, -102)
        unavailable:SetText("|cffff6666Database not ready. Reopen this tab in a moment.|r")
        content:SetHeight(60)
        return
    end

    local profile = BLU.db

    profile.minimapIconEnabled = profile.minimapIconEnabled ~= false

    -- Left column: Core on top, Behavior below
    local coreSection = BLU.Modules.design:CreateSection(content, "Core", "Interface\\Icons\\Achievement_General")
    coreSection:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -102)
    coreSection:SetPoint("TOPRIGHT", content, "TOP", -12, -102)
    coreSection:SetHeight(112)

    CreateCheckbox(coreSection.content, "Show welcome message", 4, -6, profile.showWelcomeMessage ~= false, function(self)
        profile.showWelcomeMessage = self:GetChecked()
    end, "Shows BLU's startup message after login or reload.")

    CreateCheckbox(coreSection.content, "Show minimap icon", 4, -32, profile.minimapIconEnabled ~= false, function(self)
        profile.minimapIconEnabled = self:GetChecked()
        if BLU.Modules.minimap and BLU.Modules.minimap.SetIconVisible then
            BLU.Modules.minimap:SetIconVisible(self:GetChecked())
        end
    end, "Shows a BLU button on the minimap. Left-click opens the options panel; drag to reposition; Ctrl+Right-click hides it (/blu icon on restores it).")

    local behaviorSection = BLU.Modules.design:CreateSection(content, "Behavior", "Interface\\Icons\\INV_Misc_GroupLooking")
    behaviorSection:SetPoint("TOPLEFT", coreSection, "BOTTOMLEFT", 0, -12)
    behaviorSection:SetPoint("TOPRIGHT", coreSection, "BOTTOMRIGHT", 0, -12)
    behaviorSection:SetHeight(104)

    CreateCheckbox(behaviorSection.content, "Mute in instances", 4, -6, profile.muteInInstances == true, function(self)
        profile.muteInInstances = self:GetChecked()
    end, "Suppresses BLU playback while you are inside instanced content.")

    CreateCheckbox(behaviorSection.content, "Mute in combat", 4, -34, profile.muteInCombat == true, function(self)
        profile.muteInCombat = self:GetChecked()
    end, "Suppresses BLU playback while your character is in combat.")

    -- Right column: Sound Output, anchored to top-right, same top as Core
    local soundSection = BLU.Modules.design:CreateSection(content, "Sound Output", "Interface\\Icons\\INV_Misc_Bell_01")
    soundSection:SetPoint("TOPLEFT", content, "TOP", 12, -102)
    soundSection:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -102)
    soundSection:SetHeight(220)

    local soundDesc = soundSection.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    soundDesc:SetPoint("TOPLEFT", 8, -8)
    soundDesc:SetPoint("RIGHT", soundSection.content, "RIGHT", -8, 0)
    soundDesc:SetJustifyH("LEFT")
    soundDesc:SetWordWrap(true)
    soundDesc:SetTextColor(0.72, 0.78, 0.86)
    soundDesc:SetText("All BLU sounds play through the selected channel. Adjusting the volume here changes your in-game channel level.")

    local soundChannelLabel = soundSection.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundChannelLabel:SetPoint("TOPLEFT", 8, -52)
    soundChannelLabel:SetText("Sound Channel")

    local soundChannelDropdown = CreateFrame("Frame", nil, soundSection.content, "UIDropDownMenuTemplate")
    soundChannelDropdown:SetPoint("TOPLEFT", soundChannelLabel, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(soundChannelDropdown, 160)
    soundChannelDropdown:SetAlpha(0)
    soundChannelDropdown:SetScale(0.01)

    -- The native menu still owns selection; the visible trigger matches BLU's
    -- sound-card dropdowns instead of the default Blizzard menu skin.
    local channelButton = CreateFrame("Button", nil, soundSection.content, "BackdropTemplate")
    channelButton:SetPoint("TOPLEFT", soundSection.content, "TOPLEFT", 8, -72)
    channelButton:SetPoint("TOPRIGHT", soundSection.content, "TOPRIGHT", -8, -72)
    channelButton:SetHeight(22)
    channelButton:SetBackdrop(BLU.Modules.design.Backdrops.Button)
    channelButton:SetBackdropColor(0.10, 0.14, 0.19, 0.96)
    channelButton:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)
    channelButton:RegisterForClicks("LeftButtonUp")

    local channelText = channelButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    channelText:SetPoint("LEFT", 8, 0)
    channelText:SetPoint("RIGHT", -18, 0)
    channelText:SetJustifyH("LEFT")
    channelText:SetTextColor(0.84, 0.84, 0.84, 1)

    local channelArrow = channelButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    channelArrow:SetPoint("RIGHT", -6, 0)
    channelArrow:SetText("v")
    channelArrow:SetTextColor(0.70, 0.78, 0.86, 1)

    channelButton:SetScript("OnClick", function(self)
        ToggleDropDownMenu(1, nil, soundChannelDropdown, self, 0, 0)
    end)
    channelButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(BLU.Modules.design.Colors.Primary))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Sound Channel", 1, 1, 1)
        GameTooltip:AddLine("Pick which WoW audio channel BLU uses for playback. The volume slider below controls that same channel.", 0.82, 0.82, 0.82, true)
        GameTooltip:Show()
    end)
    channelButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.14, 0.20, 0.28, 1)
        GameTooltip_Hide()
    end)

    local function FitChannelDropdown()
        local width = soundSection.content:GetWidth()
        if width and width > 40 then
            UIDropDownMenu_SetWidth(soundChannelDropdown, width - 16)
        end
    end
    soundSection.content:HookScript("OnSizeChanged", FitChannelDropdown)
    channelButton:HookScript("OnShow", FitChannelDropdown)

    -- Proxy so the framework slider's storage[key] read/write routes straight
    -- to the WoW CVar behind the selected channel, instead of a flat db field.
    local volumeStorage = setmetatable({}, {
        __index = function(_, k)
            if k == "volume" then return GetChannelVolume(profile) end
        end,
        __newindex = function(_, k, v)
            if k == "volume" then SetChannelVolume(profile, v) end
        end,
    })

    local RGX = _G.RGXFramework
    local volumeSlider
    RGX:GetDesign():WithTheme({ primary = BLU.Modules.design.Colors.Primary }, function()
        volumeSlider = RGX:GetUI():CreateSlider(soundSection.content, {
            key = "volume",
            label = "Channel Volume",
            storage = volumeStorage,
            min = 0,
            max = 100,
            step = 1,
            default = 100,
            suffix = "%",
            width = 200,
        })
    end)
    volumeSlider:SetPoint("TOPLEFT", 8, -120)
    volumeSlider:EnableMouse(true)
    volumeSlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Channel Volume", 1, 1, 1)
        GameTooltip:AddLine("Adjusts the selected WoW sound channel volume. This affects BLU because BLU plays through that channel.", 0.82, 0.82, 0.82, true)
        GameTooltip:Show()
    end)
    volumeSlider:SetScript("OnLeave", GameTooltip_Hide)

    local function RefreshVolumeSlider()
        volumeSlider.SetValue(GetChannelVolume(profile))
    end

    local function SetSelectedChannel(channel)
        profile.soundChannel = channel or "Master"
        UIDropDownMenu_SetSelectedValue(soundChannelDropdown, profile.soundChannel)
        UIDropDownMenu_SetText(soundChannelDropdown, profile.soundChannel)
        channelText:SetText(profile.soundChannel)
        RefreshVolumeSlider()
    end

    UIDropDownMenu_Initialize(soundChannelDropdown, function(_, level)
        level = level or 1
        local RGX = _G.RGXFramework
        local Drops = RGX:GetDropdowns()
        Drops:HideInlineButtons(level, "bluDeleteButton")

        for _, channel in ipairs(SOUND_CHANNELS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = channel
            info.value = channel
            info.checked = (profile.soundChannel == channel)
            info.func = function() SetSelectedChannel(channel) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    SetSelectedChannel(profile.soundChannel or "Master")

    StaticPopupDialogs["BLU_ADD_CUSTOM_SOUND"] = {
        text = "Add a custom sound file for BLU.",
        subText = "Enter a short file name like myfile or myfile.ogg. You can also paste a full path like Interface\\AddOns\\myfile.ogg. BLU will try common AddOns folders automatically.",
        button1 = ADD,
        button2 = CANCEL,
        hasEditBox = true,
        maxLetters = 255,
        editBoxWidth = 320,
        OnShow = function(self)
            if self.editBox then
                self._bluCustomSoundText = ""
                self.editBox:SetText("")
                self.editBox:SetAutoFocus(false)
                self.editBox:SetFocus()
            end
        end,
        OnHide = function(self)
            self._bluCustomSoundText = nil
        end,
        EditBoxOnTextChanged = function(self)
            local parent = self:GetParent()
            if parent then
                parent._bluCustomSoundText = self:GetText() or ""
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            if parent and parent.button1 then
                parent._bluCustomSoundText = self:GetText() or ""
                parent.button1:Click()
            end
        end,
        OnAccept = function(self)
            local soundInput = self._bluCustomSoundText or (self.editBox and self.editBox:GetText()) or ""
            soundInput = soundInput:gsub("^%s+", ""):gsub("%s+$", "")
            BLU:PrintDebug("[Options/General] Add Custom Sound popup accepted with input '" .. tostring(soundInput) .. "'")

            if soundInput == "" then
                BLU:Print("|cff00ccffBLU:|r Enter a file name like myfile or myfile.ogg.")
                return
            end

            if BLU.Modules and BLU.Modules["usersounds"] and BLU.Modules["usersounds"].AddCustomSound then
                local ok, result, resolvedPath = BLU.Modules["usersounds"]:AddCustomSound(soundInput)
                if ok then
                    if resolvedPath and soundInput:find("[/\\]") then
                        BLU:Print("|cff00ccffBLU:|r Added custom sound: " .. tostring(result) .. " (" .. tostring(resolvedPath) .. ")")
                    else
                        BLU:Print("|cff00ccffBLU:|r Added custom sound: " .. tostring(result))
                    end
                else
                    BLU:Print("|cff00ccffBLU:|r Failed to add custom sound: " .. tostring(result))
                end
            else
                BLU:Print("|cff00ccffBLU:|r User custom sounds are not available yet.")
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    content:SetHeight(480)
end
