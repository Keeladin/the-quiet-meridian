# Restoring the purchased campaign sounds

The playable game includes selected effects and 36 room atmosphere mixes
embedded in its game data. These use 33 purchased masters, including the
thirteen opening choices. Players need no separate library.

Shareable source archives omit `assets/audio/licensed-opening/` and
`assets/audio/licensed-campaign/`, including the
prepared Ogg files. These recordings belong to Gamemaster Audio and are not
relicensed as reusable source assets. The owner's working project retains the
prepared files; the purchased originals remain in Downloads. The ordinary
source archive is therefore not a complete private audio backup.

To rebuild this opening scene from an extracted source archive, use a licensed
copy of **Gamemaster Audio Pro Sound Collection v1.3, 24-bit / 96 kHz**. The
owner's exact choices and source hashes are recorded in
`docs/audio-selection/requests.json` and `opening-provenance.json` beside it.

Create a project-local Python environment, install the dependencies listed in
`tools/score-requirements.txt`, and run:

```sh
python tools/prepare_opening_audio.py --library-root /path/to/extracted/24bit-96k-collection
python tools/prepare_campaign_audio.py --library-root /path/to/extracted/24bit-96k-collection
```

This checks that each master matches the approved source hash, then recreates
the stereo 48 kHz game recordings. Godot imports them on the next project open.
Without restoring the recordings, the opening preview cannot pass its audio
checks. Do not substitute a differently sampled edition silently. The script
does not download sounds, contact an API or alter the original library.

Keep the selected effects within the game. Do not redistribute them as a
standalone sound collection or include them in a public source repository.
Terms: https://gamemasteraudio.com/wp-content/uploads/2020/01/Gamemaster-Audio-End-User-License-Agreement.pdf
