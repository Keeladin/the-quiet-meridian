# The Quiet Meridian — complete puzzle dependency map

Authored baseline: 14 November 2026. Spoilers throughout. `content/game.json` is the runtime source of truth. This map describes intended dependencies; automated tests and actual playtesting establish validation separately.

Target: six chapters, 36 environments, 60 varied investigative challenges, 6–10 hours. Counts do not establish duration.

## Search-driven campaign

All 36 rooms now require their picture search before their evidence and useful
items are awarded. Each chapter conclusion additionally requires all six room
searches. Five former collection confirmations resolve automatically; 55 further
investigations retain the dependencies below. See `CHAPTER_SEARCH_STRUCTURE.md`
for the area pairs and room rewards, and `CAMPAIGN_SEARCH_REPORT.md` for checks.

The side rail, unified Casebook and `content/story-guide.json` explain these
dependencies without changing their edges. `scripts/case_guide.gd` selects a
useful action from actual progress, preferring a ready local investigation to an
unrelated available combination. Discoveries appear only after the corresponding
search, and chapter recaps only after resolution. The illustrated city map
separates search completion from remaining investigation work.

## Recovery invariants

All unlocked locations remain revisitable. Evidence and acquisition history are
retained. Recipes are idempotent; incorporated ingredients disappear from the
active satchel, and finished tools retire only after their last required use.
They remain in the collection record for provenance and dependency validation.
Wrong answers preserve story progression, though repeated submissions update the
Detective attempt counters and can cause a short submission cooldown. Search
completion requires every listed picture target; assembly challenges require the
actual combined result. No essential dialogue can be refused or permanently missed.

Each search attempt and deduction allows at most three hints: one free and two
purchasable, with forty-five-second active-play cooldowns. Search timing and
Insight change attempt state, not these story prerequisite edges. Search rewards
and deduction rewards are granted once. Restarting a failed search refunds its
own purchases and clears only its unfinished search progress. Completed searches,
collected evidence, solved deductions and earlier chapters remain intact.

The per-puzzle recovery notes below describe narrative retryability. Any statement
about freely retrying a deduction is subject to the Detective submission cooldown;
any older reference to an untimed search is superseded by the attempt rules above.

## Chapter gates

```mermaid
flowchart LR
  p10 --> p20 --> p30 --> p40 --> p50 --> p60
```

Each final requires all other nine challenges in its chapter, as well as the previous final. Parallel internal branches are listed below. Item availability is independent of challenge completion except for explicit rewards; collection requires visiting the item’s scene.

## ch1: The Borrowed Bell

Find the path Mara left through the rain.

### p01 — The three scraps (hidden)

Location: `ch1_l1`. Requires: none.

Clues: `ch1_l1_a`, `ch1_l1_b`, `ch1_l1_c`.

Items: none. Rewards: recorded conclusion / progression.

Recover the dispatch receipt from the landing. Examine the dispatch box, mooring post and landing steps. Their fragments are retained in your journal; no tiny object is permanently lost.

**Solution:** "found". Compare the cited evidence using the explicit rule. Intended answer: found.

**Hints:** The receipt tore among the landing’s working surfaces. / Look at the dispatch box, mooring post and landing steps. / Inspect all three landing hotspots, then confirm the search.

**State change:** mark p01 solved; retain evidence and inventory. Together the scraps prove that Mara collected her parcel and paid for a passage. Someone wrote the notice without checking the receipt.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p02 — Water before its time (code)

Location: `ch1_l2`. Requires: none.

Clues: `ch1_l2_a`.

Items: none. Rewards: recorded conclusion / progression.

At what time would the normal tide reach five divisions above low water? Enter a four-digit 24-hour time, without punctuation. Count from the tide table’s low water, crossing midnight if necessary.

**Solution:** "0050". Compare the cited evidence using the explicit rule. Intended answer: 0050.

**Hints:** The tide rises at a constant rate. / Five divisions take five times six minutes. / 00:20 plus thirty minutes is 00:50. Enter 0050.

**State change:** mark p02 solved; retain evidence and inventory. Normal tide could not reach five divisions until 00:50. The removed folio reports that level in the Reach at 00:14: thirty-six minutes too early, and six minutes before low water ended.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p03 — The displaced catalogue (choice)

Location: `ch1_l3`. Requires: none.

Clues: `ch1_l3_a`, `ch1_l3_b`.

Items: none. Rewards: recorded conclusion / progression.

Which shelf ticket names the folio Mara was seeking? Use the catalogue hierarchy and the exact district, year and type. The replacement label is not necessarily reliable.

**Solution:** "C — East / 17 / works order". Compare the cited evidence using the explicit rule. Intended answer: C — East / 17 / works order.

**Hints:** Read all three parts of the catalogue reference. / East and year 17 are insufficient: the document is a works order. / Choose C — East / 17 / works order.

**State change:** mark p03 solved; retain evidence and inventory. The works-order shelf has a narrow empty space. Mara was following an administrative record, not merely a tide table.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p04 — A repair that can be undone (assembly)

Location: `ch1_l4`. Requires: `p03`.

Clues: `ch1_l3_c`, `ch1_l4_a`.

Items: `repair_kit`. Rewards: recorded conclusion / progression.

Prepare a reversible support for the damaged folio. Combine repair tissue and wheat paste in the inventory. Then apply the resulting repair kit here.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** The supply chest and the workbench hold complementary materials. / Tissue supports the tear; paste attaches that support. / Combine Repair tissue with Wheat paste, then apply the Paper repair kit.

**State change:** mark p04 solved; retain evidence and inventory. The supported page can be handled without losing its torn edges. You have preserved both writing and physical evidence.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p05 — The path through the page (order)

Location: `ch1_l4`. Requires: `p04`.

Clues: `ch1_l4_b`, `ch1_l4_c`.

Items: none. Rewards: recorded conclusion / progression.

Reconstruct the order of Mara’s actions from the four strips. Arrange the strips by their matching sentence edges. Every strip is used once.

**Solution:** ["Borrowed", "The bell key, then", "Opened the folio", "Before taking the works road"]. Compare the cited evidence using the explicit rule. Intended answer: ['Borrowed', 'The bell key, then', 'Opened the folio', 'Before taking the works road'].

**Hints:** Read the words on each edge as parts of one sentence. / Borrowing comes before opening; the road comes last. / Order: Borrowed → The bell key, then → Opened the folio → Before taking the works road.

**State change:** mark p05 solved; retain evidence and inventory. The repaired sentence gives you a route. The bell key came before the folio; the works road came after it.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p06 — An evening without a struggle (order)

Location: `ch1_l5`. Requires: `p01`.

Clues: `ch1_l5_a`, `ch1_l5_b`.

Items: none. Rewards: recorded conclusion / progression.

Put the witnessed events in chronological order. Use the boarding-house ledger. The later missing notice is an allegation, not a timed observation.

**Solution:** ["Key delivered", "Blue folio seen", "Key returned", "Mara leaves on foot"]. Compare the cited evidence using the explicit rule. Intended answer: ['Key delivered', 'Blue folio seen', 'Key returned', 'Mara leaves on foot'].

**Hints:** The ledger gives four explicit times. / 17:10 precedes 17:35, then 17:50, then 18:00. / Key delivered → Blue folio seen → Key returned → Mara leaves on foot.

**State change:** mark p06 solved; retain evidence and inventory. Mara’s movements form a deliberate itinerary. The council’s visitor was interested in what she carried, not in finding her.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p07 — The tide shutter (sequence)

Location: `ch1_l2`. Requires: `p02`.

Clues: `ch1_l2_b`.

Items: none. Rewards: recorded conclusion / progression.

Operate the shutter’s maintenance interlock. Select the engraved button sequence. Buttons may be used more than once. Do not omit the repeated rising-water step.

