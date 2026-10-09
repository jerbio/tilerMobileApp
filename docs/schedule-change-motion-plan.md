# Schedule-Change Motion — Daily List & Day Grid

Status: **Plan only, nothing implemented.**
Scope: the Daily list view (`EnhancedTileBatch` / `EnhancedWithinNowBatch`) and the Day
grid view (`DayGridWidget`). Weekly/monthly views and the tile cast are out of scope.

## 1. Problem

When the schedule changes, users see *what the list looks like now*, not *what happened*.
For an app whose value is re-arranging time, the re-arrangement itself has to be readable:

> something changed → Tiler decided → **this** Tile moved from here to there → these
> other things adjusted because of it → here is what you gained.

The rule underneath everything below: **a Tile keeps its identity through a change.** A
moved Tile is never shown as "one disappears, another appears".

## 2. Where each view stands today

| Capability | Day grid (`dayGridWidget.dart`) | Daily list (`enhancedTileBatch.dart`) |
|---|---|---|
| Stable tile identity across updates | Yes — `ValueKey('day_$dayIndex/<uniqueId>')`, carousel not remounted (`dailyTileList.dart` `_carouselStructureSignature`) | Partly — `evaluateTileDelta` computes old→new index tuples, but list items are not keyed and the delta is never used for motion |
| Moved Tile animates position | Yes — `AnimatedPositioned`, 300 ms, `easeInOutCubic`, only while `mode == idle` | **No** — `ScrollablePositionedList` rebuilds by index; Tiles hard-cut |
| Resize animates height | Yes (no-snap rule 4) | No |
| Added Tile | Staggered enter, 40 ms/tile, capped at 400 ms (`_enterDelays`) | No |
| Removed Tile | 220 ms fade ghost at last spot (`_removingTiles`) | No |
| Travel connector morphs | Band animates geometry 300 ms (`travelBandWidget.dart`) | Connectors are rebuilt |
| Moved vs added vs removed told apart | Yes, but **all of them play at the same moment** | No |
| Tile moved to another day | Shows as a plain removal (fade-out) | Disappears |
| Tile moved off-screen | Slides out of the viewport and is gone | Disappears |
| Why it changed / what was gained | None | None |
| Undo | Not supported (out of scope) | Not supported (out of scope) |

What this means:
- **Grid**: the plumbing works; what's missing is *choreography*. Every delta plays in the same
  300 ms, so a re-optimize looks like the whole column shuffling.
- **List**: there's no motion at all. It needs basic movement before choreography can matter.

## 3. Shared foundation — a schedule diff (pure Dart, no UI)

Both views (and the summary chip) need one shared answer to *what changed*. Today the grid
diffs only add/remove (`_diffTiles`) and the list diffs only indices.

### 3.1 `ScheduleDelta` (new, e.g. `lib/services/scheduleDelta.dart`)

`ScheduleDelta.compute(before, after, {required Timeline day})` uses the
**whole-window** `subEvents` (not just the one day), keyed by `uniqueId`, and classifies:

| Kind | Rule | Motion family |
|---|---|---|
| `moved` | same id, same day, start differs, duration same | lift → move → settle |
| `resized` | same id, start same, duration differs | height animates; top edge stays put |
| `movedAndResized` | both | move, then resize as part of settling |
| `movedToOtherDay` | same id, day differs | edge handoff ("→ Tomorrow") |
| `movedFromOtherDay` | the reverse | enters from the edge, labelled |
| `added` / `removed` | id only on one side | the enter / exit we have today |
| `travelChanged` | travel duration/mode into a Tile changed | connector morph + amber flash |
| `freeTimeChanged` | free-slot minutes on the day, before vs after | green flash on a slot that grew |

It also returns:
- **Causal clusters**: Tiles grouped by which ones push which. Walk the Tiles in time order;
  a run of consecutive shifted Tiles with no gap between them is one cluster. If a cluster
  starts with a `travelChanged`, that's its cause. Clusters only decide the *order*.
