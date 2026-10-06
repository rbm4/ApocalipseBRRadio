--[[
    APOCALIPSE [BR] - Emergency Broadcast System Transmissions
    Channel: emergency_broadcast (91.6 MHz)

    Government emergency broadcasts: evacuation orders, containment updates,
    and automated warnings from what remains of Central Command.

    =========================================================================
    AGENT INSTRUCTIONS — GENERATING EMERGENCY TRANSMISSIONS
    =========================================================================
    This file should contain ~365 days of emergency radio transmissions that
    tell a coherent, evolving story of societal collapse through government
    broadcasts. Follow these rules strictly:

    FORMAT:
        ABRRadio.registerTransmission("emergency_broadcast", {
            id = "ebs_<number>",       -- sequential, e.g. ebs_07, ebs_08...
            lines = { ... },
            weight = <5-20>,           -- how likely this is picked vs others in same window
            minDay = <number>,         -- first day this can play (0 = day one)
            maxDay = <number>,         -- last day this can play (-1 = forever)
        })

    LINE FORMATS:
        - i18n:    { translationId = true } (key is built from transmission id and line number)
        - static:  "<bzzt>", "<fzzt>", "<wzzt>", "<szzt>" (radio noise)
        - pause:   "..." or "...."

    NARRATIVE ARC (approximate day ranges — overlap is fine):
        Days 0-14:   Government still functional. Evacuation orders, checkpoint
                     locations, optimistic language. "The situation is under control."
        Days 15-45:  Cracks appear. Contradictory orders, supply shortages,
                     perimeter breaches. Tone shifts to urgent/desperate.
        Days 46-90:  Collapse. Military retreating, cities falling, last-ditch
                     efforts. Individual operators break protocol to give real info.
        Days 91-180: Silence from command. Automated loops still running. Rare
                     rogue operators hijack the frequency with personal messages.
        Days 181-365: Ghost broadcasts. Corrupted automated messages, fragments,
                     eerie loops. Occasional new voice — someone found the
                     equipment and tries to restart the system.

    RULES:
        - ALL text must be ASCII only. No accented characters (a not a, e not e,
          c not c, etc.). PZ cannot render them.
        - Every transmission MUST have both minDay and maxDay set.
        - Use maxDay to create time windows (e.g. minDay=0, maxDay=14).
          Use maxDay=-1 ONLY for transmissions that should loop forever
          (automated messages, corrupted loops in late game).
        - Keep lines short — each line shows on one radio display line.
          Max ~80 characters per EN line, ~90 per PTBR line.
        - Use static sounds (<bzzt>, <fzzt>, etc.) for atmosphere, especially
          at the start/end of transmissions and during "corruption" moments.
        - Weight 15-20 for important story beats, 8-12 for filler/atmosphere,
          5 for rare/secret messages.
        - Some transmissions can have a `command` field to trigger game events:
          command = "ContainmentBreach", commandArgs = { sector = "south" }
        - Maintain internal consistency: reference the same locations (Knox County,
          Louisville, Muldraugh, West Point, Riverside, Rosewood), same military
          units, same government agencies.
        - PTBR translations should feel natural, not robotic machine translation.
        - Aim for 50-80 total transmissions covering the full year.
    =========================================================================
]]


ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 15,
    minDay = 0,
    maxDay = 30,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_02",
    lines = {
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 0,
    maxDay = 45,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_03",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 0,
    maxDay = 30,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_04",
    lines = {
        "<wzzt>",
        "...",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 20,
    minDay = 14,
    maxDay = 90,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_05",
    lines = {
        "<szzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 15,
    minDay = 21,
    maxDay = 90,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_06",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 7,
    maxDay = 60,
    command = "ContainmentBreach",
    commandArgs = { sector = "south" },
})

-- =====================
-- BULK GENERATED TRANSMISSIONS
-- =====================

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_07",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 18,
    minDay = 0,
    maxDay = 10,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_08",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 15,
    minDay = 2,
    maxDay = 14,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_09",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 3,
    maxDay = 18,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_10",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 14,
    minDay = 5,
    maxDay = 20,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_11",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 13,
    minDay = 7,
    maxDay = 25,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_12",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 17,
    minDay = 10,
    maxDay = 28,
    command = "ContainmentBreach",
    commandArgs = { sector = "rosewood" },
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_13",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 12,
    maxDay = 30,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_14",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 15,
    maxDay = 35,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_15",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 11,
    minDay = 18,
    maxDay = 40,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_16",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 20,
    maxDay = 60,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_17",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 13,
    minDay = 22,
    maxDay = 50,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_18",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 16,
    minDay = 25,
    maxDay = 55,
    command = "ContainmentBreach",
    commandArgs = { sector = "riverside" },
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_19",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 14,
    minDay = 28,
    maxDay = 60,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_20",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 30,
    maxDay = 70,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_21",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 32,
    maxDay = 75,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_22",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 8,
    minDay = 35,
    maxDay = 90,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_23",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 9,
    minDay = 38,
    maxDay = 100,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_24",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 40,
    maxDay = 110,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_25",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 16,
    minDay = 45,
    maxDay = 120,
    command = "ContainmentBreach",
    commandArgs = { sector = "sector7" },
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_26",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 8,
    minDay = 50,
    maxDay = 130,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_27",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 15,
    minDay = 60,
    maxDay = 130,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_28",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 8,
    minDay = 70,
    maxDay = 100,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_29",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 14,
    minDay = 80,
    maxDay = 130,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_30",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 8,
    minDay = 90,
    maxDay = 130,
})