**Solution:** ["SHORE", "CHANNEL", "CHANNEL", "SEA"]. Compare the cited evidence using the explicit rule. Intended answer: ['SHORE', 'CHANNEL', 'CHANNEL', 'SEA'].

**Hints:** Begin where the water is lowest. / The rising-water button is pressed twice. / SHORE → CHANNEL → CHANNEL → SEA.

**State change:** mark p07 solved; retain evidence and inventory. The shutter lifts, revealing an old flood-level scratch behind it. Its height agrees with Mara’s copied measurement, not the official tide time.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p08 — The small bell (assembly)

Location: `ch1_l6`. Requires: `p06`.

Clues: `ch1_l5_c`, `ch1_l6_a`.

Items: `bell_pull`. Rewards: recorded conclusion / progression.

Restore the practice bell’s pull without touching the harbour alarm. Combine the flax bell cord with the brass bell hook in inventory, then fit the repaired pull.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** The cord and hook were left in different places. / Take the cord from the key rack and the hook from the tower’s spare rope tackle. / Combine Bell cord and Brass bell hook, then apply Repaired bell pull.

**State change:** mark p08 solved; retain evidence and inventory. The little bell moves freely again. Its private teaching signal can be reproduced without summoning the harbour.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p09 — A quiet destination (sequence)

Location: `ch1_l6`. Requires: `p08`.

Clues: `ch1_l6_b`.

Items: none. Rewards: recorded conclusion / progression.

Reproduce the destination Mara underlined. Read the practice signal card. Enter the sounds in order; a sound may be repeated.

**Solution:** ["LONG", "SHORT", "SHORT"]. Compare the cited evidence using the explicit rule. Intended answer: ['LONG', 'SHORT', 'SHORT'].

**Hints:** Mara underlined a destination, not a person. / Use the WORKS entry on the signal card. / LONG → SHORT → SHORT.

**State change:** mark p09 solved; retain evidence and inventory. The practice keeper recognises the signal. Mara was asking which road remained dry to the pumping works after the evening tide.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p10 — The borrowed bell (deduction)

Location: `ch1_l6`. Requires: `p01`, `p02`, `p03`, `p04`, `p05`, `p06`, `p07`, `p08`, `p09`.

Clues: `ch1_l1_b`, `ch1_l1_c`, `ch1_l2_c`, `ch1_l5_b`, `ch1_l6_c`.

Items: none. Rewards: recorded conclusion / progression.

Which account best fits the independent records? Your conclusion must explain the paid passage, the returned key, the repaired folio and the witnessed departure.

**Solution:** "Mara left deliberately, carrying evidence toward the works". Compare the cited evidence using the explicit rule. Intended answer: Mara left deliberately, carrying evidence toward the works.

**Hints:** Test each claim against the timed records. / A returned key and paid fare contradict an unexplained disappearance at the archive. / Choose the deliberate departure toward the works.

**State change:** mark p10 solved; retain evidence and inventory. You write a careful first conclusion: Mara left voluntarily with evidence. It does not explain why she hid. It tells you where to look next.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

## ch2: Water Has a Memory

Reconstruct the flood in the machines that survived it.

### p11 — Marks the water left (hidden)

Location: `ch2_l1`. Requires: `p10`.

Clues: `ch2_l1_a`, `ch2_l1_b`, `ch2_l1_c`.

Items: none. Rewards: recorded conclusion / progression.

Record three independent traces in the pump court. Examine the high-water nail, broken gauge and service chart. Record physical evidence before interpreting the machine.

**Solution:** "found". Compare the cited evidence using the explicit rule. Intended answer: found.

**Hints:** The flood left traces above and below eye level. / Inspect the nail, gauge and route chart. / Examine all three pump-court hotspots, then confirm.

**State change:** mark p11 solved; retain evidence and inventory. The red sediment and reservoir gauge establish an upstream source worth testing. The route chart gives you a safe approach.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p12 — A dry way through (routing)

Location: `ch2_l1`. Requires: `p11`.

Clues: `ch2_l1_c`, `ch2_l2_c`.

Items: none. Rewards: recorded conclusion / progression.

Trace a safe maintenance route from the court to the machine room. Plan a directed route from COURT to MACHINE. It must include the required gauge reading and avoid every platform named on the gallery’s current flood tag. Do not revisit nodes.

**Solution:** ["COURT", "GALLERY", "GAUGE LANDING", "DRY WALK", "MACHINE"]. SUMP and PIT are excluded by the current tag. The only remaining directed path from COURT through GAUGE LANDING to MACHINE uses GALLERY and DRY WALK. CISTERN leads only to excluded SUMP.

**Hints:** The chart alone is not enough: check today’s flooded-platform tag in the gallery. / The CISTERN branch enters SUMP, while the PIT branch misses the gauge and is flooded. / COURT → GALLERY → GAUGE LANDING → DRY WALK → MACHINE.

**State change:** mark p12 solved; retain evidence and inventory. You mark a dry access route for the investigation. Nobody needs to enter the flooded pit.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p13 — The five-valve protocol (sequence)

Location: `ch2_l2`. Requires: `p12`.

Clues: `ch2_l2_a`.

Items: none. Rewards: recorded conclusion / progression.

Run the disconnected training board through its inspection cycle. Infer the safe action order from the interlocks. Starting state: FEED open, DRAIN closed. Finish with VENT tested and both valves restored. Use every available action once.

**Solution:** ["Close FEED", "Open DRAIN", "Test VENT", "Close DRAIN", "Open FEED"]. Open DRAIN requires Close FEED first; Test VENT requires Open DRAIN before it and Close DRAIN after it. Open FEED requires both Test VENT and Close DRAIN. These constraints force all five actions uniquely.

**Hints:** Write down which condition each action needs before it can happen. / Close FEED permits Open DRAIN; the vent test must happen before that drain closes again. / Close FEED → Open DRAIN → Test VENT → Close DRAIN → Open FEED.

**State change:** mark p13 solved; retain evidence and inventory. The interlock works exactly as its maker intended. The flood required a deliberate bypass operation, not one wheel slipping by itself.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p14 — The square drive (assembly)

Location: `ch2_l3`. Requires: `p13`.

Clues: `ch2_l2_b`, `ch2_l3_a`, `ch2_l3_c`.

Items: `bypass_tool`. Rewards: recorded conclusion / progression.

Prepare the safe bypass test tool. Combine the coupling from the gallery with the insulated crank from the machine-room drawer, then use it in the disconnected socket.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** The square shaft needs a square coupling. / The coupling’s threaded end needs the insulated handle. / Combine Bypass coupling with Insulated crank, then apply Bypass test crank.

**State change:** mark p14 solved; retain evidence and inventory. The test crank reaches the old FULL scratch. You can demonstrate the mechanism without moving a live gate.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p15 — A pressure without a tide (deduction)

Location: `ch2_l3`. Requires: `p14`.

Clues: `ch2_l1_a`, `ch2_l3_b`, `ch2_l3_c`.

Items: none. Rewards: recorded conclusion / progression.

Which source explains the recorder and the test socket? Choose the explanation consistent with an unchanged main gate, rising bypass pressure and a tide that turns later.

**Solution:** "Upper reservoir water entered through the council bypass". Compare the cited evidence using the explicit rule. Intended answer: Upper reservoir water entered through the council bypass.

**Hints:** The main gate trace does not move. / The reservoir pressurises the bypass before the Reach rises. / Choose upper reservoir water entering through the council bypass.

**State change:** mark p15 solved; retain evidence and inventory. The machine supplies a causal explanation independent of anyone’s recollection. The water came from above.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p16 — The kitchen witnesses (order)

Location: `ch2_l4`. Requires: `p10`.

Clues: `ch2_l4_a`, `ch2_l4_c`.

Items: none. Rewards: recorded conclusion / progression.

