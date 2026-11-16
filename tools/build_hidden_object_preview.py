#!/usr/bin/env python3
"""Build and exercise the isolated opening-search review, without replacing the game."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'work/search-export-v3.1'
BUILD = ROOT / 'builds/hidden-object-preview'
GODOT = os.environ.get('GODOT_BIN', '/home/jaco/.local/bin/godot4')
RECORD = []


def run(label, argv, env):
    result = subprocess.run(argv, env=env, cwd=ROOT, capture_output=True, text=True, timeout=240)
    output = result.stdout + result.stderr
    (BUILD / (label + '.log')).write_text(output)
    passed = result.returncode == 0 and 'SCRIPT ERROR:' not in output and 'ERROR:' not in output
    if label.startswith('smoke-'):
        passed = passed and 'HIDDEN_SEARCH_SMOKE_OK' in output
    RECORD.append({'check': label, 'passed': passed})
    print(label, 'PASS' if passed else 'FAIL', flush=True)
    if not passed:
        raise RuntimeError(output[-4000:])


def main():
    STAGE.mkdir(parents=True, exist_ok=True)
    BUILD.mkdir(parents=True, exist_ok=True)
    files = [
        'scripts/hidden_object_state.gd', 'scripts/hidden_object_canvas.gd',
        'scripts/hidden_object_preview.gd', 'scripts/hidden_object_audio.gd', 'scenes/hidden_object_preview.tscn',
        'content/hidden-object-audio.json',
        'content/hidden-object-dispatch.json', 'assets/art/searches/dispatch-office-v2.png',
        'assets/art/meridian-icon.png', 'assets/fonts/body.ttf', 'assets/fonts/display.ttf',
        'assets/fonts/LICENSE.txt', 'assets/audio/score/ch1.ogg',
        'tools/prepare_opening_audio.py', 'tools/score-requirements.txt',
        'docs/audio-selection/requests.json', 'docs/audio-selection/opening-provenance.json',
        'docs/RESTORE_LICENSED_AUDIO.md',
        'docs/art-prompts/hidden-object-dispatch-v2.txt',
        'docs/art-prompts/hidden-object-dispatch-v2-provenance.json',
    ]
    audio = json.loads((ROOT / 'content/hidden-object-audio.json').read_text())
    files.extend(cue['path'].removeprefix('res://') for cue in audio['cues'].values())
    for name in files:
        target = STAGE / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, target)
    # Keep the standalone project specification and player guide in source control.
    for source, target in [('docs/hidden-object-preview-project.godot', 'project.godot'),
                           ('docs/HIDDEN_OBJECT_PREVIEW_README.txt', 'README.txt'),
                           ('export_presets.cfg', 'export_presets.cfg'),
                           ('docs/GODOT_NOTICES.txt', 'GODOT_NOTICES.txt'),
                           ('docs/LICENSES.md', 'LICENSES.md'),
                           ('docs/SCORE_DESIGN.md', 'SCORE_DESIGN.md')]:
        shutil.copy2(ROOT / source, STAGE / target)
    env = os.environ.copy()
    env.update(XDG_DATA_HOME=str(ROOT / 'work/engine-data'),
               XDG_CONFIG_HOME=str(ROOT / 'work/search-review/config'),
               XDG_CACHE_HOME=str(ROOT / 'work/search-review/cache'))
    templates = ROOT / 'work/engine-data/godot/export_templates'
    templates.parent.mkdir(parents=True, exist_ok=True)
    if not templates.exists():
        templates.symlink_to(Path.home() / '.local/share/godot/export_templates', target_is_directory=True)
    run('import', [GODOT, '--headless', '--editor', '--path', str(STAGE), '--import'], env)
    packages = []
    for platform, preset, executable in [('linux', 'Linux x86_64', 'dispatch-search.x86_64'),
                                         ('windows', 'Windows x86_64', 'dispatch-search.exe')]:
        folder = BUILD / ('dispatch-search-v3.1-' + platform)
        folder.mkdir(exist_ok=True)
        run('export-' + platform, [GODOT, '--headless', '--path', str(STAGE), '--export-release', preset, str(folder / executable)], env)
        for name in ['README.txt', 'GODOT_NOTICES.txt', 'LICENSES.md', 'SCORE_DESIGN.md']:
            shutil.copy2(STAGE / name, folder / name)
        shutil.copy2(STAGE / 'assets/fonts/LICENSE.txt', folder / 'FONT_LICENSE.txt')
        archive = BUILD / ('hidden-object-preview-v3.1-' + platform + '.zip')
        with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as z:
            for item in sorted(folder.iterdir()):
                z.write(item, folder.name + '/' + item.name)
        with tempfile.TemporaryDirectory(dir=ROOT / 'work', prefix='search-package-') as temporary:
            with zipfile.ZipFile(archive) as z: z.extractall(temporary)
            binary = Path(temporary) / folder.name / executable
            binary.chmod(0o755)
            probe_env = env.copy()
            probe_env['XDG_DATA_HOME'] = str(ROOT / 'work/search-package-test/user-data')
            launcher = []
            if platform == 'windows':
                if not shutil.which('wine'): raise RuntimeError('Wine unavailable for the Windows package check')
                launcher = [shutil.which('wine')]
                probe_env.update(WINEPREFIX=str(ROOT / 'work/wine'), WINEARCH='win64', WINEDEBUG='-all', WINEDLLOVERRIDES='winemenubuilder.exe=d')
            run('smoke-' + platform + ('-wine' if launcher else ''), launcher + [str(binary), '--headless', '--', '--search-smoke-test'], probe_env)
        packages.append({'file': archive.name, 'bytes': archive.stat().st_size, 'sha256': hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest()})
    source = BUILD / 'hidden-object-preview-v3.1-source.zip'
    with zipfile.ZipFile(source, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        for item in sorted(STAGE.rglob('*')):
            rel = item.relative_to(STAGE)
            if item.is_file() and not any(part in {'.godot', 'builds'} for part in rel.parts) and not item.name.endswith('.import') and not str(rel).startswith('assets/audio/licensed-opening/'):
                z.write(item, 'hidden-object-preview-source/' + str(rel))
    with zipfile.ZipFile(source) as z:
        if any('/assets/audio/licensed-opening/' in name for name in z.namelist()):
            raise RuntimeError('Reusable purchased effects must not be included in the shareable source archive')
    RECORD.append({'check': 'source-omits-licensed-recordings', 'passed': True})
    packages.append({'file': source.name, 'bytes': source.stat().st_size, 'sha256': hashlib.file_digest(source.open('rb'), 'sha256').hexdigest()})
    (BUILD / 'verification.json').write_text(json.dumps({'scope': 'One opening hidden-object review with 13 owner-selected sound cues; campaign conversion pending', 'checks': RECORD, 'packages': packages, 'native_windows': 'not tested', 'source_archive': 'Licensed audio omitted; restore from the owner library as described in docs/RESTORE_LICENSED_AUDIO.md', 'visual_review': 'Native Linux screenshots at 960x600, 1280x800 and 1920x1080', 'mix_acceptance': 'Prepared mix awaits owner listening review'}, indent=2) + '\n')


if __name__ == '__main__':
    main()
