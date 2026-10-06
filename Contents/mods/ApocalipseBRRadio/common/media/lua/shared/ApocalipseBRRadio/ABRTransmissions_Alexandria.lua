--[[
    APOCALIPSE [BR] - The Alexandria Library Transmissions
    Channel: alexandria_library (108.0 MHz)

    "The Librarian" — a solitary archivist who monitors every frequency in Knox
    County. She records, catalogs, and re-broadcasts fragments of transmissions
    she intercepts, weaving them with her own commentary. No one knows where
    she transmits from, how she powers her equipment, or how she is still alive.

    She speaks with a calm, scholarly detachment — as if narrating the end of
    the world for an audience that may never exist. She refers to herself only
    as "The Librarian" and to her broadcast as "The Alexandria Library."
]]


-- ============================================================================
-- INTRODUCTIONS / SIGN-ONS
-- ============================================================================

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_intro_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 8,
    minDay = 0,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_intro_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 15,
    minDay = 3,
})


-- ============================================================================
-- CHANNEL CATALOG — dynamically generated from registered channel descriptions
-- The Librarian introduces each frequency she monitors.
-- ============================================================================

do
    -- Split text into sentences at ". " boundaries.
    -- Modders can write multi-sentence descriptions; each sentence becomes
    -- its own radio line separated by "...." pauses for readability.
    local function splitSentences(text)
        local sentences = {}
        local remaining = text
        while true do
            local pos = remaining:find("%. ")
            if not pos then
                local trimmed = remaining:match("^%s*(.-)%s*$")
                if trimmed and trimmed ~= "" then
                    table.insert(sentences, trimmed)
                end
                break
            end
            local sentence = remaining:sub(1, pos)
            local trimmed = sentence:match("^%s*(.-)%s*$")
            if trimmed and trimmed ~= "" then
                table.insert(sentences, trimmed)
            end
            remaining = remaining:sub(pos + 2)
        end
        return sentences
    end

    local catalogIndex = 0
    for _, channelId in ipairs(ABRRadio.getChannelIds()) do
        if channelId ~= "alexandria_library" then
            local channel = ABRRadio.getChannel(channelId)
            if channel and channel.description then
                catalogIndex = catalogIndex + 1

                local freqDisplay
                if channel.frequency >= 1000 then
                    freqDisplay = string.format("%.1f MHz", channel.frequency / 1000)
                else
                    freqDisplay = string.format("%d kHz", channel.frequency)
                end

                local channelName = tostring(channel.name)
                local descriptionParts = splitSentences(tostring(channel.description))
                local maxParts = #descriptionParts

                local lines = {
                    "<fzzt>",
                    { translationKey = "RD_ABR_Alexandria_CatalogEntry", args = { string.format("%03d", catalogIndex), freqDisplay } },
                    { translationKey = "RD_ABR_Alexandria_CalledName", args = { channelName } },
                }

                for si = 1, maxParts do
                    local sentence = descriptionParts[si] or ""
                    if sentence ~= "" then
                        table.insert(lines, sentence)
                        if si < maxParts then
                            table.insert(lines, "....")
                        end
                    end
                end

                table.insert(lines, { translationKey = "RD_ABR_Alexandria_Archived" })
                table.insert(lines, "<bzzt>")

                ABRRadio.registerTransmission("alexandria_library", {
                    id    = "alx_catalog_" .. channelId,
                    lines = lines,
                    color = channel.color,
                    weight = 8,
                    minDay = 0,
                })
            end
        end
    end
    print("[ABRRadio] Alexandria Library: generated " .. catalogIndex .. " channel catalog entries.")
end


-- ============================================================================
-- COMMENTARY ON EMERGENCY BROADCASTS
-- ============================================================================

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_ebs_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 7,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_ebs_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 14,
})


-- ============================================================================
-- COMMENTARY ON GHOST RADIO
-- ============================================================================

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_gho_01",
    lines = {
        { translationId = true },
        { translationId = true },
        "<fzzt>",
        { translationId = true },
        { translationId = true },
        "<szzt>",
    },
    weight = 10,
    minDay = 10,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_gho_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    color = { r = 0.6, g = 0.4, b = 0.6 },
    weight = 8,
    minDay = 21,
})

-- COMMENTARY ON OCULTIST RADIO
ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 12,
    minDay = 3,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 4,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_03",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 5,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_04",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 9,
    minDay = 6,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_05",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 12,
    minDay = 7,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_06",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 11,
    minDay = 8,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_07",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 9,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_08",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 10,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_09",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 8,
    minDay = 11,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_10",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 9,
    minDay = 12,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_11",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 9,
    minDay = 13,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_12",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 14,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_13",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 8,
    minDay = 15,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_14",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 9,
    minDay = 16,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_occ_15",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 12,
    minDay = 17,
})


-- ============================================================================
-- COMMENTARY ON RADIO APOCALIPSE
-- ============================================================================

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_apo_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 12,
    minDay = 5,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_apo_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 10,
})


-- ============================================================================
-- COMMENTARY ON MILITARY COMMUNICATIONS
-- ============================================================================

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_mil_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 21,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_mil_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<bzzt>",
    },
    weight = 12,
    minDay = 14,
})


-- ============================================================================
-- COMMENTARY ON NUMBERS STATION
-- ============================================================================

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_num_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 10,
    minDay = 7,
})


-- ============================================================================
-- PERSONAL / META-NARRATIVE
-- ============================================================================

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_meta_01",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 15,
    minDay = 0,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_meta_02",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 12,
    minDay = 14,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_meta_03",
    lines = {
        "<wzzt>",
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        "<szzt>",
    },
    weight = 15,
    minDay = 28,
})

ABRRadio.registerTransmission("alexandria_library", {
    id = "alx_meta_04",
    lines = {
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
        { translationId = true },
    },
    weight = 18,
    minDay = 0
})