Arrange the arrivals at the workers’ kitchen. Reconstruct all six arrivals using both the meal slate and the cook’s separate note. “Exactly two places before” means one visitor stood between them. Each visitor appears once.

**Solution:** ["Ada’s messenger", "Bell apprentice", "Rowan", "Elian’s runner", "Post carrier", "Council courier"]. Apprentice immediately precedes Rowan. Runner is after Rowan and before Post, and Rowan is exactly two positions before Post, forcing Apprentice–Rowan–Runner–Post. Ada precedes Apprentice; Courier is last. Six visitors fill six positions uniquely.

**Hints:** Treat Bell apprentice → Rowan as a block. One person goes between Rowan and the post carrier. / That intervening visitor must be Elian’s runner. Ada precedes the block, and the courier is last. / Ada’s messenger → Bell apprentice → Rowan → Elian’s runner → Post carrier → Council courier.

**State change:** mark p16 solved; retain evidence and inventory. The evacuation assurance arrived with the council courier, after the engineer’s runner had asked whether the houses were clear.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p17 — What Rowan can actually prove (deduction)

Location: `ch2_l4`. Requires: `p16`.

Clues: `ch2_l4_b`, `ch2_l4_c`, `ch2_l5_c`.

Items: none. Rewards: recorded conclusion / progression.

Which statement is supported by Rowan’s account and the cook’s note? Distinguish a witnessed order from an unverified claim inside that order.

**Solution:** "Rowan closed the footway after receiving an unverified evacuation claim". Compare the cited evidence using the explicit rule. Intended answer: Rowan closed the footway after receiving an unverified evacuation claim.

**Hints:** A message can be delivered honestly and still be false. / Neither witness checked the houses. / Choose the closure after an unverified evacuation claim.

**State change:** mark p17 solved; retain evidence and inventory. Rowan signs a statement limited to what he did and heard. It is harder to evade because it does not claim what he could not know.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p18 — The key that could not fit (assembly)

Location: `ch2_l5`. Requires: `p17`.

Clues: `ch2_l5_a`, `ch2_l5_b`.

Items: `key_comparison`. Rewards: recorded conclusion / progression.

Mount the two key profiles for comparison. Combine Tomas’s gate-key tracing with the bypass lock profile. Their shoulders must be aligned, not their tips.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** Both profiles are portable evidence. / Matching the shoulders exposes the different working edges. / Combine Gate-key tracing with Lock profile plate.

**State change:** mark p18 solved; retain evidence and inventory. Tomas’s key could not operate the bypass. His custody of the residential key cannot explain the diverted reservoir.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p19 — The path of the surge (order)

Location: `ch2_l6`. Requires: `p15`, `p18`.

Clues: `ch2_l6_a`, `ch2_l6_b`.

Items: none. Rewards: recorded conclusion / progression.

Put the water’s physical route in order. Use all four stages. Begin at the source identified by the red grit and pressure roll.

**Solution:** ["RESERVOIR", "BYPASS", "REACH", "LOWER STAIR"]. Compare the cited evidence using the explicit rule. Intended answer: ['RESERVOIR', 'BYPASS', 'REACH', 'LOWER STAIR'].

**Hints:** The red sediment begins upstream of the city. / The bypass connects the reservoir to the Reach. / RESERVOIR → BYPASS → REACH → LOWER STAIR.

**State change:** mark p19 solved; retain evidence and inventory. The reconstructed route agrees with both the sediment and the scour marks. Three kinds of evidence describe the same event.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p20 — The gate above the gate (deduction)

Location: `ch2_l6`. Requires: `p11`, `p12`, `p13`, `p14`, `p15`, `p16`, `p17`, `p18`, `p19`, `p10`.

Clues: `ch2_l3_b`, `ch2_l5_b`, `ch2_l6_a`, `ch2_l6_b`, `ch2_l6_c`.

Items: none. Rewards: recorded conclusion / progression.

Which finding is now defensible? Identify what the machinery proves. Do not yet accuse a particular person of turning the bypass; physical access is not individual identity.

**Solution:** "The flood was a deliberate reservoir diversion through the council bypass". Compare the cited evidence using the explicit rule. Intended answer: The flood was a deliberate reservoir diversion through the council bypass.

**Hints:** The route and interlock establish an operation, but not the operator’s name. / The bypass is mechanically separate from Tomas’s lock. / Choose deliberate reservoir diversion through the council bypass.

**State change:** mark p20 solved; retain evidence and inventory. You can clear the mechanism of one lie. To establish who acted, you first need an exact time that the works office could not rewrite.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

## ch3: The Unstruck Hour

Find the minute the city removed from its history.

### p21 — An instrument’s history (hidden)

Location: `ch3_l1`. Requires: `p20`.

Clues: `ch3_l1_a`, `ch3_l1_b`, `ch3_l1_c`.

Items: none. Rewards: recorded conclusion / progression.

Inspect the observatory’s entrance evidence. Record the lens box, calibration plaque and Ada’s account before deciding whether the clock discrepancy is deception or a known error.

**Solution:** "found". Compare the cited evidence using the explicit rule. Intended answer: found.

**Hints:** The correction is recorded where instrument users enter. / Inspect the box, plaque and Ada. / Examine all three observatory-steps hotspots.

**State change:** mark p21 solved; retain evidence and inventory. The four-minute error was documented before the flood. A later report omitted the correction.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p22 — Four minutes fast (code)

Location: `ch3_l1`. Requires: `p21`.

Clues: `ch3_l1_b`, `ch3_l1_c`.

Items: none. Rewards: recorded conclusion / progression.

Convert the works reading to meridian time. The works clock reads 00:18 and runs four minutes fast. Enter the corrected time as four digits, without punctuation.

**Solution:** "0014". Compare the cited evidence using the explicit rule. Intended answer: 0014.

**Hints:** A fast clock displays a later time than reality. / Subtract four minutes from 00:18. / Enter 0014.

**State change:** mark p22 solved; retain evidence and inventory. The corrected works entry is 00:14. You now need an independent record to check it.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p23 — Six exposures (order)

Location: `ch3_l2`. Requires: `p22`.

Clues: `ch3_l1_b`, `ch3_l2_a`, `ch3_l2_b`.

Items: none. Rewards: recorded conclusion / progression.

Put the observatory events in time order. Arrange six events in actual meridian-time order. Convert each envelope’s reading using the clock named on it. A slow clock needs time added; a fast clock needs time subtracted. Every event is used once.

**Solution:** ["Reservoir steady", "Bypass opens", "Reach warning", "Tide turns", "Council dispatch", "Last ferry clears"]. WORKS readings subtract four minutes; HARBOUR readings add three; MERIDIAN is unchanged. Resulting six times are all distinct and force the stated chronology.

**Hints:** There are three clocks. Do not sort the printed numbers before correcting them. / Corrected times are Reservoir 00:10, Bypass 00:14, Warning 00:16, Tide 00:20, Dispatch 00:22 and Ferry 00:24. / Reservoir steady → Bypass opens → Reach warning → Tide turns → Council dispatch → Last ferry clears.

**State change:** mark p23 solved; retain evidence and inventory. The dispatch was not an advance warning. It followed the flood’s first visible effects.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p24 — Light through glass (assembly)

Location: `ch3_l3`. Requires: `p23`.

Clues: `ch3_l1_a`, `ch3_l2_c`, `ch3_l3_a`.

Items: `plate_viewer`. Rewards: recorded conclusion / progression.

Assemble a viewer for the fragile original plate. Combine the viewing lens and brass viewer frame. Use diffuse light, preserving the plate surface.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** The lens box and telescope desk hold the two parts. / The frame’s empty circular seat fits the lens. / Combine Viewing lens with Viewer frame, then apply Assembled plate viewer.

**State change:** mark p24 solved; retain evidence and inventory. The enlarged image shows the bypass open while the residential gate remains closed. The two lamp housings cannot be confused.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p25 — The wheel remembers (sequence)

