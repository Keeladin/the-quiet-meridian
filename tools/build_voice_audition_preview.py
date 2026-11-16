#!/usr/bin/env python3
"""Package unapproved local auditions for listening; no API or runtime changes."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import wave
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "builds/previews/voice"


def natural_preview():
    result = json.loads((ROOT / "docs/VOICE_NATURAL_RESULT.json").read_text())
    plan = json.loads((ROOT / "content/voice-audition-natural.json").read_text())
    sample = next(s for s in plan["samples"] if s["speaker"] == "mara")
    folder = ROOT / "builds/previews/voice-natural"
    folder.mkdir(parents=True, exist_ok=True)
    source = ROOT / result["path"]
    assert source.resolve().is_relative_to(ROOT / "assets/audio/auditions")
    assert hashlib.sha256(source.read_bytes()).hexdigest() == result["sha256"]
    assert result["provider_transcript_exact"] and result["signal_passed"] and not result["accepted_for_game"]
    shutil.copy2(source, folder / "mara-quartz-natural.wav")
    baseline = ROOT / result["baseline_path"]
    first = json.loads((baseline.parent / "result.json").read_text())
    assert hashlib.sha256(baseline.read_bytes()).hexdigest() == first["wav_sha256"]
    shutil.copy2(baseline, folder / "mara-quartz-first.wav")
    text = html.escape(sample["script"])
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mara — conversational performance comparison</title>
<style>body{{font:18px/1.65 system-ui;background:#111e24;color:#eee5cf;max-width:900px;margin:auto;padding:30px 20px}}
h1,h2{{font-family:Georgia,serif}}article{{background:#192a30;border:1px solid #40575c;padding:22px;margin:24px 0;border-radius:8px}}
audio{{width:100%}}a{{color:#e4c88d}}.status{{color:#d8b574}}summary{{cursor:pointer}}blockquote{{font-family:Georgia,serif;margin:20px 0}}
*:focus-visible{{outline:3px solid white;outline-offset:4px}}</style>
<p class="status">THE QUIET MERIDIAN · AI-GENERATED AUDITION · NOT ACCEPTED FOR PRODUCTION</p>
<h1>Mara: a more personal answer</h1>
<p>Same Quartz voice and exact 59-word script. The revised direction puts Mara face to face with Iona,
moving from an excuse toward acknowledging the hurt. It permits natural breaths and varied pauses,
with no fixed reading tempo. Please judge whether the new delivery feels like a person speaking.</p>
<article><h2>Revised conversational direction</h2><audio controls preload="metadata" src="mara-quartz-natural.wav"></audio>
<a href="mara-quartz-natural.wav" download>Original revised WAV</a>
<p>Provider transcript and independent acoustic transcription match the source words. Acting quality still needs listening approval.</p></article>
<article><h2>First direction — comparison</h2><audio controls preload="metadata" src="mara-quartz-first.wav"></audio>
<a href="mara-quartz-first.wav" download>Original first WAV</a><p>The user found this delivery too much like book narration.</p></article>
<details open><summary>Exact script — unchanged between takes</summary><blockquote>{text}</blockquote></details>
<p>Both players use the unedited masters, including their silent tails. No gain, cuts or word edits hide performance differences.
All audio is local; no API key or connection is needed. Total computed API cost across both rounds: about US$0.1242 of the US$0.25 cap.
All current take authorizations have been used.</p>
<script>document.querySelectorAll('audio').forEach(a=>a.addEventListener('play',()=>document.querySelectorAll('audio').forEach(b=>{{if(a!==b)b.pause();}})));</script></html>'''
    (folder / "index.html").write_text(page)
    shutil.copy2(ROOT / "docs/VOICE_NATURAL_RESULT.json", folder / "review-manifest.json")
    archive_path = ROOT / "builds/quiet-meridian-natural-voice-audition.zip"
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for name in ("index.html", "review-manifest.json", "mara-quartz-natural.wav", "mara-quartz-first.wav"):
            archive.write(folder / name, "quiet-meridian-natural-voice-audition/" + name)
    with zipfile.ZipFile(archive_path) as archive:
        assert archive.testzip() is None
    print("NATURAL_VOICE_PREVIEW_OK: hash-verified full masters; local A/B player; no performance acceptance")


def main():
    results = json.loads((ROOT / "docs/VOICE_AUDITION_RESULTS.json").read_text())
    plan = json.loads((ROOT / "content/voice-audition.json").read_text())
    scripts = {s["line_id"]: s for s in plan["samples"]}
    OUT.mkdir(parents=True, exist_ok=True)
    cards = []
    files = []
    for sample in results["samples"]:
        source = ROOT / sample["path"]
        assert source.resolve().is_relative_to(ROOT / "assets/audio/auditions")
        assert hashlib.sha256(source.read_bytes()).hexdigest() == sample["sha256"]
        assert sample["provider_transcript_exact"] and sample["signal_passed"]
        assert not sample["accepted_for_game"]
        with wave.open(str(source)) as audio:
            assert (audio.getnchannels(), audio.getsampwidth(), audio.getframerate()) == (1, 2, 24000)
            assert abs(audio.getnframes() / 24000 - sample["duration_seconds"]) < .001
        name = sample["speaker"].lower() + "-" + sample["voice"].lower() + "-original.wav"
        shutil.copy2(source, OUT / name)
        files.append(name)
        script = scripts[sample["line_id"]]
        cards.append(f'''<article>
<p class="status">AI-generated first audition · Natural delivery revision requested</p>
<h2>{html.escape(sample['speaker'])} <small>/{html.escape(sample['voice'])}</small></h2>
<p>{html.escape(script['direction'])}</p>
<audio controls preload="metadata" src="{name}"></audio>
<div class="buttons"><button onclick="replay(this)">Replay from start</button>
<button onclick="stop(this)">Stop</button><a href="{name}" download>Original WAV</a></div>
<p class="review">{html.escape(sample['review_note'])}</p>
<details open><summary>Exact script · {script['words']} words</summary><p>{html.escape(script['script'])}</p></details>
</article>''')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>The Quiet Meridian — voice auditions</title>
<style>
:root{color-scheme:dark;font-family:system-ui,sans-serif;color:#eee5cf;background:#111e24}
body{max-width:1100px;margin:auto;padding:32px 20px;line-height:1.6}
h1,h2{font-family:Georgia,serif;line-height:1.15}h1{font-size:2.5rem}h2{font-size:1.8rem}
small{font:400 1rem system-ui;color:#b9c7c6}.status{color:#d8b574;font-size:.83rem}
main{display:grid;gap:24px}article{padding:24px;background:#192a30;border:1px solid #40575c;border-radius:8px}
audio{display:block;width:100%;margin:20px 0}.buttons{display:flex;gap:12px;flex-wrap:wrap;align-items:center}
button{background:#d8b574;color:#111e24;border:0;padding:10px 16px;border-radius:4px;font:inherit;cursor:pointer}
a{color:#e4c88d}.review{border-left:3px solid #d8b574;padding-left:14px}
summary{cursor:pointer}details p{font-family:Georgia,serif;font-size:1.1rem}
*:focus-visible{outline:3px solid #fff;outline-offset:4px}footer{margin-top:28px;color:#b9c7c6}
</style><header><p class="status">THE QUIET MERIDIAN · DEVELOPMENT REVIEW</p>
<h1>The first three voice auditions</h1>
<p>Original GPT Live recordings for Iona, Rowan and Mara. These are auditions, not accepted game assets.
The user requested a more natural conversational delivery after hearing these first takes.
The original recordings retain their silent tails. No words have been edited, replaced or concealed.</p>
<p>Use the players to listen and adjust voice volume. Please assess the named pronunciation holds,
character identity, emotion and pacing against the complete script.</p></header><main>'''
    page += "\n".join(cards)
    page += '''</main><footer>All audio plays locally. No account, key or internet connection is required.
First-round API usage: 117 reported seconds, computed US$0.0975 against the approved US$0.25 cap.
The separately approved natural Mara revision is tracked independently and carries this spending forward.</footer><script>
function replay(button){const audio=button.closest('article').querySelector('audio');audio.currentTime=0;audio.play();}
function stop(button){const audio=button.closest('article').querySelector('audio');audio.pause();audio.currentTime=0;}
document.querySelectorAll('audio').forEach(audio=>audio.addEventListener('play',()=>{
document.querySelectorAll('audio').forEach(other=>{if(other!==audio)other.pause();});}));
</script></html>'''
    (OUT / "index.html").write_text(page)
    shutil.copy2(ROOT / "docs/VOICE_AUDITION_RESULTS.json", OUT / "review-manifest.json")
    files.extend(["index.html", "review-manifest.json"])
    archive_path = ROOT / "builds/quiet-meridian-voice-auditions.zip"
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for name in files:
            archive.write(OUT / name, "quiet-meridian-voice-auditions/" + name)
    with zipfile.ZipFile(archive_path) as archive:
        assert archive.testzip() is None
    print("VOICE_AUDITION_PREVIEW_OK: three hash-verified original WAVs; offline player and archive; no runtime promotion")
    natural_preview()


if __name__ == "__main__":
    main()
