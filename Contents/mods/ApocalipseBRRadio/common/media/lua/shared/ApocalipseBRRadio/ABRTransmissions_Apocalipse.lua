--[[
    APOCALIPSE [BR] - Radio Apocalipse Transmissions
    Channel: radio_apocalipse (104.2 MHz)

    Survivor community broadcasts: horde warnings, supply updates, words of
    hope, and distress calls from Knox County's last free voices.
]]


ABRRadio.registerTransmission("radio_apocalipse", {
    id = "apo_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 20,
    minDay = 0,
})

ABRRadio.registerTransmission("radio_apocalipse", {
    id = "apo_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    color = { r = 1.0, g = 0.6, b = 0.0 },
    weight = 12,
    minDay = 3,
    command = "HordeWarning",
    commandArgs = { intensity = "medium", area = "west_point" },
})

ABRRadio.registerTransmission("radio_apocalipse", {
    id = "apo_03",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 7,
})

ABRRadio.registerTransmission("radio_apocalipse", {
    id = "apo_04",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
    },
    color = { r = 1.0, g = 0.3, b = 0.0 },
    weight = 10,
    minDay = 10,
})

ABRRadio.registerTransmission("radio_apocalipse", {
    id = "apo_05",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 15,
    minDay = 0,
})

ABRRadio.registerTransmission("radio_apocalipse", {
    id = "apo_06",
    lines = {
        "<fzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    color = { r = 1.0, g = 0.0, b = 0.0 },
    weight = 8,
    minDay = 5,
})