Location: `ch3_l4`. Requires: `p20`.

Clues: `ch3_l4_a`, `ch3_l4_c`.

Items: none. Rewards: recorded conclusion / progression.

Encode Mara’s four-letter relay test with the moving signal wheel. Use the letter-step table and the starting cursor in Mara’s note. Transmit one pane per letter, retaining the cursor position between letters. Labels make colour recognition unnecessary.

**Solution:** ["WHITE", "BLUE", "RED", "AMBER"]. Start at index 1. Add letter steps 0,1,2,3 modulo 4: indices 1,2,0,3, corresponding to WHITE,BLUE,RED,AMBER.

**Hints:** The message is READ, and the cursor starts at WHITE, slot 1. / R moves zero: WHITE. E moves one: BLUE. Continue from BLUE rather than starting over. / READ transmits WHITE → BLUE → RED → AMBER.

**State change:** mark p25 solved; retain evidence and inventory. The test signal is readable from the north roof. Mara could communicate with someone beyond the marsh.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p26 — Across the roofline (routing)

Location: `ch3_l4`. Requires: `p25`.

Clues: `ch3_l4_b`, `ch3_l6_b`.

Items: none. Rewards: recorded conclusion / progression.

Find the permitted relay route from the loft to the island. Find the directed LOFT-to-ISLAND route with the smallest total loss. Add the number on every used link. Relays do not reset loss; do not repeat a node.

**Solution:** ["LOFT", "MARKET", "CHAPEL", "MERIDIAN ROOF", "ISLAND"]. There are four possible complete directed routes. Losses are north-meridian 7, north-quarry 10, market-harbour 10, market-chapel-meridian 6. The last is uniquely minimal.

**Hints:** Compare complete routes. A route with more relays can still lose less signal. / The north-meridian route loses 7. The market-chapel-meridian route loses 6; the harbour and quarry routes each lose 10. / LOFT → MARKET → CHAPEL → MERIDIAN ROOF → ISLAND. Total loss: 6.

**State change:** mark p26 solved; retain evidence and inventory. The relay route explains how Mara found shelter without leaving a public ferry booking under the island’s name.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p27 — A clock is not a witness (assembly)

Location: `ch3_l5`. Requires: `p24`.

Clues: `ch3_l5_a`, `ch3_l5_b`, `ch3_l5_c`.

Items: `clock_model`. Rewards: recorded conclusion / progression.

Build Ada’s demonstration of the stopped-clock fault. Combine the spare spring and detached spindle. Leave the preserved original instrument untouched.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** The model’s spring is separate from its spindle. / Both parts are in the workshop. / Combine Clock spring and Clock spindle.

**State change:** mark p27 solved; retain evidence and inventory. The model makes the error plain: a stopped hand preserves its own failure, not the time of a later event.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p28 — The lost calibration (code)

Location: `ch3_l3`. Requires: `p24`.

Clues: `ch3_l3_b`, `ch3_l2_b`, `ch3_l3_a`.

Items: none. Rewards: recorded conclusion / progression.

Recover the delay wheel’s missing seconds-per-notch calibration. Find the total interval from reference flash to the recorded plate END. Subtract the duration of exposure code II, then divide the remaining delay equally among three notches. Enter the number of seconds per notch.

**Solution:** "25". Recorded end 00:14:00 minus trigger 00:11:45 =135s. Subtract 60s code-II exposure:75s delay. Divide by three equal notches:25s each. The answer is not printed in any one clue.

**Hints:** The plate ends at 00:14:00, while its reference flash is 00:11:45. That entire interval includes both delay and exposure. / The total is 135 seconds. Code II uses 60 seconds, leaving 75 seconds for three equal delay notches. / (135 − 60) ÷ 3 = 25. Enter 25.

**State change:** mark p28 solved; retain evidence and inventory. Each delay notch represents twenty-five seconds. The restored calibration explains the instrument’s operation without changing the preserved plate or its recorded time.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p29 — The clinic bearing (choice)

Location: `ch3_l6`. Requires: `p26`.

Clues: `ch3_l4_c`, `ch3_l6_b`.

Items: none. Rewards: recorded conclusion / progression.

Which direction does Mara’s bearing instruction indicate? Start NORTH, turn one quarter-turn clockwise, then a half-turn. Use the roof’s labelled compass rose.

**Solution:** "WEST". Compare the cited evidence using the explicit rule. Intended answer: WEST.

**Hints:** Perform the two turns in sequence. / The first turn reaches EAST. The second reaches its opposite. / Choose WEST.

**State change:** mark p29 solved; retain evidence and inventory. Across the western marsh, the old clinic window flashes once. Someone has been waiting for a careful reader.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p30 — The unstruck hour (deduction)

Location: `ch3_l6`. Requires: `p21`, `p22`, `p23`, `p24`, `p25`, `p26`, `p27`, `p28`, `p29`, `p20`.

Clues: `ch3_l3_a`, `ch3_l3_c`, `ch3_l5_c`, `ch3_l6_a`, `ch3_l6_c`.

Items: none. Rewards: recorded conclusion / progression.

What does the corrected timeline establish? Choose the narrow conclusion supported by both machinery and independent optical records.

**Solution:** "The bypass was open about eight minutes before the evacuation return was dispatched". The corrected works entry places opening at 00:14; the independent plate establishes open by its labelled 00:14 exposure end. The formal return is dispatched at 00:22. These records establish the order and an approximately eight-minute interval, without pretending the calibration uncertainty is zero or the plate resolves an exact opening instant.

**Hints:** The two valid times are 00:14 and 00:22. / The hallway clock is not a valid timestamp. / Choose the bypass being open about eight minutes before dispatch.

**State change:** mark p30 solved; retain evidence and inventory. The return could not have authorised an operation already completed unless someone was willing to certify the past falsely. You take the western channel toward the people the return erased.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

## ch4: Names in the Reeds

Find the people hidden inside the missing numbers.

### p31 — Marks for the living (hidden)

Location: `ch4_l1`. Requires: `p30`.

Clues: `ch4_l1_a`, `ch4_l1_b`, `ch4_l1_c`.

Items: none. Rewards: recorded conclusion / progression.

Read the route markers and Nadi’s surviving passenger record. Inspect the cloth route tag, crossing marker and ferry log. Read the written directions; colour is not a code.

**Solution:** "found". Compare the cited evidence using the explicit rule. Intended answer: found.

**Hints:** A safe route and a passenger record share the jetty. / Read the tags and the log. / Examine all three reed-jetty hotspots.

**State change:** mark p31 solved; retain evidence and inventory. Mara’s trail is recent. Nadi’s old log explains why the official passenger count was incomplete.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p32 — Above the mud (routing)

Location: `ch4_l1`. Requires: `p31`.

Clues: `ch4_l1_a`, `ch4_l1_b`.

Items: none. Rewards: recorded conclusion / progression.

Choose a safe route from the jetty to the clinic. Plan a single directed route from JETTY to CLINIC. You start without rope, gain it at FERRY HUT, and need it for WILLOW→STONE RIDGE. Never enter the collapsed mud or repeat a node.

**Solution:** ["JETTY", "FERRY HUT", "DRY BANK", "WILLOW", "STONE RIDGE", "CLINIC"]. Mud is excluded. The only clinic approach is via STONE RIDGE, requiring rope acquired at FERRY HUT. With one-way edges and no repeats, JETTY→FERRY HUT→DRY BANK→WILLOW→STONE RIDGE→CLINIC is unique.

**Hints:** The shortest-looking first step reaches the crossing without its required rope. / Visit FERRY HUT before WILLOW; the one-way chart leads from the hut through DRY BANK. / JETTY → FERRY HUT → DRY BANK → WILLOW → STONE RIDGE → CLINIC.

