# Full environment render review — 14 November 2026

All 36 locations were rendered natively at 1280 × 720 and visually inspected through chapter contact sheets, placement guides and selected full-size frames. Every location changed across animated poses; every reduced-motion frame pair was byte-identical. Eight confirmed placement defects were corrected in JSON and the eight changed scenes were captured again.

This is an **environment render and placement review**, not a full manual gameplay playthrough. Four deterministic poses (0, 1.25, 2.5 and 3.75 seconds) sample motion; they do not establish long-session comfort, perceived animation quality, performance on minimum hardware or a 6–10 hour playtime. This Linux review does not supply native Windows evidence.

## Reproducible method

`tools/review_all_environments.gd` uses the production `EnvironmentStage` and Compatibility shader without editing their code or the paintings. It records four native frames, a reduced-motion frame, a guide frame and a difference heatmap for each selected location. Chapter contact sheets show all 36. The guide key is cyan water, white water exclusions, green fog, gold lamp centers/radii and magenta mechanism rectangles. Orange marks steam origins.

Animation differences are counts from 57,600 sampled pixels (a four-pixel stride). Reduced-motion comparisons use the entire uncompressed image byte array, not the sampled difference count. Positive counts establish visible renderer changes, not artistic merit. The script forces native draws before readback because backgrounded windows can otherwise stop emitting automatic post-draw signals. The initial interrupted capture attempts are excluded; only completed reports below are evidence.

Run inside the repository, keeping editor/config/cache state local:

```bash
env XDG_CONFIG_HOME="$PWD/work/config" XDG_CACHE_HOME="$PWD/work/cache" XDG_DATA_HOME="$PWD/work/user-data" /home/jaco/.local/bin/godot4 --path . --resolution 1280x720 --script tools/review_all_environments.gd -- --output-dir="$PWD/work/env-full-review-reproduction"
```

For a subset, add `--locations=ch1_l4,ch2_l2` after `--`. The destination must stay under repository `work/`. The harness refuses headless image evidence. It writes a profile snapshot beside every completed `render-report.json`; existing review directories should be preserved and reproductions should use a new destination.

## Evidence provenance

The baseline is source revision `2129d5b5df1e34a97c1ec22d0298e72241542505`, Godot 4.7.2, Linux X11, OpenGL Compatibility on NVIDIA GeForce RTX 5070. Stage and shader code were unchanged during this review. Captures live under ignored `work/env-full-review/`; this document preserves the results for the player/source packages without treating review images as game assets.

The full 36-scene baseline was **not** overwritten or relabeled after corrections:

- `work/env-full-review/render-report.json`: 36 scenes, completed `2026-11-14T11:28:36Z`, profile SHA-256 `f0104c8af08d62612a4ab3223c0bb7f611a57541915e3ab114a7e31cca5af591`.
- `work/env-full-review/corrected/render-report.json`: 7 scenes, completed `2026-11-14T11:50:13Z`, profile SHA-256 `bccf73daf30a0b6e0f5d83719c2b5c2df89c400eca656c73e6896db52103f934`.
- `work/env-full-review/corrected-forum/render-report.json`: 1 scene, completed `2026-11-14T11:57:49Z`, profile SHA-256 `e6613697659278afe66de5d583a90ce1b1c01d03fe2d21533532ebb9873e539a`.

The second run covers only `ch1_l4`, `ch2_l2`, `ch2_l6`, `ch3_l4`, `ch4_l2`, `ch5_l1` and `ch5_l4`. The third covers only `ch6_l5`. Dictionary comparisons verified that each current scene profile exactly matches its most recent captured snapshot; the other 28 profiles match the original baseline. This is scoped recapture evidence, not a claim that all 36 scenes were rerendered with the final whole-file hash.

## Per-scene observations

The change count below is the difference from 0 to 3.75 seconds in the latest actual capture of that scene. “Identical” means the full reduced-motion frame pair matched byte for byte. Findings refer to visual inspection of placement guides and rendered frames; they do not certify every pixel or every interaction.