- **Batches**: the changed Tiles in causal order (cluster by cluster, time order inside a
  cluster), cut into groups of **up to 3**. A batch fills to 3 even if that means taking
  Tiles from the next cluster, and a cluster bigger than 3 is split across batches. Batches
  play in sequence, and all Tiles in one batch move together. A cluster's cause (its travel
  change) plays at the start of the batch that holds the cluster's first Tile. Choreography
  timing is driven by batches.
- **Magnitude**: the number of affected Tiles and batches, used to pick a tier (§6).
- **Summary data** (`tilesMoved`, `freeMinutesDelta`, `travelUpdated`), used by the chip in §5.4.

This is pure logic and easy to test (`test/schedule_delta_test.dart`): same id with a new
start, cross-day moves, all-day/≥16 h Tiles excluded the same way `gridTiles()` excludes them,
third-party Tiles matched on `thirdpartyId` (via `uniqueId`) even when their `id` changes, noise filtering (a shift under 1 min is
not a move), and batching (7 changed Tiles → batches of 3, 3, 1; a 4-Tile cluster is split 3 + 1;
the cause stays with the batch holding its cluster's first Tile; 10+ Tiles → compressed tier).

### 3.2 Change origin — so background refreshes stay quiet

The full choreography should **only** run when the user should be watching the change. Add a
`ScheduleChangeOrigin` to the state the bloc emits after a change:

| Origin | Source in `schedule_bloc.dart` | Treatment |
|---|---|---|
| `tilerRevise` | `_onReviseSchedule` → `shuffleSchedule()` | Full choreography + summary chip |
| `userDrag` | grid drop → `EvaluateSchedule` | Immediate, physical; only the *knock-on* moves are choreographed |
| `userEdit` / `userAdd` | edit / add Tile flows | Choreograph knock-on moves, short chip |
| `refresh` | pull-to-refresh, polling, app resume | **Today's quiet motion only**: no lift, no dim, no chip |

Without this, a background poll that nudges one Tile by 2 minutes would get the full
"Tiler made a decision" treatment, and the motion would turn into noise.

`_onReviseSchedule` already passes `previousSubEvents` into `GetScheduleEvent`. Carry those
(or have each view keep its last-rendered snapshot) so the "before" side of the diff is the
schedule the user actually *saw*, not an in-between loading state.

### 3.3 Building on `ScheduleRevisionCubit`

`lib/bloc/schedule/schedule_revision_cubit.dart` already tracks the schedule's server
revision, the `(analysisId, evaluationId)` pair. `ScheduleBloc` owns it (`revisions`) and
calls `observe()` on every status it sees. It reports *that* the schedule changed, not
*what* changed, because it carries no sub-events. So it doesn't replace `ScheduleDelta`, but
it covers three things the plan otherwise had to build:

1. **Gate: only diff when the revision changes.** A view compares
   `ScheduleRevision.fromStatus(state.scheduleStatus)` with the revision of the snapshot it
   last rendered.
   - **Same revision → no delta, no motion.** This matters because the sub-event set also
     changes when nothing was rescheduled: the carousel loads more days (wider
     `lookupTimeline`), `LocalScheduleLoadedState` replays the cache, or
     `ScheduleLoadingState` echoes the previous sub-events. Without the gate, those would
     show up as `added` / `removed`.
   - **Different revision → compute `ScheduleDelta`** between the last-rendered snapshot and
     the new one, *limited to the time window both snapshots cover*.
   - **Unknown revision** (`!isKnown`: first load, tutorial) → no motion.
2. **Where the origin comes from.** `checkAfterChange(baseline:)` already uses the pattern
   the origin needs: record the revision before a change, then wait until it differs. Add a
   small pending-origin record in `ScheduleBloc` (not in the cubit, which stays generic).
   When a change starts (revise / shuffle / drag commit / edit / complete), store
   `(baselineRevision, origin)`. The first loaded state whose revision differs from that
   baseline gets that origin and clears the record. A revision change that no pending
   change claims (poll, `recover()` on resume, an edit made on another device) is `refresh`
   and stays quiet. Clear stale records with the same `_generation` / `reset()` lifecycle,
   so a failed request doesn't make an unrelated later change look like a re-optimize.
3. **Resume and reconnect come for free.** `recover()` / `suspend()` are already wired to
   `ScheduleRecoveryMonitor`. A change detected after the app resumes arrives as an
   unclaimed revision change, so it's treated as `refresh`: quiet motion only. It's a
   candidate for a plain "Schedule updated" chip (no choreography), since the user
   didn't watch it happen.

**Gaps to close:**
- **Timing.** `observe()` runs inside `getSubTiles` *before* the bloc emits the new
  sub-events. Views must **not** trigger motion from `revisions.stream`. That stream only
  says that new data is coming; the diff runs when the bloc state arrives, read through
  `state.scheduleStatus`.
- **No origin on revise today.** `_onReviseSchedule` and `_onShuffleSchedule` don't call
  `checkAfterChange`. Revise currently relies on `shouldGetRefreshedListOfTiles` seeing a
  new `evaluationId`. Recording the pending origin there is new work, but small.
- **Dedupe.** The cubit is a `Cubit` of an `Equatable`, so it emits only when the pair
  changes. A view must still remember the *last revision it animated*, so a rebuild or a
  carousel page that remounts doesn't replay the same delta.
- **Several changes within one revision.** If the client sends two quick mutations and the
  server folds them into a single new revision, they produce one delta. Attribute it to the
  latest pending origin.

## 4. Motion language

Default sequence for a Tiler-made move (`tilerRevise`, and knock-on moves from user edits).
Each phase applies to a whole **batch** of up to 3 Tiles at once (§3.1):

| Phase | Time | What happens |
|---|---|---|
| **Lift** | 0–150 ms | The batch's Tiles rise (elevation/shadow +4–6 px, scale 1.02, faint Tiler-pink glow). Everything else dims 10–15 %. |
| **Ghost** | at lift | Each lifted Tile leaves a 15 % opacity outline at its old spot, labelled "Moved to 7:20 PM". |
| **Move** | 250–450 ms (longest move in the batch sets it, capped) | The *same* Tiles slide to their new spots together. Connectors stretch/morph with it. |
| **Settle** | 150–250 ms | Unbatched neighbours slide into place, the lift drops, the ghost collapses, a small confirmation pulse plays. |
| **Flash** | ~1 s, decaying | Semantic tint: pink = moved by Tiler, green = free time created, amber = travel changed, red = new conflict. |

Budget: about 600 ms per batch. The next batch lifts while the previous one settles (about
150 ms overlap). At most **3 batches (9 Tiles)** are played, which keeps the whole sequence
around 1.6 s before the summary chip appears. Anything bigger drops to the compressed tier (§6).

Gutter rail with several Tiles: draw a rail per Tile in the batch, but label only the
longest move, so three labels never stack in the gutter.

Reduced motion (`MediaQuery.disableAnimations`, already respected in both views): no lift,
move, or ghost. Keep the semantic flash as a plain colour change and keep the summary chip.
Understanding the change must not depend on seeing the animation.

### 4.1 User setting: "Schedule updates" (Off / Minimal / Detailed)

A local, per-device setting picks how much motion a schedule change gets. **It defaults to
Detailed.** All three modes keep the information (what changed, where the user is). They
differ only in how much movement explains it.

| | **Detailed** (default) | **Minimal** | **Off** |
|---|---|---|---|
| Meant for | Seeing *why* things moved | Calm motion, no theatre | No motion at all |
| Lift, dim, ghost, gutter rail | Yes | No | No |
| Batches of up to 3, cause first | Yes | No. Everything moves together. | No |
| Tile position / height changes | Choreographed (§4) | One 300 ms slide, today's grid behaviour | Jump in one frame |
| Enter / exit | Staggered enter, fade/collapse exit, cross-day slide | Plain fade in/out, no stagger, no slide | Appear / disappear at once |
| Empty-day sequence (§6.1) | Ordered: exits, then empty state | Cross-fade | Swap |
| Connector count-up | Tweens | Tweens | New value at once |
| Semantic flash (moved / free / travel) | Yes | No | No |
| "Reworking…" button state | Yes | Yes | Yes |
| Diff banner ("3 Tiles moving…") | Yes | No | No |
| Summary chip + *See changes* | Yes | Yes | Yes |
| Off-screen / cross-day edge chip | Tile shrinks into it | Chip appears after the slide | Chip appears on its own |
| Anchor (§5.5) | Animated compensation | Animated compensation | Single `jumpTo` |

**How the effective mode is worked out.** The mode actually used for a change is the lowest
of three caps:

1. **User setting**: Off, Minimal or Detailed.
2. **OS reduced motion** (`MediaQuery.disableAnimations`) caps it at **Off**.
3. **Change origin** (§3.2): `refresh` caps it at **Minimal**. Background changes never get
   the full choreography, whatever the setting.

`effective = min(setting, osCap, originCap)`, with the order `off < minimal < detailed`.
The tier table in §6 applies only when the effective mode is Detailed.

**Persistence** follows the existing `SharedPreferences` helper idiom (`ThemeManager`,
`DayGridPreferences`):
- New enum `ScheduleUpdateMode { off, minimal, detailed }`, defined next to its
  persistence the way `DailyViewLayout` is.
- New `lib/services/scheduleMotionPreferences.dart` with static `getMode()` /
  `setMode(ScheduleUpdateMode)`. Key `scheduleUpdateMode`, stored as the enum `name`.
- A missing, wrong-type or unknown value returns **detailed** and never throws.
- Local only. Not synced to the account, the same as dark mode and the list/grid layout.

**State** follows `DailyViewLayoutCubit`:
- New `ScheduleMotionCubit extends Cubit<ScheduleUpdateMode>` (initial `detailed`)
  restores from preferences on construction and persists on every change.
- Provided in `main.dart` next to `DailyViewLayoutCubit()`.
- Sends the analytics tag `schedule_update_mode_changed` with `{from, to}`, so we can see
  how many people step down from Detailed.

**One resolver, not scattered checks.** Today the grid checks
`MediaQuery.maybeOf(context)?.disableAnimations` separately in `dayGridWidget.dart`,
`tileGridWidget.dart` and `travelBandWidget.dart`. Replace those with one helper, for
example `ScheduleMotion.modeFor(context, origin)`, which returns the effective mode.
Widgets only ask it questions:
- `mode.animates` is false only for Off.
- `mode.choreographs` is true only for Detailed.

Every new piece of motion in this plan reads only that helper. The resolver should exist
before any new motion lands, so no animation ships unguarded.

**Settings UI**
- A row in `settingsWidget.dart` titled "Schedule updates", showing the current value.
  Tapping it opens a small sheet with three radio options and a one-line description each:
  - **Detailed**: "Show each change step by step."
  - **Minimal**: "Slide Tiles to their new times."
  - **Off**: "Update instantly, no animation."
- A 3-way segmented control fits as an alternative, but the descriptions matter more than
  saving a tap.
- New l10n keys (title + 3 labels + 3 descriptions) in every `lib/l10n/app_*.arb` file
  (9 locales today).

**Edge cases**
- Changing the mode while an animation is playing affects the *next* change.
- Grid pinch-to-zoom, drag and carousel day swipes are gestures or navigation, not schedule
  updates, and are not affected in any mode.
- Drag drop (`userDrag`) in Minimal: the dropped Tile settles straight away, and knock-on
  moves slide together without ordering.

**Tests**
- Preferences: absent → detailed, unknown string → detailed, wrong type → detailed,
  round-trip each value.
- Cubit: restores the stored value and persists changes.
- Resolver: a table test over setting × reduced motion × origin (3 × 2 × 4). For example,
  Detailed + reduced motion → Off, and Detailed + `refresh` → Minimal.
- Widget: in Off, a moved grid Tile's `AnimatedPositioned` gets `Duration.zero`. In
  Minimal, there is no ghost and no lift and all moves start in the same frame. In every
  mode, the summary chip appears after a `tilerRevise` delta.

## 5. Per-view plan

### 5.1 Day grid — add choreography to motion that already works

The grid's positions come straight from the times (`top = f(start)`), so the old and new
rectangles can be computed without measuring anything. Every item below builds on code that
already exists.

1. **Per-tile move delay.** Add `moveDelay` next to the existing `enterDelay` on
   `TileGridWidget`, filled from the batches in `ScheduleDelta` (every Tile in a batch gets
   the same delay). `AnimatedPositioned` currently starts straight away; wrap it so `top`
   holds for `moveDelay` and then animates. With this, Tiles move batch by batch instead
   of all together.
2. **Lift state.** Add `lifted: bool` to `TileGridWidget` and reuse the elevated styling the
   drag-lift path already uses (`_onLongPressStart`). Turn it on for every Tile in the
   current batch during its Lift + Move phases.
3. **Move ghost.** Extend `_removingTiles` / `_lastLayoutById` so a `moved` Tile also gets a
   ghost at its old spot. Use a separate key (`daygrid_tile_from_<id>`) so it can't clash
   with an exit ghost. Keep it for about 600 ms instead of 220 ms, and add the "Moved to …"
   caption.
4. **Change rail in the gutter.** The time gutter and occupancy rail (`occupancyRail.dart`)
   already sit beside the Tiles. Draw a short-lived line there from the old start to the new
   start with a "+1h 12m" label. It's the cheapest way to make the grid *explain* a move,
   and it never covers Tile content.
5. **Off-screen handoff.** If a moved Tile's new `top` is outside
   `_scrollController.position` (or the Tile went to another day), animate it to the
   matching edge and turn it into a chip: "↓ Get some Vit.D moved to 10:00 PM" or
   "→ Tomorrow". The chip stays for about 2 s, and tapping it scrolls there (we already have
   `_applyPendingScroll`, 450 ms) or switches the carousel day.
6. **Viewport anchor.** The anchor is chosen from each incoming change (§5.5). In the grid,
   a Tile that didn't move keeps its `top`, because position comes from its time. So holding
   `pixels` (already done, no-snap §16.2) is enough to anchor a stable Tile. Only one case
   needs a compensating scroll: when the anchor is the *subject* Tile and it moved. The
   scroll then shifts by the subject's `top` delta in step with the move, so the Tile holds
   its screen position while the timeline slides behind it. Never auto-scroll to *follow*
   a move. Following happens only when the user taps the handoff chip.
7. **Gates that stay.** No choreography while `mode != idle` (zooming or dragging). On a day
   swap, everything resets as it does today (no-snap rule 8).

### 5.2 Daily list — give it real movement first

The list is harder because `ScrollablePositionedList` builds items lazily by index. It has no
implicit reorder animation, and rows that are off-screen have no on-screen rectangle.

**Step 1 — Key the rows.** Give each Tile row and connector a
`ValueKey('list_day_$dayIndex/<uniqueId>')` (connectors keyed by their from→to ids). The rows
then keep their state across updates. This change is small but a prerequisite.

**Step 2 — FLIP flight layer.** Use the "first, last, invert, play" technique:
1. Before the new schedule is applied, read the on-screen rows from
   `_itemPositionsListener` and record each visible Tile's rectangle (via a `GlobalKey`
   per *visible* row only).