**State change:** mark p32 solved; retain evidence and inventory. The ridge carries you above the drowned path. Mara’s route did not require anyone to guess their way through the marsh.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p33 — The clinic’s order (order)

Location: `ch4_l2`. Requires: `p32`.

Clues: `ch4_l2_a`, `ch4_l2_c`.

Items: none. Rewards: recorded conclusion / progression.

Reconstruct the recorded triage sequence. Arrange the six historical cards by category priority, breaking ties only by arrival number. Use the board’s rules and the actual card fields. Every card appears once.

**Solution:** ["Vale", "Moss", "Hadi", "Cora", "Elva", "Petra"]. Primary category ranking and secondary arrival ranking produce Vale(1,BREATH),Moss(2,BREATH),Hadi(3,BLEED),Cora(4,BLEED),Elva(0,BONE),Petra(1,WALK). A global sort by arrival is invalid.

**Hints:** Sort into BREATH, BLEED, BONE and WALK groups before comparing arrival numbers. / BREATH contains Vale then Moss; BLEED contains Hadi then Cora. The earliest arrival overall is not necessarily treated first. / Vale → Moss → Hadi → Cora → Elva → Petra.

**State change:** mark p33 solved; retain evidence and inventory. The register order follows treatment priority, not arrival time. You avoid mistaking a medical sorting convention for a chronology.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p34 — The page and its absence (assembly)

Location: `ch4_l2`. Requires: `p33`.

Clues: `ch4_l2_b`, `ch4_l2_c`.

Items: `restored_register`. Rewards: recorded conclusion / progression.

Rejoin the clinic leaf to its surviving binding evidence. Combine the loose register leaf and binding stub. Preserve the tear as evidence of their original connection.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** The number alone is suggestive; fibres and thread holes confirm it. / Both pieces come from the clinic. / Combine Torn clinic leaf and Clinic binding stub.

**State change:** mark p34 solved; retain evidence and inventory. The register is authenticated by its physical join. Its categories refer to distinct people, not duplicated household totals.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p35 — A shelf among the leaves (code)

Location: `ch4_l3`. Requires: `p32`.

Clues: `ch4_l3_a`, `ch4_l3_b`.

Items: none. Rewards: recorded conclusion / progression.

Read Mara’s storage reference from the plant inventory. Find a three-digit shelf reference using three distinct greenhouse inventory numbers. Apply all constraints in Mara’s note: increasing order, middle three above first, total twelve. Enter the digits without spaces.

**Solution:** "147". Among increasing triples from {1,2,4,7}, only (1,4,7) has its middle three above its first and sum 12. Distinctness and increasing order eliminate permutations.

**Hints:** The available digits are 1, 2, 4 and 7; use only three and keep them increasing. / Only the pair 1 then 4 can begin the reference while leaving a larger third digit. The total then requires 7. / The shelf reference is 147.

**State change:** mark p35 solved; retain evidence and inventory. The indexed shelf contains Mara’s working notes. Her silence was a choice, and she acknowledges the hurt it caused.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p36 — The high-ground approach (routing)

Location: `ch4_l4`. Requires: `p35`.

Clues: `ch4_l4_a`, `ch4_l4_c`.

Items: none. Rewards: recorded conclusion / progression.

Trace the remaining safe path to the refuge. Use the coordinate grid and height survey to reach REFUGE from HUT. Move only between sites sharing a grid side; do not enter any site at or below water height 3. Do not repeat sites.

**Solution:** ["HUT", "NORTH BANK", "STONE BRIDGE", "GARDEN", "REFUGE"]. Safe nodes have heights >3: HUT, NORTH BANK, STONE BRIDGE, GARDEN, REFUGE. Their side-adjacency graph is a single chain in exactly that order.

**Hints:** First exclude RIDGE, TOWER and TIDAL CUT: equal to the water level is not safe. / HUT’s only dry neighbour is NORTH BANK. Continue across the row at y=1. / HUT → NORTH BANK → STONE BRIDGE → GARDEN → REFUGE.

**State change:** mark p36 solved; retain evidence and inventory. The route passes the unofficial memorial. It is a place Mara wanted you to see before hearing her explanation.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p37 — The unaddressed names (code)

Location: `ch4_l5`. Requires: `p34`, `p36`.

Clues: `ch4_l2_b`, `ch4_l5_a`, `ch4_l5_b`, `ch4_l5_c`.

Items: none. Rewards: recorded conclusion / progression.

How many people would the city omit by counting only patients and named family members? The monument’s total includes everyone. Subtract the register’s patient and family groups to recover the omitted lodger category; check the result against the names on the garden stones. Use the transcribed names, not the number of weathered stones.

**Solution:** "6". The fixed memorial total 23 minus 8 patients and 9 family members leaves 6 lodgers. Their six individual names independently check the recovered category.

**Hints:** The full memorial contains 23 people. The city’s two categories cover 8 and 9. / The counted groups total 17. Subtract that from 23, then check the separate lodger names. / 23 − 8 − 9 = 6. Enter 6.

**State change:** mark p37 solved; retain evidence and inventory. Six lodgers would disappear if an address were treated as a condition for being counted. You cross-check each name, retaining twenty-three people in the corrected register.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p38 — A friend at the door (sequence)

Location: `ch4_l6`. Requires: `p36`.

Clues: `ch4_l6_a`.

Items: none. Rewards: recorded conclusion / progression.

Give the refuge’s complete visitor signal. Use KNOCK and PAUSE, including both separating pauses. Do not insert a pause between the two middle knocks.

**Solution:** ["KNOCK", "PAUSE", "KNOCK", "KNOCK", "PAUSE", "KNOCK"]. Compare the cited evidence using the explicit rule. Intended answer: ['KNOCK', 'PAUSE', 'KNOCK', 'KNOCK', 'PAUSE', 'KNOCK'].

**Hints:** The pattern has three groups: one, two, one. / Separate the groups with PAUSE. / KNOCK → PAUSE → KNOCK → KNOCK → PAUSE → KNOCK.

**State change:** mark p38 solved; retain evidence and inventory. Mara recognises the signal. When she sees you, the practiced explanation leaves her face. “I am sorry,” she says first.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p39 — Keep the original (assembly)

Location: `ch4_l6`. Requires: `p38`.

Clues: `ch4_l3_c`, `ch4_l6_b`, `ch4_l6_c`.

Items: `protected_tracing`. Rewards: recorded conclusion / progression.

Protect Mara’s tracing for the return journey. Combine the original tracing with archival backing. The missing authorisation flap remains a gap in the evidence; do not fill it by assumption.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** Transparent paper needs neutral support. / The glasshouse has backing prepared with matching registration marks. / Combine Mara’s original tracing and Archival backing.

**State change:** mark p39 solved; retain evidence and inventory. The instruction survives as an original tracing with its limits stated. It proves a destructive purpose; its author still requires independent identification.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p40 — People, not capacity (deduction)

Location: `ch4_l6`. Requires: `p31`, `p32`, `p33`, `p34`, `p35`, `p36`, `p37`, `p38`, `p39`, `p30`.

Clues: `ch4_l1_c`, `ch4_l2_c`, `ch4_l4_b`, `ch4_l4_c`, `ch4_l6_c`.

Items: none. Rewards: recorded conclusion / progression.

Why does the council’s evacuation return fail? Compare the actual evacuation plan, the filed return, the clinic register and the ferry record.

**Solution:** "It counted empty beds instead of verifying that residents had left". Compare the cited evidence using the explicit rule. Intended answer: It counted empty beds instead of verifying that residents had left.

**Hints:** The plan required people to be checked at several stages. / The filed return records available beds, not people moved. / Choose the substitution of empty beds for verified residents.

