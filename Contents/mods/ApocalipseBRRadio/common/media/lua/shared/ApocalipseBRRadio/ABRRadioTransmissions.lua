--[[
    APOCALIPSE [BR] - Radio Transmissions v2.0.0
    Channel definitions and transmission content registration.

    This file registers all custom radio channels and loads their transmission
    pools from individual files. Each channel has its own dedicated file under
    the ApocalipseBRRadio/ directory.

    CHANNEL FILES:
        ABRTransmissions_Emergency.lua   - Emergency Broadcast System (91.6 MHz)
        ABRTransmissions_Ghost.lua       - Ghost Radio (66.6 MHz)
        ABRTransmissions_Apocalipse.lua  - Radio Apocalipse (104.2 MHz)
        ABRTransmissions_Military.lua    - Military Communications (310 kHz)
        ABRTransmissions_Numbers.lua     - Numbers Station (47.8 MHz)
        ABRTransmissions_Alexandria.lua  - The Alexandria Library (108.0 MHz)

    TO ADD A NEW CHANNEL:
        1. Register the channel below with ABRRadio.registerChannel()
        2. Create a new ABRTransmissions_<Name>.lua file with its transmissions
        3. Add a require line at the bottom of this file
        4. Add a sandbox option in sandbox-options.txt and Sandbox.json translations

    STATIC SOUNDS:
        The game recognizes these special strings as radio static:
        "<bzzt>", "<fzzt>", "<wzzt>", "<szzt>"
        Use them as literal strings (not i18n tables) for atmosphere.
]] require "ApocalipseBRRadio/ABRRadioFramework"

-- ============================================================================
-- CHANNEL DEFINITIONS
-- ============================================================================

-- Emergency Broadcast System - 91.6 MHz
ABRRadio.registerChannel({
    id = "emergency_broadcast",
    name = { translationId = "Name" },
    description = { translationId = "Description" },
    frequency = 91600,
    category = "Emergency",
    color = {
        r = 1.0,
        g = 0.2,
        b = 0.2
    },
    intervalMin = 8,
    intervalMax = 20,
    signalStrength = -1,
    sandboxOption = "EnableEmergencyBroadcast"
})

-- Ghost Radio - 66.6 MHz
ABRRadio.registerChannel({
    id = "ghost_radio",
    name = { translationId = "Name" },
    description = { translationId = "Description" },
    frequency = 66600,
    category = "Other",
    color = {
        r = 0.6,
        g = 0.0,
        b = 0.6
    },
    intervalMin = 12,
    intervalMax = 30,
    signalStrength = -1,
    sandboxOption = "EnableCreepyTransmissions"
})

-- Radio Apocalipse - 104.2 MHz
ABRRadio.registerChannel({
    id = "radio_apocalipse",
    name = { translationId = "Name" },
    description = { translationId = "Description" },
    frequency = 104200,
    category = "Radio",
    color = {
        r = 0.2,
        g = 0.8,
        b = 0.2
    },
    intervalMin = 5,
    intervalMax = 15,
    signalStrength = -1,
    sandboxOption = "EnableRadioApocalipse"
})

-- Radio Apocalipse - 30.0 MHz
ABRRadio.registerChannel({
    id = "occ_apocalipse",
    name = { translationId = "Name" },
    description = { translationId = "Description" },
    frequency = 30000,
    category = "Radio",
    color = {
        r = 0.8,
        g = 0.1,
        b = 0.1
    },
    intervalMin = 5,
    intervalMax = 15,
    signalStrength = -1,
    sandboxOption = "EnableRadioApocalipse"
})

-- Military Communications - 310 kHz
ABRRadio.registerChannel({
    id = "military_comms",
    name = { translationId = "Name" },
    description = { translationId = "Description" },
    frequency = 310,
    category = "Military",
    color = {
        r = 0.4,
        g = 0.6,
        b = 0.2
    },
    intervalMin = 15,
    intervalMax = 35,
    signalStrength = -1,
    sandboxOption = "EnableMilitaryComms"
})

-- Numbers Station - 47.8 MHz
ABRRadio.registerChannel({
    id = "numbers_station",
    name = { translationId = "Name" },
    description = { translationId = "Description" },
    frequency = 47800,
    category = "Other",
    color = {
        r = 0.5,
        g = 0.5,
        b = 0.5
    },
    intervalMin = 10,
    intervalMax = 25,
    signalStrength = -1,
    sandboxOption = "EnableNumbersStation"
})

-- The Alexandria Library - 100.0 MHz
ABRRadio.registerChannel({
    id = "alexandria_library",
    name = { translationId = "Name" },
    description = { translationId = "Description" },
    frequency = 100000,
    category = "Radio",
    color = {
        r = 0.8,
        g = 0.7,
        b = 0.3
    },
    intervalMin = 10,
    intervalMax = 25,
    signalStrength = -1,
    sandboxOption = "EnableAlexandriaLibrary"
})

print("[ABRRadio] All channels registered.")

-- ============================================================================
-- LOAD TRANSMISSION FILES
-- ============================================================================

require "ApocalipseBRRadio/ABRTransmissions_Emergency"
require "ApocalipseBRRadio/ABRTransmissions_Ghost"
require "ApocalipseBRRadio/ABRTransmissions_Apocalipse"
require "ApocalipseBRRadio/ABRTransmissions_Military"
require "ApocalipseBRRadio/ABRTransmissions_Numbers"
require "ApocalipseBRRadio/ABRTransmissions_Alexandria"
require "ApocalipseBRRadio/ABRTransmissions_OccultSociety"

-- ============================================================================
print("[ABRRadio] Registered " .. ABRRadio.getTransmissionCount("emergency_broadcast") .. " emergency transmissions.")
print("[ABRRadio] Registered " .. ABRRadio.getTransmissionCount("ghost_radio") .. " ghost radio transmissions.")
print("[ABRRadio] Registered " .. ABRRadio.getTransmissionCount("radio_apocalipse") .. " survivor transmissions.")
print("[ABRRadio] Registered " .. ABRRadio.getTransmissionCount("occ_radio") .. " survivor transmissions.")
print("[ABRRadio] Registered " .. ABRRadio.getTransmissionCount("military_comms") .. " military transmissions.")
print("[ABRRadio] Registered " .. ABRRadio.getTransmissionCount("numbers_station") .. " numbers station transmissions.")
print("[ABRRadio] Registered " .. ABRRadio.getTransmissionCount("alexandria_library") ..
          " Alexandria Library transmissions.")
print("[ABRRadio] All transmissions loaded.")
