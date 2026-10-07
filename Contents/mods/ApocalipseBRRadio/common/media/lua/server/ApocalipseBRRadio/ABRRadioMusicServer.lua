if isClient() then return end
require "ApocalipseBRRadio/ABRRadioMusic"
require "ApocalipseBRRadio/ABRRadioServer"

-- Independent of ABR's game-minute scheduler: audio runs in real seconds.
ABRRadioMusicServer = { states = {}, sequence = getTimestampMs(), ready = false,
    scanIndex = 1, fastStations = 0 }
local S, M = ABRRadioMusicServer, ABRRadio.music
S.waitTicks = M.SCAN_WAIT_TICKS
S.LOG_INTERVAL_MS = 60000

local function stationLabel(station)
    return ABRRadio.resolveText(station.name) .. " [" .. station.id .. "] @ " .. station.frequency
end

local function logRuntime(station, state, now)
    local status = state.entry and state.phase or state.waitReason or "idle"
    if status == state.loggedStatus and state.loggedAt
        and now - state.loggedAt < S.LOG_INTERVAL_MS then return end
    state.loggedStatus, state.loggedAt = status, now
    local entry = state.entry
    local content = entry and ("; " .. entry.kind .. "=" .. entry.id
        .. "; caption=" .. M.caption(entry)
        .. "; elapsed=" .. string.format("%.1f/%.1fs", state.elapsed, entry.duration)) or ""
    print("[ABRRadio Music Server] Runtime: " .. stationLabel(station)
        .. "; state=" .. status .. "; songs=" .. #station.songs
        .. "; talks=" .. #station.talks .. content)
end

local function broadcast(station, state, announcement, lineText)
    local packet = { id = state.entry.id, sequence = state.sequence, phase = state.phase }
    if isServer() then
        sendServerCommand(ABRRadio.NET_MODULE, "MusicState", packet)
    elseif ABRRadioMusicClient then
        ABRRadioMusicClient.receiveState(packet)
    end
    local text = lineText
    if announcement then
        local caption = M.caption(state.entry)
        if caption ~= "" then text = M.MUSIC_NOTE .. " " .. caption end
    end
    -- Control packets never pass through vanilla speech/static simulation.
    if text and text ~= "" then
        local radio = ABRRadio.getRadio()
        if radio then
            local color = station.color
            radio:SendTransmission(0, 0, station.frequency, text, "", "",
                color.r, color.g, color.b, station.signalStrength, false)
        end
    end
    state.sinceBroadcast = 0
end

local function broadcastTalkLine(station, state)
    if state.entry.kind ~= "talk" then return end
    local index = M.talkLineIndex(state.entry, state.elapsed)
    if index == 0 or index <= state.textIndex then return end
    state.textIndex = index
    local text = ABRRadio.resolveText(state.entry.lines[index].text)
    if text ~= "" then broadcast(station, state, false, text) end
end

local function start(station, state, entry)
    S.sequence = S.sequence + 1
    state.entry, state.sequence, state.elapsed = entry, S.sequence, 0
    state.phase = entry.kind == "song" and "announce" or "play"
    state.phaseElapsed, state.sinceBroadcast = 0, 0
    state.textIndex = 0
    if entry.kind == "song" then state.previousSong = entry.id end
    if entry.kind == "talk" then state.previousTalk = entry.id end
    broadcast(station, state, entry.kind == "song")
    broadcastTalkLine(station, state)
end

local function startNext(id, station, state)
    local entry
    if state.wantTalk then entry = M.pick(station.talks, state.previousTalk) end
    entry = entry or M.pick(station.songs, state.previousSong)
    if entry and ABRRadioServer.tryAcquireChannel(id, "music") then
        state.wantTalk = false
        state.waitReason = nil
        start(station, state, entry)
    else
        state.waitReason = entry and "waiting_for_channel" or "waiting_for_songs"
    end
end

local function updateStation(id, station, now)
    local state = S.states[id]
    if not state then state = {}; S.states[id] = state end
    -- Include all real time since this station's previous visit, including
    -- the scan delay and server stalls. Frame delta would lose that time.
    local delta = state.checkedAt and math.max(0, (now - state.checkedAt) / 1000) or 0
    state.checkedAt = now
    if ABRRadio.isChannelEnabled(id) then
        state.waitReason = nil
        if not state.entry then
            -- With an empty template catalog, stay silent until songs exist.
            startNext(id, station, state)
        else
            state.phaseElapsed = state.phaseElapsed + delta
            state.sinceBroadcast = state.sinceBroadcast + delta
            if state.phase == "announce" then
                if state.phaseElapsed >= M.ANNOUNCEMENT_DURATION then
                    state.phase, state.phaseElapsed = "play", 0
                    broadcast(station, state)
                elseif state.sinceBroadcast >= M.HEARTBEAT then
                    broadcast(station, state)
                end
            elseif state.phase == "end" then
                -- Keep ownership through the pause so text cannot start early.
                if state.phaseElapsed >= state.intermission then
                    state.entry = nil
                    ABRRadioServer.releaseChannel(id, "music")
                    startNext(id, station, state)
                elseif state.sinceBroadcast >= M.HEARTBEAT then
                    broadcast(station, state)
                end
            else
                state.elapsed = state.elapsed + delta
                if state.elapsed >= state.entry.duration then
                    print("[ABRRadio Music Server] Completed: " .. stationLabel(station)
                        .. "; " .. state.entry.kind .. "=" .. state.entry.id)
                    state.elapsed = state.entry.duration
                    state.phase, state.phaseElapsed = "end", 0
                    broadcast(station, state)
                    state.wantTalk = state.entry.kind == "song"
                        and ZombRand(100) < (station.talkChance or 0)
                    if state.entry.kind == "song" then
                        state.intermission = ZombRand(M.INTERMISSION_MIN, M.INTERMISSION_MAX + 1)
                        if state.intermission == 0 then
                            state.entry = nil
                            ABRRadioServer.releaseChannel(id, "music")
                            startNext(id, station, state)
                        end
                    else
                        state.entry = nil
                        ABRRadioServer.releaseChannel(id, "music")
                        startNext(id, station, state)
                    end
                else
                    broadcastTalkLine(station, state)
                    if state.sinceBroadcast >= M.HEARTBEAT then broadcast(station, state) end
                end
            end
        end
    else
        state.waitReason = "disabled"
        if state.entry then
            state.phase = "end"
            state.elapsed = state.entry.duration
            broadcast(station, state)
        end
        state.entry = nil
        state.wantTalk = false
        ABRRadioServer.releaseChannel(id, "music")
    end
    -- Keep the one-station-per-tick budget, but avoid the 50-tick sleep while
    -- announcing, ending a pause, or delivering short timed announcer lines.
    local fast = state.entry ~= nil and (state.entry.kind == "talk" or state.phase ~= "play")
    if fast ~= (state.fast == true) then
        S.fastStations = S.fastStations + (fast and 1 or -1)
        state.fast = fast
    end
    logRuntime(station, state, now)
end

local function tick()
    if not S.ready then return end
    if #M.stationIds == 0 then
        local now = getTimestampMs()
        if not S.emptyLoggedAt or now - S.emptyLoggedAt >= S.LOG_INTERVAL_MS then
            print("[ABRRadio Music Server] Runtime: waiting for registered music stations.")
            S.emptyLoggedAt = now
        end
        return
    end
    if S.waitTicks > 0 then
        S.waitTicks = S.waitTicks - 1
        return
    end

    local id = M.stationIds[S.scanIndex]
    if id then
        local station = M.stations[id]
        if station then updateStation(id, station, getTimestampMs()) end
        S.scanIndex = S.scanIndex + 1
    end
    if S.scanIndex > #M.stationIds or not id then
        S.scanIndex = 1
        S.waitTicks = S.fastStations > 0 and 0 or M.SCAN_WAIT_TICKS
    end
end

Events.OnLoadRadioScripts.Add(function()
    S.ready = true
    print("[ABRRadio Music Server] Controller ready: " .. #M.stationIds
        .. " stations; runtime heartbeat every 60 seconds.")
    for _, id in ipairs(M.stationIds) do
        local station = M.stations[id]
        print("[ABRRadio Music Server] Station ready: " .. stationLabel(station)
            .. "; songs=" .. #station.songs .. "; talks=" .. #station.talks
            .. "; enabled=" .. tostring(ABRRadio.isChannelEnabled(id)))
    end
end)
Events.OnTick.Add(tick)
print("[ABRRadio Music Server] Controller loaded; waiting for OnLoadRadioScripts.")
