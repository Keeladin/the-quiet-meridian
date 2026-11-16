# The Quiet Meridian — original score and sound design

Audiovisual polish pass, 14 November 2026. This set replaces the short musical
ambient loops in normal play. The preserved alpha and its original eight WAVs
remain unchanged. Music, environmental ambience and interaction effects are now
separate assets so the audio director can mix and crossfade them independently.

## What is delivered

Nine original composed cues provide **1,380.2 seconds (23 minutes)** of music.
Each has a written note-event score, several contrasting sections, phrase dynamics,
melody, accompaniment and selective countermelody. These are rendered compositions,
not a short ambient waveform repeated to reach a longer duration.

| Cue | Duration | Meter / tempo | Musical character |
|---|---:|---|---|
| Main theme | 163.0 s | 3/4, 72 BPM | Piano introduces the Meridian phrase; flute answers; bowed harmony develops it |
| The Borrowed Bell | 133.9 s | 3/4, 66 BPM | Sparse harp, warm cello foundation, hesitant flute answers |
| Water Has a Memory | 143.5 s | 3/4, 82 BPM | Cello and reed exchange the Record theme above a measured work rhythm |
| The Unstruck Hour | 158.7 s | 4/4, 74 BPM | Celesta and flute expose the clock motif; upper glass tones remain occasional |
| Names in the Reeds | 172.4 s | 4/4, 68 BPM | Lyrical flute, cello counterline and major-colour Names theme |
| An Unbroken Chain | 150.7 s | 3/4, 78 BPM | Reed and piano develop a questioning Record motif; the register stays restrained |
| A Record Kept in Common | 154.6 s | 4/4, 76 BPM | Piano and flute reframe the Names theme with more open harmony |
| The Unaccounted Minute | 131.0 s | 4/4, 90 BPM | Low cello, repeated plucked bass and an unsettled harmonic progression |
| Every Name at Dawn | 172.4 s | 4/4, 68 BPM | The Meridian material returns in major, with an extended release and coda |

The main tonal material is shared deliberately: the Meridian theme represents
reconstructing a reliable measure; Names is the city's human memory; Record is
procedural authority and doubt. Each theme uses an authored sequence of scale
degrees and durations. Answer phrases change register and interval emphasis;
shadow sections thin the texture; reprises add a countermelody and higher peak;
codas return to a tonic and leave room for the environment.

Eight synthesized timbres have distinct attack, sustain, partial structure and
release models: felt-like piano, harp, celesta, bowed string ensemble, cello,
flute, reed and plucked bass. Slow bow variation, delayed vibrato, breath/rosin
components, constrained timing/velocity variation and a diffuse stereo room make
the arrangement less mechanical. No real instrument recordings are sampled.

Six independently rendered 72-second soundscapes cover harbor water, indoor air
and distant ticking, machinery, marsh water/reeds, wind and rain. They are not
baked into the music. Twelve effects distinguish interface touch, page handling,
object collection, combination, discovery, a rejected theory, travel, a door,
mechanical operation, a document stamp, chapter resolution and voice skipping.
Their material character comes from transient, resonant and filtered-noise
synthesis rather than reusing the same generic click.

**Subsequent interaction pass:** the descriptions above document the preserved
original synthesis set. The current runtime now substitutes edited CC0 material
Foley for routine handling and travel, with authored object/action mappings,
multiple takes, slight pitch variation and cooldowns. Music, ambience and the
original discovery/error/chapter cues retain their authored synthesis. See
`SFX_POLISH_REPORT.md` and `assets/audio/foley/manifest.json` for the new assets
and their separate provenance; they are not claimed as original field recordings.

## Files and reproducibility

* `tools/compose_score.py` contains the original score, arrangement and instrument
  authoring code. Seeds and event timings are deterministic.
* `assets/audio/score/events/` preserves every cue's full note-event score.
* `assets/audio/score/masters/`, `assets/audio/ambience/masters/` and
  `assets/audio/sfx/masters/` preserve 32 kHz, stereo, 16-bit PCM originals.
* Runtime `.ogg` files are separate derivatives. `.gdignore` files keep masters,
  event scores and previews out of resource imports and runtime packages; they
  remain in the source archive and Git history.
* `content/audio-score.json` maps the music, ambience and effect identifiers to
  local runtime resources, gains and all 36 location ambience choices.
* `assets/audio/score/manifest.json` records hashes of both originals and runtime
  files, durations, PCM format, peak/RMS measurements, section measurements,
  authoring method, event score and provenance.
* `assets/audio/score/previews/quiet-meridian-score-preview.wav` is a 60-second
  sequence of eight excerpts: title, chapters one through five, tension and
  resolution. It has no dialogue and is intended for direct audition.

Build tools are confined to `work/av-env/`. Reproduction uses Python, NumPy,
SciPy, SoundFile and ImageIO's bundled FFmpeg; exact installed versions in this
pass are NumPy 2.5.4, SciPy 1.18.1, SoundFile 0.14.0 and ImageIO-FFmpeg 0.8.1.
Exact build requirements are retained in `tools/score-requirements.txt`.
Neither the player nor the packaged game needs these tools. Regenerate with:

```
work/av-env/bin/python tools/compose_score.py
```

The exact source that produced the existing synthesis masters is retained at
`assets/audio/score/sources/compose_score_20261114.py`; the score manifest points
at that hash. The current generator additionally merges the separate Foley cue
manifest so regenerating music cannot silently restore the old effects.
Rebuild material Foley with `work/av-env/bin/python tools/build_foley.py`, then
refresh the runtime catalog with `work/av-env/bin/python tools/compose_score.py --only preview`.

The ordinary Python standard-library audit does not require that environment:

```
python3 tests/audit_score.py
```

## Mix intent and evidence

Music masters average approximately -23.6 dBFS RMS with peaks from -9.4 to
-7.5 dBFS. This leaves room for speech and transient effects. The configuration
adds -2 dB for normal music, -4 dB for tension and -8 dB for ambience before the
player's volume controls and dialogue ducking. Interface/page/skip effects are
quieter than physical discoveries and transitions. RMS values are not LUFS or
true-peak measurements; they must not be presented as broadcast loudness approval.

The audit passed **528 checks** over actual local audio and scores: intact hashes,
Ogg signatures, original PCM format, correct durations, conservative peaks,
non-silence, quiet boundaries, active distinct sections throughout each cue,
instrumental variety, valid event ranges, and complete runtime/location coverage.
It rejects the most obvious regressions of repeating a short signal or extending
it with silence. Those checks do not judge a performance's musical taste.

## Provenance and quality limits

Every note, rhythm, arrangement, soundscape and synthesis model was authored for
this project. There are no third-party sample libraries, soundfonts, recordings,
melodies, artist imitations, service-generated audio outputs or paid API calls in
this set. Build-tool packages are not distributed in the game; their licenses do
not turn the original rendered audio into sampled third-party music. Preserve the
source and manifest as the project's commercial-use provenance record.

This is a developed **synthesized chamber score**, not live orchestral recording,
human performance, or a claim of presentation parity with Grim Legends or
Enigmatis. The wind/reed/string models remain perceptibly synthetic. No blind
listener panel or final loudspeaker/headphone mix approval has been completed.
Final acceptance requires listening with actual character dialogue, checking
fatigue over long sessions, transition timing, cue placement, ducking recovery,
and avoiding melodramatic resolution cues for small discoveries. A later paid
performance/generation option would need its own approval and rights record.
