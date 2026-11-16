# Picture-first interface and clearer case

14 November 2026. Follow-up to the owner's Archive Vestibule screenshot and
request for a vertical item rail.

The picture uses the available screen beside a narrow right rail. The entire
painting remains visible at Fit, with no cropping or navigation over targets.
The rail holds a single vertical checklist, room title, short lead, five
navigation icons and zoom/fit/hint controls. Tooltips, keyboard focus and
accessible names explain the icons. Larger text widens the rail. Widescreen
windows expand the viewport instead of keeping the former fixed outer bars.

The opening now states who Iona is, why Mara's disappearance matters and what
she must establish about the flood. Each chapter opens with its central
question and task. The original letter and chapter prose remain available on
demand, along with their existing voice controls. No recordings were created.

The compass (C) opens the case overview and an actionable next step. The
notebook opens this room's evidence and investigations; map, inventory and
pause use their own icons. All investigations remain accessible through J.
Every room has a purpose and a discovery explanation in `content/story-guide.json`.
Discovery summaries appear only after a search is cleared; chapter recaps
require their final deduction. The mission changes when Mara is found and when
the case is resolved. Guidance never supplies the puzzle's answer.

Progress, target geometry, artwork and sound mixes are unchanged. Existing
hidden-object campaign saves load into this revision, including partial lists.
No restart is needed: C opens the new explanation during an existing case.
The previous campaign packages remain available as rollback copies.

## Verification

`tests/test_case_guide.gd` follows actual available actions from a new case to
all six chapter conclusions: 1,136 checks and 103 guided actions, with no
progress mutation when asking for guidance and no unearned room discoveries.

`tests/test_search_layout.gd` checks every room at three logical window sizes
(960×600, 1280×800 and 1920×1080), both text sizes, list visibility, nonoverlapping
picture/rail, controls, icon dispatch, hint countdown and briefing text. The
headless layout and native Compatibility renderer runs each pass 3,921 checks.
Window-manager-adjusted native dimensions are recorded separately from requested
sizes in the screenshot metrics. Fullscreen is captured separately at 1920×1080.

The existing search tests still cover all 507 click targets, hints, repeat
clicks, persistence, rewards and keyboard zoom. `tools/game.sh verify` is the
required complete content/progression/UI/package check; its final results and
exact source revision are stored in `builds/verification.json`.

This is a development revision. The existing full-playthrough, blind pacing,
voice-production and native-Windows acceptance gaps remain; Wine checks do not
replace native Windows testing.
