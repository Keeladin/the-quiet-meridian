#!/usr/bin/env python3
"""Independent consistency check for the four authored route diagrams.

Exact link/weight tables below are transcribed from the cited clue text. The
checker enumerates legal routes; it does not use the authored answer to choose
a route. It then compares the uniquely legal/optimal route with that answer.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
boards = json.loads((ROOT / "content/boards.json").read_text())
game = json.loads((ROOT / "content/game.json").read_text())
puzzles = {p["id"]: p for p in game["puzzles"]}
hotspots = {s["id"]: s for loc in game["locations"] for s in loc["hotspots"]}

EXPECTED_EDGES = {
    "p12": {
        ("COURT", "GALLERY"), ("COURT", "CISTERN"),
        ("GALLERY", "PIT"), ("GALLERY", "GAUGE LANDING"),
        ("GAUGE LANDING", "DRY WALK"), ("DRY WALK", "MACHINE"),
        ("DRY WALK", "SUMP"), ("CISTERN", "SUMP"),
        ("SUMP", "MACHINE"), ("PIT", "SEA DRAIN"),
    },
    "p26": {
        ("LOFT", "NORTH ROOF"), ("LOFT", "MARKET"),
        ("NORTH ROOF", "MERIDIAN ROOF"), ("NORTH ROOF", "QUARRY"),
        ("MARKET", "HARBOUR"), ("MARKET", "CHAPEL"),
        ("HARBOUR", "ISLAND"), ("CHAPEL", "MERIDIAN ROOF"),
        ("QUARRY", "ISLAND"), ("MERIDIAN ROOF", "ISLAND"),
    },
    "p32": {
        ("JETTY", "WILLOW"), ("JETTY", "FERRY HUT"),
        ("FERRY HUT", "DRY BANK"), ("DRY BANK", "WILLOW"),
        ("DRY BANK", "SOFT MUD"), ("WILLOW", "STONE RIDGE"),
        ("WILLOW", "SOFT MUD"), ("STONE RIDGE", "CLINIC"),
        ("SOFT MUD", "CLINIC"),
    },
}
LOSS = {
    "LOFT>NORTH ROOF": 2, "LOFT>MARKET": 1,
    "NORTH ROOF>MERIDIAN ROOF": 3, "NORTH ROOF>QUARRY": 2,
    "MARKET>HARBOUR": 1, "MARKET>CHAPEL": 2,
    "HARBOUR>ISLAND": 8, "CHAPEL>MERIDIAN ROOF": 1,
    "QUARRY>ISLAND": 6, "MERIDIAN ROOF>ISLAND": 2,
}
SURVEY = {
    "HUT": (0, 0, 5), "NORTH BANK": (0, 1, 4),
    "STONE BRIDGE": (1, 1, 4), "RIDGE": (1, 0, 2),
    "GARDEN": (2, 1, 4), "TOWER": (2, 0, 3),
    "REFUGE": (3, 1, 5), "TIDAL CUT": (1, 2, 1),
}
EXPECTED_CLUES = {
    "p12": {"ch2_l1_c", "ch2_l2_c"},
    "p26": {"ch3_l4_b", "ch3_l6_b"},
    "p32": {"ch4_l1_a", "ch4_l1_b"},
    "p36": {"ch4_l4_a", "ch4_l4_c"},
}


def routes(board, start, finish):
    graph = {node["id"]: [] for node in board["nodes"]}
    for a, b in board["edges"]:
        graph[a].append(b)
        if not board["directed"]:
            graph[b].append(a)
    found = []

    def visit(path):
        if path[-1] == finish:
            found.append(path)
            return
        for nxt in graph[path[-1]]:
            if nxt not in path:
                visit(path + [nxt])

    visit([start])
    return found


assert set(boards) == set(EXPECTED_CLUES), "Expected exactly four route boards"
for pid, board in boards.items():
    puzzle = puzzles[pid]
    nodes = {n["id"]: n for n in board["nodes"]}
    assert len(nodes) == len(board["nodes"]), (pid, "duplicate node")
    assert {n["option"] for n in nodes.values()} == set(puzzle["options"]), (pid, "option mismatch")
    assert set(board["source_clues"]) == EXPECTED_CLUES[pid] == set(puzzle["clues"]), (pid, "clue mismatch")
    assert all(c in hotspots for c in board["source_clues"]), (pid, "missing clue")
    assert all(0 <= n["x"] <= 1 and 0 <= n["y"] <= 1 for n in nodes.values())
    edges = {tuple(e) for e in board["edges"]}
    assert len(edges) == len(board["edges"]), (pid, "duplicate edge")
    assert all(a in nodes and b in nodes and a != b for a, b in edges)
    if pid in EXPECTED_EDGES:
        assert board["directed"] is True, (pid, "must be directed")
        assert edges == EXPECTED_EDGES[pid], (pid, "links differ from cited clue")
    else:
        assert board["directed"] is False
        expected = {
            frozenset((a, b)) for a in SURVEY for b in SURVEY if a != b
            and abs(SURVEY[a][0] - SURVEY[b][0]) + abs(SURVEY[a][1] - SURVEY[b][1]) == 1
        }
        assert {frozenset(e) for e in edges} == expected, "Survey edges must match side adjacency exactly"
        # Layout preserves the actual grid, with positive survey y drawn upward.
        for a in SURVEY:
            for b in SURVEY:
                if SURVEY[a][0] == SURVEY[b][0]:
                    assert nodes[a]["x"] == nodes[b]["x"]
                if SURVEY[a][1] == SURVEY[b][1]:
                    assert nodes[a]["y"] == nodes[b]["y"]
    by_option = {n["option"]: n["id"] for n in nodes.values()}
    selected = [by_option[o] for o in puzzle["solution"]]
    assert all((a, b) in edges or (not board["directed"] and (b, a) in edges) for a, b in zip(selected, selected[1:])), (pid, "answer skips a link")
    assert len(selected) == len(set(selected)), (pid, "answer repeats a node")
    assert not any(nodes[n].get("hazard") for n in selected), (pid, "answer enters visible hazard")

safe12 = [p for p in routes(boards["p12"], "COURT", "MACHINE") if "GAUGE LANDING" in p and not {"PIT", "SUMP"}.intersection(p)]
assert safe12 == [puzzles["p12"]["solution"]], "Service constraints must yield exactly the authored route"
assert {n["id"] for n in boards["p12"]["nodes"] if n.get("hazard")} == {"PIT", "SUMP"}

assert {k: int(v) for k, v in boards["p26"]["edge_labels"].items()} == LOSS, "Relay weights differ from clue"
relay_routes = routes(boards["p26"], "LOFT", "ISLAND")
scored = [(sum(LOSS[a + ">" + b] for a, b in zip(p, p[1:])), p) for p in relay_routes]
minimum = min(cost for cost, _ in scored)
assert minimum == 6 and [p for cost, p in scored if cost == minimum] == [puzzles["p26"]["solution"]]

marsh_routes = routes(boards["p32"], "JETTY", "CLINIC")
safe32 = [p for p in marsh_routes if "SOFT MUD" not in p and "FERRY HUT" in p and p.index("FERRY HUT") < p.index("WILLOW")]
assert safe32 == [puzzles["p32"]["solution"]], "Rope acquisition must precede the Willow crossing"
assert boards["p32"]["edge_labels"] == {"WILLOW>STONE RIDGE": "ROPE"}
assert {n["id"] for n in boards["p32"]["nodes"] if n.get("hazard")} == {"SOFT MUD"}

safe36 = [p for p in routes(boards["p36"], "HUT", "REFUGE") if all(SURVEY[n][2] > 3 for n in p)]
assert safe36 == [puzzles["p36"]["solution"]], "Strict height rule must yield exactly the authored route"
assert {n["id"] for n in boards["p36"]["nodes"] if n.get("hazard")} == {n for n, (_, _, h) in SURVEY.items() if h <= 3}
print("BOARD_CHECKS_OK: 4 boards, 32 selectable nodes, 38 documented links; exact clue tables, relay weights, rope acquisition, strict water-height safety, and uniquely constrained routes")