2. Build the new list. In a post-frame callback, measure where those same Tiles ended up.
3. For each `moved` Tile that is visible at both ends, draw a copy in an `Overlay` that flies
   from the old rectangle to the new one, with the real row hidden until it lands. This is
   where Lift / Ghost / Settle happen.
4. If the destination is off-screen or on another day, use the edge-handoff chip (same widget
   as the grid, §5.1-5).
5. For a Tile that was off-screen before and is visible after, play a short enter animation
   with a "moved from 6:11 PM" caption on the row.

**Step 3 — Row-level transitions.** Wrap row heights in `AnimatedSize` so resized Tiles and
grown or shrunk free-time slots change height smoothly, with the top edge fixed. Give
connectors a `TweenAnimationBuilder` over their duration so "7 min drive → 22 min" counts and
stretches instead of being rebuilt.

**Step 4 — Anchor.** Before applying the change, pick the anchor from the incoming delta
(§5.5) and note its row index and leading edge. After the rebuild,
`jumpTo(index, alignment)` puts it back where it was. Without
this, rows inserted above the user push everything down, which is the worst kind of jump.
This is the list version of the grid's no-snap contract.

The live-view auto-scroll (`_isAutoScrolled`, one shot) stays as it is. It must not fire
again because of a `tilerRevise`.

