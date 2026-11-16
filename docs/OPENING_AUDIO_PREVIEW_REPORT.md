# Opening-room audio preview — 14 November 2026

All thirteen recordings in Jaco’s updated opening choices are now used in the
isolated Dispatch Office hidden-object preview, revision 3. The main campaign’s
runtime remains unchanged. The other 44 sound-request families are now available for routine
selection by Codex, following the owner’s later direction.

## What changed

- Harbour water, rain and the selected quiet background form three independent
  looping layers. Short wrap crossfades smooth their loop boundaries.
- The selected clock ticks once a second. Boat creaks play at intervals of
  13–23 seconds; building creaks at 22–39 seconds. A pause does not trigger a
  burst of missed events when play resumes.
- Ordinary discoveries use the chosen camera-lever recording. Club and Knight
  use the chosen symbol-recognition sound. Finding an already-found object
  does not repeat the reward sound.
- Accepted hints and button selections use their chosen recordings.
- Completing the search plays its payoff, then the receipt sound, then the
  writing sound as the receipt is recorded in the preview’s saved progress.
  This is not a claim of integration into the campaign casebook. A failed save
  does not announce a journal update. Loading an already-completed search does
  not repeat the completion sequence; restarting cancels any pending sequence.
- Sound mutes all layers and cancels pending event sounds. The separate Music
  button lets the owner hear the room atmosphere without the existing score.
  The score itself is unchanged and plays more quietly.

The original filenames’ categories did not override the owner’s choices: the
selected door creaks represent the boat/building, and the selected wood movement
represents receipt handling. No additional library recordings were selected.

## Preparation and licensing

The thirteen selected 24-bit / 96 kHz masters were preserved unchanged. Game
copies are stereo 48 kHz Ogg Vorbis at quality 6, totalling 1,069,587 bytes.
Reducing unused ultrasonic bandwidth and compressing for playback does not
remove a selected sound. Short effects retain their natural timing and tails.
The background layers have gentle distance filtering; each sound has its own
playback level. Sources, processing and output hashes are recorded in
`docs/audio-selection/opening-provenance.json`.

Only selected effects are embedded in the playable packages. Shareable source
archives omit reusable purchased recordings and include restoration instructions
for an owner with the licensed collection. No API calls, paid generation,
library upload, system installation or service changes were needed.

## Verification

The full project verification passes: 32 checks passed, with native Windows
playtesting and blind-duration testing explicitly not performed. Within those
checks, 114 search/state/interaction assertions and 71 audio assertions passed.
Checks cover selected resource loading, looping, event triggers, replay guards,
muting, music independence, completion ordering and cleanup on exit. Original
master hashes were rechecked unchanged, and all thirteen prepared assets passed
format/hash/no-clipping checks.

The search interaction suite also passed with native Linux rendering. The
960 × 600 screenshot was inspected to confirm the added music control fits.
Extracted Linux and Windows preview packages pass startup checks that load
all thirteen sounds. Windows execution uses Wine; it is not a native Windows
listening test. Both source archives were checked to omit the reusable purchased
recordings. The extracted preview source was then restored from the owner’s
licensed masters, imported and successfully launched.

## Listening review remains open

This is a prepared mix for the owner to hear, not a claim of final listening
approval. Start with Music off to hear the room layers. Try discoveries, a hint
and the completed-room reward, then compare with Music on. If a v2 search was
already completed, use Start again to hear a new completion sequence. This
revision preserves that preview save and does not change campaign saves.

Full campaign hidden-object conversion, scene-by-scene audio integration,
voice production and final playtesting remain separate unfinished milestones.

## Owner listening feedback — ocean/rain balance revision 3.1

The owner said the sounds were good, but the ocean was too loud and the rain
was not audible. Only these two playback levels changed: ocean down 6 dB
(from -12 to -18 dB), rain up 9 dB (from -13 to -4 dB). The selected recordings,
prepared audio files, other sound levels, timing and saved progress are unchanged.
The rain recording has quieter sustained sound than the ocean recording; its
new level brings the two layers to comparable average levels (approximately
-39.9 and -38.8 dBFS respectively). This is a measured balance correction,
with the revised mix still available for the owner to judge by ear.

The owner also delegated routine selection and mixing to Codex; individual
recording approvals are no longer required. Existing explicit choices remain
in place. Scene context, descriptions and audio analysis guide curation; the
agent has disclosed that it cannot reliably judge character by ear in this
session. Overall gameplay feedback guides later subjective adjustments.

Revision 3.1 passed all 32 automated project checks and both extracted preview
startup checks (native Linux and Windows under Wine). The audio files are
unchanged; only the two playback levels differ from revision 3.
