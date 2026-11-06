-- Dropdown Play buttons must come from the framework's themed, recycle-safe helper,
-- not hand-built frames with hard-coded colours.
local function read(path)
    local f = assert(io.open(path, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end

local function check(cond, msg)
    if not cond then error("CHECK FAILED: " .. msg, 2) end
end

for _, path in ipairs({ "core/interface/options/sound_panel.lua", "core/interface/options/combat.lua" }) do
    local s = read(path)
    check(s:find('Drops:AddInlineButton(button, {', 1, true), path .. " must use Drops:AddInlineButton")
    check(s:find('key = "bluPreviewButton"', 1, true), path .. " must keep the bluPreviewButton key ForceWidth reserves")
    check(not s:find('CreateFrame("Button", nil, button, "BackdropTemplate")', 1, true), path .. " still hand-builds a Play button")
    check(not s:find('"RIGHT", button, "RIGHT", -8, 0', 1, true), path .. " anchors Play with the old -8 inset")
end

local panel = read("core/interface/options/sound_panel.lua")
check(panel:find('"Task Progress Sound"', 1, true), "Legacy tab must say Task Progress, not Achievement Progress")
check(not panel:find('"Achievement Progress Sound"', 1, true), "no Achievement Progress label in Forever")

print("inline-play-button-test OK")
