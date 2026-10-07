# Music contract (framework v2.3.0)

ApocalipseBRRadio owns the shared music registry/protocol, real-time server
scheduler, client audio, and channel arbitration. Content packs supply
stations, songs, timed talk, sound definitions, and audio assets. The framework
loads without any music pack and does not register a music station on its own.

```lua
require "ApocalipseBRRadio/ABRRadioMusic"

ABRRadio.registerMusicStation({
    id = "my_music", frequency = 94200,
    name = { EN = "My music station", PTBR = "Minha radio musical" },
    talkChance = 35,
})

ABRRadio.registerSong({
    id = "mypack_song01", station = "my_music",
    title = "Title", artist = "Artist", duration = 120,
    -- Supply these sound scripts and assets in the content pack.
    sound = "MySong",
})

ABRRadio.registerMusicTalk({
    id = "mypack_ident", station = "my_music", duration = 6,
    lines = { { at = 0, text = "You are listening to My music station." } },
})
```

IDs are stable, unique catalog codes (1-24 ASCII alphanumeric/underscore/hyphen
characters), not array indices. Duration and timestamps use real seconds.
Default weight is 10; song repetition is avoided when more than one is available.
Song lyrics are not supported. Legacy song `lyrics`, `lyricDuration`, and `lines`
fields are discarded during registration. Timed talk lines are sent by the
authority as ordinary radio text on the first station check within their active
timestamp window. Windows shorter than a complete scan can be skipped. Talk uses
until-next-line timing by default, with optional `untilTime`. Labels and captions
use the framework's configured EN/PTBR language.

Late listeners start the current song from its beginning on their first playback
heartbeat. Ordinary files cannot seek through the exposed API. Only the server
tracks the registered song duration to end the broadcast and schedule the next
segment. Clients receive no elapsed or remaining time and do not estimate a song
deadline. They follow start/end metadata and the heartbeat timeout instead.

Whole-file `sound = "MySound"` is preferred. Existing chunk-only catalogs remain
supported: the receiver starts the first chunk and advances using local playback
time. When both `sound` and `chunks` are supplied, the whole-file sound wins.
This is local file playback, not streamed audio or exact musical synchronization.

The authority waits 50 OnTick callbacks, then visits one music station per tick
in registration order. During normal song playback it waits another 50 ticks
after the last station. Announcements, post-song pauses, and timed announcer
segments skip that wait so transitions and short text windows are checked each
scan. It still processes at most one station per tick. At the
target 10 ticks/second, a complete cycle takes `(50 + station count) / 10` real
seconds. Station updates use the elapsed `getTimestampMs()` time since that
station's previous check, so server stalls are included. Waiting callbacks do
not read the clock or scan the station table. Song selection still scales with
the selected station's catalog size when a new segment is chosen.

Before each song, the authority transmits `[img=music] Title - Artist`, then waits
at least three real seconds before sending the playback heartbeat on its next
station check. Heartbeats are due after five seconds and sent during those
checks as silent `ApocalipseBRRadio/MusicState` server commands. Only the initial
announcement and timed announcer lines use native radio text; control packets
never trigger vanilla chatter/static effects. Clients cache the newest station
state and apply it to tuned, audible receivers during bounded device discovery.
Clients do not report listeners or acknowledge heartbeats.

On its first check at or after the registered song duration, the authority sends
an end heartbeat. Clients
fade remaining audio to zero over two real seconds, then stop and return the
emitter. Repeated end heartbeats cannot restart the song. The channel stays owned
for a random, inclusive 0-5 real seconds after the song ends. A zero-second
pause releases ownership in the completion check; positive pauses release it at
the first check after their deadline. The same check attempts the next segment,
with queued radio text retaining priority. Only then are
queued text, timed talk, and the next song eligible. Every registered music
station uses this lifecycle independently.

## Receiver audio

Each client owns one local music emitter per receiving radio, not per listener.
The client uses `playSoundImpl(sound, false, nil)`; `playSound` would send a
native sound packet and duplicate playback on other clients that already render
the same broadcast. Server heartbeats identify the active transmission and its
lifecycle; each receiver starts its own audio at zero. Repeated callbacks for
the same receiver do not restart audio.

Speaker playback is 3D: placed radios emit from their tile center, equipped
portable radios follow their owner, and vehicle radios follow their vehicle.
FMOD handles direction, distance attenuation, and occlusion. Gain uses the
receiver's `getDeviceVolume()` directly, without a second Lua distance fade.
Headphones remain owner-only, non-spatial playback.

Content sound definitions must use `is3D = true` and explicit clip attenuation
distances (the importer supplies `distanceMin = 1`, `distanceMax = 20`). Older
generated definitions using `is3D = false` need updating for native attenuation
and occlusion. The sound script defines FMOD's attenuation curve. The Lua
playback lifetime uses a fixed 200-yard listener radius (182.88 tiles, assuming
roughly one metre per tile), independent of radio volume/type. Vertical
separation retains the three-tile weight per floor. Walking beyond this radius
releases the emitter; returning starts the current song at its beginning.
Within this radius, FMOD can still attenuate the sound to silence according to
its clip settings. Headphones remain owner-only. Bounded discovery checks the
full registered receiver list (`ZomboidRadio.getDevices()`), including one-way
radios, and applies cached music state independently of the microphone guard's
small neighbourhood. Radios must be loaded on the client to be discovered.

