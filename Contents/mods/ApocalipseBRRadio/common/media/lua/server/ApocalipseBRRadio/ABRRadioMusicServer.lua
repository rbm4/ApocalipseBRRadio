if isClient() then return end
require "ApocalipseBRRadio/ABRRadioMusic"
require "ApocalipseBRRadio/ABRRadioServer"

-- Independent of ABR's game-minute scheduler: audio runs in real seconds.
ABRRadioMusicServer = { states = {}, sequence = getTimestampMs(), ready = false }
local S, M = ABRRadioMusicServer, ABRRadio.music

local function broadcast(station, state)
    local radio = ABRRadio.getRadio()
    if not radio then return end
    local color = station.color
    radio:SendTransmission(0, 0, station.frequency, "", "",
        M.encode(state.entry.id, state.sequence, state.elapsed),
        color.r, color.g, color.b, station.signalStrength, false)
    state.sinceBroadcast = 0
end

local function start(station, state, entry)
    S.sequence = S.sequence + 1
    state.entry, state.sequence, state.elapsed = entry, S.sequence, 0
    state.sinceBroadcast = 0
    if entry.kind == "song" then state.previousSong = entry.id end
    if entry.kind == "talk" then state.previousTalk = entry.id end
    broadcast(station, state)
end

local function tick()
    if not S.ready then return end
    local delta = getGameTime():getRealworldSecondsSinceLastUpdate()
    for id, station in pairs(M.stations) do
        local state = S.states[id]
        if not state then state = {}; S.states[id] = state end
        if ABRRadio.isChannelEnabled(id) then
            if not state.entry then
                -- With an empty template catalog, stay silent until songs exist.
                local entry
                if state.wantTalk then entry = M.pick(station.talks, state.previousTalk) end
                entry = entry or M.pick(station.songs, state.previousSong)
                if entry and ABRRadioServer.tryAcquireChannel(id, "music") then
                    state.wantTalk = false
                    start(station, state, entry)
                end
            else
                state.elapsed = state.elapsed + delta
                state.sinceBroadcast = state.sinceBroadcast + delta
                if state.elapsed >= state.entry.duration then
                    state.wantTalk = state.entry.kind == "song"
                        and ZombRand(100) < (station.talkChance or 0)
                    state.entry = nil
                    ABRRadioServer.releaseChannel(id, "music")
                elseif state.sinceBroadcast >= M.HEARTBEAT then
                    broadcast(station, state)
                end
            end
        else
            state.entry = nil -- listeners expire when heartbeats stop
            state.wantTalk = false
            ABRRadioServer.releaseChannel(id, "music")
        end
    end
end

Events.OnLoadRadioScripts.Add(function() S.ready = true end)
Events.OnTick.Add(tick)