### 5.3 The "Reworking…" state (both views)

`_onReviseSchedule` already emits `ScheduleEvaluationState` while it waits on the network.
Use that wait instead of adding an artificial pause:
- The Re-optimize control changes to "✨ Re-optimizing…".
- If the request comes back in under ~300 ms, hold the label to about 300 ms so it doesn't
  flicker. Never add a delay longer than that.
- Once the diff is known, show "3 Tiles moving · 2 travel times updated" for the first
  ~400 ms of the choreography. This label runs *during* the animation, not before it.

### 5.4 Summary chip and "See changes" (both views)

After things settle (`tilerRevise`, and user edits that caused knock-on moves):

> ✨ **Plan updated** · 2 Tiles moved · +31 min free  `See changes`

- The chip auto-dismisses after about 5 s. It sits in the same slot as the existing in-flow
  alert rows (`DayGridAlertRows` / list banners), so it doesn't add another layer.
- **See changes** opens a bottom sheet listing the *diff*, not the schedule. Each line shows
  the Tile name and `old → new` (or "→ Tomorrow"). The free-time delta comes last.
- **No Undo.** There is no undo or restore capability, and faking one by re-sending old
  times would be fragile, so it isn't part of this plan.
- **No per-Tile reasons.** The server doesn't return why a Tile moved. The only cause shown
  is the one the client can work out from the diff: a travel change at the head of a cluster
  ("🚗 +12 min" on the rail and in the sheet). Anything else is shown as a plain move.

