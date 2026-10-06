# Music contract (framework v2.1.0)

ApocalipseBRRadio owns the shared music registry/protocol, real-time server
scheduler, client audio/lyrics, and channel arbitration. Content packs supply
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
    chunks = {
        { at = 0, sound = "MySongChunk1" },
        { at = 5, sound = "MySongChunk2" },
        -- Continue with chunks covering the full duration.
    },
    lyrics = {
        { at = 12.5, untilTime = 16.0, text = "A lyric line" },
        { at = 30, untilTime = 33.0, text = { EN = "Another line", PTBR = "Outra linha" } },
    },
})

ABRRadio.registerMusicTalk({
    id = "mypack_ident", station = "my_music", duration = 6,
    lines = { { at = 0, text = "You are listening to My music station." } },
})
```

IDs are stable, unique catalog codes (1-24 ASCII alphanumeric/underscore/hyphen
characters), not array indices. Duration and timestamps use real seconds.
Default weight is 10; song repetition is avoided when more than one is available.
Lyrics may be absent or empty. Sparse cues expire at `untilTime`, or after
`lyricDuration` seconds (default four), capped at the next cue/song end. Do not
insert blank entries for instrumental sections. Heartbeats continue throughout
the whole duration regardless of lyrics. Talk uses until-next-line timing by
default. Labels and captions use the framework's configured EN/PTBR language.

Whole-file `sound = "MySound"` is also accepted, but late listeners cannot seek
into ordinary files through the exposed API. Chunks let them join at the next
boundary. The music-pack importer generates audio chunks and sound registrations.
Ordinary file playback is approximate synchronization, not streamed audio.

## Receiver audio

Each client owns one local music emitter per receiving radio, not per listener.
The client uses `playSoundImpl(sound, false, nil)`; `playSound` would send a
native sound packet and duplicate playback on other clients that already render
the same broadcast. Server sequence/position heartbeats select the same chunks
on all clients. Repeated callbacks for the same receiver do not restart audio.

Speaker playback is 3D: placed radios emit from their tile center, equipped
portable radios follow their owner, and vehicle radios follow their vehicle.
FMOD handles direction, distance attenuation, and occlusion. Gain uses the
receiver's `getDeviceVolume()` directly, without a second Lua distance fade.
Headphones remain owner-only, non-spatial playback.

Content sound definitions must use `is3D = true` and explicit clip attenuation
distances (the importer supplies `distanceMin = 1`, `distanceMax = 20`). Older
generated definitions using `is3D = false` need updating for native attenuation
and occlusion. The sound script defines FMOD's attenuation curve; the receiver's
native sound-volume range separately bounds playback eligibility, and changes
with receiver type, location, and volume. It is not a per-emitter FMOD distance
override. Walking beyond that range releases the local emitter; returning joins
at the next chunk boundary.

Power off, mute, retuning, recorded-media playback, blocked reception,
unequipping/transferring a portable radio, picking up/removing a placed radio,
uninstalling/removing a vehicle radio, song end, and missing heartbeats stop and
release the owned emitter. Losing heartbeats uses the existing eight-second
timeout. Native static/VOIP emitters remain owned by the game.

## Channel ownership

`ABRRadioServer.tryAcquireChannel(channelId, owner)` acquires an enabled idle
channel only when no immediate message is waiting and no eligible scheduled text
is due. `releaseChannel(channelId, owner)` releases only the matching owner.
`isChannelBusy(channelId)` reports ownership or an active text transmission.
These calls are server/SP contracts; clients only render received state.

The music scheduler owns a channel for the complete song or timed talk duration.
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

Wire format remains `AMP1|content_id|broadcast_sequence|elapsed_deciseconds`.
Song position determines its local audio chunk and lyric cue. Lyrics, paths, and
labels are never sent. Empty native text carries the codes; reception is filtered
through the radio device. Duplicate/old packets do not restart playback.

`ApocalipseMusic` remains an alias of `ABRRadio.music` for existing generated
catalog modules. New code should use the public `ABRRadio.register*` methods.
Install the updated radio framework on server and clients, and rebuild older
music-pack installations to remove their former `AMPClient`/`AMPServer` runtime;
two runtimes must not run together.

Behavioral integration tests are in `Apocalipse-Music-Pack/tests`; `npm test`
loads this framework source using `ABR_RADIO_MOD` or the development Workshop
path. In-game Kahlua/FMOD and multiplayer playback still need a smoke test.