-- =====================
-- POST-COLLAPSE, MANUFACTURED WAR, AND HIJACKED BROADCASTS (DAYS 130–365)
-- =====================

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_31",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        "<szzt>"
    },
    weight = 15,
    minDay = 130,
    maxDay = 190,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_32",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true }
    },
    weight = 14,
    minDay = 140,
    maxDay = 185,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_33",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        "<szzt>"
    },
    weight = 13,
    minDay = 145,
    maxDay = 190,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_34",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true }
    },
    weight = 13,
    minDay = 150,
    maxDay = 185,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_35",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true }
    },
    weight = 12,
    minDay = 155,
    maxDay = 190,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_36",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 160,
    maxDay = 220,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_37",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 8,
    minDay = 165,
    maxDay = 225,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_38",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 9,
    minDay = 170,
    maxDay = 230,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_39",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 10,
    minDay = 175,
    maxDay = 235,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_40",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        "<bzzt>",
    },
    weight = 16,
    minDay = 180,
    maxDay = 240,
    command = "ContainmentBreach",
    commandArgs = { sector = "sector7" },
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_41",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true }
    },
    weight = 10,
    minDay = 260,
    maxDay = 320,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_42",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true }
    },
    weight = 10,
    minDay = 280,
    maxDay = 340,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_43",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true }
    },
    weight = 10,
    minDay = 300,
    maxDay = 360,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_44",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true }
    },
    weight = 10,
    minDay = 320,
    maxDay = 380,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_45",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true }
    },
    weight = 10,
    minDay = 340,
    maxDay = 460,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_46",
    lines = {
        "<szzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true },
    },
    weight = 12,
    minDay = 350,
    maxDay = 420,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_47",
    lines = {
        "<fzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<wzzt>",
        { translationId = true },
        { translationId = true },
    },
    weight = 11,
    minDay = 360,
    maxDay = 430,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_48",
    lines = {
        "<szzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true },
    },
    weight = 13,
    minDay = 300,
    maxDay = 400,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_49",
    lines = {
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
        { translationId = true },
        { translationId = true },
    },
    weight = 14,
    minDay = 280,
    maxDay = 380,
})

ABRRadio.registerTransmission("emergency_broadcast", {
    id = "ebs_50",
    lines = {
        "<fzzt>",
        "<szzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 8,
    minDay = 330,
    maxDay = 420,
})