### 5.5 Choosing the anchor (both views)

The anchor is the Tile that holds its screen position while the rest of the change plays
around it. It is **chosen fresh from each incoming change**, not from past interaction, so
nothing has to be remembered between changes or sessions. `ScheduleDelta` exposes it as
`anchorId` (nullable), worked out from the delta plus the Tiles visible just before the
change, in this order:

1. **Subject Tile.** If the change has a subject (the Tile the user dragged, edited or
   completed, recorded with the pending origin in §3.3) and that Tile is still on this day
   and was on screen, it is the anchor. The user's eye is already on it.
2. **Stable Tile next to the change.** Otherwise, if the first affected cluster is on screen,
   the anchor is the nearest *unchanged* Tile just before that cluster. The change then
   unfolds just below a fixed reference point. If nothing comes before it, use the nearest
   unchanged Tile after it.
3. **Stable Tile at the top.** If no affected cluster is on screen, the anchor is the first
   unchanged Tile fully in view. Changes off screen are reported with handoff chips.
4. **Head of the first visible cluster.** If every visible Tile changed, anchor on the first
   Tile of the first visible cluster.
5. **No anchor** when there were no Tiles before, or none after (see §6.1).

For `refresh` changes, only rules 3–5 apply, because nothing has a subject.

## 6. Tiers by size of change

