--[[
    APOCALIPSE [BR] - Ghost Radio Transmissions
    Channel: ghost_radio (66.6 MHz)

    Creepypasta-style transmissions: unsettling whispers, cryptic warnings,
    and voices from a frequency no one claims to operate.
]]


ABRRadio.registerTransmission("ghost_radio", {
    id = "gho_01",
    lines = {
        "<wzzt>",
        { translationId = true },
        "<szzt>",
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 0,
})

ABRRadio.registerTransmission("ghost_radio", {
    id = "gho_02",
    lines = {
        "<fzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<wzzt>",
        { translationId = true },
        "<szzt>",
    },
    weight = 12,
    minDay = 3,
})

ABRRadio.registerTransmission("ghost_radio", {
    id = "gho_03",
    lines = {
        "<fzzt>",
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<szzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 8,
    minDay = 7,
})

ABRRadio.registerTransmission("ghost_radio", {
    id = "gho_04",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<szzt>",
    },
    color = { r = 0.8, g = 0.0, b = 0.0 },
    weight = 15,
    minDay = 10,
})

ABRRadio.registerTransmission("ghost_radio", {
    id = "gho_05",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 5,
})

ABRRadio.registerTransmission("ghost_radio", {
    id = "gho_06",
    lines = {
        { translationId = true },
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<szzt>",
    },
    weight = 10,
    minDay = 14,
})

ABRRadio.registerTransmission("ghost_radio", {
    id = "gho_07",
    lines = {
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    color = { r = 0.7, g = 0.0, b = 0.3 },
    weight = 12,
    minDay = 21,
    command = "ParanormalEvent",
    commandArgs = { type = "invasion" },
})
