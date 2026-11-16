#!/usr/bin/env python3
"""Validate authored content and solve its dependency graph without the UI.

This checks structural reachability, not whether a human can infer the answers.
The Godot state tests exercise the actual state API independently.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
TYPES = {"code", "choice", "deduction", "order", "sequence", "routing", "hidden", "assembly"}


def audit(data: dict, allow_missing_art: bool = False) -> dict:
    errors: list[str] = []
    warnings: list[str] = []

    def check(condition, message):
        if not condition:
            errors.append(message)

    def indexed(name):
        rows = data.get(name, [])
        check(isinstance(rows, list), f"{name}: expected array")
        if not isinstance(rows, list):
            return {}
        values = {}
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("id"), str):
                errors.append(f"{name}: entry without string id")
                continue
            check(row["id"] not in values, f"{name}: duplicate id {row['id']}")
            values[row["id"]] = row
        return values

    chapters = indexed("chapters")
    locations = indexed("locations")
    puzzles = indexed("puzzles")
    items = indexed("items")
    recipes = indexed("recipes")
    characters = indexed("characters")
    hotspots = {}
    hotspot_locations = {}
    art_paths = set()
    art_hashes = set()
    chapter_order = list(chapters)
    check(len(chapters) == 6, "Production target requires six authored chapters")
    check(len(locations) >= 36, "Production target requires at least 36 locations")
    check(len(puzzles) >= 60, "Production target requires at least 60 challenges")
    for field in ("title", "subtitle", "intro", "ending"):
        check(isinstance(data.get(field), str) and bool(data.get(field, "").strip()), f"Missing {field}")

    for lid, location in locations.items():
        check(location.get("chapter") in chapters, f"{lid}: unknown chapter")
        for field in ("title", "description", "art"):
            check(isinstance(location.get(field), str) and bool(location.get(field, "").strip()), f"{lid}: missing {field}")
        art = location.get("art", "")
        art_paths.add(art)
        check(art.startswith("res://assets/"), f"{lid}: art must be a packaged project asset")
        if art.startswith("res://") and not (ROOT / art.removeprefix("res://")).is_file():
            message = f"{lid}: missing artwork {art}"
            (warnings if allow_missing_art else errors).append(message)
        elif art.startswith("res://"):
            art_hashes.add(hashlib.sha256((ROOT / art.removeprefix("res://")).read_bytes()).hexdigest())
        for hotspot in location.get("hotspots", []):
            hid = hotspot.get("id")
            check(isinstance(hid, str) and hid not in hotspots, f"{lid}: missing or duplicate hotspot {hid}")
            hotspots[hid] = hotspot
            hotspot_locations[hid] = lid
            for field in ("label", "text"):
                check(isinstance(hotspot.get(field), str) and bool(hotspot.get(field, "").strip()), f"{hid}: missing {field}")
            for axis in ("x", "y"):
                value = hotspot.get(axis)
                check(isinstance(value, (int, float)) and not isinstance(value, bool) and 0 <= value <= 1, f"{hid}: invalid {axis}")
            check(not hotspot.get("item") or hotspot["item"] in items, f"{hid}: unknown item")

    assigned = []
    for cid, chapter in chapters.items():
        for field in ("title", "summary", "intro", "closing"):
            check(bool(chapter.get(field)), f"{cid}: missing {field}")
        check(chapter.get("final_puzzle") in puzzles, f"{cid}: missing final puzzle")
        for lid in chapter.get("locations", []):
            assigned.append(lid)
            check(lid in locations and locations[lid].get("chapter") == cid, f"{cid}: incorrect location {lid}")
        check(len(chapter.get("locations", [])) == 6, f"{cid}: expected six locations")
        final = puzzles.get(chapter.get("final_puzzle"), {})
        check(final.get("chapter") == cid, f"{cid}: final puzzle belongs to another chapter")
    check(Counter(assigned) == Counter(locations.keys()), "Chapter location lists must cover each location exactly once")

    for pid, puzzle in puzzles.items():
        cid = puzzle.get("chapter")
        lid = puzzle.get("location")
        check(cid in chapters, f"{pid}: unknown chapter")
        check(lid in locations and locations[lid].get("chapter") == cid, f"{pid}: location outside chapter")
        kind = puzzle.get("type")
        check(kind in TYPES, f"{pid}: unsupported puzzle type {kind}")
        for field in ("title", "prompt", "details", "success", "rationale"):
            check(isinstance(puzzle.get(field), str) and bool(puzzle.get(field, "").strip()), f"{pid}: missing {field}")
        check(len(puzzle.get("hints", [])) == 3 and all(isinstance(h, str) and h.strip() for h in puzzle.get("hints", [])), f"{pid}: requires three real hints")
        for dependency in puzzle.get("requires", []):
            check(dependency in puzzles and dependency != pid, f"{pid}: invalid prerequisite {dependency}")
        for clue in puzzle.get("clues", []):
            check(clue in hotspots, f"{pid}: unknown clue {clue}")
        check(bool(puzzle.get("clues")), f"{pid}: needs discoverable evidence")
        for item in puzzle.get("items", []) + puzzle.get("rewards", []):
            check(item in items, f"{pid}: unknown item {item}")
        options = puzzle.get("options", [])
        answer = puzzle.get("solution")
        if kind in {"choice", "deduction"}:
            check(answer in options and len(options) >= 2, f"{pid}: invalid choice answer/options")
        elif kind in {"order", "sequence", "routing"}:
            check(isinstance(answer, list) and bool(answer) and all(part in options for part in answer), f"{pid}: invalid sequence answer/options")
            if kind == "order" and isinstance(answer, list):
                check(Counter(answer) == Counter(options), f"{pid}: ordering answer must use every option once")
        elif kind == "hidden":
            check(answer == "found", f"{pid}: hidden answer must be found")
        elif kind == "assembly":
            check(answer == "assembled" and bool(puzzle.get("items")), f"{pid}: assembly needs required item and assembled answer")
        elif kind == "code":
            check(isinstance(answer, str) and bool(answer.strip()), f"{pid}: missing code answer")

    for rid, recipe in recipes.items():
        ingredients = recipe.get("ingredients", [])
        check(len(ingredients) == 2 and len(set(ingredients)) == 2 and all(i in items for i in ingredients), f"{rid}: recipe requires two different known ingredients")
        check(recipe.get("result") in items and recipe.get("result") not in ingredients, f"{rid}: invalid recipe result")
        check(bool(recipe.get("text")), f"{rid}: missing feedback")
    for iid, item in items.items():
        check(bool(item.get("name")) and bool(item.get("description")), f"{iid}: missing inventory inspection text")

    # Traverse chapter gates, obtainable evidence, recipes and dependencies together.
    solved, evidence, inventory, accessible = set(), set(), set(), set()
    route = []
    changed = True
    while changed:
        changed = False
        for index, cid in enumerate(chapter_order):
            if index == 0 or chapters[chapter_order[index - 1]].get("final_puzzle") in solved:
                if cid not in accessible:
                    accessible.add(cid)
                    changed = True
                for location in locations.values():
                    if location.get("chapter") != cid:
                        continue
                    for hotspot in location.get("hotspots", []):
                        evidence.add(hotspot.get("id"))
                        if hotspot.get("item"):
                            inventory.add(hotspot["item"])
        for recipe in recipes.values():
            if set(recipe.get("ingredients", [])) <= inventory and recipe.get("result") not in inventory:
                inventory.add(recipe.get("result"))
                changed = True
        for pid, puzzle in puzzles.items():
            if (pid not in solved and puzzle.get("chapter") in accessible
                    and set(puzzle.get("requires", [])) <= solved
                    and set(puzzle.get("clues", [])) <= evidence
                    and set(puzzle.get("items", [])) <= inventory):
                solved.add(pid)
                inventory.update(puzzle.get("rewards", []))
                route.append(pid)
                changed = True
    check(solved == set(puzzles), "Unreachable challenges: " + ", ".join(sorted(set(puzzles) - solved)))
    check(accessible == set(chapters), "Unreachable chapters: " + ", ".join(sorted(set(chapters) - accessible)))
    check(inventory == set(items), "Unobtainable inventory: " + ", ".join(sorted(set(items) - inventory)))

    # A chapter's closing gate must transitively require every challenge in it.
    def ancestors(pid, seen=None):
        seen = set() if seen is None else seen
        for dep in puzzles.get(pid, {}).get("requires", []):
            if dep not in seen:
                seen.add(dep)
                ancestors(dep, seen)
        return seen
    for cid, chapter in chapters.items():
        final = chapter.get("final_puzzle")
        mandatory = {pid for pid, puzzle in puzzles.items() if puzzle.get("chapter") == cid} - {final}
        check(mandatory <= ancestors(final), f"{cid}: closing gate can skip challenges {sorted(mandatory - ancestors(final))}")

    # Supplemental authored dialogue and the art-coordinate override are
    # resources too: validate every cross-reference before an export.
    conversation_count, topic_count, dialogue_words = 0, 0, 0
    dialogue_path = ROOT / "content/dialogues.json"
    if dialogue_path.is_file():
        document = json.loads(dialogue_path.read_text())
        conversations = document.get("conversations", [])
        seen = set()
        for conversation in conversations:
            cid = conversation.get("id")
            check(isinstance(cid, str) and cid not in seen, "Dialogue has missing/duplicate id")
            seen.add(cid)
            conversation_count += 1
            lid = conversation.get("location")
            check(lid in locations, f"{cid}: dialogue location is unknown")
            check(conversation.get("character") in characters, f"{cid}: dialogue character is unknown")
            check(bool(conversation.get("greeting")), f"{cid}: dialogue greeting is empty")
            dialogue_words += len(str(conversation.get("greeting", "")).split())
            for prerequisite in conversation.get("requires", []):
                check(prerequisite in puzzles, f"{cid}: unknown conversation prerequisite")
            check(bool(conversation.get("topics")), f"{cid}: conversation has no topics")
            for topic in conversation.get("topics", []):
                topic_count += 1
                check(bool(topic.get("question")) and bool(topic.get("reply")), f"{cid}: empty question or reply")
                dialogue_words += len((str(topic.get("question", "")) + " " + str(topic.get("reply", ""))).split())
                for prerequisite in topic.get("requires", []):
                    check(prerequisite in puzzles, f"{cid}: unknown topic prerequisite")
                if topic.get("evidence"):
                    check(hotspot_locations.get(topic["evidence"]) == lid, f"{cid}: dialogue tries to collect evidence outside its location")
    else:
        errors.append("Supplemental dialogue file is missing")
    layout_path = ROOT / "content/hotspot-layout.json"
    if layout_path.is_file():
        layout = json.loads(layout_path.read_text())
        check(set(layout) == set(hotspots), "Hotspot layout must cover every clue ID exactly")
        for hid, position in layout.items():
            check(isinstance(position, list) and len(position) == 2
                  and all(isinstance(v, (int, float)) and not isinstance(v, bool) and 0 <= v <= 1 for v in position),
                  f"{hid}: invalid hotspot layout coordinates")
    else:
        errors.append("Reviewed hotspot layout file is missing")

    prose = [data.get("intro", ""), data.get("ending", "")]
    prose += [str(c.get(field, "")) for c in chapters.values() for field in ("intro", "closing")]
    prose += [str(h.get("text", "")) for h in hotspots.values()]
    prose += [str(p.get(field, "")) for p in puzzles.values() for field in ("prompt", "details", "success")]
    return {"scope": "Structural authored-content validation; no human deduction or duration validation", "passed": not errors,
            "counts": {"chapters": len(chapters), "locations": len(locations), "challenges": len(puzzles),
                       "hotspots": len(hotspots), "items": len(items), "recipes": len(recipes), "characters": len(characters),
                       "distinct_location_art_paths": len(art_paths), "distinct_existing_art_hashes": len(art_hashes),
                       "story_and_challenge_words": len(" ".join(prose).split()),
                       "conversations": conversation_count, "dialogue_topics": topic_count,
                       "supplemental_dialogue_words": dialogue_words},
            "puzzle_types": dict(sorted(Counter(p.get("type") for p in puzzles.values()).items())),
            "reachable_solution_order": route, "errors": errors, "warnings": warnings}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-missing-art", action="store_true", help="Validate narrative graph before the art production gate; missing assets remain warnings")
    parser.add_argument("--content", type=Path, default=ROOT / "content/game.json")
    parser.add_argument("--output", type=Path, default=ROOT / "builds/content-audit.json")
    args = parser.parse_args()
    try:
        result = audit(json.loads(args.content.read_text()), args.allow_missing_art)
    except (OSError, ValueError, TypeError, KeyError, AttributeError) as exc:
        result = {"passed": False, "errors": [str(exc)]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result.get("counts", {})))
    for message in result.get("errors", []):
        print("FAIL: " + message)
    for message in result.get("warnings", []):
        print("WARNING: " + message)
    print("CONTENT_AUDIT_OK" if result["passed"] else "CONTENT_AUDIT_FAILED")
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