| Change | Behaviour |
|---|---|
| 1 Tile, small shift | Lift → move → settle, no chip for `refresh` origin |
| 1 Tile goes off-screen / to another day | Move → edge handoff chip |
| 2–3 Tiles | One batch: they lift, move and settle together, then the summary chip |
| 4–9 Tiles | 2–3 batches of up to 3, cause first, each batch moving together, then the summary chip |
| 10+ Tiles | Short "Reworking…" → **compressed** move (everything at once, 300 ms, no lift) → summary chip with *See changes* doing the explaining |
| Most of the day replaced | No animation. Cross-fade to the new day, show the summary chip, and point to *See changes*. |
| N Tiles → 0, or 0 → N | See §6.1 |

### 6.1 Empty-day transitions (N → 0 and 0 → N)

**First, check it's real.** An empty list isn't always an empty day. For example,
`_onCompleteTask` emits `FailedScheduleLoadedState` with `subEvents: []` and
`scheduleStatus: null` when the request fails. The revision gate (§3.3) handles this: no
known new revision means no delta, so a failure or a pending load must **never** play the
"day cleared" animation. It renders as a failure (or keeps the last known Tiles), as it does
today.

**Today's behaviour.** In the list, the empty state (`EmptyDayTile`) and the Tile list are
different branches of `EnhancedTileBatch.build`, so N → 0 and 0 → N swap them in one frame.
The empty state then fades in over 500 ms (`_emptyDayOpacity`). In the grid, the time grid
stays put, removed Tiles fade out as exit ghosts (220 ms), and added Tiles get the staggered
enter.

