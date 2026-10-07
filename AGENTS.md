# ApocalipseBRRadio Contributor Guide

## Project layout

The Workshop project is the repository root. The installable mod is
`Contents/mods/ApocalipseBRRadio/`; its game files live under `common/media/`.
This is a Project Zomboid Build 42 mod.

- `common/media/lua/shared/ApocalipseBRRadio/ABRRadioFramework.lua` owns the
  shared channel/transmission registry, translation resolution, queues, and
  helper APIs.
- `ABRRadioTransmissions.lua` registers channels and requires the channel
  catalogs.
- `ABRTransmissions_<Channel>.lua` files register the regular radio content.
  Keep new channels and their require statements in the central transmission
  module.
- `common/media/lua/server/ApocalipseBRRadio/ABRRadioServer.lua` owns regular
  scheduling, immediate messages, broadcasts, listener reports, and server
  command hooks.
- `common/media/lua/client/ApocalipseBRRadio/ABRRadioClient.lua` matches
  received radio text and reports listeners. The music client/server modules
  handle their separate music protocol and scheduling.
- Sandbox options are in `common/media/sandbox-options.txt`; their UI text is in
  `common/media/lua/shared/Translate/{EN,PTBR}/Sandbox.json`.
- Radio channel and transmission labels are in
  `common/media/lua/shared/Translate/{EN,PTBR}/RadioData.json`.
- `MUSIC.md` describes the music registration and channel ownership contract.

## Radio registration workflow

1. Register each channel once with `ABRRadio.registerChannel` in
   `ABRRadioTransmissions.lua`. Channel IDs are stable internal identifiers;
   frequencies must not collide with vanilla or other mod channels.
2. Register its transmissions with `ABRRadio.registerTransmission` in the
   channel catalog. Use a stable, unique transmission `id`; the ID is part of
   translation keys and listener matching.
3. Put all player-visible channel names, descriptions, and transmission text in
   `RadioData.json`, not in Lua as bilingual text. Preserve static effects such
   as `"<bzzt>"`, and non-linguistic number/binary sequences, as literal lines.
4. Keep registrations deterministic and identical on server and clients. The
   client builds its `OnDeviceText` lookup from these registrations.

Example transmission:

```lua
ABRRadio.registerTransmission("my_channel", {
    id = "my_tx_01",
    lines = {
        { translationId = true },
        "<bzzt>",
        { translationId = true },
    },
})
```

The first translated line above is `Line01`; the static sound occupies array
position 2, so the next translated line is `Line03`. Line numbering uses the
actual `lines` array index, including static sounds. Add matching keys such as
`RD_ABR_my_channel_my_tx_01_Line01_EN` and
`RD_ABR_my_channel_my_tx_01_Line01_PTBR` to both `RadioData.json` files.

Channel definitions use `{ translationId = "Name" }` or
`{ translationId = "Description" }`. Their keys are
`RD_ABR_Channel_<channelId>_<Name|Description>_<LANG>`.

For reusable/formatted copy, a line can instead use an explicit translation key
and arguments:

```lua
{ translationKey = "RD_ABR_MyReusableLine", args = { value1, value2 } }
```

The framework appends `_<LANG>` and calls `getText(key, unpack(args))`. JSON
format placeholders use the game translation convention (`%1`, `%2`, etc.).
This form is useful for generated transmissions such as the Alexandria channel
catalog and Numbers Station templates.

## Radio label lookup and sandbox language

Dedicated-server startup loads `Translator` before activating mods. The shared
framework calls `Translator.loadFiles()` once when first loaded on the server,
before resolving catalog labels, so the active mod JSON dictionaries are present.
`node tests/translations_spec.js` (with Fengari available) simulates this startup
and validates both catalogs, channel ownership, placeholders, and EN fallback.

`ABRRadio.getLanguage()` maps `SandboxVars.ApocalipseBRRadio.Language` through
`ABRRadio.LANGUAGES` (`1 = EN`, `2 = PTBR`). `registerChannel` resolves channel
name/description keys, and `registerTransmission` resolves marked lines during
registration. A normal line key is composed as:

```text
RD_ABR_<channelId>_<transmissionId>_Line<two-digit array index>_<LANG>
```

The `RD_` prefix makes Project Zomboid read the `RadioData` translation
category. Missing selected-language entries fall back to the `_EN` key.

Both `EN/RadioData.json` and `PTBR/RadioData.json` currently contain the same
set of language-suffixed keys. This duplication is intentional: `getText()`
reads the game process's active language dictionary, while the radio sandbox
option independently selects the suffix. Keeping both variants available in
either active dictionary lets the shared server setting work even when the
server process's game language differs from the chosen broadcast language.
When adding a language, add its code to `ABRRadio.LANGUAGES`, update the sandbox
enum and its translation labels, and add the new suffixed entries to both
`RadioData.json` files.

Text is resolved before `ZomboidRadio:SendTransmission` sends it. All players
therefore hear the one language selected by the server sandbox setting; this
scheme does not localize a broadcast separately for each player's game
language. The resolved text is also what the client matches for listener
reports, so do not replace it with keys after registration.

## Scheduling, listeners, and commands

The server controller selects eligible transmissions by weight and day range,
then sends each line. Clients detect received lines through `OnDeviceText` and
report the channel to the server. The server associates reports with the active
transmission; after its final line, configured commands can be dispatched to
confirmed listeners. Server-side hooks are available through
`ABRRadioServer.registerServerHook`. Preserve the existing listener-report flow
when changing line resolution or transmission data.

Use `ABRRadio.triggerImmediate` for one-shot event broadcasts. Commands and
command arguments belong on the transmission or immediate queue entry, not in
translation text. `ABRRadioServer` also arbitrates scheduled text with music
ownership; see `MUSIC.md` before changing that contract.

## Music content is a separate API

Music stations, songs, and timed talk use `ABRRadio.registerMusicStation`,
`registerSong`, and `registerMusicTalk`. Song title/artist announcements and timed
talk lines use `ABRRadio.resolveText`; song lyrics are not supported. These do
not pass through `registerTransmission`'s `RadioData` key construction. Follow
`MUSIC.md` and the current music content schema when editing that subsystem.

## Validation and encoding

- Keep all edited Lua and JSON UTF-8 without a BOM.
- Parse every changed JSON file and check that each generated `RD_ABR_...` key
  used by registrations exists in both language dictionaries.
- Confirm the EN and PTBR variants for a key have matching placeholders.
- Preserve key IDs when editing copy; changing an ID requires updating every
  corresponding Lua reference and both translation files.
- Prefer focused static validation of the JSON/key mapping. In-game radio
  playback, sandbox selection, listener reports, and event commands still need
  an in-game multiplayer or single-player smoke test when behavior changes.
