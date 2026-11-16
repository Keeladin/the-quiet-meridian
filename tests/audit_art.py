#!/usr/bin/env python3
"""Verify original artwork provenance, local copies and expression sheet identity."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "assets/asset-manifest.json").read_text())
checks = 0


def check(condition, message):
    global checks
    checks += 1
    if not condition:
        raise AssertionError(message)


ids = set()
for entry in manifest["assets"]:
    check(entry["id"] not in ids, "Duplicate artwork identity")
    ids.add(entry["id"])
    path = ROOT / entry["path"]
    check(path.is_file() and path.resolve().is_relative_to(ROOT), "Artwork must be retained locally")
    check(hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"], "Artwork hash mismatch: " + entry["id"])
    check((ROOT / entry["prompt_document"]).is_file(), "Missing original prompt: " + entry["id"])
    check(bool(entry.get("generator")) and bool(entry.get("review_status")), "Missing provenance or review status")

searches = json.loads((ROOT / "content/hidden-object-scenes.json").read_text())
observations = json.loads((ROOT / "tests/campaign_search_observations.json").read_text())
game = json.loads((ROOT / "content/game.json").read_text())
check(set(searches) == {room['id'] for room in game['locations']}, "Every campaign room has a search")
check(sum(len(scene['items']) for scene in searches.values()) == 507, "Complete 507-target campaign")
for room in game['locations']:
    scene = searches[room['id']]
    art = ROOT / scene['art'].removeprefix('res://')
    check(hashlib.sha256(art.read_bytes()).hexdigest() == observations[room['id']]['art_sha256'], "Observed target positions bind to the actual painting: " + room['id'])
    check(scene['reward_clues'] == [spot['id'] for spot in room['hotspots']], "Room reward preserves story evidence: " + room['id'])
    check(12 <= len(scene['items']) <= 20, "Substantive search list: " + room['id'])
    check(set(observations[room['id']]['interiors']) == {item['id'] for item in scene['items']}, "Every target visually observed: " + room['id'])
for chapter in game['chapters']:
    areas = {}
    for room in chapter['locations']:
        area = searches[room]['area']; areas[area] = areas.get(area, 0) + 1
    check(len(areas) == 3 and set(areas.values()) == {2}, "Three areas with two rooms: " + chapter['id'])

expressions = json.loads((ROOT / "assets/art/characters/manifest.json").read_text())
check(len(expressions["assets"]) == 7, "Seven active character sheets required")
source = ROOT / "assets/art/portraits/cast.png"
check(hashlib.sha256(source.read_bytes()).hexdigest() == expressions["source_atlas_sha256"], "Reference cast changed")
for entry in expressions["assets"]:
    check(entry in manifest["assets"], "Expression provenance differs from global manifest")
    check(entry["layout"]["columns"] * entry["layout"]["rows"] == len(entry["layout"]["frames"]) == 8,
          "Expression layout missing frames")
    check(entry["reference_images"] == ["assets/art/portraits/cast.png"] and entry["external_references"] == [],
          "Unexpected external character reference")
print(f"ART_AUDIT_OK: {checks} checks; local originals, hashes, prompts and seven expression sheets")