**N → 0 (the day is cleared)**

The delta says *where the Tiles went*, and that decides what's shown:

| Where they went | Behaviour |
|---|---|
| Moved to other days (`movedToOtherDay`) | One handoff chip per destination, not one per Tile: "→ 3 Tiles moved to Thursday". With 1–3 Tiles, each lifts and moves to the edge in turn. With more, they all fade toward the edge together. |
| Out of the loaded window | A Tile that left the window looks the same as a removed one. If the diff can't place it, the chip just says "moved later". It never shows that Tile as deleted. |
| Completed or deleted (`removed`) | The existing exit (fade or collapse). No handoff chip. |
| Mixed | Moves animate first, then removals, then the empty state. |

Sequence: Tiles leave first. The empty state fades in **only after** the last exit
finishes. In the list, that means replacing the hard branch swap with an `AnimatedSwitcher`
(or a short cross-fade) between the Tile list and `EmptyDayTile`, so the two never overlap.
The grid keeps its hour lines and tap-to-add. The summary chip (for `tilerRevise` /
`userEdit`) reads "Day cleared · 3 Tiles moved to Thursday", and the chip's tap action
switches the carousel to that day. There's no anchor, because nothing is left to anchor to.

**0 → N (an empty day fills)**

1. The empty state fades out quickly (~150 ms) **before** any Tile appears.
2. Tiles enter with the existing stagger (40 ms per Tile, capped at 400 ms). A Tile that came
   from another day (`movedFromOtherDay`) gets a "from Wednesday" caption for about 1 s.
3. With 5+ Tiles, the stagger is compressed to one shared enter, and the summary chip
   does the explaining ("4 Tiles added · 1 from Wednesday").
4. **No anchor** existed before, so there's nothing to hold:
   - **List**: start at the top, except for today, where the existing live-view one-shot
     scroll to the current or next Tile still applies (`_isAutoScrolled`).
   - **Grid**: keep `pixels`. If none of the new Tiles land in view, show an edge chip
     ("↓ 3 Tiles from 6:00 PM") instead of auto-scrolling, consistent with the
     never-follow rule.

For `refresh` changes (a poll, or an edit made on another device), both directions use the
plain exit / enter and the empty-state cross-fade, with no handoff chips and no lift. If the
day was cleared while the app was in the background, a single "Schedule updated" chip is
enough.

## 7. Phasing

