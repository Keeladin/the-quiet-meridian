#!/usr/bin/env python3
"""Check owner approval, source provenance and all shipped opening recordings."""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'docs/audio-selection/opening-provenance.json').read_text())
config = json.loads((ROOT / 'content/hidden-object-audio.json').read_text())
requests = {r['id']: r for r in json.loads((ROOT / 'docs/audio-selection/requests.json').read_text())['requests']}
assert set(manifest['assets']) == set(config['cues']) and len(config['cues']) == 13
for cue, record in manifest['assets'].items():
    assert requests[cue]['selected_by'] == 'Jaco'
    assert record['source_file'] in requests[cue]['selected_files']
    path = ROOT / record['runtime_file']
    assert config['cues'][cue]['path'] == 'res://' + record['runtime_file']
    blob = path.read_bytes()
    assert hashlib.sha256(blob).hexdigest() == record['runtime_sha256'], cue
    header = blob.index(b'\x01vorbis')
    assert blob[header + 11] == 2 and struct.unpack_from('<I', blob, header + 12)[0] == 48000, cue
    assert record['runtime_peak_dbfs'] < 0 and record['runtime_seconds'] > .05
    # Recordings have different crest factors; check actual playback headroom
    # rather than imposing the same fader ceiling on every recording.
    assert record['runtime_peak_dbfs'] + config['cues'][cue]['volume_db'] <= -6
print('OPENING_AUDIO_AUDIT_OK: 13 owner-selected stereo 48 kHz resources with matching hashes')