**State change:** mark p40 solved; retain evidence and inventory. The return transformed accommodation capacity into a false claim of completed evacuation. The people in the register were still there. Mara agrees to return as a witness, while Nadi carries a separate copy of the evidence.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

## ch5: The Price of Silence

Follow the records from a machine to a decision.

### p41 — The city’s public promises (hidden)

Location: `ch5_l1`. Requires: `p40`.

Clues: `ch5_l1_a`, `ch5_l1_b`, `ch5_l1_c`.

Items: none. Rewards: recorded conclusion / progression.

Collect the public rules and the surviving petition. Inspect the destruction notice, occupancy petition and sitting rules. These documents establish a lawful route for preserving the case.

**Solution:** "found". Compare the cited evidence using the explicit rule. Intended answer: found.

**Hints:** The square contains a deadline, a prior acknowledgement and a procedure. / Read all three posted documents. / Examine each civic-square hotspot, then confirm.

**State change:** mark p41 solved; retain evidence and inventory. Rusk acknowledged occupied houses before the flood. The public rules still permit the originals to be deposited before destruction.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p42 — Who could order the water? (deduction)

Location: `ch5_l2`. Requires: `p41`.

Clues: `ch5_l2_a`, `ch5_l2_b`.

Items: none. Rewards: recorded conclusion / progression.

Which office held authority to authorise the diversion? Separate authorising, operating, transmitting and maintaining. Use the authority ledger rather than a character’s social status.

**Solution:** "The magistrate authorised; the engineer operated". Compare the cited evidence using the explicit rule. Intended answer: The magistrate authorised; the engineer operated.

**Hints:** A machine operator and an authorising officer need not be the same person. / The ledger reserves diversion authority to the magistrate. / Choose the magistrate authorising and the engineer operating.

**State change:** mark p42 solved; retain evidence and inventory. The chain of responsibility includes both Rusk’s authority and Elian’s act. Neither can be substituted for the other.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p43 — The land beneath the water (order)

Location: `ch5_l3`. Requires: `p41`.

Clues: `ch5_l1_b`, `ch5_l3_a`, `ch5_l5_a`.

Items: none. Rewards: recorded conclusion / progression.

Reconstruct the title transaction. Reconstruct the six title events using the deed conditions and the ledger’s relative-position annotation. “Exactly two positions before” means one event between them. Every event is used once.

**Solution:** ["Tenant claims lodged", "Foundry option purchased", "Option assigned", "Emergency clearance declared", "Claims extinguished", "Land transferred"]. The distance constraint plus clearance adjacency forces Assignment–Clearance–Extinguishment. Lodging precedes Purchase precedes Assignment, and Transfer follows Extinguishment. The six-event total order is unique.

**Hints:** Clearance must sit immediately before extinguishment. Assignment is exactly two places before extinguishment. / That forces Assignment → Clearance → Extinguishment; purchase and lodging precede it, and transfer follows. / Tenant claims lodged → Foundry option purchased → Option assigned → Emergency clearance declared → Claims extinguished → Land transferred.

**State change:** mark p43 solved; retain evidence and inventory. The flood was used to remove an obstacle to a transaction already planned. The transaction did not arise only as a response to disaster.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p44 — A seal and its limits (assembly)

Location: `ch5_l3`. Requires: `p43`.

Clues: `ch5_l3_b`, `ch5_l3_c`, `ch5_l6_b`.

Items: `seal_comparison`. Rewards: recorded conclusion / progression.

Authenticate the office seal on the original counterfoil. Combine the wax impression and seal-register rubbing. This proves the office seal; retain the separate signature evidence for personal attribution.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** A distinctive defect can authenticate an impression. / Align the crescent chip in the two records. / Combine Wax seal impression and Seal register rubbing.

**State change:** mark p44 solved; retain evidence and inventory. The impression is genuine. You explicitly avoid claiming that a seal alone proves who held it.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p45 — A case a reader can follow (order)

Location: `ch5_l4`. Requires: `p42`, `p44`.

Clues: `ch5_l1_c`, `ch5_l4_a`.

Items: none. Rewards: recorded conclusion / progression.

Arrange Sera’s five account blocks. Use the public sitting’s causal order: event, time, authority, purpose, consequence. Every block is used once.

**Solution:** ["ACT", "TIME", "AUTHORITY", "PURPOSE", "CONSEQUENCE"]. Compare the cited evidence using the explicit rule. Intended answer: ['ACT', 'TIME', 'AUTHORITY', 'PURPOSE', 'CONSEQUENCE'].

**Hints:** Begin with the event before explaining who ordered it. / Time follows act; consequence follows purpose. / ACT → TIME → AUTHORITY → PURPOSE → CONSEQUENCE.

**State change:** mark p45 solved; retain evidence and inventory. The accusation becomes a sequence of claims with sources, rather than an atmosphere of suspicion.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p46 — Print only what you can prove (assembly)

Location: `ch5_l4`. Requires: `p45`.

Clues: `ch5_l4_a`, `ch5_l4_b`, `ch5_l4_c`.

Items: `publication_proof`. Rewards: recorded conclusion / progression.

Prepare the publication proof with its citations. Combine the corrected type forme and proofing sheet. The original records remain separate from this distributable copy.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** Sera has set the text; the sheet holds its citations. / Take the forme and the ruled sheet from the print shop. / Combine Corrected type forme and Proofing sheet.

**State change:** mark p46 solved; retain evidence and inventory. Sera approves the proof. It says Elian operated the bypass, Rusk authorised it, and twenty-three people died; each statement has its own source.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p47 — The clear-title premium (code)

Location: `ch5_l5`. Requires: `p43`.

Clues: `ch5_l5_a`, `ch5_l5_b`.

Items: none. Rewards: recorded conclusion / progression.

Calculate the private gain shown by the acquisition account. Subtract the option cost and legitimate survey fee from the transfer payout. Enter the remaining number of crowns.

**Solution:** "150". Compare the cited evidence using the explicit rule. Intended answer: 150.

**Hints:** Start from the 310-crown payout. / Subtract 120 and then 40. / 310 − 120 − 40 = 150. Enter 150.

**State change:** mark p47 solved; retain evidence and inventory. The unexplained premium is 150 crowns, paid to Rusk’s trust. The ledger ties his benefit to the cleared title.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p48 — Relief for whom? (deduction)

Location: `ch5_l5`. Requires: `p47`.

Clues: `ch5_l5_a`, `ch5_l5_b`, `ch5_l5_c`.

Items: none. Rewards: recorded conclusion / progression.

What does the premium establish? Use the trust ledger and accountant’s note. Do not confuse financial benefit with independent proof of the signed order.

**Solution:** "Rusk personally benefited from the land transfer". Compare the cited evidence using the explicit rule. Intended answer: Rusk personally benefited from the land transfer.

**Hints:** The beneficiary is named and the relief classification was rejected. / The ledger establishes benefit, while other documents establish the act. / Choose Rusk’s personal benefit from the land transfer.

**State change:** mark p48 solved; retain evidence and inventory. You record motive precisely. The money supports the case without being asked to prove what only the order can prove.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p49 — The unbroken dispatch (order)

Location: `ch5_l6`. Requires: `p44`.

Clues: `ch5_l2_c`, `ch5_l6_a`, `ch5_l6_b`.

Items: none. Rewards: recorded conclusion / progression.

Reconstruct the original instruction’s chain of custody. Order receipt cards A–F by matching each recipient to the next sender. Start with the unsigned draft from the Works drafting room; end at the Public vault. Each card appears once. This tracks one document, not the later evacuation return.

**Solution:** ["E", "C", "A", "B", "D", "F"]. The unique document chain is Works drafting room→Rusk→Olan→Vey→Elian→Records office→Public vault. Receipt labels along it are E,C,A,B,D,F.

**Hints:** Find the only card whose sender is the Works drafting room. Its recipient tells you the next sender to seek. / E reaches Rusk, so C follows; C reaches Olan, so A follows. Continue matching endpoints. / E → C → A → B → D → F.

