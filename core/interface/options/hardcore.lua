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
	content:SetPoint("TOPLEFT", 10, -10)
	content:SetPoint("BOTTOMRIGHT", -10, 10)

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

	-- Title bar matching the other event pages: icon + teal title +
	-- module switch (same size, alignment, and location).
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
	icon:SetTexture("Interface\\Icons\\Spell_Shadow_AnimateDead")

	local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	title:SetText("|cff05dffaHardcore Sounds|r")

	local switchFrame = CreateFrame("Frame", nil, titleBar)
	switchFrame:SetSize(44, 20)
	switchFrame:SetPoint("RIGHT", -10, 0)

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

	local status = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	status:SetPoint("RIGHT", switchFrame, "LEFT", -6, 0)

	local moduleToggleKey = "hardcore"
	local moduleLoadName = "hardcore"

	local function UpdateToggleState(enabled)
		toggle:ClearAllPoints()
		if enabled then
			toggle:SetPoint("RIGHT", switchFrame, "RIGHT", -1, 0)
			switchBg:SetVertexColor(unpack(BLU.Modules.design.Colors.Primary))
			status:SetText("|cff00ff00ON|r")
		else
			toggle:SetPoint("LEFT", switchFrame, "LEFT", 1, 0)
			switchBg:SetVertexColor(0.3, 0.3, 0.3, 1)
			status:SetText("|cffff0000OFF|r")
		end
	end

	local function IsModuleEnabled()
		if not BLU.db then return true end
		local modules = BLU.db.modules
		if not modules then return true end
		if modules[moduleToggleKey] ~= nil then return modules[moduleToggleKey] ~= false end
		if moduleLoadName ~= moduleToggleKey and modules[moduleLoadName] ~= nil then
			return modules[moduleLoadName] ~= false
		end
		return true
	end

	local function SetModuleEnabledState(enabled)
		BLU.db.modules[moduleToggleKey] = enabled
		if moduleLoadName ~= moduleToggleKey then
			BLU.db.modules[moduleLoadName] = enabled
		end
	end

	UpdateToggleState(IsModuleEnabled())

	toggle:SetScript("OnClick", function()
		if not BLU.db then return end
		BLU.db.modules = BLU.db.modules or {}
		local newState = not IsModuleEnabled()
		SetModuleEnabledState(newState)
		BLU:PrintDebug("[Options/Hardcore] Toggled event module '" .. tostring(moduleLoadName) .. "' to " .. tostring(newState))
		UpdateToggleState(newState)
		if newState then
			if BLU.LoadModule then BLU:LoadModule("features", moduleLoadName) end
		else
			if BLU.UnloadModule then BLU:UnloadModule(moduleLoadName) end
		end
		C_Timer.After(0, function()
			if toggle and toggle:IsVisible() then UpdateToggleState(IsModuleEnabled()) end
		end)
	end)

	local intro = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	intro:SetPoint("TOPLEFT", 0, -64)
	intro:SetPoint("TOPRIGHT", 0, -64)
	intro:SetJustifyH("LEFT")
	intro:SetWordWrap(true)
	intro:SetTextColor(0.6, 0.66, 0.72)
	intro:SetText("Pick a sound for each death trigger. Made for hardcore and self-found runs, where every death is a story.")

	if BLU.CreateSoundDropdown then
		BLU.CreateSoundDropdown(content, "death_self",  "Your death",        -102, nil)
		BLU.CreateSoundDropdown(content, "death_party", "Party member death", -182, nil)
		BLU.CreateSoundDropdown(content, "death_raid",  "Raid member death",  -262, nil)
		BLU.CreateSoundDropdown(content, "death_other", "Other player death",  -342, nil)
	else
		BLU:PrintError("[Options/Hardcore] BLU.CreateSoundDropdown unavailable")
	end

	content:SetHeight(504)
end
