# Independent offline voice transcription — provenance and limits

Prepared 14 November 2026 for development review of The Quiet Meridian's saved
voice auditions. **No paid transcription API, authenticated inference service,
Runway call, system package installation or Atlas/GCC change was used.** This is
an independent transcription aid; it does not approve acting or prove that every
spoken word matches the script.

## Toolchain and placement

An initial read-only check found no `faster_whisper`, `whisper`, `ctranslate2`,
`onnxruntime` or `vosk` module in the active system Python, and no Whisper or FFmpeg
CLI on PATH. A separate environment was created at `work/voice-asr-env`.
Python version: **3.14.4**. The ASR model and public model-card/
license files are only under `work/voice-asr-model`. Both directories are ignored
and excluded from game/source distributions. No model or ASR dependency is bundled
into the Windows/Linux game; all released dialogue is ordinary local audio.

The recognizer is faster-whisper **1.2.1**, using CPU `int8` execution with four
threads by default. The maintained project documents CPU int8 and PyAV audio
decoding without requiring system FFmpeg.
[Official faster-whisper documentation](https://github.com/SYSTRAN/faster-whisper)

PyAV **16.0.1** is deliberately pinned. The first environment resolved PyAV 19.0.2,
which rejected faster-whisper 1.2.1's `metadata_errors` decoder argument in an actual
smoke test. Replacing only that project-local wheel with 16.0.1 fixed decoding.
The failure and successful rerun are retained in `work/voice-asr-env/` logs. The
installed environment's exact package set is recorded below and in
`work/voice-asr-env/pip-freeze.txt`.

```text
anyio==4.16.0
av==16.0.1
click==8.5.1
ctranslate2==4.9.0
faster-whisper==1.2.1
filelock==4.2.10
flatbuffers==25.12.19
fsspec==2026.9.0
h11==0.16.0
hf-xet==1.8.0
httpcore2==2.16.0
httpx2==2.16.0
huggingface_hub==2.4.0
idna==3.20
numpy==2.5.4
onnxruntime==1.32.0
packaging==26.3
protobuf==7.36.2
PyYAML==6.0.3
tokenizers==0.23.3
tqdm==4.70.1
truststore==0.10.5
typing_extensions==4.16.0
```

A fresh project-local installation can use:

```sh
python3 -m venv work/voice-asr-env
work/voice-asr-env/bin/python -m pip --isolated --disable-pip-version-check \
  --cache-dir "$PWD/work/voice-asr-env/.pip-cache" install \
  --index-url https://pypi.org/simple faster-whisper==1.2.1 av==16.0.1
```

## Model and licensing record

The downloaded model is **Systran/faster-whisper-small.en**, a CTranslate2 conversion
of `openai/whisper-small.en`, identified as MIT licensed by its publisher. The
conversion is distributed as FP16 weights and is loaded as CPU int8 locally.
[Publisher's model card](https://huggingface.co/Systran/faster-whisper-small.en)

Pinned model revision: `d1d751a5f8271d482d14ca55d9e2deeebbae577f`.
Download UTC: `2026-11-14T11:13:08.407304+00:00`.
The download used an unauthenticated public Hugging Face snapshot with
`token=False`; it did not invoke an inference endpoint. Full local records are
in `work/voice-asr-model/download-manifest.json`.

Original Whisper's MIT notice and faster-whisper's MIT notice are retained as
`LICENSE.openai-whisper` and `LICENSE.faster-whisper` beside the local model.
[OpenAI Whisper license](https://github.com/openai/whisper/blob/main/LICENSE),
[faster-whisper 1.2.1 license](https://github.com/SYSTRAN/faster-whisper/blob/v1.2.1/LICENSE)

| Retained file | Bytes | SHA-256 |
| --- | ---: | --- |
| `README.md` | 1,330 | `c87ff776137c2ecb30ee3b324b4cf5f38abf9423464613641ee45430bf580851` |
| `config.json` | 2,657 | `666a9605530ac1f61fa8177f3702b4dacec9966749e42610839fcc32661d5fae` |
| `model.bin` | 483,545,366 | `62b2a45b05ee59acb4a5341b33ee35e041395d378d418a18acfe4c9e768ee37a` |
| `tokenizer.json` | 2,128,466 | `929c5252409436dce1b38a75d1abbcb5e132d170d8e324e4e04ed915fa2d22df` |
| `vocabulary.txt` | 422,309 | `ff77588746d3a2595d32ab5b69ffd7b95ce2441ac57533cb66fc3eb575a115cf` |
| `LICENSE.openai-whisper` | 1,063 | `b5d65a59060e68c4ff940e1eddfa6f94b2d68fdf58ed7f4dd57721c997e35e9d` |
| `LICENSE.faster-whisper` | 1,064 | `af6798135e729f8aa6c853936d037dfdea449734d26b8ea6a89805fca758c0d5` |

To reproduce the public download, use `huggingface_hub.snapshot_download` with
repository `Systran/faster-whisper-small.en`, the pinned revision above,
`local_dir=work/voice-asr-model`, cache directory inside that same model folder,
`token=False`, and the five model files listed above (README, config, model,
tokenizer and vocabulary). Retain the two linked license notices and regenerate
the hash manifest. Do not point the running game at this toolchain.

## Operation and evidence boundary

`tools/transcribe_voice_candidate.py` first verifies the local model hashes and
reads the saved candidate waveform. ASR receives **no expected script, names,
phonetic hints, initial prompt, prefix or hotwords**. Only after the acoustic
transcription completes is its text compared against the source using
`tools/voice_fidelity.py`. Input audio must remain inside this repository; the
report must remain under `work/`. Audio and runtime manifests are never changed.

The tool explicitly sets Hugging Face/Transformers offline modes and disables
implicit tokens/telemetry before importing the ASR library. `WhisperModel` uses
a local path and `local_files_only=True`. The model, CPU inference and PyAV decoder
run locally. No network is required after provisioning.

```sh
work/voice-asr-env/bin/python tools/transcribe_voice_candidate.py \
  --audio work/voice-auditions/iona.wav --script-id ch1_closing \
  --output work/voice-asr-reports/iona.json
```

Replace the example audio path with the actual sealed candidate path. JSON
reports include the audio hash, model revision/hashes, installed versions,
transcript and segment/word timestamps, uncorrected source-word differences,
uncertainty notes and `accepted_for_game: false`. Exit 0 means the independent
transcript matches after narrow formatting normalization but is still
`pending_listening`. Exit 2 means `asr_mismatch_hold`; exit 1 means a tool/capture
error. No exit status promotes a recording into the game.

## Actual local validation and remaining review

The decoder/model loaded and ran on a one-second, all-zero 24 kHz mono WAV created
specifically for testing. The independent ASR emitted **“You”**
from silence. Its comparison against the Iona script correctly returned
`asr_mismatch_hold`, exit 2, with `accepted_for_game: false`. This concrete
hallucination illustrates why an ASR transcript is not a substitute for acoustic
and human listening review. The separate PCM integrity helper rejects silence;
the probe is not game dialogue or evidence of speech quality. Its report is
`work/voice-asr-reports/silence-probe.json`.

The first three saved auditions were checked on 14 November 2026 using
the same unprompted local recognizer. Their evidence is retained under
`assets/audio/auditions/2026-11-14/`, whose parent `.gdignore` excludes these
review candidates from Godot resources. No candidate has been accepted for
the game, and no human listening approval is claimed here. A later revised Mara
take and the user's delivery feedback are recorded separately below.

### Mara: matching speech transcript and a demonstrated silence hallucination

The full 31.62-second master for `mara_refuge_r0`, attempt
`56e17e6bda42440c93a80b5508e108e5`, produced the 59 source words followed by an
extra ASR word, **“You”**, at 30.2–31.6 seconds. The uncorrected full-master report
remains `asr_mismatch_hold`. Direct examination of the PCM samples establishes
that every sample in that extra-word interval is exactly zero; the apparent word
is therefore a recognizer hallucination, not recorded speech.

A separately retained derivative is exactly the original PCM prefix through
every nonzero sample, followed by the original one-second zero tail. Independent
byte checks confirmed that it modifies or adds no sample and removes only
170,542 exact-zero samples. The last nonzero sample is index 564,337 at 24 kHz;
the derivative is 588,338 samples (24.514083 seconds). No gain, fade, resynthesis
or spoken-content edit was made. Its fresh unprompted ASR pass matches all 59
source words and is **`pending_listening`**, not approved dialogue.

| Evidence | SHA-256 |
| --- | --- |
| Original Mara WAV | `879fd147f49f7903c1d4c6729929113f9296d4ed925dddb51d59f7505f6929ac` |
| PCM-prefix derivative | `201c7bbb92344c084ff400ab5eb92ffcc877d37ab3e6ad33547a79c78dce4689` |

The original master remains unchanged. Its archive subdirectory
`mara_refuge_r0-56e17e6bda42440c93a80b5508e108e5/review/` contains
`mara-first.json`, `mara-bounded.json`, `mara-audio-bounded.wav`,
`mara-tail-analysis.json` and the separate byte-validation record
`mara-independent-review.json`. The waveform evidence resolves the extra ASR
word only; it does not establish acting quality, pronunciation or the acoustic
correctness of every source word.

### Iona: unresolved opening-name recognition

The full replacement master for `ch1_closing`, attempt
`09ffe6a4812c46f8a6ff2e555054e82c`, has SHA-256
`b5b80f218855a07a02aea7c0fe8e75502eba7271a681e51169c6b98405379fce`.
Its independent transcript recognizes **“Mary”** where the source says
**“Mara”**; the remaining 39 words match. ASR places the first word at
0.84–1.48 seconds with a reported probability of about 0.326. These are model
observations, not a verified pronunciation diagnosis. No expected name or
phonetic hint was provided to the recognizer, and its result has not been
silently corrected.

This candidate remains **`asr_mismatch_hold`** pending complete listening against
the source, with explicit attention to the opening name. The complete attempt
and original ASR JSON/log are archived in
`ch1_closing-09ffe6a4812c46f8a6ff2e555054e82c/`; ASR evidence is in its `review/`
subdirectory. The candidate waveform was not edited.

### Rowan: unresolved name and a second silence hallucination

The full 33.52-second replacement master for `rowan_kitchen_r2`, attempt
`b50598c8dbac4cd18252aab854656a25`, has SHA-256
`687e709f6d6343134cdf094e6cf6804169323154a0ab4bf80c8b47cd92a9eee7`.
The recognizer renders source **“Tomas”** as **“Thomas”** at 4.66–5.00 seconds,
and adds **“You”** at 30.42–31.82 seconds after the source's 68 words.
The name observation has a reported ASR probability of about 0.995; confidence
does not resolve whether the difference reflects pronunciation or ASR spelling.
The name remains an explicit listening hold and has not been normalized away.

Every PCM sample in the final extra-word interval is exactly zero. The final
nonzero sample is index 605,759 (25.239958 seconds), followed by 8.28 seconds of
exact zeros. This establishes that the final extra word is another ASR silence
hallucination. The full master and uncorrected report are preserved, and its
overall status remains **`asr_mismatch_hold`**. The complete attempt, raw ASR
JSON/log and `review/rowan-tail-analysis.json` are archived under
`rowan_kitchen_r2-b50598c8dbac4cd18252aab854656a25/`. This review did not edit
the waveform or claim listening acceptance.

### Revised Mara: conversational direction, awaiting listening comparison

After hearing the original auditions, the user described their delivery as too
book-like and requested a more natural conversational performance. One revised
Mara take was explicitly authorized, with a US$0.05 limit within the cumulative
US$0.25 cap. That feedback is a request for improvement, not approval of the
revised performance. This ASR review made no chargeable calls.

The revised `mara_refuge_r0` attempt is
`b51c12f2ecec4bc98597099940f62a9b`. The full 31.90-second saved master again
produced all 59 source words followed by an extra ASR **“You”**. Its reported
30.0–30.8-second interval contains only exact-zero PCM samples. The uncorrected
full-master report remains `asr_mismatch_hold`; the additional word is a
demonstrated silence hallucination.

For an independent follow-up pass, a separately retained derivative keeps the
original PCM prefix through its last nonzero sample (index 574,435), followed
by one second of the original zero tail. Byte comparison confirms that no
sample was added or modified and only 167,164 exact-zero samples were removed.
The derivative is 598,436 samples (24.934833 seconds) at 24 kHz. Its fresh,
unprompted ASR pass matches all 59 source words and remains
**`pending_listening`**. Punctuation differences do not change the word match.

| Revised Mara evidence | SHA-256 |
| --- | --- |
| Original master | `c30a8c54c8a5e4fab886b4c4c21d97a49da6096031df6f017f3baad7ed37aaf9` |
| PCM-prefix derivative | `c33beb2f86b87504c804dbfd1e0273fb6786c58e81b33a754a9401a923c3e023` |

The complete attempt is archived under
`assets/audio/auditions/2026-11-14-natural/mara_refuge_r0-b51c12f2ecec4bc98597099940f62a9b/`.
Its `review/` folder retains the original and bounded ASR JSON/log files,
`mara-natural-audio-bounded.wav`, and `mara-natural-tail-analysis.json`.
The source master remains unchanged. No naturalness, acting-quality or human
listening acceptance is inferred from the matching transcript, and this take
has not been promoted into the runtime voice manifest.

Whisper may misrecognize fictional names, contractions, numbers or quiet endings.
A mismatch requires a hold and documented listening decision; an exact
transcript still requires listening to every word, the beginning and the fully
released ending. Timings are ASR observations, not approved subtitles. User
acceptance of the three auditions remains separate from tool checks and is
required before the full 98-clip batch. These local ASR checks made no paid API
calls and did not promote any candidate into the runtime voice manifest.
