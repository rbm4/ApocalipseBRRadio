--[[
    APOCALIPSE [BR] - Numbers Station Transmissions
    Channel: numbers_station (47.8 MHz)

    Enigmatic automated broadcasts: number sequences, NATO phonetic codes,
    binary strings, and coordinates. Its purpose is unknown. Its origin, untraceable.
]]


ABRRadio.registerTransmission("numbers_station", {
    id = "num_01",
    lines = {
        "<wzzt>",
        "... 4... 8... 15... 16... 23... 42...",
        "<fzzt>",
        "... 4... 8... 15... 16... 23... 42...",
        "<szzt>",
    },
    weight = 15,
    minDay = 0,
})

ABRRadio.registerTransmission("numbers_station", {
    id = "num_02",
    lines = {
        { translationId = true },
        { translationId = true },
        "<wzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 0,
})

ABRRadio.registerTransmission("numbers_station", {
    id = "num_03",
    lines = {
        "<fzzt>",
        { translationId = true },
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        "<szzt>",
    },
    weight = 12,
    minDay = 7,
})

ABRRadio.registerTransmission("numbers_station", {
    id = "num_04",
    lines = {
        "01001000 01000101 01001100 01010000",
        "<fzzt>",
        "01001000 01000101 01001100 01010000",
        "<wzzt>",
        { translationId = true },
        "<szzt>",
    },
    weight = 8,
    minDay = 14,
})

ABRRadio.registerTransmission("numbers_station", {
  id = "num_05",
  lines = {
    "<wzzt>",
    "... ... ...",
    { translationId = true },
    "... ... ...",
    "<szzt>",
  },
  weight = 10,
  minDay = 0,
})

-- 100+ new transmissions below, following the established style
local cryptic_transmissions = {
  {
    lines = {"<wzzt>", "... 3... 1... 4... 1... 5... 9...", "<fzzt>", "... 2... 6... 5... 3... 5... 8...", "<szzt>"},
    weight = 8, minDay = 0
  },
  {
    lines = {"01000001 01000010 01010010", "<wzzt>", "01001110 01010101 01001101 01000010 01000101 01010010 01010011", "<szzt>"},
    weight = 7, minDay = 2
  },
  {
    lines = {{ translationKey = "RD_ABR_Numbers_JulietSequence" }, "<bzzt>", { translationKey = "RD_ABR_Numbers_RepeatJuliet" }, "<szzt>"},
    weight = 7, minDay = 1
  },
  {
    lines = {"<fzzt>", { translationKey = "RD_ABR_Numbers_LondonCoordinates" }, "<wzzt>", { translationKey = "RD_ABR_Numbers_LondonConfirmed" }, "<szzt>"},
    weight = 6, minDay = 3
  },
  {
    lines = {"01101101 01100101 01110011 01110011 01100001 01100111 01100101", "<wzzt>", { translationKey = "RD_ABR_Numbers_MessageRepeats" }, "<szzt>"},
    weight = 6, minDay = 4
  },
  {
    lines = {"... 7... 13... 21... 34... 55... 89...", "<fzzt>", "... 144... 233... 377...", "<szzt>"},
    weight = 8, minDay = 0
  },
  {
    lines = {"<wzzt>", { translationKey = "RD_ABR_Numbers_EchoSequence" }, "<bzzt>", { translationKey = "RD_ABR_Numbers_EndTransmission" }, "<szzt>"},
    weight = 7, minDay = 2
  },
  {
    lines = {"<fzzt>", "... 19... 20... 21... 22... 23... 24...", "<wzzt>", "... 25... 26... 27...", "<szzt>"},
    weight = 7, minDay = 0
  },
  {
    lines = {"01010011 01001001 01001100 01000101 01001110 01000011 01000101", "<wzzt>", { translationKey = "RD_ABR_Numbers_Silence" }, "<szzt>"},
    weight = 6, minDay = 5
  },
  {
    lines = {"<wzzt>", { translationKey = "RD_ABR_Numbers_RomeoSequence" }, "<bzzt>", { translationKey = "RD_ABR_Numbers_RepeatRomeo" }, "<szzt>"},
    weight = 7, minDay = 1
  },
}

-- Generate 90 more transmissions with varied cryptic content
for i = 1, 90 do
  local n = i + 5
  local t = {}
  if i % 5 == 1 then
    t.lines = {"<wzzt>", string.format("... %d... %d... %d... %d... %d... %d...", n, n+1, n+2, n+3, n+4, n+5), "<fzzt>", string.format("... %d... %d... %d...", n+6, n+7, n+8), "<szzt>"}
    t.weight = 7 + (i % 4)
    t.minDay = i % 15
  elseif i % 5 == 2 then
    t.lines = {string.format("%08d %08d %08d", n*11, n*13, n*17), "<wzzt>", string.format("%08d %08d", n*19, n*23), "<szzt>"}
    t.weight = 6 + (i % 3)
    t.minDay = i % 20
  elseif i % 5 == 3 then
    t.lines = {{ translationKey = "RD_ABR_Numbers_AlphaBravoCharlie" }, "<bzzt>", { translationKey = "RD_ABR_Numbers_RepeatAlphaBravo" }, "<szzt>"}
    t.weight = 7
    t.minDay = i % 10
  elseif i % 5 == 4 then
    t.lines = {"<fzzt>", { translationKey = "RD_ABR_Numbers_GridCoordinates", args = { 10+i, i, 20+i, i } }, "<wzzt>", { translationKey = "RD_ABR_Numbers_CoordinatesReceived"}, "<szzt>"}
    t.weight = 6
    t.minDay = i % 12
  else
    t.lines = {string.format("%08d %08d %08d", n*7, (n+1)*7, (n+2)*7), "<wzzt>", { translationKey = "RD_ABR_Numbers_MessageRepeats" }, "<szzt>"}
    t.weight = 5 + (i % 4)
    t.minDay = i % 18
  end
  table.insert(cryptic_transmissions, t)
end

for idx, t in ipairs(cryptic_transmissions) do
  ABRRadio.registerTransmission("numbers_station", {
    id = string.format("num_%02d", idx+5),
    lines = t.lines,
    weight = t.weight,
    minDay = t.minDay,
  })
end
