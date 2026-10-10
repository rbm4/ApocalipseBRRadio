-- Run with RadioTranslationCatalog populated from the actual RadioData.json.
local root = "Contents/mods/ApocalipseBRRadio/common/media/lua/shared/"
package.path = root .. "?.lua;" .. package.path
unpack = unpack or table.unpack
local warnings = {}
-- Reproduce a dedicated server whose initial dictionary predates mod activation.
local activeCatalog = {}
local translationLoads = 0
function isServer() return true end
Translator = { loadFiles = function()
    translationLoads = translationLoads + 1
    activeCatalog = RadioTranslationCatalog
end }
print = function(message)
    if message:find("WARNING", 1, true) then warnings[#warnings + 1] = message end
end
function getText(key, ...)
    local text = activeCatalog[key]
    if not text then return key end
    local args = {...}
    return (text:gsub("%%([1-9])", function(index)
        return tostring(args[tonumber(index)] or ("%" .. index))
    end))
end
require "ApocalipseBRRadio/ABRRadioFramework"
assert(translationLoads == 1, "Server did not refresh mod translations")
for languageId, language in ipairs({"EN", "PTBR"}) do
    SandboxVars = { ApocalipseBRRadio = { Language = languageId } }
    dofile(root .. "ApocalipseBRRadio/ABRRadioFramework.lua")
    dofile(root .. "ApocalipseBRRadio/ABRRadioTransmissions.lua")
    -- require caches catalogs; explicitly reload them for the second language.
    if languageId == 2 then
        for _, channel in ipairs({"Emergency", "Ghost", "Apocalipse", "Military",
            "Numbers", "Alexandria", "OccultSociety"}) do
            dofile(root .. "ApocalipseBRRadio/ABRTransmissions_" .. channel .. ".lua")
        end
    end
    assert(#warnings == 0, table.concat(warnings, "\n"))
    for channelId, transmissions in pairs(ABRRadio.transmissions) do
        assert(ABRRadio.channels[channelId], "Unregistered channel: " .. channelId)
        assert(#transmissions > 0, "Empty channel: " .. channelId)
        for _, transmission in ipairs(transmissions) do
            for _, line in ipairs(transmission.lines) do
                assert(type(line) == "string", "Unresolved line in " .. transmission.id)
                assert(not line:find("RD_ABR_", 1, true), "Missing translation: " .. line)
            end
        end
    end
    assert(#ABRRadio.transmissions.occ_apocalipse == 15)
    assert(ABRRadio.transmissions.occ_apocalipse[1].lines[1] ==
        RadioTranslationCatalog["RD_ABR_occ_apocalipse_occ_01_Line01_" .. language])
    for key, args in pairs({ Queued = { "Alice", "Song" },
        BatchQueued = { "Alice", 3, "Song" }, Message = { "Alice", "Hello" },
        Dedication = { "Alice", "Hello" }, Remaining = { 2 } }) do
        local text = ABRRadio.resolveRegisteredLabel("RD_ABR_Jukebox_" .. key, args)
        assert(text == getText("RD_ABR_Jukebox_" .. key .. "_" .. language, unpack(args)))
        assert(not text:find("RD_ABR_", 1, true) and not text:find("%%[1-9]"),
            "Unresolved jukebox translation or placeholder: " .. text)
    end
end

-- Normal generated keys and explicit keys must both fall back and format args.
RadioTranslationCatalog.RD_ABR_test_fallback_Line01_EN = "Fallback %1"
RadioTranslationCatalog.RD_ABR_test_explicit_EN = "Explicit %1"
ABRRadio.registerTransmission("test", { id = "fallback", lines = {
    { translationId = true, args = { "works" } }, "<bzzt>",
    { translationKey = "RD_ABR_test_explicit", args = { "works" } },
} })
local lines = ABRRadio.transmissions.test[1].lines
assert(lines[1] == "Fallback works")
assert(lines[2] == "<bzzt>")
assert(lines[3] == "Explicit works")
assert(#warnings == 0, table.concat(warnings, "\n"))
assert(translationLoads == 1, "Server reloaded translations more than once")