Power off, mute, retuning, recorded-media playback, blocked reception,
unequipping/transferring a portable radio, picking up/removing a placed radio,
uninstalling/removing a vehicle radio stop and release the owned emitter
immediately. Song end, a replacement transmission, and missing heartbeats fade
the remaining audio before release. Losing heartbeats uses a timeout of three
complete scans at the target tick rate, with an eight-second minimum, followed
by the two-second fade. Both authority and receivers use the same station
registration list to compute this allowance. At one station the timeout is 15.3
seconds; it grows with station count. Sustained tick rates substantially below
the target can still cause expiry. End heartbeats repeat during the pause
so a lost end packet can be recovered on the next heartbeat. A replacement song
waits for outgoing audio to finish fading before starting at zero. Local time is
used only for chunk sequencing, fades, retries, and heartbeat expiry.

Playback handles must be positive: a zero or negative result releases the failed
emitter and retries at most once every two seconds while the broadcast remains
active. One diagnostic is printed per receiver/transmission. Native static/VOIP
emitters remain owned by the game.

## Channel ownership

The listener controller forces microphone mute on local inventory radios and
nearby placed, dropped, and vehicle radios tuned to any registered music
frequency. This applies to admins too, during silence and with speaker volume
zero or power off. Discovery visits at most eight registered devices globally,
eight inventory items and four nearby grid squares per local player per tick;
all dropped objects on each visited square are checked. A complete nearby
square scan takes 41 ticks. Inventory and registered-device discovery latency
grows with their list sizes. A received music heartbeat also protects its device
immediately. Once discovered, forced mute is checked every tick independently
of playback; the previous microphone setting is restored on retuning or when
the device leaves the local inventory/neighbourhood.

Do not set `NoTransmit` for this purpose: vanilla also rejects received
broadcasts for these devices, preventing the music heartbeat protocol. The
microphone guard uses `DeviceData.setMicIsMuted` and is a client restriction,
not validation of malicious clients on the server. Original microphone settings
are retained in memory for the current session; saving while forcibly muted
can preserve that muted setting across reloads.

Audio emitters still tick each frame for smooth playback and fades. The
controller reuses the audibility position lookup and only changes FMOD volume
and headphone/spatial mode when their values change. Empty receiver tables naturally skip the audio loops. Kahlua has no `next()`
global; use `pairs()` for iteration.

`ABRRadioServer.tryAcquireChannel(channelId, owner)` acquires an enabled idle
channel only when no immediate message is waiting and no eligible scheduled text
is due. `releaseChannel(channelId, owner)` releases only the matching owner.
`isChannelBusy(channelId)` reports ownership or an active text transmission.
These calls are server/SP contracts; clients only render received state.

The music scheduler owns a channel through the song announcement, complete song
duration, and 0-5 second post-song pause. Timed talk owns it for its duration.
During ownership, the normal scheduler cannot send/advance text on that channel,
and `triggerImmediate` messages remain queued. Deferred messages retain all their
lines and drain in order after release, before music resumes. Scheduled-text
cooldowns can become due during music and receive a turn at a segment boundary.
Music cannot start over an ongoing text transmission. Other frequencies remain
independent. Existing immediate text can still interrupt ordinary text when it
has not been held behind a music segment; held messages wait for text completion.

Arbitration governs the framework's scheduling APIs, not direct native or
third-party `ZomboidRadio.SendTransmission` calls. Choose a frequency that does
not collide with a vanilla station or another mod's broadcaster.

## Runtime files and compatibility

- Shared: `common/media/lua/shared/ApocalipseBRRadio/ABRRadioMusic.lua`.
- Authority: `common/media/lua/server/ApocalipseBRRadio/ABRRadioMusicServer.lua`.
- Listener: `common/media/lua/client/ApocalipseBRRadio/ABRRadioMusicClient.lua`.
- Ownership and text scheduling: `ABRRadioServer.lua`.

Server commands carry `id`, `sequence`, and `phase` (`announce`, `play`, or
`end`). Sequence and phase ordering reject delayed packets that would revive an
ended transmission. There are no elapsed-time, remaining-time, duration,
audio-path, or lyric fields in the metadata. The initial announcement sends the
resolved title/artist as radio text. Lifecycle heartbeats contain no visible
text. Timed talk is sent separately as ordinary radio text. Playback is filtered
by tuning, power, volume, position, and listener hearing. The legacy
`AMP2|content_id|sequence|phase` decoder remains for old radio events; new servers
send control commands. Deploy the updated framework to server and clients
together. AMP1 is no longer accepted.

`ApocalipseMusic` remains an alias of `ABRRadio.music` for existing generated
catalog modules. New code should use the public `ABRRadio.register*` methods.
Install the updated radio framework on server and clients, and rebuild older
music-pack installations to remove their former `AMPClient`/`AMPServer` runtime;
two runtimes must not run together.

Framework behavioral checks live in `tests/music_spec.lua`. From the Workshop
repository root run:

```sh
npm exec --yes --package=fengari-node-cli -- fengari tests/run.lua
```

The older music-pack test suite targets the former chunk-boundary joining
contract. In-game Kahlua/FMOD and multiplayer playback still need a smoke test.

Server diagnostics use `[ABRRadio Music Server]`. Startup logs distinguish the
controller loading from `OnLoadRadioScripts` readiness and list each station's
name, ID, frequency, song/talk counts, and enabled state. Runtime logs print on
phase changes and every 60 real seconds per station, including content ID,
caption, and elapsed/duration. Waiting states identify an empty catalog, channel
ownership contention, or a disabled station. Completion is logged separately.
These logs report the authority's scheduling state; client reception and local
audio playback still require checking a listening device.

Client diagnostics use `[ABRRadio Music Client] Received` for control phase
changes and `Audio started` when FMOD returns a positive handle. Missing catalog
entries and failed sound starts identify the content/sound ID. These diagnostics
do not prove the local audio is audible; receiver volume and proximity still apply.
