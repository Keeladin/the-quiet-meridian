#!/usr/bin/env python3
"""Capture real offline game actions and mix; requires project-local AV tools."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'builds/previews/sfx-game'
WORK = ROOT / 'work/sfx-preview'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    for key, folder in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        path = WORK / folder
        path.mkdir(exist_ok=True)
        env[key] = str(path)
    avi, mp4 = WORK / 'native.avi', OUT / 'quiet-meridian-interactions.mp4'
    command = [env.get('GODOT_BIN', '/home/jaco/.local/bin/godot4'), '--path', str(ROOT),
               '--resolution', '1280x800', '--windowed', '--disable-vsync', '--fixed-fps', '24',
               '--write-movie', str(avi), '--script', 'res://tools/capture_sfx_preview.gd']
    result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, timeout=240)
    log = result.stdout + result.stderr
    (OUT / 'capture.log').write_text(log)
    if result.returncode or 'SFX_PREVIEW_CAPTURE_OK' not in log or 'ERROR:' in log:
        raise RuntimeError(log[-5000:])
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    encoding = [ffmpeg, '-y', '-i', str(avi), '-c:v', 'libx264', '-preset', 'medium', '-crf', '19',
                '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', str(mp4)]
    result = subprocess.run(encoding, capture_output=True, text=True, timeout=180)
    (OUT / 'encode.log').write_text(result.stderr)
    result.check_returncode()
    result = subprocess.run([ffmpeg, '-i', str(mp4), '-af', 'volumedetect', '-f', 'null', '-'],
                            capture_output=True, text=True, timeout=60)
    (OUT / 'measurement.log').write_text(result.stderr)
    result.check_returncode()
    mean = float(re.search(r'mean_volume: ([-.\d]+) dB', result.stderr)[1])
    peak = float(re.search(r'max_volume: ([-.\d]+) dB', result.stderr)[1])
    assert -65 < mean < -5 and peak < 0, 'Silent or clipped preview'
    path = OUT / 'capture-manifest.json'
    report = json.loads(path.read_text())
    assert len(report['events']) == 6 and all(e['sound'].get('path') for e in report['events'])
    report.update({'sha256': hashlib.sha256(mp4.read_bytes()).hexdigest(), 'bytes': mp4.stat().st_size,
                   'signal': {'mean_dbfs': mean, 'peak_dbfs': peak, 'listening_acceptance': False},
                   'source_hashes': {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in
                       ('scripts/main.gd', 'scripts/audio_director.gd', 'content/audio-score.json',
                        'content/interaction-audio.json', 'tools/capture_sfx_preview.gd', 'tools/render_sfx_preview.py')},
                   'commands': {'capture': command, 'encode': encoding}})
    path.write_text(json.dumps(report, indent=2) + '\n')
    print('SFX_PREVIEW_RENDER_OK:', mp4.relative_to(ROOT))


if __name__ == '__main__':
    main()
