# Detective update — 15 November 2026

This update implements the owner's approved navigation, inventory, challenge
and menu revisions across the existing six-chapter hidden-object campaign.

## Navigation and story

- A geographic map of Leth replaces the scroll of room illustrations. District
  pins open local room pins with search/investigation/completion states, a
  current-location marker and a travel card. Locked names remain concealed.
- One Casebook replaces the separate room-notes and next-mystery-step screens.
  Its room, chapter and story views retain evidence and completed recaps, while
  the primary action opens the ready investigation directly. A ready local
  investigation takes priority over preparing an item for another room.
- The title introduction explains the flood, Iona's return, Mara's disappearance
  and the threatened records. The title and pause menus each retain only the
  four requested actions. Removed manual-save, recovery/import and build-status
  menu handlers are absent from the game presentation. Distribution licence
  notices and internal automatic-save integrity protections remain.

## Inventory

The active inventory shows useful objects in a compact grid with an inspection
and combination panel. Combining two components replaces them with the result
in that view. Tools retire after their last unfinished use. Collection history
is retained separately so old saves and evidence provenance remain consistent.

## Detective rules

| Rule | Implemented value |
|---|---|
| Search budget | 8 minutes for 14 objects; 10 for the 17-object opening |
| Rapid guessing | Warn on 3 misses; 5 within 3 active seconds cost 10 seconds |
| Hints | At most 3 per attempt/puzzle; first free, next two 1 Insight each |
| Hint cooldown | 45 active seconds |
| Starting balance | 6 Insight |
| Search reward | 2 Insight on first completion, plus 1 without a click penalty |
| Deduction reward | 1 Insight on first successful non-hidden investigation |
| Time purchase | 1 Insight for 30 seconds, at most twice per search attempt |
| Wrong deductions | 3 changed wrong submissions within 60 active seconds impose a 10-second submission cooldown |
| Search expiry | Buy an unused extension or restart only this room |
| Retry | Reset the room's finds and clock; refund precisely its spent hints/extensions |

Deductions are untimed. Searches and hint cooldowns freeze behind opaque panels
and when the application loses focus. Keyboard auto-repeat does not manufacture
search misses. Completed work cannot be replayed to farm Insight. Timers,
cooldowns, purchases and reward claims persist in version-4 automatic saves.
Older valid saves remain supported; existing partial searches retain their
found objects and start their first timed attempt with a full clock. Existing
completions do not receive retroactive currency.

## Verification and limits

The owner's supplied `Sonder(chosic.com).mp3` is now the continuous background
music for the title and campaign. It is **Sonder by Purrple Cat**, from *City
Nights 2*. The source file is unchanged; playback uses a conservative gain,
the existing music slider and dialogue ducking, while environmental audio and
effects keep their separate controls. Room and panel changes do not restart it.
`MUSIC_LICENSE.txt` preserves attribution and the licence-source discrepancy
to resolve before a commercial release. Earlier original score assets remain
in the repository as history.

The verifier includes dedicated Detective state, Detective UI and map suites,
alongside the existing full story traversal, room target/layout, audio and
packaging checks. `builds/verification.json` records the exact exported revision
and actual results. Native Linux captures accompany the delivery.

These checks do not replace first-time difficulty/balance playtesting or a
complete manual playthrough. Native Windows gameplay, measured 6–10 hour
duration and human voice-performance review remain separate acceptance work. This update
does not spend provider credits or change Atlas, GCC or server services.
