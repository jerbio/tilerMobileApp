# DayGrid View — Design & Tracking

> Status: **Design locked (all §10 decisions settled) / P1 complete (Steps 1.1–1.8); P2 in flight through Step 2.3 pinch-to-zoom (`69b2757`)**
> Last updated: 2026-09-05
> Owner: _TBD_
> Execution plan: §12 (step-by-step TDD plan with per-step trackers, tests, telemetry)

Living document for surfacing the calendar **DayGrid** view in the main UI and
layering on future UI enhancements (pinch-to-zoom, drag-and-drop, travel-time
rendering). Use the tracking tables at the bottom to record decisions and
implementation progress over time.

---

## 1. Background & goal

`DayGridWidget` ([lib/routes/authenticatedUser/calendarGrid/dayGridWidget.dart](../lib/routes/authenticatedUser/calendarGrid/dayGridWidget.dart))
is a 24-hour, absolutely-positioned "day on a clock" renderer. Today it is only
reachable through the **forecast / what-if** flow:

```
ForecastPreview → ForecastBloc.FetchData → whatIfApi.forecastNewTile
  → ForecastResponse.peekDays → DayCast(peekDay) → DayGridWidget(peekDay)
```

`DayCast` ([lib/routes/authenticatedUser/forecast/dayCast.dart](../lib/routes/authenticatedUser/forecast/dayCast.dart))
pairs the grid with a Google Map + route polylines, which is what makes it feel
"forecast-only". The grid itself is independent — its **only** dependency on the
forecast domain is `peekDay.subEvents`.

**Goal:** let users view their real schedule in the grid layout from the main
UI, persist that choice across app launches, and evolve the grid to support
pinch-to-zoom, drag-and-drop rescheduling, and inline travel-time rendering.

---

## 2. How the main UI selects a view (current state)

Single source of truth for "which day am I looking at" is
`UiDateManagerBloc.currentDate`. Three actors orbit it:

- **DailyTileList `CarouselSlider`** — one page per day; swipe → `DateChangeEvent`.
- **DayRibbonCarousel** — tap a day → `DateChangeEvent`; listens back and animates to the selected day.
- **Go-to-today** button → `DateChangeEvent`.

View selection (Daily/Weekly/Monthly):

- Enum `AuthorizedRouteTileListPage { Daily, Weekly, Monthly }` in [lib/bloc/schedule/schedule_bloc.dart](../lib/bloc/schedule/schedule_bloc.dart), held as `ScheduleBloc.currentView`.
- `selectCalendarView()` in [lib/components/calendarViewSwitcher/calendarViewSwitcherController.dart](../lib/components/calendarViewSwitcher/calendarViewSwitcherController.dart) dispatches `ChangeViewEvent`.
- `HomeBottomNav` bottom-left icon opens a pop-out via `_showViewMenu` ([lib/components/homeBottomNav.dart](../lib/components/homeBottomNav.dart)).
- Presentation (icon + label + order) in [lib/components/calendarViewSwitcher/calendarViewOptions.dart](../lib/components/calendarViewSwitcher/calendarViewOptions.dart).
- `AuthorizedRoute._buildTileList()` / `_ribbonCarousel()` switch on `currentView`.

Each daily carousel page is an `EnhancedTileBatch` (or `EnhancedWithinNowBatch`
for today), built in `processUpcomingAndPrecedingTiles()` / `processTodayTiles()`
in [lib/components/tilelist/dailyView/dailyTileList.dart](../lib/components/tilelist/dailyView/dailyTileList.dart).

---

## 3. Chosen approach — Option B: a toggle inside the Daily view

Considered three options:

- **A. 4th calendar view (`DayGrid`)** — add an enum value; compiler exhaustiveness walks every switch. Integrated but large blast radius; conceptually the grid is a *daily* variant, not a peer of Weekly/Monthly.
- **B. Toggle inside the Daily view (list ↔ grid)** — **CHOSEN.** Semantically correct (grid is a per-day layout), reuses the day's already-loaded `subEvents`, no enum/date-manager churn.
- **C. Standalone pushed route (`/DayGrid`)** — fastest, near-zero switch-machinery change, but feels modal/separate.

**Rationale for B:** the grid is fundamentally a single-day rendering; scoping it
as a Daily sub-mode matches its nature and avoids threading a 4th value through
Weekly/Monthly enums, date managers, ribbons, and tests.

---

## 4. The parametric core (why all enhancements share one foundation)

`GridPositionableWidget` ([lib/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart](../lib/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart))
reduces the whole layout to two parameters — `height` (pixels per cell) and
`durationPerCell` (default 1h) — and derives every position from them:

```
top(t)      = H_day * msSinceMidnight(t) / msPerDay,   H_day = pxPerHour * 24
height(d)   = pxPerHour * d_hours
time(y)     = y / pxPerHour            (inverse: drop offset → time)
```

Promoting `heightPerCell` (currently a fixed `80` in `DayGridWidget`) to a
reactive **`pxPerHour`** value makes:

- **Zoom** = animate `pxPerHour`.
- **Drag-drop** = invert `time(y)` from the drop offset.
- **Travel bands** = `height(travelDuration)` at the same scale.

This is the load-bearing refactor; everything else builds on it.

---

## 5. Architecture

```
DayGridPreferences (SharedPreferences: layout enum + pxPerHour)
  ├─ restore → DailyViewLayoutCubit (list vs grid)
  └─ restore/save → DayGridController (ChangeNotifier: pxPerHour, mode, snapInterval)

DailyViewLayoutCubit → DailyTileList day page (swap EnhancedTileBatch ↔ DayGridWidget)
DayGridController     → DayGridWidget (zoom) → positioned tiles / lines / travel bands / draggables
Draggable drop        → ScheduleBloc.EvaluateSchedule(rendered + updateSubEvent callback)
Tap on empty grid     → time(y) inversion → /AddTile with PreTile(startTime)
```

- **`DailyViewLayoutCubit`** — mirrors `ScheduleBloc.currentView`; restores `list|grid` on startup, toggled from `HomeTopRightActions`.
- **`DayGridController`** — a `ChangeNotifier`/`ValueNotifier`, **not** a bloc, because it mutates at gesture frame-rate during a pinch. Owns `pxPerHour` (clamped `[40, 240]`; first launch auto-fits ~4 hours in the viewport per C8, persisted thereafter), `snapInterval` (zoom-derived per C4, seeded 15 min at default zoom), and interaction `mode` (idle | dragging | zooming). Debounced persist on settle.
- **`DayGridPreferences`** — one `SharedPreferences` helper storing both the layout enum and last `pxPerHour`, following the existing `ThemeManager` / `TutorialPreferencesHelper` / `OnBoardingSharedPreferencesHelper` idiom.

---

## 6. Feature designs

### 6.1 Daily grid + persistence + navigation

- `DailyViewLayoutCubit` restores `list|grid`; toggle button in `HomeTopRightActions` (Daily-only, gated like "go to today").
- Persistence: local `SharedPreferences` (device-level UI pref, no network dependency), **not** the server `SettingsApi`.
- Each carousel page swaps `EnhancedTileBatch` → a zoomable `DayGridWidget`. **Adapter (C1, decided):** refactor the grid constructor to accept `List<SubCalendarEvent>` directly; `DailyTileList` pre-filters (non-viable / declined / pending-RSVP), and `DayCast` adapts by passing `peekDay.subEvents`.
- **Navigation carries over for free** — swipe (`onPageChanged` → `DateChangeEvent`) and ribbon tap both route through `UiDateManagerBloc`, which is layout-agnostic. The grid scrolls **vertically** (SingleChildScrollView), so it doesn't fight the **horizontal** day-swipe.

**Navigation integration points to reconcile:**

1. **Today's ribbon (C2, decided): collapsed tab, tap to expand.** Replace the current hard hide (`if (dayRibbonDate.isToday) return SizedBox.shrink()` in `_ribbonCarousel`) with a slim collapsed tab (chevron/handle) that expands the `DayRibbonCarousel` on tap and collapses again on selection or re-tap. Consistent across list and grid modes, so grid-mode today isn't left with neither ribbon nor summary; list-mode today keeps its embedded `EnhancedWithinNowBatch` summary and simply gains the optional tab.
2. **Alert banners (C3, decided): compact banner strip** above the grid — a single-row condensed strip reusing the existing detectors (`ConflictGroup.detectGroups`, `ExtendedTilesBanner.detectExtendedTiles`, pending-RSVP split) and tap-through modals from `CombinedAlertsBannerHelpers`. Grid stays a pure timeline below the strip.
3. **Live "now" line (C10, decided).** A 1–2px horizontal line at `evalTopPosition(TimeOfDay.now())` with a small time bubble in the gutter, refreshed by a minute timer; today only. Compensates for the grid losing the elapsed/not-elapsed split from `EnhancedWithinNowBatch` (the grid already auto-scrolls to the active/first-event hour).
4. **All-day / ≥16h tiles (C7, decided): excluded from the timeline and shown in a pinned header strip** between the banner strip and the grid, matching the list view's ≥16h conflict exclusion threshold.