**State change:** mark p49 solved; retain evidence and inventory. The originals and linked receipts connect the instruction to Rusk’s hand and Elian’s receipt. Mara’s tracing is corroborated, not left to stand alone.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p50 — The price of silence (deduction)

Location: `ch5_l6`. Requires: `p41`, `p42`, `p43`, `p44`, `p45`, `p46`, `p47`, `p48`, `p49`, `p40`.

Clues: `ch5_l1_b`, `ch5_l2_b`, `ch5_l2_c`, `ch5_l5_b`, `ch5_l6_b`, `ch5_l6_c`.

Items: none. Rewards: recorded conclusion / progression.

Which account of intent survives all the evidence? Join Rusk’s occupancy acknowledgement, the signed destructive instruction, the false-return direction and his private gain.

**Solution:** "Rusk knowingly ordered diversion to destroy claims and secure the transfer". Compare the cited evidence using the explicit rule. Intended answer: Rusk knowingly ordered diversion to destroy claims and secure the transfer.

**Hints:** Rusk acknowledged occupied houses and then forbade household checks. / His instruction names the records store and acquisition; the trust records his benefit. / Choose the knowing diversion to destroy claims and secure the transfer.

**State change:** mark p50 solved; retain evidence and inventory. The case now identifies action, authority and purpose without relying on a single confession. The originals must enter the public record, and copies must survive beyond one office’s reach.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

## ch6: A City That Remembers

Make a record that cannot be erased by one locked door.

### p51 — More than one copy (assembly)

Location: `ch6_l1`. Requires: `p50`.

Clues: `ch6_l1_a`, `ch6_l1_b`, `ch6_l1_c`.

Items: `sealed_copies`. Rewards: recorded conclusion / progression.

Prepare the independent public copies for distribution. Combine the verified copy bundle and waterproof dispatch wrap. Keep the originals separate for deposition.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** Copies preserve access; the original preserves physical evidence. / Nadi’s wraps protect Sera’s bundles. / Combine Verified copy bundle and Waterproof dispatch wrap.

**State change:** mark p51 solved; retain evidence and inventory. The island, library and print shop each receive a complete checked set. One closed office can no longer erase the case.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p52 — What each witness knows (order)

Location: `ch6_l2`. Requires: `p51`.

Clues: `ch6_l2_a`, `ch6_l2_b`, `ch6_l2_c`.

Items: none. Rewards: recorded conclusion / progression.

Arrange the witness accounts in the planned causal order. Arrange six witnesses under all scheduling conditions from the scope cards and corrected draft. “Immediately” means adjacent positions. Every witness appears once.

**Solution:** ["Rowan", "Mara", "Olan", "Ada", "Elian", "Sera"]. Rowan–Mara is adjacent; Olan lies after Mara and before Ada; Ada–Elian is adjacent; Sera is last. These constraints fill all six slots uniquely.

**Hints:** Form the two adjacent pairs Rowan→Mara and Ada→Elian. / Olan goes between Mara and Ada; Sera closes. This fixes the two pairs’ order. / Rowan → Mara → Olan → Ada → Elian → Sera.

**State change:** mark p52 solved; retain evidence and inventory. The witnesses agree on their limits as well as their observations. Their differences no longer provide a convenient place to hide the whole event.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p53 — The relay’s safe path (sequence)

Location: `ch6_l3`. Requires: `p51`.

Clues: `ch6_l3_a`, `ch6_l3_b`.

Items: none. Rewards: recorded conclusion / progression.

Find the shortest pulse sequence from COLD to READY. Use both halves of the relay transition table. Begin at COLD; each selected pulse changes the current state. Submit the FEWEST pulses that reach READY. Wrong attempts are safe simulations and consume no actual resources.

**Solution:** ["SHORT", "SHORT", "LONG", "SHORT", "LONG"]. READY has one incoming edge from CHECK via LONG, CHECK one from BRIDGED via SHORT, BRIDGED one from CHARGED via LONG. The shortest COLD-to-CHARGED path is SHORT,SHORT. Thus the unique shortest complete sequence is SHORT,SHORT,LONG,SHORT,LONG.

**Hints:** Work backward from READY: it can only be reached by LONG from CHECK. CHECK is reached by SHORT from BRIDGED. / The shortest path to BRIDGED is COLD→PRIMED→CHARGED→BRIDGED. Avoid VENTED and OVERLOAD loops. / SHORT → SHORT → LONG → SHORT → LONG. States: PRIMED, CHARGED, BRIDGED, CHECK, READY.

**State change:** mark p53 solved; retain evidence and inventory. Both contacts answer. The outer wards receive the same public notice as the city centre.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p54 — Count the sources (code)

Location: `ch6_l3`. Requires: `p53`.

Clues: `ch6_l3_b`, `ch6_l3_c`.

Items: none. Rewards: recorded conclusion / progression.

Calculate the notice’s packet check digit. Use the five source packet numbers in their recorded causal order. Multiply each by position 1–5, sum, then enter the single digit 0–9 that makes the total divisible by ten. Do not simply enter the sum’s last digit.

**Solution:** "1". Weighted sum =3+14+6+16+30=69; unique digit d in [0,9] with (69+d)%10=0 is 1.

**Hints:** The ordered weighted products are 3×1, 7×2, 2×3, 4×4 and 6×5. / Their sum is 69. You need a digit that takes it to the next multiple of ten. / 69 + 1 = 70. Enter 1.

**State change:** mark p54 solved; retain evidence and inventory. The transmitted source list is complete. Recipients can ask for the same five evidence packets instead of trusting an unsupported summary.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p55 — A witnessed safe state (assembly)

Location: `ch6_l4`. Requires: `p52`.

Clues: `ch6_l4_a`, `ch6_l4_b`.

Items: `isolation_set`. Rewards: recorded conclusion / progression.

Pair the bypass isolation hardware with its signed record. Combine the gate isolation pin and witnessed isolation tag. This records the already-secured real gate and supports the procedural reconstruction.

**Solution:** "assembled". Compare the cited evidence using the explicit rule. Intended answer: assembled.

**Hints:** Physical restraint and an accountable record serve different purposes. / The pin and tag belong together. / Combine Gate isolation pin and Witnessed isolation tag.

**State change:** mark p55 solved; retain evidence and inventory. The secured bypass has both a physical interlock and a witnessed record. Future operators can see who checked it and what was checked.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p56 — The limit of this hearing (choice)

Location: `ch6_l4`. Requires: `p55`.

Clues: `ch6_l4_c`, `ch6_l5_c`.

Items: none. Rewards: recorded conclusion / progression.

What action can the council properly take under the emergency charter? Choose the response within the charter’s authority. A referral preserves the distinction between administrative removal and a criminal trial.

**Solution:** "Withdraw emergency authority, preserve evidence and refer the case". Compare the cited evidence using the explicit rule. Intended answer: Withdraw emergency authority, preserve evidence and refer the case.

**Hints:** The charter allows withdrawal of delegated powers. / Criminal responsibility is reserved for the outside court. / Choose withdrawal, preservation and referral.

**State change:** mark p56 solved; retain evidence and inventory. The proposed decision has a defined legal purpose inside the fiction: protect the city and the evidence while an outside court hears the case.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p57 — The five parts of the case (order)

Location: `ch6_l5`. Requires: `p52`, `p54`, `p56`.

Clues: `ch6_l5_a`.

Items: none. Rewards: recorded conclusion / progression.

Present the evidence board as a causal argument. Arrange all five claims. Use the public sitting’s established order, with consequences following the act, timing, authority and purpose.