| Phase | Deliverable | Depends on | Risk |
|---|---|---|---|
| **M0** | `ScheduleDelta` + tests; revision gate (§3.3) + pending-origin record in `ScheduleBloc`, keyed off `ScheduleRevisionCubit` | — | Low (pure logic; reuses existing revision tracking). **Done 2026-10-08:** `lib/services/scheduleDelta.dart`, `lib/bloc/schedule/schedule_change_tracker.dart`, wired in `ScheduleBloc` + grid drag. |
| **M0b** | Update-mode setting (§4.1): `ScheduleUpdateMode` + `ScheduleMotionPreferences`, `ScheduleMotionCubit`, `ScheduleMotion.modeFor` resolver replacing the existing `disableAnimations` checks, settings row + picker sheet + l10n | — | Low. Lands before any new motion so everything after is gated from day one. **Done 2026-10-08:** `ScheduleMotionPreferences`, `ScheduleMotionCubit`, `ScheduleMotion.modeFor`, settings row + sheet. |
| **M1** | Summary chip + *See changes* sheet (both views, no motion yet) | M0 | Low. Delivers the "what did you just do?" value even before any animation. **Done 2026-10-08:** `ScheduleChangeSummaryHost` over the Daily content, `ScheduleChangeSummaryChip`, `ScheduleChangeSheet`. |
| **M2** | Grid choreography: move delay, lift, move ghost, batches of 3 | M0 | Low–medium (adds to existing `AnimatedPositioned`). **Done 2026-10-08:** `GridChoreography` + `DayGridWidget` held/lifted/ghost steps. Cause-first ordering is in the batch order; the travel band follows its tile rather than stretching first. |
| **M3** | Grid gutter change rail + off-screen / cross-day handoff chip | M2 | Medium. **Done 2026-10-08:** `motion/moveRail.dart`, `motion/gridHandoff.dart`, `motion/gridHandoffChip.dart`. Tiles slide off the edge and the chip appears once they land, rather than shrinking into it. |
| **M4** | List: keyed rows, anchor preservation, `AnimatedSize` / connector morph | M0 | Medium. **Done 2026-10-08:** row keys in `tileConnectorLayout`, `dailyView/motion/listAnchor.dart`, `CountingDuration`. No `AnimatedSize`: list rows are fixed-height, so only the duration labels change. |
| **M5** | List: FLIP overlay flights + ghost + handoff (reuse M3 chip) | M4 | Medium–high (overlay sync with a lazy list). **Done 2026-10-08:** `dailyView/motion/listFlights.dart` + `listMotion.dart`, reusing the grid's batch timing and edge chips. Tiles arriving from off screen just appear in place; no "moved from" caption. |
| **M6** | Semantic flashes, tier selection, reduced-motion pass | M2, M5 | Low. **Done 2026-10-08:** `services/changeFlash.dart`, grown gaps in `ScheduleDelta`, cause lead in `GridChoreography`, flashes in grid and list, chip timed to the change. No red conflict flash. |

M1 comes before any animation on purpose. The chip and the diff sheet carry the explanation
even for reduced-motion users and for very large changes where animation can't help.

## 8. Decisions and open questions

### Settled

1. **Undo: not available.** There's no backend support. The chip and sheet ship without it.
2. **Reasons: not available.** The server gives no reason per Tile. The sheet shows
   `old → new`, plus a travel cause only when the diff itself shows one (§5.4).
3. **Id stability: ids are stable.** A revise keeps sub-event ids. A *different* id means a
   genuinely new sub-event, so `ScheduleDelta` treats it as `added` with no fallback matching.
   For third-party sub-events, `thirdpartyId` is the identity. `TilerEvent.uniqueId` already
   returns `thirdpartyId` for non-Tiler sources (`lib/data/tilerEvent.dart`), so the diff, the
   grid keys and the list keys all key on `uniqueId` and need no special case. Tests should
   cover a third-party Tile whose `id` changes while its `thirdpartyId` stays the same: it
   must read as `moved`, not `removed + added`. The one guard is an empty `uniqueId`: those
   Tiles are left out of motion and render without animation.

4. **Anchor: chosen per change.** The anchor comes from each incoming delta (§5.5), so
   nothing is stored between changes or sessions.
5. **Preview mode: out of scope.** Previewing a re-optimize before it's applied needs a
   backend call that proposes a schedule without committing it, and `shuffleSchedule()`
   commits immediately. Large changes fall back to cross-fade + summary chip + *See changes*.

## 9. Not adopting (or adopting differently)

- **No artificial 400–700 ms pause before the result.** The network wait during
  `ScheduleEvaluationState` already gives that moment. Adding more delay would make
  Re-optimize feel slower.
- **No choreography for background refreshes.** See §3.2.
- **No following the moved Tile with the camera by default.** The handoff chip plus tap-to-
  follow keeps the user in control and respects the no-snap contract.