**P1 hardening — pre-existing `DayGridWidget` gaps that main-UI usage exposes**
(the grid was only ever exercised in the one-shot forecast flow; it is not
rebuild-safe today):

1. **Rebuild safety.** `tileGridWidgetCell` is a state field that `build()` appends to without clearing → duplicate tiles on any `setState` (tap-select already triggers this). Rebuild the list per `build`.
2. **`didUpdateWidget`.** The grid never reacts to new `subEvents`, so carousel refreshes / `EvaluateSchedule` settles won't render. Also `build()` sorts `widget.peekDay.subEvents` **in place** (mutates widget-owned data) — sort a copy.
3. **Zoom-readiness.** `allDayTimeTiles`/`tileTimeCell` are built once in `initState`, and `TileGridWidget` computes `topPosition`/`widgetHeight` in *its* `initState`. Reactive `pxPerHour` means deriving these in `build`/`didUpdateWidget`, not just swapping the constant.
4. **Responsive width.** `TileGridWidgetState` hard-codes `leftPosition = 80`, `widgetWidth = 270` — won't fill wide screens, can overflow narrow ones. Derive from constraints (`LayoutBuilder`).
5. **Pull-to-refresh.** `RefreshIndicator` lives inside `EnhancedTileBatch`; grid mode loses it. Wrap the grid's scroll view with the same `ScheduleBloc` refresh wiring.
6. **Filtering parity.** `EnhancedTileBatch` excludes non-viable, declined, and pending-RSVP tiles from the main list; the grid renders everything in `subEvents`. Apply the same filter — ideally in `DailyTileList` before handing the grid a pre-filtered `List<SubCalendarEvent>` (reinforces C1 = drop the `PeekDay` wrapper).
7. **Cross-midnight tiles.** Positioning uses `TimeOfDay.fromDateTime(startTime)`, so a tile starting 11 PM yesterday renders at 23:00 on today's page / overflows the day bottom. Clamp render bounds to the visible day.
8. **Overlap layout (C11, decided): Google Calendar-style columns.** Overlapping tiles currently render fully stacked, last-on-top. Adopt the GCal algorithm: cluster transitively-overlapping tiles (reuse `ConflictGroup.detectGroups`), assign each tile the leftmost free column within its cluster, divide the cluster's width by its column count, and let a later-starting tile expand rightward over columns that have ended (slight left-edge overlap + z-order by start time). Tap raises a tile to full width/top-z (the existing `selectedSubEvent` re-add already approximates this). Belongs in P1/P2, not deferred to travel bands.
9. Minor: clamp `_scrollController.jumpTo` to `maxScrollExtent`; dispose the scroll controller before `super.dispose()`.

### 6.2 Pinch-to-zoom (time axis)

Scale gesture over the grid body that scales `pxPerHour` **and re-anchors scroll**
so the time under the fingers stays fixed:

```
onScaleStart:  _startPx = pxPerHour; _focalHours = (scroll.offset + focalY) / pxPerHour
onScaleUpdate: zoomTo(_startPx * verticalScale)
               scroll.jumpTo((_focalHours * pxPerHour - focalY).clamp(0, maxExtent))
onScaleEnd:    persistZoom()
```

- **Vertical scale only** — horizontal stays fixed so pinch never fights the day-swipe carousel.
- **Clamp + initial fit (C8, decided)** — `pxPerHour ∈ [40, 240]` ("whole day on screen" ↔ "~5-min precision"). No persisted value yet → auto-compute `pxPerHour = gridViewportHeight / 4` so **~4 hours are in view** at first launch (e.g. ~600px viewport → 150 px/h), clamped to the range; once the user pinches, the persisted value wins.
- **Adaptive lines/labels** — thin hour lines to every 2–3h at low zoom, add half/quarter-hour ticks at high zoom. Parameterize the `tileTimeCell` / `allDayTimeTiles` loop stride on `pxPerHour`.
- **Tile content reflow** — extend the existing `minDuration` padding switch in `_TilerEventInnerGridWidget` to collapse to a color bar below a pixel-height threshold.
- **Snap granularity (C4, decided): zoom-dependent, seeded.** `DayGridController.snapInterval` derives from `pxPerHour`, seeded at 15 min for the default zoom:

  | `pxPerHour` | snap |
  |---|---|
  | < 80 | 30 min |
  | 80–159 | 15 min (seed/default) |
  | ≥ 160 | 5 min |

  Shared by tap-to-add and drag-and-drop so both feel consistent at any zoom.
- **Zoom scope (C6, decided): global** — one persisted `pxPerHour` across all days (no per-day memory).
- **Gesture-arena risk** — vertical-only scaling avoids *visual* conflict, but a two-finger scale gesture still competes with `CarouselSlider`'s horizontal drag recognizer, which can claim the second pointer. Likely needs the carousel to ignore multi-pointer input (or a `RawGestureDetector` that wins on pointer count). Validate early in P2.

### 6.3 Drag-and-drop reschedule