**Solution:** ["Bypass diversion", "00:14 meridian", "Rusk’s signed authority", "Destruction for acquisition", "Twenty-three named deaths"]. Compare the cited evidence using the explicit rule. Intended answer: ['Bypass diversion', '00:14 meridian', 'Rusk’s signed authority', 'Destruction for acquisition', 'Twenty-three named deaths'].

**Hints:** Use ACT, TIME, AUTHORITY, PURPOSE, CONSEQUENCE. / The time comes immediately after the physical act. / Bypass diversion → 00:14 meridian → Rusk’s signed authority → Destruction for acquisition → Twenty-three named deaths.

**State change:** mark p57 solved; retain evidence and inventory. Each claim is supported by a different part of the record. The whole case does not collapse if one witness is frightened or one copy is lost.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p58 — The tide defence (deduction)

Location: `ch6_l5`. Requires: `p57`.

Clues: `ch6_l5_a`, `ch6_l5_b`.

Items: none. Rewards: recorded conclusion / progression.

Why does Rusk’s exceptional-tide explanation fail? Choose the rebuttal supported by the physical route, independent time and original instruction.

**Solution:** "Upstream diversion preceded the tide and followed a signed destructive order". Compare the cited evidence using the explicit rule. Intended answer: Upstream diversion preceded the tide and followed a signed destructive order.

**Hints:** A natural tide cannot explain an upstream pressure rise before its own turn. / The machine evidence agrees with a signed order, not merely a suspicion. / Choose upstream diversion preceding the tide under a signed destructive order.

**State change:** mark p58 solved; retain evidence and inventory. Rusk asks for the originals. The chair answers that they have already been deposited, and that copies are being read on both shores.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p59 — A correction that can be read (order)

Location: `ch6_l6`. Requires: `p58`.

Clues: `ch6_l6_a`, `ch6_l6_b`.

Items: none. Rewards: recorded conclusion / progression.

Correct Tomas’s entry without hiding the original institutional failure. Follow the archive correction rule, using every step once. Preserve the old writing beneath a single readable cancellation.

**Solution:** ["Retain original", "Rule through false claim", "Add sourced correction", "Date and sign"]. Compare the cited evidence using the explicit rule. Intended answer: ['Retain original', 'Rule through false claim', 'Add sourced correction', 'Date and sign'].

**Hints:** Do not begin by erasing the entry. / The sourced replacement comes after the readable cancellation. / Retain original → Rule through false claim → Add sourced correction → Date and sign.

**State change:** mark p59 solved; retain evidence and inventory. Your father’s name is corrected in public. The old accusation remains legible as evidence of what the city once chose to believe.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

### p60 — The public record (deduction)

Location: `ch6_l6`. Requires: `p51`, `p52`, `p53`, `p54`, `p55`, `p56`, `p57`, `p58`, `p59`, `p50`.

Clues: `ch6_l6_a`, `ch6_l6_b`, `ch6_l6_c`.

Items: none. Rewards: recorded conclusion / progression.

What does the finished record owe the city? Choose the conclusion that preserves the evidence, names the people harmed and leaves responsibility open to a proper hearing.

**Solution:** "Keep the originals, publish the sources and name every person lost". Compare the cited evidence using the explicit rule. Intended answer: Keep the originals, publish the sources and name every person lost.

**Hints:** The investigation began with one name and uncovered twenty-three. / A durable correction needs sources as well as a conclusion. / Choose keeping originals, publishing sources and naming every person lost.

**State change:** mark p60 solved; retain evidence and inventory. Mara closes the register only after the last name has been read. Outside, the midnight bell’s repaired mechanism waits for its next honest hour.

**Recovery:** revisit cited locations and review recorded evidence. Retry the deduction subject to its hint budget and submission cooldown; story progress and collected evidence are retained.

## Item sources and combinations

| Item | Obtainable source |
|---|---|
| tissue — Repair tissue | ch1_l3_c |
| paste — Wheat paste | ch1_l4_a |
| repair_kit — Paper repair kit | recipe r01 (tissue + paste) |
| bell_cord — Bell cord | ch1_l5_c |
| bell_hook — Brass bell hook | ch1_l6_a |
| bell_pull — Repaired bell pull | recipe r02 (bell_cord + bell_hook) |
| coupling — Bypass coupling | ch2_l2_b |
| handle — Insulated crank | ch2_l3_a |
| bypass_tool — Bypass test crank | recipe r03 (coupling + handle) |
| key_blank — Gate-key tracing | ch2_l5_a |
| key_plate — Lock profile plate | ch2_l5_b |
| key_comparison — Key comparison mount | recipe r04 (key_blank + key_plate) |
| lens — Viewing lens | ch3_l1_a |
| viewer_frame — Viewer frame | ch3_l2_c |
| plate_viewer — Assembled plate viewer | recipe r05 (lens + viewer_frame) |
| clock_spring — Clock spring | ch3_l5_a |
| clock_spindle — Clock spindle | ch3_l5_b |
| clock_model — Clock demonstration model | recipe r06 (clock_spring + clock_spindle) |
| register_leaf — Torn clinic leaf | ch4_l2_b |
| register_stub — Clinic binding stub | ch4_l2_c |
| restored_register — Rejoined clinic register | recipe r07 (register_leaf + register_stub) |
| tracing — Mara’s original tracing | ch4_l6_b |
| backing — Archival backing | ch4_l3_c |
| protected_tracing — Protected instruction tracing | recipe r08 (tracing + backing) |
| seal_impression — Wax seal impression | ch5_l3_b |
| seal_register — Seal register rubbing | ch5_l3_c |
| seal_comparison — Authenticated seal comparison | recipe r09 (seal_impression + seal_register) |
| type_form — Corrected type forme | ch5_l4_a |
| proof_sheet — Proofing sheet | ch5_l4_b |
| publication_proof — Verified publication proof | recipe r10 (type_form + proof_sheet) |
| copy_bundle — Verified copy bundle | ch6_l1_a |
| dispatch_wrap — Waterproof dispatch wrap | ch6_l1_b |
| sealed_copies — Sealed public copies | recipe r11 (copy_bundle + dispatch_wrap) |
| locking_pin — Gate isolation pin | ch6_l4_a |
| lock_tag — Witnessed isolation tag | ch6_l4_b |
| isolation_set — Witnessed isolation set | recipe r12 (locking_pin + lock_tag) |

## Test evidence and limitations

Run `python3 tools/audit_content.py --allow-missing-art` for dependency/content validation and `tools/game.sh verify` for engine, state/save and package checks. Record actual results in the QA report. This generated map alone does not prove fairness, illustration alignment, native Windows behavior, first-time duration or a complete GUI playthrough. In particular, readable hotspot labels are an accessibility feature, not evidence that final hidden-object art is legible.

## Audiovisual milestone — 14 November 2026

The audiovisual pass preserves all existing puzzle, item, clue and chapter
dependencies. The 98 voice entries are optional presentations of source text;
missing recordings, muted channels and reduced motion never gate a clue,
conversation, puzzle, save or ending. Tension/resolution cues follow existing
puzzle state, and decorative mechanisms do not change evidence values.

## Opening audio revision 3

The thirteen selected audio cues add feedback to the isolated Dispatch Office
search only. They do not change its seventeen-clue completion condition, grant
extra finds, alter the proposed chapter rewards or modify campaign progression.
Completion sound timing follows the reward; audio muting never blocks a find
or save. See `OPENING_AUDIO_PREVIEW_REPORT.md`.

## Campaign search gates (14 November 2026)

Each room’s three evidence entries now come from completing its visible hidden-object
list, not from three exposed clue buttons. Room investigations require their local
search to be complete. Each chapter’s final deduction additionally requires all six
room searches. Original clue, inventory, recipe and earlier-deduction dependencies
remain in force. Five legacy `hidden` confirmation tasks resolve automatically when
the corresponding search and prerequisites are complete. Forward and reverse full
state traversals exercise the combined graph, including save/load boundaries.
