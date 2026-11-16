# Chapter 1 artwork inspection

14 November 2026. All six original PNGs were inspected at source resolution;
the Ferry Landing and main UI were also reviewed at 1280×800 under the actual
Compatibility renderer. Paper, brass, teal shadow and amber-light treatment is
consistent. Portrait atlas cells and their biographies were inspected in-engine.

`content/hotspot-layout-ch1.json` replaces the original repeated three-point
layout with 18 positions on meaningful surfaces in the paintings. It is merged
into `content/hotspot-layout.json`, used by the runtime. Hidden-evidence sprites
are separately generated original art, overlaid at inspection points until found.

## Correspondence review and corrections

* Ferry Landing: prose, labels and p01 hints now use the depicted dispatch box,
  mooring post and landing steps. The third receipt is caught in a stone crack,
  not beneath an unpictured boat bench. Receipt sprites supply collectible art.
* Tide Office: the tide table and gauge are depicted; the missing-person notice
  is an inspection of the document area rather than readable background text.
* Archive: catalogue, shelves and supply chest support the clues. The former
  cupboard reference now consistently describes the depicted supply chest.
* Restoration: paper, bottles, press and implements are readable. Clue prose
  supplies exact written detail; decorative map marks must not be interpreted as
  the puzzle's literal solution.
* Boarding House: testimony uses the armchair area; the landlady is offscreen.
  The former coat-peg clue now describes the depicted key rack. Exact cord detail
  is supplied by the inspected item and its inventory art.
* Bell Tower: rope tackle and inspection documents support anchors. The hook is
  now found among spare rope tackle, without claiming a painted chalk outline
  on a sill. The small hook is not individually painted into the background.

These are production art/text integration issues, not blockers in the tested
state graph. Final polish should change specific scene details or equivalent
prose consistently; do not label this review as final hidden-object acceptance.