| Location | Changed samples | Reduced motion | Visual inspection / correction |
| --- | ---: | --- | --- |
| ch1_l1 — Ferry Landing | 5,133 | Identical | Post exclusions and hanging/desk lamps retained; no new defect. |
| ch1_l2 — Tide Office | 3,803 | Identical | Window surface islands and tide-gauge water remain local; lamps align. |
| ch1_l3 — Archive Vestibule | 1,987 | Identical | Small water islands stay between window dividers; lamps align. |
| ch1_l4 — Restoration Room | 1,968 | Identical | Corrected pendant glow from metal hood to bulb. |
| ch1_l5 — Boarding House | 3,218 | Identical | Window water, oil lamps and fireplace align with the painting. |
| ch1_l6 — Bell Tower | 3,181 | Identical | Water islands avoid rail posts; rope displacement remains an approximate illustration effect. |
| ch2_l1 — Pump Court | 2,094 | Identical | Doorway water is a small distant strip; no conspicuous native-frame deformation. |
| ch2_l2 — Sluice Gallery | 4,127 | Identical | Corrected four water masks that touched brass posts and diagonal rails. |
| ch2_l3 — Machine Room | 4,031 | Identical | Water avoids the upper bridge/window; piston/steam remain local. Flywheel is moving highlights. |
| ch2_l4 — Workers’ Kitchen | 1,787 | Identical | Window water, kitchen fixtures and kettle steam align. |
| ch2_l5 — Lockkeeper’s Cabin | 2,426 | Identical | Water islands avoid central window dividers; lamps align. |
| ch2_l6 — Spillway Overlook | 2,769 | Identical | Moved the lower water island below the foreground cable. |
| ch3_l1 — Observatory Steps | 1,358 | Identical | Water behind the terrace and the three lamp centers align. |
| ch3_l2 — Transit Hall | 1,704 | Identical | Window water avoids telescope/evidence; visible fixtures align. |
| ch3_l3 — Plate Darkroom | 831 | Identical | Safelight regions align; no water deformation applied to plate evidence. |
| ch3_l4 — Signal Loft | 2,163 | Identical | Moved fog off interior flags/wood into left-window background. |
| ch3_l5 — Clock Workshop | 1,433 | Identical | Water islands avoid window bars; pendulum displacement is local and clock faces remain unchanged. |
| ch3_l6 — Meridian Roof | 4,394 | Identical | Water bands leave the meridian monument and terrace still; lanterns align. |
| ch4_l1 — Reed Jetty | 6,893 | Identical | Surface islands leave jetty posts and reeds still; boat motion remains subtle. |
| ch4_l2 — Abandoned Clinic | 1,413 | Identical | Trimmed water clear of the brass armillary rim. |
| ch4_l3 — Glasshouse | 1,790 | Identical | Water islands follow the narrow channel; lamp aligns. |
| ch4_l4 — Survey Hut | 1,853 | Identical | Window water and survey-hut lamps align. |
| ch4_l5 — Memorial Garden | 9,708 | Identical | Pond surface islands avoid its stone rim; lantern centers align. |
| ch4_l6 — Island Refuge | 2,230 | Identical | Water islands and room/fireplace fixtures align. |
| ch5_l1 — Civic Square | 4,868 | Identical | Relocated small water island above the foreground chain. |
| ch5_l2 — Council Chamber | 2,545 | Identical | Window water and selected council-room fixtures align. |
| ch5_l3 — Deed Vault | 2,406 | Identical | Water islands avoid the foreground rail posts; pendant aligns. |
| ch5_l4 — Print Shop | 3,692 | Identical | Shortened water island to protect paintbrush tips. |
| ch5_l5 — Counting Room | 1,094 | Identical | Water islands remain between window dividers; two fixtures align. |
| ch5_l6 — Dispatch Station | 1,216 | Identical | No water distortion; indicator motion and lamp centers remain local. |
| ch6_l1 — Dawn Quay | 3,031 | Identical | Quay water remains outside ferry/quay silhouettes; lamps align. |
| ch6_l2 — Witness Room | 1,649 | Identical | Small window-water islands and room fixtures align. |
| ch6_l3 — Relay House | 1,765 | Identical | Water avoids the roof; relay movement and fixtures remain local. |
| ch6_l4 — Gate Crown | 1,300 | Identical | Water islands leave rail posts and locked gate machinery still. |
| ch6_l5 — Public Forum | 1,949 | Identical | Trimmed right water mask beyond a vertical window mullion. |
| ch6_l6 — Memory Room | 1,276 | Identical | Window water and interior lamps align; desk evidence stays still. |

## Corrections and remaining limits

For this environment review, only `content/environment-effects.json` changed in production: one pendant center, five water-region layouts, the Public Forum's right water island and the Signal Loft fog placement. Story, puzzles, hotspots, save formats, source paintings, engine script and shader were untouched. The environment structural/state suite passed 1,166 assertions after the first seven corrections; final package verification is recorded separately in `builds/verification.json` after the complete change set.

The review closes the previously unreviewed 32-scene native placement sample. It does **not** close the broader animation quality gate. Fog still uses soft rectangular bands rather than painted depth masks; subtle mechanical displacement is not a separated character/mechanical rig. Diagonal ropes and very small distant water details would benefit from finer masks in a subsequent illustration pass. The flywheel has animated highlights rather than separately rotating spokes. Continuous motion, comfort, lower-powered GPUs, alternate resolutions, character/conversation staging and native Windows still require further testing. No complete manual playthrough, blind duration measurement or finished-game claim follows from these render comparisons.