`LongPressDraggable` (long-press to enter drag → doesn't hijack scroll/tap) with a
live ghost; convert drop Y → start time; reuse existing reschedule API.

- **Coordinate → time:** `newStartHours = dropTop / pxPerHour`, snap to `snapInterval`; new end preserves duration.
- **Constraints:** validate against `SubCalendarEvent.rangeStart/rangeEnd` and `calendarEventStart/End`. Outside window → red ghost + block drop (no silent clamp).
- **Persist move:** `subCalendarEventApi.updateSubEvent(EditTilerEvent{ Start, End, CalStart, CalEnd })`, wrapped in the established optimistic pattern — dispatch `EvaluateSchedule(renderedSubEvents, …, callBack: request)` (same as `playBackButtons.setAsNowTile`). Server re-evaluation stays authoritative.
- **Rollback:** on error, `ReloadLocalScheduleEvent` with pre-drag subEvents + toast.
- **Feedback:** snap-line at target time, floating time chip on ghost, haptic tick per snap, edge auto-scroll near viewport top/bottom.
- **Rigid vs flexible (C5, decided): hard pin.** A manual drop pins the tile to the dropped time (start/end persisted as-is; the scheduler does not re-fit it elsewhere). Third-party/read-only tiles (`!isFromTiler`) are drag-disabled.

### 6.4 Travel-time rendering in the grid

Data already present per tile: `travelTimeBefore` / `travelTimeAfter` (ms) and
`travelDetail.before/.after` (medium, start/end location).

- **Pre-travel band** of `height(travelTimeBefore)` immediately above the tile top; **post/return band** of `height(travelTimeAfter)` below the bottom.
- Reuse visuals + tap-to-directions from `TravelConnector` / `ReturnConnector` (icon by `travelMedium`, `TileColors.travel`, `TileColors.late` when `isTardy`, "leave by" time). Render as thin segments in the existing left gutter (tiles sit at `left: 80`).
- **Zoom-aware:** collapse to icon + hairline below a height threshold; expand to duration/leave-by text when tall.
- **During drag:** dim + mark travel bands "recalculating" — real travel depends on new neighbors and only the server knows post-`EvaluateSchedule`. Do **not** fabricate client-side estimates.
- **Overlap:** reuse `ConflictGroup` detection to offset overlapping tiles/bands horizontally.

### 6.5 Tap-to-add (tap empty grid → new tile)

Tapping an empty region of the grid starts tile creation at that time. This is
the inverse mapping drag-and-drop needs (`time(y) = y / pxPerHour`) minus the
ghost/constraint machinery, so it ships **before** P4 and de-risks it.

- **Hit detection:** a `GestureDetector` on the grid body *behind* the
  positioned tiles (first child of the `Stack`). Existing tiles sit on top and
  win the hit test, so only empty space triggers add; tapping a tile keeps its
  current behavior (`onTileTap` → select/detail).
- **Coordinate → time:** `tapTime = dayStart + (scroll.offset + localY) / pxPerHour`,
  snapped down to `DayGridController.snapInterval` (shared with drag-drop).
- **Flow into the existing add path (C12, decided):** `AddTile` already accepts a `PreTile`
  and seeds `_startTime` from `preTile.startTime`
  ([lib/routes/authenticatedUser/newTile/addTile.dart](../lib/routes/authenticatedUser/newTile/addTile.dart)),
  and `EmptyDayTile` already navigates via `Navigator.pushNamed('/AddTile', …)`.
  Reuse that: push `/AddTile` with `PreTile(startTime: tapTime)` + a **1h default
  duration (C13, decided)** — user adjusts in `AddTile` if needed.
- **Affordance:** on tap-down, render a transient snap-aligned highlight block
  with a time chip so the user sees the slot being created before the route
  opens; dismiss on cancel/scroll.
- **Guard rails (C14, decided):** taps resolving to past times prefill with "now"
  (matching `AddTile`'s default) rather than silently creating in the past; ignore taps
  while `DayGridController.mode == dragging | zooming`.

### 6.6 Tile position transitions (animate on update)

When the schedule changes (refresh, `EvaluateSchedule` settle, drag-drop
result, RSVP change), tiles must **slide to their new position** rather than
teleport, and new tiles **ease into place** — otherwise the grid feels broken
after every server re-evaluation.

- **Mechanism:** tiles are absolutely positioned in a `Stack`, so this is
  cheap — render each tile via `AnimatedPositioned` (or a
  `TweenAnimationBuilder` over top/height) with a **stable `ValueKey(tile.uniqueId)`**
  so Flutter reuses element/state and animates the delta instead of
  rebuilding a new widget at the new spot. ~300ms, `Curves.easeInOutCubic`.
  This rides on the P1 `didUpdateWidget` hardening (§6.1) — without stable
  keys + update handling there is no "old position" to animate from.
- **Delta classification** (mirror `evaluateTileDelta` in `EnhancedTileBatch`,
  which already tracks old→new index tuples for exactly this purpose):
  - **Moved/resized** (same `uniqueId`, new start/duration) → animate
    top/height to the new values.
  - **Added** → slide in: fade + scale-Y from the tile's snap slot (or slide
    from its final top with slight offset), staggered ~40ms per tile when a
    batch arrives.
  - **Removed** → fade/collapse out before the reflow of neighbors (GCal
    column widths from §6.1-8 re-animate as part of the same pass).
- **What must NOT animate:**
  - **Zoom** — pinch is gesture-driven and updates every frame; animating
    positions on top of `pxPerHour` changes double-animates and lags the
    fingers. Gate: animate only when `DayGridController.mode == idle`;
    during `zooming | dragging`, positions track the controller directly.
  - **Day-page swap** — a carousel page showing a *different* day gets fresh
    keys (prefix `uniqueId` with `dayIndex`), so tiles from yesterday never
    "fly" into today's layout.
- **Drag settle:** on drop, the ghost hands off to the tile animating from the
  drop position to the server-confirmed slot — the same moved-tile path, so an
  unchanged confirmation is a no-op and a scheduler adjustment reads as a
  gentle correction. On rollback, the tile slides back to its pre-drag slot.
- **Column reflow:** overlap-column assignment (C11) recomputes on every
  update; left/width changes animate with the same duration/curve as
  top/height so cluster reshuffles read as one coordinated motion.
- **Reduced motion:** respect `MediaQuery.disableAnimations` → jump-cut.

### 6.7 TileCast (vibe-chat preview) support

TileCast is the vibe-chat preview surface: `TileCastCarousel` renders one page
per `VibePreviewAction` over the *downloaded preview schedule*
(`VibeChatState.previewTiles`), delegating to `PreviewDailyTileList`, which
today always builds **list-view** batches (`EnhancedTileBatch` /
`EnhancedWithinNowBatch` with `preview: true` + `selectedActionEntityId`
highlighting). The grid must be a first-class TileCast surface so users who
live in grid mode aren't bounced back to the list to review AI proposals.

- **Layout follows the user's choice:** `PreviewDailyTileList._buildDayWidget`
  branches on `DailyViewLayoutCubit` exactly like `DailyTileList` —
  `layout == grid` → `DayGridWidget(tiles: previewTiles-for-day)`. Same
  pre-filter rules (§6.1), same C7 pinned header for ≥16h entries.
- **Preview mode flag:** grid gains a `preview: bool` (default false) mirroring
  `EnhancedTileBatch.preview`. In preview mode: read-only — **no** tap-to-add
  (§6.5), **no** drag-and-drop (§6.3), **no** pull-to-refresh dispatches to
  `ScheduleBloc` (preview tiles belong to `VibeChatBloc`); zoom stays enabled
  (shared global `pxPerHour`, C6, but persist is skipped so a preview pinch
  doesn't overwrite the user's saved zoom).
- **Action highlight:** grid accepts `selectedActionEntityId`; the matching
  tile (id `contains(entityId)`, same rule as `_tileForAction` /
  `EnhancedTileCard.hasDottedBorder`) renders with the dotted-border treatment,
  is raised to top-z in its C11 cluster, and the grid auto-scrolls it into view
  (`evalTopPosition(tile.start) - viewportOffset`, ~0.15 alignment to match the
  list's `jumpTo` behavior).
- **Carousel navigation:** swiping TileCast pages changes
  `selectedActionEntityId` only; the grid animates highlight + scroll between
  actions (§6.6 machinery, `mode == idle`) instead of remounting — preview
  tiles keep stable keys across pages since every page shows the same schedule.
- **Non-viable emphasis:** TileCast surfaces non-viable placements; grid
  preview must **not** filter non-viable tiles that match a preview action
  (contrast §6.1 filtering parity for the live grid) — render them with the
  existing non-viable styling so the user sees *why* the proposal conflicts.
- **Now-line & banners in preview:** now-line stays (orientation aid); the C3
  banner strip is suppressed — TileCast's own header sheet / action list is the
  chrome there.

---

## 7. Data-model & API touchpoints (all already exist)

| Need | Existing hook |
|---|---|
| Position/height math | `GridPositionableWidget` (`evalTopPosition`, `durationPerCell`, `height`) |
| Reschedule persist | `subCalendarEventApi.updateSubEvent(EditTilerEvent)` |
| Optimistic settle | `ScheduleBloc.EvaluateSchedule(..., callBack:)` |
| Rollback | `ReloadLocalScheduleEvent(previous subEvents)` |
| Drag bounds | `SubCalendarEvent.rangeStart/rangeEnd`, `calendarEventStart/End` |
| Travel data | `travelTimeBefore/After`, `travelDetail.before/.after` |
| Travel visuals/maps | `TravelConnector` / `ReturnConnector` |
| Persist zoom+layout | `SharedPreferences` (theme/tutorial pattern) |
| Tap-to-add prefill | `AddTile(preTile:)` / `/AddTile` route (`PreTile.startTime`, `.duration`) |
| Update delta tracking | `evaluateTileDelta` pattern in `EnhancedTileBatch` (old→new position tuples) |
| TileCast preview data | `VibeChatState.previewTiles` / `selectedActionEntityId`; `PreviewDailyTileList` day-widget branch; `preview:` flag idiom on `EnhancedTileBatch` |

No new backend contracts required — client rendering + gesture layer only.

---

## 8. Anticipated file touch list

| File | Change |
|---|---|
| `lib/services/dailyViewLayoutPreferencesHelper.dart` (or `dayGridPreferences.dart`) | new — layout enum + pxPerHour persistence |
| `lib/bloc/dailyViewLayout/daily_view_layout_cubit.dart` | new — holds + restores layout choice |
| `lib/routes/authenticatedUser/calendarGrid/dayGridController.dart` | new — pxPerHour / mode / snapInterval |
| [lib/routes/authentication/AuthorizedRoute.dart](../lib/routes/authentication/AuthorizedRoute.dart) | provide cubit/controller; ribbon → collapsed tap-to-expand tab (C2) |
| `lib/components/homeTopRightActions.dart` | add layout toggle button (Daily only) |
| `lib/routes/authenticatedUser/calendarGrid/dayGridBannerStrip.dart` | new — compact alert strip reusing `ConflictGroup` / `ExtendedTilesBanner` detectors + `CombinedAlertsBannerHelpers` modals (C3) |
| `lib/routes/authenticatedUser/calendarGrid/dayGridPinnedHeader.dart` | new — pinned strip for excluded all-day / ≥16h tiles (C7) |
| [lib/routes/authenticatedUser/forecast/dayCast.dart](../lib/routes/authenticatedUser/forecast/dayCast.dart) | pass `peekDay.subEvents` to refactored grid constructor (C1) |
| [lib/components/tilelist/dailyView/previewDailyTileList.dart](../lib/components/tilelist/dailyView/previewDailyTileList.dart) | branch on `DailyViewLayoutCubit`; grid page for TileCast preview (§6.7) |
| [lib/components/tilelist/dailyView/dailyTileList.dart](../lib/components/tilelist/dailyView/dailyTileList.dart) | `BlocBuilder` on layout; swap day page widget |
| [lib/routes/authenticatedUser/calendarGrid/dayGridWidget.dart](../lib/routes/authenticatedUser/calendarGrid/dayGridWidget.dart) | constructor takes `List<SubCalendarEvent>` (C1); render from `pxPerHour`; rebuild/`didUpdateWidget` hardening; cross-midnight clamp; `RefreshIndicator`; tap-to-add hit layer; pinch; drag; travel bands; wire `onTileTap` → tile detail |
| `lib/routes/authenticatedUser/calendarGrid/tileGridWidget.dart` | accept dynamic `pxPerHour`; responsive width (drop hard-coded 80/270); `AnimatedPositioned` + stable `ValueKey(dayIndex + uniqueId)` (§6.6); draggable |
| `lib/routes/authenticatedUser/calendarGrid/timeCellWidget.dart`, `timeOfDayTimeCell.dart`, `tileTimeCell.dart` | accept dynamic `pxPerHour`; adaptive label/line stride |
| [lib/components/tilelist/dailyView/dailyTileList.dart](../lib/components/tilelist/dailyView/dailyTileList.dart) | apply list-view filtering (non-viable / declined / pending-RSVP) before handing tiles to the grid |
| `test/...` | grid layout, zoom math, drag/tap coordinate inversion, persistence, filtering parity |

---

## 9. Phased rollout

1. **P1 — Parametric grid + persisted layout/zoom (static) + hardening.** Promote `heightPerCell` → `DayGridController.pxPerHour`; wire `DayGridPreferences` + `DailyViewLayoutCubit` + toggle; ship grid at a fixed default zoom. Includes the §6.1 hardening list (rebuild safety, `didUpdateWidget`, responsive width, filtering parity, pull-to-refresh, cross-midnight clamp), the C1 constructor refactor, the C7 pinned header strip, the C2 ribbon tab, and the C3 compact banner strip. **Load-bearing refactor; safe to land alone.**
2. **P2 — Tap-to-add + pinch-to-zoom + position transitions + TileCast.** Tap-to-add lands first — it proves the `time(y)` inversion with near-zero gesture risk. Then scale gesture + focal anchoring + adaptive labels + persist-on-settle (validate the carousel gesture-arena risk early). §6.6 slide/fade transitions land here too — they depend on P1's stable keys + `didUpdateWidget`, and must gate off during the new zoom gesture. §6.7 TileCast grid support closes the phase: it needs the `preview` flag, highlight raise (C11), and §6.6 highlight/scroll animation, but none of P3/P4.
3. **P3 — Travel bands (read-only).** Positioned before/after segments, zoom-aware, tap-to-directions.
4. **P4 — Drag-and-drop.** Long-press ghost → snap → `updateSubEvent` optimistic → rollback; travel bands react to settled result.

P4 last is deliberate: depends on coordinate inversion proven in P2 (tap-to-add, pinch) and travel bands existing (P3) so the drag result reads correctly.

---

## 10. Open concerns / decisions to settle

| # | Concern | Options | Decision | Status |
|---|---|---|---|---|
| C1 | Grid data adapter | `PeekDay` wrapper vs refactor `DayGridWidget` to take `List<SubCalendarEvent>` | **Refactor to `List<SubCalendarEvent>`** — caller pre-filters; `DayCast` adapts | **Decided 2026-09-03** |
| C2 | Today's ribbon + summary in grid mode | always show ribbon in grid vs embed a summary | **Ribbon becomes a collapsed tab that expands on tap** (all layouts consistent) | **Decided 2026-09-03** |
| C3 | Alert banners in grid | pure timeline vs compact banner strip | **Compact banner strip** above the grid, reusing `ConflictGroup.detectGroups` / `ExtendedTilesBanner.detectExtendedTiles` | **Decided 2026-09-03** |
| C4 | Snap granularity | fixed 5 min vs zoom-dependent | **Zoom-dependent with seeded initial value** (see §6.2 table) | **Decided 2026-09-03** |
| C5 | Drag semantics | hard-pin start vs request re-fit near time (scheduler contract) | **Hard pin** — drop persists exact start/end | **Decided 2026-09-03** |
| C6 | Zoom scope | global `pxPerHour` vs per-day memory | **Global** | **Decided 2026-09-03** |
| C7 | All-day / ≥16h tiles | exclude + pinned header strip | **Exclude from grid + pinned header strip** (P1) | **Decided 2026-09-03** |
| C8 | Zoom range | `[40, 240]` px/hour | **`[40, 240]`; initial value auto-computed to fit ~4h in viewport** (`viewportHeight / 4`, clamped), persisted zoom wins thereafter | **Decided 2026-09-03** |
| C9 | Toggle placement | `HomeTopRightActions` vs in-body segmented control | **Top-right (`HomeTopRightActions`)** | **Decided 2026-09-03** |
| C10 | "Now" indicator in grid | add live now-line vs rely on auto-scroll | **Live now-line** — `evalTopPosition(now)` + minute timer, today only | **Decided 2026-09-03** |
| C11 | Overlap layout timing | P1 vs P2; side-by-side columns via `ConflictGroup.detectGroups` | **Google Calendar-style column layout** (cluster → leftmost free column → shared width, expand-over-ended, tap raises); land P1/P2 | **Decided 2026-09-03** |
| C12 | Tap-to-add target | full `/AddTile` route vs lightweight quick-create sheet | **Full `/AddTile` route** (reuses `PreTile`) | **Decided 2026-09-03** |
| C13 | Tap-to-add default duration | fixed 1h vs snap-interval vs fit-to-gap | **Fixed 1h default** (user adjusts in `AddTile`) | **Decided 2026-09-03** |
| C14 | Tap-to-add on past days | block vs prefill "now" | **Prefill "now"** (matches `AddTile` default) | **Decided 2026-09-03** |
| C15 | TileCast grid layout source | always list in preview vs follow user's layout choice | **Follow `DailyViewLayoutCubit`** — grid users review proposals in the grid (§6.7); preview is read-only, zoom-persist skipped | **Decided 2026-09-03** |

---

## 11. Implementation tracking

| Phase | Item | PR / commit | Status | Notes |
|---|---|---|---|---|
| P1 | `DayGridPreferences` helper | 64c4785 | Done | Step 1.2; `test/daygrid_preferences_test.dart` (10) |
| P1 | `DailyViewLayoutCubit` + restore | 64c4785 | Done | Step 1.5; `test/daily_view_layout_cubit_test.dart` — restore from prefs, toggle persists, `daygrid_layout_toggled` analytics |
| P1 | `DayGridController` (pxPerHour) | 64c4785 | Done | Step 1.1; `test/daygrid_controller_test.dart` (13) |
| P1 | `DayGridWidget` renders from pxPerHour | 64c4785 | Done | Step 1.4; `test/daygrid_layout_math_test.dart` (6) |
| P1 | Toggle in `HomeTopRightActions` | 64c4785 | Done | Step 1.5; Daily-view only (icon shows target layout); `switchDayGridLayout` l10n (en/es) |
| P1 | Day-page swap in `DailyTileList` | 64c4785 | Done | Step 1.5; `DayGridPage` wraps day pages (today keeps `EnhancedWithinNowBatch` in list mode); `test/daygrid_layout_swap_test.dart` (4) |
| P1 | Grid constructor → `List<SubCalendarEvent>` (C1) | 64c4785 | Done | Step 1.3; `DayCast` adapts |
| P1 | Ribbon collapsed tab, tap-to-expand (C2) | 4313ded | Done | Step 1.7; `DayRibbonTab` (`dayRibbonTab.dart`) collapses on the current-day page, expands on tap; l10n added (en/es); `test/ribbon_tab_test.dart` |
| P1 | Compact alert banner strip (C3) | b97b987 | Done | Step 1.7; `dayGridBannerStrip` reuses list-mode conflict/RSVP/extended detectors + modals; hidden when clean; `test/daygrid_banner_strip_test.dart` |
| P1 | Pinned header for all-day/≥16h tiles (C7) | b97b987 | Done | Step 1.7; all-day/≥16h tiles render in a pinned strip above the timeline (excluded from the grid); `test/daygrid_pinned_header_test.dart` (8) |
| P1 | Rebuild / `didUpdateWidget` hardening | 64c4785 | Done | Step 1.3; `test/daygrid_widget_rebuild_test.dart` (7) — dupes on `setState` + in-place sort fixed; stale-state tile swap fixed via `ValueKey` + `TileGridWidgetState.didUpdateWidget` |
| P1 | Responsive tile width | 64c4785 | Done | Step 1.4 — drops hard-coded `80` / `270`; `LayoutBuilder` constraints |
| P1 | Filtering parity with list view | 64c4785 | Done | Step 1.5; `DayGridPage.gridTiles` mirrors `EnhancedTileBatch` rules (null ids, non-viable, third-party pending/tentative + declined RSVP; tiler-sourced exempt) |
| P1 | Cross-midnight clamp | 64c4785 | Done | Step 1.4 |
| P1 | Pull-to-refresh in grid mode | b8d2fe5 | Done | Step 1.6; `RefreshIndicator` wraps the grid scroll view (same `ScheduleBloc` refresh wiring as the list); `test/daygrid_refresh_nowline_test.dart` (6) |
| P1 | Live now-line (C10) | b8d2fe5 | Done | Step 1.6; today-only, 1px line + gutter time bubble; minute `Timer` + `ValueKey` bump rebuilds the line in place (no full-grid remount); `test/daygrid_refresh_nowline_test.dart` |
| P1 | GCal-style overlap columns (C11) | 5ccf822 | Done | Step 1.8; pure `OverlapColumns.assign` + `DayGridWidget` wiring; `test/daygrid_overlap_columns_test.dart` (13) — overlapping tiles cluster into shared-width columns; a singleton keeps the full region; tap-to-raise z-order + no-duplicate preserved |
| P2 | Auto-fit initial zoom (C8) | b8d2fe5 | Done | folded into C10 (step 1.6); `DayGridController.autoFit(viewportHeight)` = `viewportHeight / 4` clamped [40, 240], first-launch only, stored value wins; `_autoFitOnFirstLaunch` in `dayGridPage` |
| P2 | Zoom-dependent `snapInterval` (C4) | 64c4785 | Done | `DayGridController.snapInterval` derives the band from `pxPerHour` (coarse/fine thresholds); drives tap-to-add snapping |
| P2 | Tap-to-add: hit layer + snap highlight | df2e1e8 | Done | Steps C12/C14; behind-tiles tap layer maps y → `time(y)` → `snapInterval` (C4); `test/daygrid_tap_to_add_test.dart` |
| P2 | Tap-to-add: `PreTile` prefill → `/AddTile` | df2e1e8 | Done | Steps C12/C13; tapped slot → `/AddTile` prefill (start + 1h default duration) |
| P2 | Moved/resized tile transitions (§6.6) | | Done | Step 2.2; `AnimatedPositioned(top/left)` 300ms `easeInOutCubic`, gated on `mode == idle` (immediate while zooming/dragging), honors `MediaQuery.disableAnimations`; day-scoped `ValueKey` prefix prevents cross-day slides; `test/daygrid_transitions_test.dart` (5) |
| P2 | Added/removed slide-in / fade-out (§6.6) | 3378dbd, 2a71cd9 | Done | Step 2.2b; `didUpdateWidget` diffs by `uniqueId` — added tiles slide in (staggered ~40ms), removed tiles fade out as ghosts pinned at their last position (`exiting: true` + ~220ms cleanup timer); `test/daygrid_enter_exit_test.dart` |
| P2 | Carousel key stability — no remount on data updates (§6.6) | 3378dbd, 2a71cd9 | Done | Root-cause fix: `DailyTileList` rebuilt `carouselKey` from volatile `evaluationId` on every `ScheduleLoadedState`, remounting the whole `CarouselSlider` + every `DayGridWidget` (fresh element has no old positions → tiles hard-cut). Key now changes only when the structural signature (day window + current view day + `_forceRefreshCounter`) changes; `DayGridWidget` gets stable `ValueKey(daygrid_$dayIndex)` in `DayGridPage`; sole remaining remount path is the intentional zero-index navigation in `updateDayCarouselSlide` (user swipe to carousel start) |
| P2 | TileCast: grid `preview` mode + highlight (§6.7) | | Not started | read-only; dotted border + raise + auto-scroll |
| P2 | TileCast: `PreviewDailyTileList` layout branch (§6.7) | | Not started | non-viable action tiles NOT filtered |
| P2 | Pinch scale gesture + focal anchor | 69b2757 | Done | Step 2.3; two-finger scale on the full-area grid background (behind the tiles) claims the arena - a single finger never satisfies the scale recognizer; `pxPerHour = startPx * pinchScale` clamped [40,240] anchored to the pinch-start centre hour; settle-to-step + debounced persist; `test/daygrid_pinch_zoom_test.dart` (12) |
| P2 | Adaptive lines/labels | | Not started | |
| P2 | Tile content reflow | | Not started | |
| P3 | Travel bands (before/after) | | Not started | |
| P3 | Zoom-aware collapse/expand | | Not started | |
| P3 | Tap-to-directions reuse | | Not started | |
| P4 | LongPressDraggable + ghost | | Not started | |
| P4 | Coordinate→time snap + constraints | | Not started | |
| P4 | Optimistic `updateSubEvent` + rollback | | Not started | |
| P4 | Travel recompute on settle | | Not started | |

---

## 12. Step-by-step implementation plan (TDD)

Execution plan for the rollout. Every step follows the same TDD loop and
carries its own tracker, tests, feedback signals, and logging. Status of each
step is mirrored in the §11 tracking table.

### 12.0 Conventions used by every step

**TDD loop**
1. **Red** — write the failing test(s) listed for the step first (`test/` + `flutter test`).
2. **Green** — implement the minimum to pass.
3. **Refactor** — clean up with tests staying green; run `flutter analyze`.
4. Widget tests live beside existing ones in `test/` (`daygrid_*_test.dart` prefix); pure math/controller tests are plain unit tests (no widget pump) wherever possible.

**Pre-commit verification (required — every commit, every phase)**
No DayGrid commit lands without an engineer running and attesting the
following checklist. A commit that skips it is treated as invalid and reverted.

1. `flutter analyze` — zero issues in touched files.
2. `flutter test` — **full** suite green (not just the step's new tests; regressions in list-mode/TileCast/forecast tests block the commit).
3. **Step exit criteria met** — every "Exit" row of the step(s) the commit touches is satisfied, not partially done.
4. **Manual verification on a device/emulator** — the engineer exercises the changed surface (and its list-mode counterpart for parity steps) and confirms the step's logging/analytics lines actually fire in the debug output.
5. **Sign-off recorded** — commit message footer `DayGrid-Verified-By: <engineer>` + the §11 tracker row updated with the commit hash in the same change. A PR without both is not mergeable.

At each **phase gate** (end of P1–P4), a second engineer — not the author —
repeats items 2–4 end-to-end before the phase is marked complete in §11. The
gate reviewer's name goes in the tracker Notes column.

**Logging & error detection**
- **Debug tracing:** `Utility.debugPrint` gated messages, prefix `"DayGrid::"` for grep-ability.
- **Analytics/telemetry:** `AnalysticsSignal.send(tag, additionalInfo:)` (Firebase Analytics). Tag scheme: `daygrid_<area>_<event>`, e.g. `daygrid_layout_toggled`, `daygrid_drag_rollback`.
- **Error funnels:** every catch/rollback path emits both a `Utility.debugPrint` and an `AnalysticsSignal.send('daygrid_error', additionalInfo: {step, cause})` so field failures are countable per step.
- **Assertions:** invariants (no duplicate keys, positions within `[0, 24h]`) as `assert`s so debug builds fail loudly.

**User-feedback instrumentation** — each step lists the signals that tell us the feature works *for users*, not just in tests: adoption counters (toggle usage, tap-to-add conversions), error-rate counters (rollbacks, blocked drops), and qualitative checks in dogfood builds ("Feedback watch").

**Step exit criteria (all steps)**
- New tests green + full `flutter test` suite green.
- `flutter analyze` clean for touched files.
- Analytics/log lines verified once in a debug run.
- Pre-commit verification checklist completed and signed off (above).
- Tracker row in §11 updated.

### 12.1 Phase P1 — Parametric grid, hardening, layout persistence

#### Step 1.1 — `DayGridController` (pxPerHour / mode / snapInterval)
**Goal:** the reactive core: `ChangeNotifier` owning `pxPerHour` (clamp `[40,240]`), `mode` (idle|dragging|zooming), zoom-derived `snapInterval` (30/15/5 min bands, C4), auto-fit seed `viewportHeight / 4` (C8).

| | |
|---|---|
| New files | `lib/routes/authenticatedUser/calendarGrid/dayGridController.dart` |
| Tests first | `test/daygrid_controller_test.dart` — clamp bounds; snapInterval bands at 79/80/159/160 px/h; auto-fit seed math incl. clamp at extreme viewports; notify-on-change only when value actually changes; mode transitions |
| Logging | `debugPrint` on clamp hits; no analytics (pure state) |
| Feedback | n/a (invisible) |
| Exit | unit tests green; zero widget dependencies in the file |

#### Step 1.2 — `DayGridPreferences` (SharedPreferences helper)
**Goal:** persist layout enum (`list|grid`) + last `pxPerHour`, `ThemeManager`/`TutorialPreferencesHelper` idiom. Absent value → sentinel so auto-fit (C8) can run.

| | |
|---|---|
| New files | `lib/services/dayGridPreferences.dart` |
| Tests first | `test/daygrid_preferences_test.dart` (use `SharedPreferences.setMockInitialValues`) — round-trip layout + zoom; missing keys → defaults; corrupt value → defaults (not throw) |
| Logging | `debugPrint` on restore (value + source: stored vs default) |
| Feedback | n/a |
| Exit | round-trip + corruption tests green |

#### Step 1.3 — Grid constructor refactor to `List<SubCalendarEvent>` (C1) + rebuild hardening
**Goal:** the load-bearing fix set from §6.1: constructor takes tiles directly (`DayCast` adapts); rebuild-safe `build()` (no state-list append); `didUpdateWidget` reacts to new tiles; sort a copy (no widget-data mutation); scroll-jump clamped; dispose order fixed.

| | |
|---|---|
| Touched | `dayGridWidget.dart`, `dayCast.dart` |
| Tests first | `test/daygrid_widget_rebuild_test.dart` — pump grid, `setState`/tap-select twice → tile widget count unchanged (duplicate-tiles regression); pump with new tile list → new tile rendered, removed tile gone (didUpdateWidget); original input list order untouched after build; forecast path (`DayCast`) still renders |
| Logging | `assert` no duplicate `uniqueId` keys per build; `debugPrint` tile count per rebuild in debug |
| Feedback | Forecast flow dogfood: peek days still render/scroll correctly |
| Exit | duplicate-regression test red-before/green-after; forecast flow manually verified |

#### Step 1.4 — Parametric rendering from `pxPerHour` + responsive width
**Goal:** all positions/heights derive from `DayGridController.pxPerHour` (grid lines, time cells, tile top/height); `TileGridWidget` drops hard-coded `left: 80` / `width: 270` for `LayoutBuilder` constraints; cross-midnight clamp to day bounds; ≥16h/all-day excluded (C7 — pinned strip renders them, Step 1.7).

| | |
|---|---|
| Touched | `dayGridWidget.dart`, `tileGridWidget.dart`, `timeCellWidget.dart`, `timeOfDayTimeCell.dart`, `tileTimeCell.dart` |
| Tests first | `test/daygrid_layout_math_test.dart` — top/height at pxPerHour 40/80/240 for known start times; controller change → repositioned without remount (key identity held); cross-midnight tile clamps to `[0, 24h]`; ≥16h tile absent from timeline; tile width fills viewport minus gutter at narrow/wide widths |
| Logging | `assert` computed top/height finite and within day bounds |
| Feedback | Dogfood on small (SE-class) and tablet widths — no overflow stripes |
| Exit | math tests green at all three zoom levels; no `RenderFlex` overflows in widget tests |

#### Step 1.5 — `DailyViewLayoutCubit` + top-right toggle (C9) + persistence wiring
**Goal:** cubit restores `list|grid` from `DayGridPreferences`; toggle button in `HomeTopRightActions` (Daily only); `DailyTileList` day pages swap `EnhancedTileBatch` ↔ grid via `BlocBuilder`; filtering parity applied in `DailyTileList` before handing tiles to the grid.

| | |
|---|---|
| New files | `lib/bloc/dailyViewLayout/daily_view_layout_cubit.dart`, `lib/components/tilelist/dailyView/dayGridPage.dart` |
| Touched | `homeTopRightActions.dart`, `dailyTileList.dart`, `AuthorizedRoute.dart`, `main.dart` (cubit provider), l10n (`switchDayGridLayout`) |
| Tests first | `test/daily_view_layout_cubit_test.dart` — restore from prefs; toggle persists. `test/daygrid_layout_swap_test.dart` — day page shows grid when cubit=grid; declined/pending-RSVP/non-viable tiles filtered from grid input (parity with `EnhancedTileBatch` rules) |
| Logging | `AnalysticsSignal.send('daygrid_layout_toggled', {to, dayIndex})`; restore logs stored-vs-default |
| Feedback | **Primary adoption metric:** toggle events + share of sessions ending in grid mode. Watch: users flipping back to list immediately (< 10s) = friction signal |
| Exit | toggle round-trips across a simulated app restart in tests |

#### Step 1.6 — Pull-to-refresh + live now-line (C10)
**Goal:** wrap grid scroll view in `RefreshIndicator` with the same `ScheduleBloc` refresh wiring as `EnhancedTileBatch`; 1–2px now-line at `evalTopPosition(now)` + gutter time bubble, minute timer, today only.

| | |
|---|---|
| Touched | `dayGridWidget.dart` |
| Tests first | `test/daygrid_refresh_nowline_test.dart` — pull gesture dispatches `GetScheduleEvent(forceRefresh: true)`; now-line present only for today's dayIndex; now-line top matches injected clock; timer cancelled on dispose (no pending-timer test failure) |
| Logging | `daygrid_pull_refresh` analytics tag; `debugPrint` on refresh dispatch |
| Feedback | Refresh usage count in grid vs list mode |
| Exit | fake-clock positioning test green; no leaked timers (`flutter test` reports none) |

#### Step 1.7 — Ribbon tab (C2), compact banner strip (C3), pinned all-day header (C7)
**Goal:** replace `isToday` ribbon hard-hide with collapsed tap-to-expand tab; new `dayGridBannerStrip.dart` reusing `ConflictGroup.detectGroups` / `ExtendedTilesBanner.detectExtendedTiles` / RSVP split + `CombinedAlertsBannerHelpers` modals; new `dayGridPinnedHeader.dart` for excluded ≥16h/all-day tiles.

| | |
|---|---|
| New files | `dayGridBannerStrip.dart`, `dayGridPinnedHeader.dart` |
| Touched | `AuthorizedRoute.dart` |
| Tests first | `test/daygrid_banner_strip_test.dart` — strip shows conflict/RSVP/extended counts from fixture tiles, hidden when clean; tap opens the right modal. `test/daygrid_pinned_header_test.dart` — ≥16h tile in header, not timeline. `test/ribbon_tab_test.dart` — collapsed on today, expands on tap, collapses on selection |
| Logging | `daygrid_banner_tap`, `daygrid_ribbon_expanded` tags |
| Feedback | Banner tap-through rate (are grid users still catching conflicts/RSVPs they'd have seen in list mode?) — **the C3 success metric** |
| Exit | list-mode behavior unchanged (existing ribbon/banner tests still green) |

**P1 gate:** all P1 steps green; **independent engineer pre-commit verification (§12.0) repeated end-to-end**; dogfood build behind the toggle; watch `daygrid_error` funnel for one dogfood cycle before starting P2.

### 12.2 Phase P2 — Tap-to-add, transitions, pinch-to-zoom

#### Step 2.1 — Tap-to-add (C12/C13/C14)
**Goal:** behind-tiles `GestureDetector`; `time(y)` inversion + snap; tap-down highlight block + time chip; push `/AddTile` with `PreTile(startTime: snappedTime, duration: 1h)`; past times prefill "now"; ignore while `mode != idle`.

| | |
|---|---|
| Touched | `dayGridWidget.dart` |
| Tests first | `test/daygrid_tap_to_add_test.dart` — tap Y → expected snapped `DateTime` at multiple zooms/scroll offsets (**inversion proof for P4**); tap on a tile does NOT trigger add; past tap → "now" prefill; navigator receives `/AddTile` with correct `PreTile`; no-op while dragging/zooming |
| Logging | `daygrid_tap_add_opened` {snappedTime, pxPerHour}; `daygrid_tap_add_completed` vs abandoned (route pop without save) |
| Feedback | **Conversion funnel:** opened → tile created. Low conversion = wrong default duration or mis-aimed taps (check snap band distribution) |
| Fixes-detection | Mis-aim reports: log `rawY - snappedY` delta distribution to tune snap bands |
| Exit | inversion table-test green at pxPerHour ∈ {40, 80, 150, 240} |

#### Step 2.2 — Tile position transitions (§6.6)
**Goal:** `AnimatedPositioned` + stable `ValueKey(dayIndex + uniqueId)`; delta classification (moved/added/removed) mirroring `evaluateTileDelta`; stagger on batch add; animate only when `mode == idle`; day-swap gets fresh keys; respect `MediaQuery.disableAnimations`.

| | |
|---|---|
| Touched | `dayGridWidget.dart`, `tileGridWidget.dart` |
| Tests first | `test/daygrid_transitions_test.dart` — moved tile: pump update, advance 150ms, position is between old/new (actually animating), settles at new; same element (key) reused across update; no animation during `mode == zooming` (position immediate); different dayIndex → no cross-day animation; `disableAnimations` → jump-cut |
| Logging | debug-only frame log of delta counts {moved, added, removed} per update |
| Feedback | Dogfood: does a schedule re-evaluation "read" correctly? Motion-sickness/too-slow complaints → tune 300ms |
| Exit | mid-flight interpolation test green; zero animations triggered in zooming-mode test |

#### Step 2.3 — Pinch-to-zoom + adaptive rendering (C4/C6/C8)
**Goal:** scale gesture with focal-point re-anchoring; clamp; persist-on-settle (global, C6); adaptive line/label stride; tile content reflow below height threshold; **first task: spike the carousel gesture-arena risk** (two-pointer claim) before building on it.

| | |
|---|---|
| Touched | `dayGridWidget.dart`, time-cell widgets, `dailyTileList.dart` (carousel gesture config if spike demands) |
| Tests first | `test/daygrid_zoom_test.dart` — focal anchor math: time under focal Y identical before/after `zoomTo` (pure function test); clamp at gesture extremes; persist called once on settle (debounce), not per frame; label stride at 40/80/240 px/h |
| Logging | `daygrid_zoom_settled` {from, to}; gesture-arena spike results recorded in §6.2 |
| Feedback | Zoom distribution histogram — if users park at clamp edges, widen the C8 range |
| Fixes-detection | Carousel-swipe-during-pinch bug class: count `mode == zooming` interrupted by page change |
| Exit | spike outcome documented; focal-anchor property test green |

#### Step 2.4 — TileCast grid support (§6.7, C15)
**Goal:** grid `preview` flag (read-only: no tap-to-add/drag/refresh dispatch, zoom-persist skipped) + `selectedActionEntityId` highlight (dotted border, C11 top-z raise, auto-scroll ~0.15 alignment); `PreviewDailyTileList._buildDayWidget` branches on `DailyViewLayoutCubit`; non-viable tiles matching a preview action are NOT filtered; C3 banner strip suppressed in preview.

| | |
|---|---|
| Touched | `dayGridWidget.dart`, `tileGridWidget.dart`, `previewDailyTileList.dart` |
| Tests first | `test/daygrid_tilecast_test.dart` — preview mode blocks tap-to-add navigation + `ScheduleBloc` refresh dispatch; `selectedActionEntityId` tile gets highlight + top-z; entityId change animates scroll/highlight without remount (keys held); non-viable action tile rendered (not filtered) with non-viable styling; `PreviewDailyTileList` returns grid page when cubit=grid, list page when cubit=list; preview pinch does not write `DayGridPreferences` |
| Logging | `daygrid_tilecast_shown` {actionCount}; `daygrid_error` on entityId with no matching tile (silent-highlight-miss funnel) |
| Feedback | Proposal review completion (accept/reject reached from grid preview) vs list preview — parity means grid users aren't losing AI-flow effectiveness |
| Fixes-detection | Highlight-miss count (entityId unmatched) — spike means id-matching rule drifted from `_tileForAction` |
| Exit | existing TileCast list-mode tests (`test/preview/tilecast_*_test.dart`) still green; grid preview verified in dogfood vibe-chat flow |

**P2 gate:** tap-to-add conversion and zoom-settle telemetry healthy in dogfood; §6.6 transitions verified on-device (profile mode, no jank > 16ms frames on mid-tier Android); **independent engineer pre-commit verification (§12.0) repeated end-to-end**.

### 12.3 Phase P3 — Travel bands (read-only)

#### Step 3.1 — Travel band rendering
**Goal:** pre/post bands sized by `height(travelTimeBefore/After)` in the left gutter; visuals + tap-to-directions reused from `TravelConnector`/`ReturnConnector`; zoom-aware collapse (icon+hairline) / expand (duration + leave-by).

| | |
|---|---|
| New files | `lib/routes/authenticatedUser/calendarGrid/travelBandWidget.dart` |
| Tests first | `test/daygrid_travel_band_test.dart` — band top/height math from fixture travel times at multiple zooms; no band when travel fields null/0; collapsed vs expanded rendering across the height threshold; `isTardy` → late color |
| Logging | `daygrid_travel_band_tap` (directions launched) |
| Feedback | Directions-launch count from grid vs list connectors |
| Exit | math + threshold tests green; bands never overlap tile content in fixture layouts |

**P3 gate:** visual QA pass on dense schedules (bands + GCal columns + now-line coexisting); **independent engineer pre-commit verification (§12.0) repeated end-to-end**.

### 12.4 Phase P4 — Drag-and-drop reschedule (C5: hard pin)

#### Step 4.1 — Drag gesture + ghost + snap (UI only, no persist)
**Goal:** `LongPressDraggable` with live ghost, snap-line + floating time chip, haptic per snap, edge auto-scroll; range violations → red ghost + blocked drop; `!isFromTiler` drag-disabled; travel bands dim "recalculating" during drag.

| | |
|---|---|
| Touched | `tileGridWidget.dart`, `dayGridWidget.dart` |
| Tests first | `test/daygrid_drag_gesture_test.dart` — long-press begins drag, plain tap doesn't; drop Y → snapped start (reuses Step 2.1 inversion — table test); outside `rangeStart/rangeEnd` → drop rejected, tile returns; read-only tile ignores long-press |
| Logging | `daygrid_drag_started` / `daygrid_drag_blocked` {reason} |
| Feedback | Blocked-drop rate: high = constraint feedback isn't legible pre-drop |
| Exit | rejection paths tested; scroll unaffected by plain vertical drags |

#### Step 4.2 — Persist + optimistic settle + rollback
**Goal:** on drop, `updateSubEvent(EditTilerEvent{Start, End, CalStart, CalEnd})` hard-pinned (C5) inside `EvaluateSchedule(renderedSubEvents, callBack:)` (the `setAsNowTile` pattern); §6.6 transition handles settle motion; on error `ReloadLocalScheduleEvent` (pre-drag subEvents) + toast; travel bands refresh from settled result.

| | |
|---|---|
| Touched | `dayGridWidget.dart`, possibly `schedule_bloc.dart` (only if callback shape needs a param) |
| Tests first | `test/daygrid_drag_persist_test.dart` — mocked API: drop → `updateSubEvent` called with snapped Start/End; success → tile at server-confirmed position; API failure → tile restored to pre-drag position AND rollback event dispatched; double-drop during in-flight request is queued/ignored (no race) |
| Logging | `daygrid_drag_committed` {deltaMinutes}; **`daygrid_drag_rollback` {httpStatus} — the key error funnel for this phase** |
| Feedback | Commit vs rollback ratio; median drag deltaMinutes (are users making meaningful moves or micro-fidgeting → snap too fine?) |
| Fixes-detection | Rollback spike alerts on the analytics dashboard; debug logs carry subEvent id + timeline for repro |
| Exit | failure-injection test proves visual state never diverges from bloc state |

**P4 gate / GA:** rollback rate < 2% of drags over a dogfood cycle; **independent engineer pre-commit verification (§12.0) repeated end-to-end**; then default the toggle's discoverability nudge (one-time tooltip on the top-right toggle).

### 12.5 Cross-cutting: test & telemetry inventory

| Area | Test file | Key invariant |
|---|---|---|
| Controller math | `daygrid_controller_test.dart` | clamp, snap bands, auto-fit |
| Persistence | `daygrid_preferences_test.dart` | round-trip, corrupt-safe |
| Rebuild safety | `daygrid_widget_rebuild_test.dart` | no dup tiles, didUpdateWidget |
| Layout math | `daygrid_layout_math_test.dart` | position ∝ pxPerHour, clamps |
| Layout swap | `daily_view_layout_cubit_test.dart`, `daygrid_layout_swap_test.dart` | restore, filtering parity |
| Refresh/now | `daygrid_refresh_nowline_test.dart` | refresh event, today-only line |
| Chrome | `daygrid_banner_strip_test.dart`, `daygrid_pinned_header_test.dart`, `ribbon_tab_test.dart` | parity with list-mode surfacing |
| Tap-to-add | `daygrid_tap_to_add_test.dart` | y→time inversion, guards |
| Transitions | `daygrid_transitions_test.dart` | animate idle-only, stable keys |
| Zoom | `daygrid_zoom_test.dart` | focal anchor, debounced persist |
| TileCast | `daygrid_tilecast_test.dart` | preview read-only, highlight, layout branch |
| Travel | `daygrid_travel_band_test.dart` | band math, thresholds |
| Drag | `daygrid_drag_gesture_test.dart`, `daygrid_drag_persist_test.dart` | snap, constraints, rollback |

| Analytics tag | Fired when | Watches for |
|---|---|---|
| `daygrid_layout_toggled` | layout switch | adoption, instant flip-back friction |
| `daygrid_pull_refresh` | grid refresh | engagement parity with list |
| `daygrid_banner_tap` / `daygrid_ribbon_expanded` | chrome interaction | alert visibility parity (C3) |
| `daygrid_tap_add_opened` / `_completed` | tap-to-add funnel | conversion, mis-aim |
| `daygrid_zoom_settled` | pinch settle | zoom range fit (C8) |
| `daygrid_tilecast_shown` | grid preview opened | AI-flow parity, highlight misses |
| `daygrid_travel_band_tap` | directions launch | travel feature value |
| `daygrid_drag_started` / `_blocked` / `_committed` / `_rollback` | drag lifecycle | **rollback error funnel** |
| `daygrid_error` | any catch path | field failure counts per step |

---

## 13. Change log

| Date | Author | Change |
|---|---|---|
| 2026-07-19 | _TBD_ | Initial design captured (options analysis, parametric core, zoom/drag/travel designs, phasing, concerns). |
| 2026-09-03 | _TBD_ | Code-review findings folded in: P1 hardening list (rebuild safety, `didUpdateWidget`, responsive width, filtering parity, refresh, cross-midnight, overlap), pinch gesture-arena risk, C7 escalated to P1 blocker, C10–C14 added. New §6.5 tap-to-add design; tap-to-add slotted into P2. |
| 2026-09-03 | _TBD_ | Decisions locked: C1 constructor refactor, C2 ribbon-as-tab, C3 compact banner strip, C4 zoom-dependent snap (15 min seed), C6 global zoom, C7 exclude+pin, C13 1h tap-to-add default. Sections 6.1/6.2/6.5, touch list, phasing, and tracking updated to match. |
| 2026-09-03 | _TBD_ | Decisions locked: C5 hard-pin drops, C8 `[40,240]` with auto-fit ~4h initial zoom, C9 top-right toggle, C10 live now-line, C11 Google Calendar-style overlap columns. All §10 concerns now decided except C12/C14 (tap-to-add target & past-day semantics). |
| 2026-09-03 | _TBD_ | Decisions locked: C12 full `/AddTile` route, C14 prefill "now" for past-time taps. **All §10 concerns are now decided.** |
| 2026-09-03 | _TBD_ | New §6.6: tile position transitions — slide to new position / ease-in on schedule updates (`AnimatedPositioned` + stable keys, delta classification, zoom/day-swap gating, drag settle handoff). Slotted into P2. |
| 2026-09-03 | _TBD_ | Step-by-step TDD implementation plan added as §12 (12 steps across P1–P4, per-step trackers, test-first specs, analytics/logging funnels, phase gates); change log renumbered to §13. |
| 2026-09-03 | _TBD_ | New §6.7: TileCast (vibe-chat preview) grid support — preview follows the user's layout choice (C15, decided), read-only grid preview flag, `selectedActionEntityId` highlight/raise/auto-scroll, non-viable action tiles unfiltered. Plan Step 2.4 added. |
| 2026-09-03 | _TBD_ | Mandatory pre-commit verification added to §12.0: per-commit engineer checklist (analyze, full suite, exit criteria, on-device check, `DayGrid-Verified-By` sign-off + tracker hash) and independent second-engineer verification at every phase gate. |
| 2026-09-03 | _TBD_ | Step 1.5 implemented: `DailyViewLayoutCubit` (restore/persist/`daygrid_layout_toggled`), `DayGridPage` with `EnhancedTileBatch`-parity `gridTiles` filter, day-page swap in `DailyTileList` (today page keeps `EnhancedWithinNowBatch` in list mode via `listView`), `HomeTopRightActions` list/grid toggle (Daily-only), cubit provider in `main.dart`, `switchDayGridLayout` l10n. Tests: `daily_view_layout_cubit_test.dart`, `daygrid_layout_swap_test.dart` (list path needs the `SingleChildScrollView` parent per the existing ETB test convention). |
| 2026-09-03 | _TBD_ | §12.0 pre-commit checklist signed off for Step 1.5 (code commit `64c4785`): `flutter analyze` clean in all 26 touched files; full `flutter test` 599 passing / 6 pre-existing unrelated failures (no daygrid/forecast/TileCast regressions); exit criterion green (toggle round-trips across simulated app restart); on-device list/grid + toggle rendering verified. §11 tracker rows for Steps 1.1–1.5 now record `64c4785`. |
| 2026-09-04 | _TBD_ | §6.6 transitions now fire on in-app schedule updates: root cause was app-level, not grid-level — `DailyTileList` rebuilt `carouselKey` from volatile `evaluationId` on every `ScheduleLoadedState`, remounting the `CarouselSlider` and every `DayGridWidget`, so there was no old position for `AnimatedPositioned` to animate from. `carouselKey` is now stable across pure data updates (only changes when day window / current view day / `_forceRefreshCounter` change, so `initialPage` still re-applies on real structural changes); `DayGridWidget` in `DayGridPage` now carries a stable `ValueKey(daygrid_$dayIndex)`. Step 2.2b (enter stagger + exit ghosts) completed and green. Verified: `daygrid_enter_exit_test.dart`, `daygrid_widget_rebuild_test.dart`, `daygrid_layout_swap_test.dart` all pass; `dart analyze` clean on touched files (3 pre-existing warnings untouched). On-device animation check + commit hash still pending. §11: added/removed row → Done, new carousel-key-stability row added. |
| 2026-09-04 | _TBD_ | §12.0 sign-off for the carousel-key fix: code committed as `3378dbd` (grid widget/page + `DailyTileList` key-stability), tests + this tracker update committed as `2a71cd9`; on-device verified — schedule updates in grid mode now animate tile enter/exit/position transitions instead of hard-cutting. |
| 2026-09-04 | _TBD_ | Change-log catch-up for Steps 1.6-2.2 (tracker rows already recorded): 1.6 pull-to-refresh + live now-line + C8 auto-fit (`b8d2fe5`); 1.7 banner strip C3 + pinned header C7 + ribbon tab C2 (`b97b987`, `4313ded`); 1.8 overlap columns C11 (`5ccf822`); 2.1 tap-to-add C12/C13/C14 (`df2e1e8`, `36d4c6f`); 2.2 moved/resized tile transitions §6.6 (`ad8d646`). |
| 2026-09-05 | _TBD_ | Step 2.3 pinch-to-zoom implemented: two-finger scale on the full-area grid background (behind the tiles) claims the gesture arena (a single finger never satisfies the scale recognizer, so vertical scroll, the horizontal day carousel, and tile taps are unaffected); `pxPerHour = startPx * pinchScale` clamped [40,240] and anchored to the pinch-start centre hour (anchor-zoom); settle-to-step + debounced `DayGridPreferences` persist on end; no gesture fallback needed. Tests: `test/daygrid_pinch_zoom_test.dart` (12); full DayGrid suite + `test/tile_carousel_test.dart` green. On-device verification pending. |
