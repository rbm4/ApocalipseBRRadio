--[[
    APOCALIPSE [BR] - Military Communications Transmissions
    Channel: military_comms (310 kHz)

    Intercepted military transmissions: tactical operations, extraction requests,
    and classified communications from soldiers fighting a war they've already lost.
]]


ABRRadio.registerTransmission("military_comms", {
    id = "mil_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        "<szzt>",
    },
    weight = 12,
    minDay = 0,
})

ABRRadio.registerTransmission("military_comms", {
    id = "mil_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 3,
    command = "MilitaryResponse",
    commandArgs = { action = "fallback", sector = 9 },
})

ABRRadio.registerTransmission("military_comms", {
    id = "mil_03",
    lines = {
        "<fzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<szzt>",
    },
    color = { r = 0.5, g = 0.5, b = 0.5 },
    weight = 8,
    minDay = 14,
})

ABRRadio.registerTransmission("military_comms", {
    id = "mil_04",
    lines = {
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 7,
})

ABRRadio.registerTransmission("military_comms", {
    id = "mil_05",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 15,
    minDay = 21,
})
