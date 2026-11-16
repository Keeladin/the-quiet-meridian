# Gamemaster Audio source review — 14 November 2026

The owner reports poor-quality effects in the current game and has purchased
Gamemaster Audio Pro Sound Collection v1.3. The owner authorized browsing the
extracted downloads and their three PDF guides. This review inventories usable
sources and defines the replacement work; it does not claim a listening-approved
mix or an audio replacement has already been delivered.

## Available files

All three archives and extracted folders are now present under
`/home/jaco/Downloads/`:

| Folder/archive stem | WAV files | Extraction check |
|---|---:|---|
| `Gamemaster_Audio_Pro_Sound_Collection_v1.3_16bit_44.1k` | 8,082 | Every WAV member exists at the expected size. |
| `Gamemaster_Audio_Pro_Sound_Collection_v1.3_16bit_48k` | 8,076 | Every WAV member exists at the expected size. |
| `Gamemaster_Audio_Pro_Sound_Collection_v1.3_24bit_96k` | 8,076 | Download completed during review; every WAV member exists at the expected size. |

These are variants of the same collection, not three independent sound banks.
The 44.1 kHz set has six extra nature/ambience variants and some differently
spelled filenames. Compare files by identity and inspect their actual format,
not merely the parent folder. The bonus-music folders include 44.1 kHz material.
Sampled headers confirmed 16-bit/48 kHz and 24-bit/96 kHz stereo recordings.
The 96 kHz archive is 5,849,766,289 bytes. This was a filename/size and sampled
header check, not a full archive CRC scan or listening audit of every file.

## Three distinct guides reviewed

* **General Tips for Game Developers.pdf**: read the full two-page guide.
  Audition short effects and loops in an editor or the game; use appropriate
  WAV/Ogg loop playback and explicitly enable looping. Search creatively across
  names/categories. Repeated actions need multiple performances and careful
  selection/mixing. A large library does not guarantee every effect is covered.
* **Pro Sound Collection (v1.3) - Sound List.pdf**: extracted and indexed the
  147-page catalogue, then cross-checked relevant groups against the actual
  files. It is an inventory, not an instruction to import everything.
* **How To Setup Automatic Guns Sounds in Games.pdf**: read the full two-page
  guide. The same document also appears as a prefixed copy in a nested folder.
  Its opening/body/tail and variation advice is weapon-specific. The relevant
  general lesson is to control overlapping sound tails. No combat or weapon
  system is implied for this mystery game.

## Relevant candidates for the game

These are candidates identified through filenames, categories and sample
headers. They still need listening review in the scene. A filename alone does
not establish that its performance or style fits the game.

| Game use | Existing examples | Review focus |
|---|---|---|
| Evidence pages and books | `magic_spell_book_page_flips_01.wav` and the page-turn family | Check for an appropriate natural paper sound despite the category name; choose several performances. |
| Bags, cloth and handling | `foley_cloth_light_fast_movement_01.wav` and related Foley files | Preserve quiet tactile detail without exaggerated rustle. |
| Doors and locks | `door_lock_open_01.wav`, `door_lock_close_01.wav`, lock/handle families | Match latch, opening and failed interaction to the actual action. |
| Small fittings | `metal_impact_light_06.wav` and related light impacts | Avoid ringing impacts on soft objects; balance close-up handling. |
| Timber and mechanisms | Wood blocks/rattles, wooden doors, gears/levers/switches | Prefer convincing material movement to a generic electronic click. |
| Harbour detail | `water_splash_small_item_01.wav`, dripping/running loops, ship creaks | Match scene scale and avoid an oversized splash on every find. |
| Rain and wind | `rain_light_hard_surface_loop_01.wav`, `wind_general_soft_low_loop_01.wav` | Verify the loop seam and use restrained scene-specific ambience. |
| Discovery and interface | `chime_tinkle_wood_bell_positive_03.wav`, `coin_bag_ring_gemstone_item_01.wav`, UI variants | Keep frequent finds subtle; reserve a richer payoff for a completed search or chapter. |

Examples checked at 48 kHz include a 0.523-second lock opening, 0.631-second
light metal impact, 1.689-second cloth movement, 2.457-second page flip,
1.850-second positive chime, 9.225-second rain loop and 8.770-second ship-creak
loop. These are measured durations, not listening-quality ratings.

The library also includes many footsteps, bells, clocks, nature ambiences and
human vocalizations. Vocalizations are not scripted character dialogue.
Most glass-labelled files found in this pass are breaking/impact sounds; do
not use a glass smash for gently picking up a goblet just to fill a category.

## Routine selection delegated to Codex

After choosing the first thirteen opening recordings, the owner clarified
that they need not review every sound. Codex may choose and mix further
suitable library recordings, preserving explicit owner choices and accepting
overrides. `SOUND_SELECTION_BRIEF.md` supplies 57 cue families;
`audio-selection/requests.json` records selections and remaining work. Document
who chose each source. Routine curation uses scene context, source descriptions
and signal analysis; overall listening feedback remains useful because this
session does not reliably judge audio character by ear.

## Integration direction

1. Keep the purchased archives and original masters in the owner's library.
   Select a documented set as extensive as the game needs, with source filename,
   hash, treatment and assigned interaction recorded.
2. Use the 24-bit/96 kHz masters where editing benefits from them; make runtime
   derivatives at an appropriate rate after auditioning. The complete 48 kHz
   version is already suitable for selection and game playback. Do not upscale
   lower-resolution material or automatically apply the old 32 kHz Foley
   pipeline to every new source.
3. Replace weak effects by action/material, with variation for repeated finds,
   coherent ambience and distinct room/chapter completion cues. Maintain voice
   ducking, independent volume controls, sensible cooldowns and clean tail
   handling. Loudness should be balanced by role, not peak-normalized to make
   every sound equally prominent.
4. Review the result through actual gameplay on headphones and speakers.
   Check clipping, intrusive repetitions, click timing, seamless loops and
   dialogue intelligibility. Obtain listening feedback before claiming that
   the subjective quality problem has been solved.
5. Package only sounds used by the game. Keep the original library private;
   any source archive intended for public sharing must omit licensed raw or
   reusable effect assets and explain how a licensed owner restores them.

## Source and permitted use

The vendor describes the three formats on its [collection page](https://www.gamemasteraudio.com/).
Its [current EULA](https://gamemasteraudio.com/wp-content/uploads/2020/01/Gamemaster-Audio-End-User-License-Agreement.pdf)
allows editing and use within commercial games, including use of AI coding
assistants under its stated conditions. Standalone redistribution and AI
training/dataset use are excluded. The owner's purchased source recordings
have only been inspected locally in this review; none were uploaded or changed.

## Opening selections received — 14 November 2026

Jaco supplied thirteen exact 24-bit / 96 kHz masters in
`audio-selection/opening-owner-choices.txt`. All exist and their hashes are
recorded in `audio-selection/opening-provenance.json`. The isolated opening
preview now uses prepared stereo 48 kHz versions of those exact choices, with
three looping background layers, periodic clock/creaks and event effects.
The original library is unchanged. Final mix listening approval remains open;
this does not replace sounds across the main campaign. The remaining 44 cue
families are now available for Codex selection.
