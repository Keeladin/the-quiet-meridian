#!/usr/bin/env python3
"""Independent oracles for the 17 revised investigation puzzles.

Rules were transcribed from the answer-withheld clue packet on 2026-11-14,
before comparing authored solutions. This is not a natural-language parser:
changes to the corresponding clue rules need another human/editorial review.
Unlike the traversal tests, these oracles derive answers instead of accepting
the solution field as proof that a puzzle is logically solvable.
"""
from collections import deque
from itertools import combinations, permutations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def only(candidates, name):
    values = list(candidates)
    if len(values) != 1:
        raise AssertionError(f"{name}: expected exactly one solution, found {len(values)}")
    return list(values[0]) if isinstance(values[0], tuple) else values[0]


def paths(graph, start, end, forbidden=(), required=()):
    def walk(path):
        here = path[-1]
        if here == end:
            if all(node in path for node in required):
                yield path
            return
        for node in graph.get(here, []):
            if node not in path and node not in forbidden:
                yield from walk(path + [node])
    return list(walk([start]))


def derive():
    answers = {}
    graph = {"COURT": ["GALLERY", "CISTERN"], "GALLERY": ["PIT", "GAUGE LANDING"],
             "GAUGE LANDING": ["DRY WALK"], "DRY WALK": ["MACHINE", "SUMP"],
             "CISTERN": ["SUMP"], "SUMP": ["MACHINE"], "PIT": ["SEA DRAIN"]}
    answers["p12"] = only(paths(graph, "COURT", "MACHINE", ["PIT", "SUMP"], ["GAUGE LANDING"]), "p12")

    def legal_protocol(steps):
        feed, drain, tested = True, False, False
        for step in steps:
            if step == "Close FEED":
                if not feed:
                    return False
                feed = False
            elif step == "Open DRAIN":
                if feed or drain:
                    return False
                drain = True
            elif step == "Test VENT":
                if not drain:
                    return False
                tested = True
            elif step == "Close DRAIN":
                if not drain:
                    return False
                drain = False
            elif step == "Open FEED":
                if feed or drain or not tested:
                    return False
                feed = True
        return feed and not drain and tested
    actions = ["Open FEED", "Close DRAIN", "Test VENT", "Close FEED", "Open DRAIN"]
    answers["p13"] = only((p for p in permutations(actions) if legal_protocol(p)), "p13")

    visitors = ["Post carrier", "Council courier", "Rowan", "Ada’s messenger", "Elian’s runner", "Bell apprentice"]
    def kitchen(order):
        pos = {name: order.index(name) for name in visitors}
        return (pos["Bell apprentice"] + 1 == pos["Rowan"]
                and pos["Rowan"] + 2 == pos["Post carrier"]
                and pos["Council courier"] == 5
                and pos["Ada’s messenger"] < pos["Bell apprentice"]
                and pos["Rowan"] < pos["Elian’s runner"] < pos["Post carrier"])
    answers["p16"] = only((p for p in permutations(visitors) if kitchen(p)), "p16")

    correction = {"MERIDIAN": 0, "WORKS": -4, "HARBOUR": 3}
    envelopes = [("Council dispatch", "WORKS", 26), ("Reach warning", "HARBOUR", 13),
                 ("Reservoir steady", "MERIDIAN", 10), ("Last ferry clears", "HARBOUR", 21),
                 ("Bypass opens", "WORKS", 18), ("Tide turns", "MERIDIAN", 20)]
    corrected = [(time + correction[clock], name) for name, clock, time in envelopes]
    assert len({time for time, _ in corrected}) == len(corrected), "p23: ordering tie"
    answers["p23"] = [name for _, name in sorted(corrected)]

    panes, cursor = ["RED", "WHITE", "BLUE", "AMBER"], 1
    letters = {"R": 0, "E": 1, "A": 2, "D": 3}
    encoded = []
    for letter in "READ":
        cursor = (cursor + letters[letter]) % len(panes)
        encoded.append(panes[cursor])
    answers["p25"] = encoded

    links = [("LOFT", "NORTH ROOF", 2), ("LOFT", "MARKET", 1),
             ("NORTH ROOF", "MERIDIAN ROOF", 3), ("NORTH ROOF", "QUARRY", 2),
             ("MARKET", "HARBOUR", 1), ("MARKET", "CHAPEL", 2), ("HARBOUR", "ISLAND", 8),
             ("CHAPEL", "MERIDIAN ROOF", 1), ("QUARRY", "ISLAND", 6), ("MERIDIAN ROOF", "ISLAND", 2)]
    graph, weights = {}, {}
    for start, end, loss in links:
        graph.setdefault(start, []).append(end)
        weights[start, end] = loss
    candidates = [(sum(weights[a, b] for a, b in zip(path, path[1:])), path)
                  for path in paths(graph, "LOFT", "ISLAND")]
    best = min(loss for loss, _ in candidates)
    answers["p26"] = only((path for loss, path in candidates if loss == best), "p26")

    total_interval = 14 * 60 - (11 * 60 + 45)
    delay = total_interval - 60
    assert delay % 3 == 0
    answers["p28"] = str(delay // 3)

    graph = {"JETTY": ["WILLOW", "FERRY HUT"], "FERRY HUT": ["DRY BANK"],
             "DRY BANK": ["WILLOW", "SOFT MUD"], "WILLOW": ["STONE RIDGE", "SOFT MUD"],
             "STONE RIDGE": ["CLINIC"], "SOFT MUD": ["CLINIC"]}
    routes = paths(graph, "JETTY", "CLINIC", ["SOFT MUD"])
    answers["p32"] = only((p for p in routes if "FERRY HUT" in p and p.index("FERRY HUT") < p.index("WILLOW")), "p32")

    priorities = {"BREATH": 0, "BLEED": 1, "BONE": 2, "WALK": 3}
    cards = [("Moss", "BREATH", 2), ("Elva", "BONE", 0), ("Cora", "BLEED", 4),
             ("Vale", "BREATH", 1), ("Petra", "WALK", 1), ("Hadi", "BLEED", 3)]
    answers["p33"] = [card[0] for card in sorted(cards, key=lambda c: (priorities[c[1]], c[2]))]
    choices = [c for c in combinations(sorted([4, 2, 7, 1]), 3) if c[1] == c[0] + 3 and sum(c) == 12]
    answers["p35"] = "".join(str(n) for n in only(choices, "p35"))

    sites = {"HUT": (0, 0, 5), "NORTH BANK": (0, 1, 4), "STONE BRIDGE": (1, 1, 4),
             "RIDGE": (1, 0, 2), "GARDEN": (2, 1, 4), "TOWER": (2, 0, 3),
             "REFUGE": (3, 1, 5), "TIDAL CUT": (1, 2, 1)}
    graph = {a: [b for b in sites if abs(sites[a][0] - sites[b][0]) + abs(sites[a][1] - sites[b][1]) == 1] for a in sites}
    answers["p36"] = only(paths(graph, "HUT", "REFUGE", [name for name, (_, _, height) in sites.items() if height <= 3]), "p36")
    answers["p37"] = str(23 - 8 - 9)

    events = ["Land transferred", "Option assigned", "Emergency clearance declared", "Tenant claims lodged", "Claims extinguished", "Foundry option purchased"]
    def deeds(order):
        p = {name: order.index(name) for name in events}
        return (p["Tenant claims lodged"] < p["Foundry option purchased"] < p["Option assigned"]
                and p["Emergency clearance declared"] + 1 == p["Claims extinguished"]
                and p["Land transferred"] > p["Claims extinguished"]
                and p["Option assigned"] + 2 == p["Claims extinguished"])
    answers["p43"] = only((p for p in permutations(events) if deeds(p)), "p43")

    receipts = {"A": ("Olan", "Vey"), "B": ("Vey", "Elian"), "C": ("Rusk", "Olan"),
                "D": ("Elian", "Records office"), "E": ("Works drafting room", "Rusk"), "F": ("Records office", "Public vault")}
    def custody(order):
        return (receipts[order[0]][0] == "Works drafting room" and receipts[order[-1]][1] == "Public vault"
                and all(receipts[a][1] == receipts[b][0] for a, b in zip(order, order[1:])))
    answers["p49"] = only((p for p in permutations(receipts) if custody(p)), "p49")

    witnesses = ["Elian", "Rowan", "Sera", "Olan", "Ada", "Mara"]
    def hearing(order):
        p = {name: order.index(name) for name in witnesses}
        return (p["Sera"] == 5 and p["Ada"] + 1 == p["Elian"]
                and p["Rowan"] + 1 == p["Mara"] and p["Mara"] < p["Olan"] < p["Ada"])
    answers["p52"] = only((p for p in permutations(witnesses) if hearing(p)), "p52")

    table = {"COLD": ("PRIMED", "COLD"), "PRIMED": ("CHARGED", "VENTED"),
             "CHARGED": ("OVERLOAD", "BRIDGED"), "BRIDGED": ("CHECK", "VENTED"),
             "CHECK": ("OVERLOAD", "READY"), "VENTED": ("COLD", "PRIMED"), "OVERLOAD": ("COLD", "COLD")}
    queue, completed, shortest = deque([("COLD", [])]), [], None
    while queue:
        state, path = queue.popleft()
        if shortest is not None and len(path) > shortest:
            break
        if state == "READY":
            shortest = len(path)
            completed.append(path)
            continue
        for pulse, next_state in zip(["SHORT", "LONG"], table[state]):
            queue.append((next_state, path + [pulse]))
    answers["p53"] = only(completed, "p53")
    total = sum(position * value for position, value in enumerate([3, 7, 2, 4, 6], 1))
    answers["p54"] = str((-total) % 10)
    return answers


def main():
    data = json.loads((ROOT / "content/game.json").read_text())
    authored = {p["id"]: p for p in data["puzzles"]}
    for pid, derived in derive().items():
        assert authored[pid]["solution"] == derived, f"{pid}: authored answer differs from independently derived result {derived}"
        print(pid + ": independently derived answer matches")
    print("PUZZLE_LOGIC_OK: 17 independent oracles; constrained permutations and routes have unique solutions")


if __name__ == "__main__":
    main()
