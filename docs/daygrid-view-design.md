# DayGrid View — Design & Tracking

> Status: **Design locked (§10 decisions settled — C16 + C17 decided 2026-09-09) / P1 complete (Steps 1.1–1.8); P2 complete (Steps 2.1–2.4); P3 Step 3.1 complete (travel bands, `a269b88` + `c95123f`); P4 Steps 4.1–4.2 complete (drag-and-drop, `7c3db43` + `fcf514e` + `993424a`; 36 DnD tests green; **P4 GA gate skipped/deferred 2026-09-09 — resume after the P5 addendum**); P5 (§14 chrome addendum: top-chrome layout + date-picker (C16) + day-summary entry point (C17)) Steps 15.1–15.4 implemented (`b4f1d0a`, `d93d1f6`, `6786fd1`, `0830cad`, `dc6b853`), Step 15.5 on-device QA in progress); **P6 (§16 visual redesign per the 2026-09-11 mock: scroll-collapsing header, restyled grid/tiles, in-column travel band, any-day summary entry, no-snap contract) — decisions C18–C27 locked 2026-09-11, NOT implemented**
> Last updated: 2026-09-11
> Owner: _TBD_
> Execution plan: §12 (P1–P4 step-by-step TDD plan) · §15 (P5 chrome-layout addendum step-by-step TDD plan, 5 steps) · §16 (P6 visual-redesign step-by-step TDD plan, 8 steps)

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
  - **Spike outcome (P2):** a custom `ScaleGestureRecognizer` subclass (`_ArenaWinningScaleGestureRecognizer`) that calls `resolve(accepted)` the moment the second pointer lands pre-empts the carousel/scroll pan recognizers. A second, subtler hazard: each pointer is hit-tested **independently**, so the recognizer must receive *both* pointers on the same instance — it is mounted as the **topmost `HitTestBehavior.translucent` full-area overlay** of the grid Stack (not behind the tiles, where fingers landing on events would route their pointers away and the scale recognizer would only ever see one pointer). Translucent keeps single-finger tile taps, tap-to-add, vertical scroll and horizontal day-carousel paging intact; a won pinch cancels the tiles' taps (no accidental selection mid-pinch).

### 6.3 Drag-and-drop reschedule

`LongPressDraggable` (long-press to enter drag → doesn't hijack scroll/tap) with a
live ghost; convert drop Y → start time; reuse existing reschedule API.

- **Coordinate → time:** `newStartHours = dropTop / pxPerHour`, snap to `snapInterval`; new end preserves duration.
- **Day-agnostic:** every time computation is relative to the currently selected grid day — drag, settle, and persist work identically for past, Today, and future days. Past-day drops persist to the selected past day and are **not clamped to `now`**. The only Today-specific behavior is the now-line / live-now visuals and AddTile "now" prefill (§6.5, C14).
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
5. **P5 — Chrome layout refinement (addendum, §14/§15, in progress — Steps 15.1–15.4 Done: `b4f1d0a`, `d93d1f6`, `6786fd1`, + "Wired date of header to uidate manager" (15.4; hash volatile — branch is being amended through checkpoint cycles, see the 2026-09-10 hash-sync entries); 15.5 in progress — headless verification done 2026-09-10; on-device QA pending).** Grid-mode-only: reserve real layout space above the grid for the day selector + a new search/settings/day-label row, converting grid-mode's top chrome from `Stack`-overlay to `Column`+`Expanded`. Independent of P1–P4; can land whenever scheduled. Requires explicit user approval per step before any commit (§14.8).

P4 last (of P1–P4) is deliberate: depends on coordinate inversion proven in P2 (tap-to-add, pinch) and travel bands existing (P3) so the drag result reads correctly. P5 is unordered relative to P1–P4 — it only touches chrome composition, not grid math.

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
| C16 | Grid-mode day-label tap target | reuse Weekly/Monthly's bespoke picker dialog vs plain `showDatePicker` | **Plain `showDatePicker`** (§14.7) — matches the existing single-date-pick idiom used elsewhere in the app; dispatches `DateChangeEvent` to `UiDateManagerBloc` like the ribbon does | **Decided 2026-09-09** |
| C17 | Day-summary entry point scope in grid mode | today-only (parity with list mode) vs every day | **Today-only** (§14.6) — matches `EnhancedWithinNowBatch`'s current exclusivity; every-day is a **separate, deferred** product decision, not required to unblock P5 | **Decided 2026-09-09** |

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
| P2 | TileCast: grid `preview` mode + highlight (§6.7) | c3fb1ce | Done | read-only (no tap-to-add / drag / `ScheduleBloc` refresh; zoom-persist skipped); `selectedActionEntityId` drives the dotted-border highlight via `tileMatchesAction` + `DashedBorderPainter` (C11 top-z raise); `test/preview/tilecast_grid_preview_test.dart` (10) |
| P2 | TileCast: `PreviewDailyTileList` layout branch (§6.7) | c3fb1ce | Done | `context.watch<DailyViewLayoutCubit>()` — grid → read-only `DayGridWidget(preview: true)` over `DayGridPage.previewGridTiles` (non-viable action tiles NOT filtered; C7 `DayGridPinnedHeader` kept; C3 banner suppressed), list → existing `EnhancedTileBatch` / `EnhancedWithinNowBatch`; stable `ValueKey('daygrid_preview')` so page swipes change only `selectedActionEntityId` (highlight + auto-scroll, no remount) |
| P2 | Pinch scale gesture + focal anchor | 69b2757 + a269b88 | Done | Step 2.3; topmost `HitTestBehavior.translucent` full-area overlay carries `_ArenaWinningScaleGestureRecognizer` (resolves accepted on the 2nd pointer, so scroll/carousel/tile-taps stay intact and fingers landing on tiles still pinch); `pxPerHour = startPx * pinchScale` clamped [40,240] anchored to the pinch-start centre hour; settle-to-step + debounced persist; `test/daygrid_pinch_zoom_test.dart` (16, incl. pinch-on-tile regression cases) |
| P2 | Adaptive lines/labels | 1446eb4 | Done | Step 2.3 (adaptive rendering, §6.2); gutter hour guide lines AND labels thin to every 2nd hour below 64 px/h (`gutterLineStride`, mirrors `gutterLabelStride`); sub-hour tick hairlines appear at higher zoom — 30 min, 15 min at/above the C4 fine-snap 160 px/h boundary (`gutterTickIntervalMinutes`, `gutterFineTickThreshold`); pure fns unit-tested + widget-level line/label/tick counts across 40/80/240 px/h in `test/daygrid_adaptive_test.dart` |
| P2 | Tile content reflow | 1446eb4 | Done | Step 2.3 (adaptive rendering, §6.2); `TileGridWidgetState.tileContentCollapsed` (32px caption threshold, pure fn) — `_TilerEventInnerGridWidget` collapses tiles shorter than the threshold to a plain color bar (no name Text); the TileCast dotted-border highlight survives collapse; `test/daygrid_adaptive_test.dart` (short tile: bar at 40 px/h, caption returns at 240 px/h, same element) |
| P3 | Travel bands (before/after) | a269b88, c95123f | Done | Step 3.1; `travelBandWidget.dart` — pure `TravelBand.bandsForTile` math (pre/post bands sized by `height(travelTimeBefore/After)` in the grid's left gutter, clamped to the visible day like the tiles; no band when travel is null/0) rendered in `dayGridWidget.dart`; effective height clamped to the 18px `iconHeightThreshold` (`c95123f`) so 3–6 min bands stay visible at the default 80 px/h (pre-band extends upward, post-band downward); `isTardy` → `TileColors.late`; `test/daygrid_travel_band_test.dart` (18) |
| P3 | Zoom-aware collapse/expand | a269b88, c95123f | Done | hairline-only below 18px → + 14px travel-medium icon at `iconHeightThreshold` (18px) → + duration / "leave-by" pill inside the tile column at `expandedHeightThreshold` (56px, `TravelBand.leaveByTime` + `formatDuration`, mirrors `CompactTravelIndicator`); `test/daygrid_travel_band_test.dart` (collapsed/expanded threshold cases incl. the min-height clamp) |
| P3 | Tap-to-directions reuse | a269b88 | Done | same Google Maps directions URL construction as `TravelConnector` / `ReturnConnector` (no directions for home-return bands — same `ReturnConnector._isHome` rule); `daygrid_travel_band_tap` analytics; non-tappable bands leave `onTap` null so taps fall through to the grid's tap-to-add layer |
| P4 | LongPressDraggable + ghost | 7c3db43, 993424a | Done | Step 4.1; long-press lifts a ghost (plain tap never starts a drag), snap-line + time chip, haptic tick per snap, top/bottom edge auto-scroll (incl. behind the bottom nav); outside `rangeStart/rangeEnd` → red ghost + blocked drop; `!isFromTiler` drag-disabled; day-agnostic — all math relative to the selected grid day (past/Today/future); `test/daygrid_drag_gesture_test.dart` (22) |
| P4 | Coordinate→time snap + constraints | 7c3db43 | Done | Step 4.1; drop Y → `time(y)` snap to the C4 zoom-dependent `snapInterval` (duration preserved); constraint violations block the drop (no silent clamp) |
| P4 | Optimistic `updateSubEvent` + rollback | 7c3db43, fcf514e, 993424a | Done | Step 4.2; `updateSubEvent(EditTilerEvent{Start, End, CalStart, CalEnd})` hard-pinned (C5; parent `CalStart/CalEnd` window preserved when present) inside `EvaluateSchedule(renderedSubEvents, callBack:)` (the `setAsNowTile` pattern); save badge spinner → saved / error (`fcf514e`, `tileSaveStatusBadge_test.dart`); on error `ReloadLocalScheduleEvent` + rollback to the pre-drag slot; a second drop while the first is in flight is ignored (no race); day-agnostic — past-day drops persist the past-day slot, never clamped to `now` (3 past-day tests, uncommitted at 2026-09-08); `test/daygrid_drag_persist_test.dart` (14) |
| P4 | Travel recompute on settle | 7c3db43 | Done | bands are server-derived — no client-side estimate is fabricated; after settle they refresh from the re-evaluated `EvaluateSchedule` render (per §6.4) |
| P5 | Extract `HomeTopRightActionsRow` + `DayRibbonCarousel.topMargin` | b4f1d0a | Done | Step 15.1; pure refactor, list/Weekly/Monthly pixel-identical: `HomeTopRightActions` is now a thin `Positioned` wrapper around the in-flow `HomeTopRightActionsRow`; `DayRibbonCarousel.topMargin` param (default `50`) keeps every existing overlay call site pixel-identical; `test/home_top_right_actions_test.dart`, `test/day_ribbon_carousel_test.dart` |
| P5 | `DayGridTopChromeRow` (day label + actions) | d93d1f6 | Done | Step 15.2; grid-mode-only, built in isolation: `lib/components/dayGridTopChromeRow.dart` — leading tappable `DateTimeHuman.humanDate` label (C16 date-picker seam: `onDateSelected` callback + injectable `pickDate` seam; widget stays ignorant of `UiDateManagerBloc`) + trailing `HomeTopRightActionsRow`; `test/day_grid_top_chrome_row_test.dart`; not yet referenced by `AuthorizedRoute` (that is Step 15.3) |
| P5 | `AuthorizedRoute` `Column` wiring + `DailyTileList` flexible height (§14.4) | 6786fd1 | Done | Step 15.3; gated on `DailyViewLayoutCubit == grid && currentView == Daily`: `AuthorizedRoute.renderAuthorizedUserPageView()` now mounts `GridDailyPageBody` (`lib/components/dayGridPageBody.dart`) — in-flow `Column` (chrome row → in-flow ribbon/tab at `topMargin: 0` → `Expanded(DailyTileList)`); `DailyTileList.carouselHeight` param lets the grid's scroll viewport start below the chrome; `test/daygrid_chrome_layout_test.dart`; list mode / Weekly / Monthly keep the exact current `Stack` untouched |
| P5 | Day-label tap → `showDatePicker` → `DateChangeEvent` (C16) | "Wired date of header to uidate manager" (hash volatile — amended through checkpoint cycles) | Done | Step 15.2 (widget, `d93d1f6`) + 15.4 (bloc wiring): `GridDailyPageBody` forwards the `pickDate` seam to `DayGridTopChromeRow` and its `onDateSelected` dispatches `DateChangeEvent` (`DateChangeTrigger.buttonPress`) to `UiDateManagerBloc`, mirroring `DayRibbonCarousel.onDateButtonTapped`; cancelled (null) and same-day picks are no-ops; the `daygrid_date_picker_opened`/`daygrid_date_picker_selected` logs from 15.2 now fire in production via this path; `test/daygrid_date_picker_navigation_test.dart` (3); §14.7 |
| P5 | Day summary entry point in grid mode, today-only (C17) | "Wired date of header to uidate manager" (hash volatile — amended through checkpoint cycles) | Done | Step 15.4; `DayGridPage` mounts the unmodified `DaySummaryHeader` above the grid only when the shown day is today; tapping it opens `TodayStatusScreen` with the day's `Timeline` (same `TimelineSummary`/`ScheduleSummaryBloc` pipeline as list mode); `test/daygrid_day_summary_entry_test.dart` (3); §14.6 |
| P5 | On-device QA + tutorial spotlight recheck | _TBD_ | In progress | Step 15.5; headless verification done 2026-09-10 — tutorial-spotlight recheck (code): `scheduleViewKey` attached to the outer full-body `Container` (`AuthorizedRoute.dart:568`), geometry identical in list & grid mode; `topRightActionsKey` attached to the shared `HomeTopRightActionsRow` `Row` (`homeTopRightActions.dart:40`), present in both the legacy `Positioned` overlay and the grid in-flow chrome (same `GlobalKey`, now-correct in-flow geometry); `onboarding_tour_sync_test.dart` id→key contract + `topRightActionsKey` live-mount pass. Layout-contract (`daygrid_chrome_layout_test.dart`: no viewport overlap, no RenderFlex overflow at the 480px short viewport, non-grid legacy-`Stack` regression), date-picker + C17 (`daygrid_date_picker_navigation_test.dart` 3, `daygrid_day_summary_entry_test.dart` 3), and grid regressions (`ribbon_tab`, `daygrid_layout_swap`, `daygrid_banner_strip`, `daygrid_pinned_header`, `tile_carousel`, `day_ribbon_carousel`) all green; `flutter analyze` clean on the four grid files. The reported grid-mode overflow is **not reproduced** at the headless viewports — a real-device geometry case, remains an open on-device item. On-device QA (small-height/tablet/notched) pending user hardware |
| P6 | Grid body restyle (gutter, hour lines, now-line accent, tile card, pinned card) | _TBD_ | Not started | Step 16.1; pure paint inside `_TilerEventInnerGridWidget` / gutter cells / `DayGridPinnedHeader`; keys + `_TileLayout` untouched |
| P6 | Tile width/height transitions (closes an existing snap gap) | _TBD_ | Not started | Step 16.2; `AnimatedPositioned` currently animates only `top`/`left` (`tileGridWidget.dart:476`) |
| P6 | `CustomScrollView(center:)` host + negative-extent header slot | _TBD_ | Not started | Step 16.3; C18 — grid stays anchored at `pixels == 0`, header lives in `[minScrollExtent, 0)`; zero scroll↔time math changes |
| P6 | `DayGridScrollHeader` (big date, subtitle, compact swipeable day strip, conflict + RSVP banner rows) | _TBD_ | Not started | Step 16.4; C21/C23; built in isolation |
| P6 | Top bar rework: toggle · date pill ▾ · day-summary (any day) · search · settings, cross-fade by reveal progress | _TBD_ | Not started | Step 16.5; C19/C20; retires the today-only `DaySummaryHeader` mount from `DayGridPage` (C17 superseded) |
| P6 | Travel in-column band tier | _TBD_ | Not started | Step 16.6; 4th zoom tier drawn beneath tiles, not an overlap-column participant |
| P6 | Bottom-nav labels | _TBD_ | Not started | Step 16.7; C25; not grid-scoped — separate small commit |
| P6 | No-snap regression harness + on-device QA | _TBD_ | Not started | Step 16.8; C27; `test/daygrid_no_snap_test.dart` |

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

**P4 gate / GA — _**skipped / deferred 2026-09-09** (user decision):_ rollback rate < 2% of drags over a dogfood cycle; **independent engineer pre-commit verification (§12.0) repeated end-to-end**; then default the toggle's discoverability nudge (one-time tooltip on the top-right toggle). Step 4.2's engineering work remains Done (36/36 DnD tests green, `7c3db43` + `fcf514e` + `993424a`) — what is parked is the gate's field-quality + second-engineer-verification criteria, so DnD stays behind the grid-layout toggle. The gate resumes after the P5 chrome addendum (§14/§15) is through; the criteria above are unchanged, pick up from here.

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
| Adaptive | `daygrid_adaptive_test.dart` | line/label stride, tick density, caption reflow |
| TileCast | `daygrid_tilecast_test.dart` | preview read-only, highlight, layout branch |
| Travel | `daygrid_travel_band_test.dart` | band math, thresholds |
| Drag | `daygrid_drag_gesture_test.dart` (22), `daygrid_drag_persist_test.dart` (14) — 36 total | snap, constraints, rollback, day-agnostic (past-day drops persist the past-day slot, not clamped to `now`) |

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
| 2026-09-11 | _TBD_ | P5 status corrected (15.1–15.4 done, 15.5 in progress). P6 visual redesign designed from the 2026-09-11 three-state mock: decisions C18–C27 locked (§16.1), no-snap contract (§16.2), 8-step TDD plan (§16.3). Free-time blocks explicitly rejected (C22). |
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
| 2026-09-05 | 1446eb4 | Step 2.3 adaptive rendering completed (the last two P2 rows: "Adaptive lines/labels" + "Tile content reflow", §6.2). Gutter: `gutterLineStride` now thins the hour guide lines to every 2nd hour below 64 px/h (labels already thinned in the pinch step) and `gutterTickIntervalMinutes` adds sub-hour tick hairlines — 30 min between the thresholds, 15 min at/above the C4 fine-snap 160 px/h boundary (`gutterFineTickThreshold`), none at low zoom. Tile body: new `TileGridWidgetState.tileContentCollapsed` (32px caption threshold) — `_TilerEventInnerGridWidget` renders tiles shorter than the threshold as a plain color bar (no name Text), and the TileCast dotted-border highlight survives the collapse. Tests: `test/daygrid_adaptive_test.dart` (10) — pure stride/tick/collapse math + widget-level line/label/tick counts at 40/80/240 px/h + short-tile bar/caption reflow. Verified: `test/daygrid_adaptive_test.dart` green; `flutter analyze` clean on touched files; full `flutter test` 684 passing with 6 pre-existing unrelated failures (identical failure set on a clean tree — counter smoke test, HomeFab/onboarding chat icon, 2 `EnhancedWithinNowBatch` banner tests; no DayGrid/TileCast regressions). §11: both rows → Done. On-device visual check pending. |
| 2026-09-05 | c3fb1ce | Step 2.4 TileCast grid preview (§6.7, C15) implemented and merged (`c3fb1ce` "Implemented tilecast previews"). `DayGridWidget` gains a read-only `preview` flag — suppresses tap-to-add / drag / `ScheduleBloc` refresh dispatch and skips zoom-persist — plus a `selectedActionEntityId` highlight (dotted border via `DashedBorderPainter`, C11 top-z raise). `DayGridPage.previewGridTiles` keeps non-viable tiles (contrast §6.1 `gridTiles` parity filtering) so conflicting proposals stay visible with non-viable styling. `PreviewDailyTileList._buildDayWidget` now branches on `DailyViewLayoutCubit`: grid renders the read-only `DayGridWidget(preview: true)` under a stable `ValueKey('daygrid_preview')` (a page swipe changes only `selectedActionEntityId` → highlight + auto-scroll instead of remount), list mode keeps the existing `EnhancedWithinNowBatch` / `EnhancedTileBatch` path. Tests: `test/preview/tilecast_grid_preview_test.dart` (10) — `tileMatchesAction` highlight rule, `previewGridTiles` vs `gridTiles` non-viable filtering, and `DayGridWidget` preview rendering (non-viable visible + exactly one `DashedBorderPainter` on a selected `selectedActionEntityId`). §11 Step 2.4 rows → Done. On-device dogfood vibe-chat verification pending. |
| 2026-09-05 | a269b88 | Pinch-on-tile fix: root cause was hit-testing, not arena resolution — with the scale recognizer on the grid's bottom background layer, pointers landing on event tiles routed to the tiles, so a finger-on-tile pinch never gave the recognizer both pointers and the arena was lost to the tiles. Fix in `dayGridWidget.dart`: the scale recognizer now lives on a topmost `Positioned` full-area overlay with `HitTestBehavior.translucent`, using `_ArenaWinningScaleGestureRecognizer` (resolves accepted the moment the 2nd pointer lands, pre-empting vertical scroll + horizontal carousel pan); single-finger input passes through to tiles/background, and a won pinch cancels tile taps. Debug `print`s removed. Tests: `test/daygrid_pinch_zoom_test.dart` extended 12 → 16 (pinch with both fingers on a tile; one finger on tile + one on background; single-finger tap on tile does not zoom; tap-to-add on empty background still works) — all 16 green; 145 tests across 16 DayGrid/grid suites green; `flutter analyze` clean on touched files. On-device verification pending. |
| 2026-09-05 | c95123f | Travel-band visibility fix: at the default zoom (80 px/hr) 3–6 min travel times produced 4–8 px band heights — below the 18 px icon threshold — so bands rendered only a 2 px gradient hairline, essentially invisible. Root cause confirmed on-device via debug overlay (red rectangles in the gutter at the correct position). Fix in `travelBandWidget.dart`: the band's effective height is clamped to `iconHeightThreshold` (18 px); for pre-bands the extra height extends upward into the empty gutter space above the tile, for post-bands it extends downward below the tile. The travel-medium icon and hairline now always render. Test updated: `test/daygrid_travel_band_test.dart` icon-threshold test now expects the icon visible at all heights ≥ 1 px (min-height clamp). All 34 tests (18 travel + 16 pinch) green; `flutter analyze` clean. |
| 2026-09-05 | a269b88, c95123f | P3 Step 3.1 — travel bands (read-only) — tracker catch-up: the step landed bundled in `a269b88` (pinch-on-tile fix) but was never recorded in §11. New `travelBandWidget.dart`: pure `TravelBand.bandsForTile` gutter-band math (pre/post bands sized by `height(travelTimeBefore/After)`, clamped to the visible day like the tiles; no band when travel is null/0), zoom-aware collapse/expand (hairline → + travel-medium icon at 18px → + duration / "leave-by" pill at 56px, mirroring `CompactTravelIndicator`; the `c95123f` min-height clamp keeps short bands visible at the default 80 px/h), tap-to-directions reusing the `TravelConnector` / `ReturnConnector` Google Maps URL construction (`daygrid_travel_band_tap`; no directions for home-return bands per `ReturnConnector._isHome`; non-tappable bands pass taps through to the tap-to-add layer), `isTardy` → `TileColors.late`. Wired into `dayGridWidget.dart`; `test/daygrid_travel_band_test.dart` (18). §11 P3 rows → Done. P3 gate still open: on-device visual QA on a dense schedule (bands + GCal columns + now-line coexisting) + independent second-engineer verification (§12.0). |
| 2026-09-08 | _TBD_ | New §14 addendum recorded (design-only, no code changes): (14.1) in grid mode the grid must start **below** the day selector, never run behind/under it (with `time(y)` anchor math accounting for the inset); (14.2) the search + settings buttons move into their own horizontal section that also shows the currently selected day; both refinements are explicitly **grid-mode-scoped** — the Daily list view's chrome and behavior must remain unchanged. Deferred; not slotted into any P1–P4 step until scheduled. |
| 2026-09-08 | _TBD_ | P4 DnD verification + tracker sync: confirmed drag/settle/persist is **day-agnostic** — it applies to the selected grid day (past, Today, future), past-day drops persist the past-day slot and are not clamped to `now`, and Today-specific behavior is limited to now-line/live-now visuals + AddTile "now" prefill (C14). §6.3 gains the day-agnostic bullet; the four §11 P4 rows (LongPressDraggable + ghost; coordinate→time snap + constraints; optimistic `updateSubEvent` + rollback; travel recompute on settle) → Done with `7c3db43` + `fcf514e` + `993424a`; §12.5 drag inventory updated to gesture 22 + persist 14 = 36 tests (incl. 3 new past-day persist tests — uncommitted at this entry). `flutter test test/daygrid_drag_persist_test.dart test/daygrid_drag_gesture_test.dart`: 36/36 green. P4 GA gate still open: rollback rate < 2% dogfood + independent second-engineer verification (§12.0). |
| 2026-09-09 | _TBD_ | §14 addendum root-caused against the current tree (still design-only, no code changes): `AuthorizedRoute.renderAuthorizedUserPageView()` composes the whole Daily page as one `Stack` — `_buildTileList()` (full-height `CarouselSlider` of `DayGridPage`s), `_ribbonCarousel()` (`Align.topCenter` → `DayRibbonTab`/`DayRibbonCarousel`), and `HomeTopRightActions` (`Positioned(top:0,right:8)`) all overlap the same coordinate space; `DayGridWidget`'s `SingleChildScrollView` starts at content y=0 with no top padding/inset and its existing `_edgeScrollBottomClearance()` pattern (bottom-only) has no top counterpart. Chosen design direction (§14.4): convert grid-mode's top chrome from Stack-overlay to real flex layout (`Column` + `Expanded`) so the grid's own scroll viewport genuinely starts below the chrome — this needs zero changes to the already-tested auto-scroll/pinch-focal/tap-to-add math (all viewport-relative), versus bolting an inset constant through every one of those call sites. List mode / Weekly / Monthly keep the exact current `Stack` untouched. New §15 adds a 4-step TDD plan (chrome extraction → new top-chrome row → Column wiring → on-device QA), gated on `DailyViewLayoutCubit == grid && currentView == Daily`. Per user instruction, no step in §15 is committed without explicit user review/approval of the diff first. |
| 2026-09-09 | _TBD_ | Two more addendum requirements folded in per user request: (1) the grid-mode day label (§14.3) must be tappable to jump to an arbitrary date — root-caused that Daily has no such affordance today (only bounded ribbon-day taps + go-to-today); chosen design (C16, §14.7) reuses the app's existing plain `showDatePicker` idiom and dispatches `DateChangeEvent` to `UiDateManagerBloc` exactly like `DayRibbonCarousel.onDateButtonTapped` does — no new bloc/event. (2) grid mode needs a path to the day summary (`TodayStatusScreen`) — root-caused that this is currently reachable **only** via `DaySummaryHeader` inside `EnhancedWithinNowBatch` (today, list mode only); `DayStatusWidget` in `status.dart` is confirmed unrelated/dead code (old `DayStatusApi` model, never mounted). Chosen design (C17, §14.6, **proposed pending confirmation**): mount the same `DaySummaryHeader` widget (unmodified) inside `DayGridPage`, today-only, matching current list-mode parity; showing it on every day is called out as a separate, deferred decision. §15 gained a new Step 15.4 (day-summary entry point + date-picker bloc wiring) between the Column-wiring step and on-device QA, and Step 15.2's scope grew to include the date-picker tap seam on `DayGridTopChromeRow`; the QA step renumbered to 15.5. §10 gained C16 (decided) and C17 (proposed, pending confirmation). Still design-only — no code changes. |
| 2026-09-09 | _TBD_ | P4 GA gate (Step 4.2's closeout: rollback rate < 2% of drags over a dogfood cycle + independent second-engineer verification, §12.4) marked **skipped / deferred** at user direction — parked to make way for the P5 chrome addendum (§14/§15), to be resumed after the addendum is done. Step 4.2's implementation stays Done (`7c3db43` + `fcf514e` + `993424a`, 36/36 DnD tests green); DnD remains behind the grid-layout toggle until the gate resumes. The §12.4 P4 gate line and the §1 status line were annotated with the deferral; the gate's criteria are unchanged. |
| 2026-09-09 | _TBD_ | C17 confirmed by user — **decided** (was "proposed, pending confirmation"): the grid-mode day-summary entry point is **today-only**, mounting the unmodified `DaySummaryHeader` at the top of today's `DayGridPage` so tapping it navigates to `TodayStatusScreen` (same `TimelineSummary` / `ScheduleSummaryBloc` pipeline as list mode). User re-stated the two interactions: tapping the day label opens the date picker (C16) and tapping the summary header opens the summary page — both already match the §14.6/§14.7 design, so no design change was needed. Status line, §10 C17 row, and §14.6 now read "Decided 2026-09-09". Also fixed the §9 P5 row's stale approval-policy cross-reference (§14.6 → §14.8). Still design-only — no code changes. |
| 2026-09-09 | _TBD_ | P5 tracker synced to committed implementation: the §9 P5 rows for Steps 15.1–15.3 are now **Done** with hashes — `b4f1d0a` (Step 15.1, chrome extraction: in-flow `HomeTopRightActionsRow` + `DayRibbonCarousel.topMargin`, overlay call sites pixel-identical), `d93d1f6` (Step 15.2, isolated `DayGridTopChromeRow` incl. the C16 date-picker seam — `onDateSelected` callback + injectable `pickDate` seam, no `UiDateManagerBloc` knowledge), `6786fd1` (Step 15.3, `GridDailyPageBody` in-flow `Column` wired into `AuthorizedRoute.renderAuthorizedUserPageView()` for Daily+grid + flexible `DailyTileList.carouselHeight`, §14.4). Steps 15.4 (`onDateSelected` → `DateChangeEvent` bloc wiring + today-only `DaySummaryHeader` in grid mode, C16/C17) and 15.5 (on-device QA) verified still Not started against the tree: `GridDailyPageBody` does not pass `onDateSelected` and no grid-mode page mounts `DaySummaryHeader`. §1 phase list annotated to match. Doc-only change — no code touched. |
| 2026-09-09 | _TBD_ | P5 Step 15.4 **Done** (C16 + C17), committed as `6092c5a` after user review/approval of the diff: `GridDailyPageBody` gained the `pickDate` seam (forwarded to `DayGridTopChromeRow`) and an `onDateSelected` handler that dispatches `DateChangeEvent` with `DateChangeTrigger.buttonPress` to `UiDateManagerBloc` — same-day and cancelled picks are no-ops, mirroring `DayRibbonCarousel.onDateButtonTapped`; `DayGridPage` mounts the unmodified `DaySummaryHeader` only when the shown day is today, and tapping it opens `TodayStatusScreen` with the day's `Timeline`. New tests 6/6 — `test/daygrid_date_picker_navigation_test.dart` (3: different-day pick → exactly one `DateChangeEvent`; cancel → none; same-day → none) + `test/daygrid_day_summary_entry_test.dart` (3: today renders the header; non-today does not; tap opens `TodayStatusScreen`); 22/22 related grid regression tests green; `flutter analyze` clean on the four touched files. Note: the `daygrid_summary_opened` tag proposed in the Step 15.4 table was **not** added in this commit (the header tap carries no tag yet) — parked as a follow-up rather than retrofitting list mode. §9 P5 row and the §11 C16/C17 rows now record `6092c5a` (re-committed 2026-09-10 as `5f9075d` — see the hash-sync entry below; `6092c5a` is no longer in the branch history; tracker rows re-pointed to `5f9075d`). Doc-only change — no code touched. |
| 2026-09-10 | _TBD_ | P5 Step 15.5 **in progress** — headless (code/test) verification completed; on-device QA pending. Tutorial-spotlight recheck (code): `TutorialKeys.scheduleViewKey` is attached to the outer full-body `Container` (`AuthorizedRoute.dart:568`, wrapping the whole daily-view `Stack`) so its geometry is identical in list and grid mode; `TutorialKeys.topRightActionsKey` is attached to the shared `HomeTopRightActionsRow` `Row` (`homeTopRightActions.dart:40`), used by both the legacy `HomeTopRightActions` `Positioned` overlay and the grid-mode `DayGridTopChromeRow` — the same `GlobalKey` now resolves to the (correct) in-flow position. `onboarding_tour_sync_test.dart` id→key contract and the `topRightActionsKey` live-mount assertion pass. Layout-contract `daygrid_chrome_layout_test.dart` green (grid viewport never overlaps chrome/ribbon; no RenderFlex overflow at the 480px short viewport; non-grid legacy-`Stack` overlay regression untouched). Date-picker + C17 green (`daygrid_date_picker_navigation_test.dart` 3/3, `daygrid_day_summary_entry_test.dart` 3/3). Grid regressions green (`ribbon_tab`, `daygrid_layout_swap`, `daygrid_banner_strip`, `daygrid_pinned_header`, `tile_carousel`, `day_ribbon_carousel`, 32). `flutter analyze` clean on the four grid-touched files (`dayGridPage`, `dayGridPageBody`, `dayGridTopChromeRow`, `homeTopRightActions`); only a pre-existing `unused_field` in `AuthorizedRoute` and a pre-existing `peekDay` error in the legacy `calendarGrid/tileDayGrid.dart` (unmodified, out of scope). One pre-existing unrelated failure: `onboarding_tour_sync_test.dart` → "chat_fab step icon matches the chat FAB" (HomeFab/onboarding chat icon — in the known-unrelated-failure set, not grid-related). The user-reported grid-mode overflow is **not reproduced** at the headless test viewports (the 480px short-viewport guard and the full-page C17 test both run with no overflow exception) — so it is a real-device geometry case (short viewport + status bar / safe-area insets) and remains an open on-device item. Remaining on-device manual checks (pending user hardware): short-viewport usable grid, tablet, safe-area insets, rotate/resize, list⇄grid no-flash, tutorial overlay visual landing, date-picker follow, C17 on-device. Doc-only change — no code touched. |
| 2026-09-10 | _TBD_ | P5 Step 15.4 hash sync: the 15.4 work (C16 bloc wiring + C17 day-summary entry) landed in branch history as `5f9075d` ("Wired date of header to uidate manager" — `dayGridPageBody.dart` pickDate seam + `onDateSelected` → `DateChangeEvent`, `dayGridPage.dart` today-only `DaySummaryHeader`, and the two new test files `daygrid_date_picker_navigation_test.dart` / `daygrid_day_summary_entry_test.dart`); the originally recorded `6092c5a` (and the intermediate `6c9ad24`) are no longer reachable from the branch — only dangling objects. Current-state references now point at `5f9075d`: §1 phase list and the §11 C16/C17 tracker rows. The 2026-09-09 entry above is preserved as the historical record (annotated in place). Doc-only change — no code touched. |
| 2026-09-10 | _TBD_ | P5 Step 15.4 hash de-referencing: `5f9075d` was itself rewritten (current HEAD of `feature/gridLayout` is `0830cad`, same message "Wired date of header to uidate manager"; the branch has been amended through Cline checkpoint cycles — `6092c5a` → `6c9ad24` → `5f9075d` → `0830cad`). Since the commit will keep changing hash until the branch is final, current-state references (§1 phase list, §11 C16/C17 tracker rows) now cite the commit **by message** ("Wired date of header to uidate manager", 2026-09-10) instead of a hash. Re-record the concrete hash once the branch is no longer being amended. Historical entries above are preserved verbatim. Doc-only change — no code touched. |
| 2026-09-10 | _TBD_ | C17 follow-up — `daygrid_summary_opened` now fires on grid-mode `DaySummaryHeader` taps with a reliable, testable seam. Seam: `DayGridPage.gridSummaryOpenTag(dayIndex)` (prints the `DayGrid::` debug line + `AnalysticsSignal.send('daygrid_summary_opened', {'dayIndex': ...})` + increments the production-inert `DayGridPage.summaryOpenTagFireCount` seam) is passed as the new optional `DaySummaryHeader.onOpen`; the header calls it from its **own deepest tap recognizer** immediately before navigating (non-preview only). Rationale (verified by a throwaway probe): an outer competing `GestureDetector.onTap` never fires because the header's deeper recognizer wins the tap arena, and a raw `Listener.onPointerUp` would overcount (fires on any pointer-up — long-press / drag-release that does not navigate). `onOpen` fires exactly once per real tap that also opens the summary, and is null for every other caller (list mode / preview), so the shared header is behaviour-identical for them. The counter is the reliable test seam because the debug line flows through the non-interceptable built-in `print` via `Utility.debugPrint` and `AnalysticsSignal.send` is a no-op in this build. Removed the dead `gridSummaryOpenTagWith` helper and the temporary `test/zz_gesture_probe_test.dart` probe. Strengthened `test/daygrid_day_summary_entry_test.dart`: the widget test asserts the grid mount wires `onOpen` (non-null) AND that the tag **fires** on a real tap (counter resets to 0, real header tap, then asserts == 1) AND navigation still occurs on the same tap; the unit test asserts the returned line's `daygrid_<area>_<event>` shape + `dayIndex` payload + `DayGrid::` prefix. Grid-only and list-mode-untagged preserved. Targeted daygrid tests green (29 across five daygrid suites incl. the 5-entry file), `flutter analyze` clean on the touched files. |
---

## 14. Addendum — grid-mode chrome layout refinement (design refined 2026-09-09; implemented via §15, Steps 15.1–15.4 done)

> Status: **Design refined and root-caused against the current tree — no code changes
> made.** These are chrome/layout adjustments to the Daily view header in **grid mode
> only** and must **not** change the behavior (or visual contract) of the Daily
> **list** view, or of Weekly/Monthly. Implementation plan: §15.

### 14.1 Verified root cause (2026-09-09)

`AuthorizedRoute.renderAuthorizedUserPageView()` ([AuthorizedRoute.dart](../lib/routes/authentication/AuthorizedRoute.dart))
builds the entire Daily page as **one `Stack`**, three layers deep, all sharing the
same coordinate space:

```dart
return Stack(children: [
  _buildTileList(scheduleState.currentView),   // layer 0: full-height CarouselSlider of DayGridPage/day pages
  _ribbonCarousel(scheduleState.currentView),  // layer 1: Align.topCenter -> DayRibbonTab | DayRibbonCarousel
  HomeTopRightActions(...),                    // layer 2: Positioned(top: 0, right: 8) -> Row of IconButtons
]);
```

- **Layer 0 — `_buildTileList()`.** For Daily this is `DailyTileList`'s `CarouselSlider`,
  sized via `CarouselOptions(height: MediaQuery.of(context).size.height, viewportFraction: 1.0)`
  ([dailyTileList.dart](../lib/components/tilelist/dailyView/dailyTileList.dart)) — i.e. it
  deliberately claims the **full screen height**, starting at y=0. Each page is a
  `DayGridPage` ([dayGridPage.dart](../lib/components/tilelist/dailyView/dayGridPage.dart)),
  which in grid mode is itself a plain `Column` (`DayGridBannerStrip` → `DayGridPinnedHeader`
  → `Expanded(DayGridWidget)`) — so the *page* is well-behaved; the problem is that the page
  starts at the very top of the screen with nothing reserved above it.
- **Layer 1 — `_ribbonCarousel()`.** For today, `DayRibbonTab` ([dayRibbonTab.dart](../lib/components/ribbons/dayRibbon/dayRibbonTab.dart)):
  `Align(Alignment.topCenter, child: Column([handle, if(expanded) SizedBox(height: 180, child: DayRibbonCarousel)]))`,
  handle ≈ 8px top margin + 6px vertical padding + one text row (≈40–44px collapsed,
  ≈220–224px expanded). For any other day, `DayRibbonCarousel` directly
  ([dayRibbonCarousel.dart](../lib/components/ribbons/dayRibbon/dayRibbonCarousel.dart)):
  `margin: EdgeInsets.fromLTRB(0, 50, 0, 0)`, `height: 130` — i.e. it bakes its own
  50px top offset in *because* it expects to be painted over content, not laid out in-flow.
- **Layer 2 — `HomeTopRightActions`.** [homeTopRightActions.dart](../lib/components/homeTopRightActions.dart):
  `Positioned(top: 0, right: 8, child: Row([layout toggle?, go-to-today?, search, settings]))`,
  ≈48px tall (standard `IconButton` hit target). Also `Positioned`, also assumes overlay.
- **`DayGridWidget`'s scroll view** ([dayGridWidget.dart](../lib/routes/authenticatedUser/calendarGrid/dayGridWidget.dart))
  starts its `SingleChildScrollView` content at y=0 with **no top padding**. It already has a
  *bottom*-only clearance pattern worth mirroring: `edgeScrollBottomClearance` (constructor
  override) / `_computeEdgeScrollBottomClearance()` (falls back to
  `MediaQuery.maybeOf(context)?.padding.bottom`), consumed by the scroll `padding`, the
  edge-auto-scroll-during-drag bounds, and the viewport-height reads used by auto-scroll-to-now
  (`_keepAnchorHourOnscreen`) and the pinch focal-anchor math. There is **no top-side
  equivalent** anywhere in that file today.

**Net effect:** in grid mode, the first visible hour rows of `DayGridWidget` render directly
behind layers 1 and 2 — confirmed, not a hypothetical — because layer 0 is never actually
given a reduced/offset viewport; it is simply painted first and then drawn over.

### 14.2 Required behavior — grid must sit *below* the day selector

- The day selector (ribbon / collapsed tab) and the new §14.3 chrome row become **solid
  chrome that reserves real vertical space** above the grid in grid mode — the grid's
  scrollable region begins strictly below them; the first visible hour row must never be
  covered.
- **Out of scope:** the list view. `EnhancedTileBatch` / `EnhancedWithinNowBatch` pages, and
  Weekly/Monthly, keep their current `Stack`-overlay layout and behavior byte-for-byte.

### 14.3 Required behavior — search + settings as their own row, with the selected day

- The **search** and **settings** buttons (and the existing layout-toggle / go-to-today
  buttons currently grouped with them in `HomeTopRightActions`) move into their **own
  horizontal section**, separate from the day selector/ribbon strip.
- That same section displays the **currently selected day** (`UiDateManagerBloc.currentDate`),
  so the user always sees which day the grid is showing alongside the actions. Reuse
  `DateTimeHuman.humanDate(context)` ([util.dart](../lib/util.dart)) for the label — it
  already renders Today/Tomorrow/localized dates and is the existing convention for this
  (see repo memory: reuse over inventing a second date-formatting path).
- The day selector (ribbon / collapsed tab, C2) remains its own strip below this row;
  day-change interactions (`DateChangeEvent`, go-to-today, ribbon tap) are unchanged.
- **The day label is tappable (C16, new 2026-09-09):** tapping it opens a date picker so
  the user can jump to an arbitrary date, not just the days visible in the ribbon/tab
  window or "today". See §14.7 for the chosen design.
- **Out of scope:** the list view keeps its existing header arrangement unchanged.

### 14.4 Proposed technical design

**Chosen shape: convert grid-mode's top chrome from `Stack`-overlay to real flex layout,
not an inset bolted onto the scroll view.** Rationale: `DayGridWidget`'s auto-scroll-to-now,
pinch focal-anchor, and tap-to-add math are already viewport-relative (`position.viewportDimension`,
`position.pixels`) and covered by 12+ green test files (§12.5); if the chrome genuinely reserves
space above the grid via `Expanded`, the grid's own viewport origin is correct by construction
and **none of that math needs to change**. An inset-padding approach would require threading a
new `topInsetClearance` through every one of those call sites (mirroring the existing
`edgeScrollBottomClearance` pattern) purely to compensate for an overlay that didn't need to
overlay in the first place — more surface area, more ways to drift out of sync on zoom changes.

```dart
// AuthorizedRoute.renderAuthorizedUserPageView(), Daily case only:
if (scheduleState.currentView == AuthorizedRouteTileListPage.Daily &&
    context.watch<DailyViewLayoutCubit>().state == DailyViewLayout.grid) {
  return Column(children: [
    DayGridTopChromeRow(...),           // NEW — §14.3: day label + search/settings/toggle/go-to-today
    _ribbonCarousel(scheduleState.currentView), // unchanged widget, now laid out in-flow, not Align-overlaid
    Expanded(child: _buildTileList(scheduleState.currentView)),
  ]);
}
// else: existing Stack(...) untouched (list mode, Weekly, Monthly)
```

Touch points this implies:

| File | Change |
|---|---|
| `lib/components/homeTopRightActions.dart` | Extract the inner `Row` of icons into a reusable, non-`Positioned` piece (e.g. `HomeTopRightActionsRow`) so both the legacy `Positioned` call site (list/Weekly/Monthly, untouched) and the new §14.3 row can share the icon logic without duplicating it. |
| `lib/components/dayGridTopChromeRow.dart` | New — grid-mode-only row: leading day label (`DateTimeHuman.humanDate`) + trailing `HomeTopRightActionsRow`. |
| `lib/components/ribbons/dayRibbon/dayRibbonCarousel.dart` | Add an in-flow variant (e.g. `topMargin: double` param, default `50` preserved for existing overlay call sites) so the Column composition doesn't double-reserve the 50px the widget currently bakes in for its overlay context. |
| [AuthorizedRoute.dart](../lib/routes/authentication/AuthorizedRoute.dart) | Branch `renderAuthorizedUserPageView()` on `DailyViewLayoutCubit` (Daily only) between the existing `Stack` and the new `Column`; keep the branch's `false` path byte-for-byte identical to today. |
| `lib/components/tilelist/dailyView/dailyTileList.dart` | `CarouselOptions.height` currently hard-codes `MediaQuery.of(context).size.height`, which conflicts with being hosted inside `Expanded` (bounded-but-not-yet-known height). Needs a `height` override param (grid-mode caller passes `constraints.maxHeight` via `LayoutBuilder`); list-mode call sites keep passing the full screen height unchanged. |
| `lib/routes/authenticatedUser/calendarGrid/dayGridWidget.dart` | **No change required** under this design — see rationale above. |

### 14.5 Guard rails

- Both refinements are **strictly grid-mode-scoped**, gated on
  `context.watch<DailyViewLayoutCubit>().state == DailyViewLayout.grid && scheduleState.currentView == AuthorizedRouteTileListPage.Daily`.
  Any other combination (list mode, Weekly, Monthly) must take the exact pre-existing `Stack` path.
- Existing list-mode/chrome tests must stay green **without modification**:
  `ribbon_tab_test.dart`, `daygrid_layout_swap_test.dart` (list path), the banner-strip and
  pinned-header tests, and `test/tile_carousel_test.dart`.
- Tutorial spotlight keys (`TutorialKeys.topRightActionsKey`, `TutorialKeys.scheduleViewKey`)
  must still resolve to sane on-screen positions once the icons move from `Positioned` overlay
  to in-flow `Row` — same `GlobalKey`, different (now correct) geometry; verify the tutorial
  overlay manually on-device, it is not covered by the widget tests below.
- No new analytics tags are required beyond what's noted per step in §15; the existing
  `daygrid_*` tag scheme (e.g. `daygrid_ribbon_expanded`) is unaffected — this is a pure
  layout change, no new user action is introduced.
- Verify on at least: a small-height phone (short viewport, ribbon expanded — does the chrome
  + expanded ribbon leave a usable grid viewport?), a tablet, and a device with top safe-area
  insets (notch/status bar via `SafeArea(bottom: false)` already wraps the whole page).
- The §14.6/§14.7 additions (day-summary entry point, tap-to-pick-date) are **also
  grid-mode-scoped** and must not add any new widget/behavior to list mode, Weekly, or
  Monthly — `DaySummaryHeader`'s existing list-mode usage in `EnhancedWithinNowBatch`
  stays exactly as-is; grid mode gets its own instance/entry point.
- Not part of any P1–P4 step in §11/§12; tracked as its own phase, **P5**, in §11's tracker
  and executed via the step-by-step plan in §15.

### 14.6 Day summary navigation from grid mode (new 2026-09-09)

**Root cause (verified 2026-09-09):** the day summary (`TodayStatusScreen`) is reachable
from exactly one place in the app today — [DaySummaryHeader](../lib/components/tilelist/dailyView/components/daySummaryHeader.dart)'s
`onTap` → `_navigateToSummary()`, which pushes
`TodayStatusScreen(timeline: Timeline(dayStart, dayEnd))`. That header is only ever
mounted by [StickyDayHeaderDelegate](../lib/components/tilelist/dailyView/components/stickyDayHeaderDelegate.dart),
which only [EnhancedWithinNowBatch](../lib/components/tilelist/dailyView/enhancedWithinNowBatch.dart)
uses — i.e. **today's list-mode page only**. `DayGridPage` (grid mode, any day) never
mounts it, so grid-mode users currently have **no path at all** to the day summary.
(`DayStatusWidget` in [status.dart](../lib/components/status.dart), referenced from
`AuthorizedRoute` but never added to the widget tree, is an unrelated, already-dead
widget from an older `DayStatusApi` model — not to be confused with `DaySummaryHeader`/
`TodayStatusScreen`, which use the current `TimelineSummary` / `ScheduleSummaryBloc`
pipeline.)

**Required behavior (grid mode only):**

- Grid mode gets an entry point to the same `TodayStatusScreen`, using the same
  `DaySummaryHeader` widget (no fork/rewrite) so the metrics (non-viable / complete /
  tardy counts) and the `ScheduleSummaryBloc` data pipeline are identical to list mode.
- **C17 (decided 2026-09-09): today-only, matching current parity.**
  Render `DaySummaryHeader` at the top of `DayGridPage`'s `Column` (above
  `DayGridBannerStrip`) **only for the day-page whose `dayIndex` is today** — exactly
  the set of days that already get it in list mode via `EnhancedWithinNowBatch`. Other
  days' `DayGridPage`s render without it, matching `EnhancedTileBatch`'s current
  (summary-less) list-mode treatment of non-today days.
  - *Rejected/deferred alternative:* show it on every day (the widget is already
    `dayIndex`-driven and would technically support this) — deferred because it would
    give grid mode a capability list mode doesn't have for non-today days, which is a
    product decision beyond "fix the chrome", and `ScheduleSummaryBloc`'s current fetch
    pattern is not verified to be efficient for arbitrary non-today days. Revisit as a
    follow-up decision (not blocking P5) if wanted.
- **Out of scope:** list mode's `EnhancedWithinNowBatch` / `EnhancedTileBatch` keep their
  exact current `DaySummaryHeader` wiring, untouched.

### 14.7 Tap the day label to pick a different date (C16, new 2026-09-09)

**Root cause / gap (verified 2026-09-09):** Daily has no "jump to an arbitrary date"
affordance today. The only date-navigation inputs are: swiping the carousel, tapping a
visible `DayButton` in the ribbon (bounded to the currently-loaded window — see
`DayRibbonCarousel.onDateButtonTapped` → `DateChangeEvent`), and the "go to today" icon.
Weekly/Monthly *do* have a tap-a-header-to-pick pattern (`WeekPickerPage`/`MonthPickerPage`
→ `WeeklyPickerDialog`/`MonthlyPickerDialog`), but those are bespoke grid dialogs wired to
their own `WeeklyUiDateManagerBloc`/`MonthlyUiDateManagerBloc` — not reusable as-is for
Daily's `UiDateManagerBloc`.

**Chosen design:** reuse Flutter's built-in `showDatePicker` — already the established
idiom elsewhere in this codebase for plain "pick one date" needs (`dateInput.dart`,
`editTile/editDate.dart`, `newTile/addTile.dart`, `accountInfo.dart`, etc.) — rather than
building a bespoke calendar dialog like Weekly/Monthly's. Daily only needs a single-date
jump, not a week/month grid concept, so the plain picker is the smaller, more consistent
addition.

- Tapping the day label in `DayGridTopChromeRow` (§14.3) calls
  `showDatePicker(context: context, initialDate: currentViewDate, firstDate: ..., lastDate: ...)`.
- On a non-null result, dispatch to `UiDateManagerBloc` exactly like the ribbon does:
  `DateChangeEvent(selectedDate: picked, previousSelectedDate: currentViewDate, dateChangeTrigger: DateChangeTrigger.buttonPress)`
  (mirrors [DayRibbonCarousel.onDateButtonTapped](../lib/components/ribbons/dayRibbon/dayRibbonCarousel.dart)).
  No new bloc/event is needed.
- `firstDate`/`lastDate` bounds: reuse whatever range the app already treats as navigable
  (check existing `showDatePicker` call sites for a shared min/max convention before
  inventing a new one; default to a generous multi-year window if none exists).
- **Out of scope:** list mode's day header (if any) is unchanged — this affordance lives
  only on the new grid-mode `DayGridTopChromeRow`.
- Analytics: `daygrid_date_picker_opened` / `daygrid_date_picker_selected`, following the
  existing `daygrid_*` tag convention.

### 14.8 Approval / commit policy for this addendum's implementation

Per explicit user instruction: **no step in §15 is committed to version control without the
user first reviewing and approving the diff.** Each step below still follows the TDD loop and
pre-commit checklist in §12.0, but the implementer stops after the "Refactor" pass and the
test run, presents the diff, and waits for explicit approval before running `git commit`
(or any push). This is stricter than the existing §12.0 sign-off convention (which assumes
an engineer commits their own verified work) — treat §15 as review-gated on top of it.

---

## 15. Step-by-step implementation plan (TDD) — P5 chrome-layout addendum

Same TDD loop and logging/telemetry conventions as §12.0, with **one addition that
overrides §12.0's commit assumption for this phase only**:

> **No `git commit` / `git add` / `git push` for any §15 step without the user explicitly
> approving the diff first.** After Red → Green → Refactor and a full local test run, stop,
> summarize the diff and test results, and wait. Do not batch multiple steps' changes into
> one approval request — each step is reviewed and (if approved) committed on its own before
> the next step starts, so the user can course-correct early.

All five steps are gated the same way: they only change behavior when
`DailyViewLayoutCubit.state == DailyViewLayout.grid && ScheduleBloc.currentView == AuthorizedRouteTileListPage.Daily`.
Every step's exit criteria include a regression check that list mode, Weekly, and Monthly are
byte-for-byte unchanged.

### Step 15.1 — Extract reusable chrome pieces (pure refactor, no behavior change)

**Goal:** make the existing overlay-only widgets reusable in an in-flow layout without
changing anything about how they render today. Zero visual/behavioral change in this step —
it's scaffolding for 15.2/15.3.

| | |
|---|---|
| Touched | `homeTopRightActions.dart` (extract inner `Row` into `HomeTopRightActionsRow`, `HomeTopRightActions` becomes a thin `Positioned(child: HomeTopRightActionsRow(...))` wrapper), `dayRibbonCarousel.dart` (add `topMargin` param, default `50` so all existing call sites are unaffected) |
| Tests first | `test/home_top_right_actions_test.dart` (new or extended) — `HomeTopRightActionsRow` renders the same icons/callbacks as before with no `Positioned` ancestor required; `HomeTopRightActions` (legacy wrapper) still renders identically (golden/property check: same icons, same tap callbacks). `test/day_ribbon_carousel_test.dart` — `topMargin: 0` renders with no top margin; omitting the param preserves the existing `50` |
| Logging | none (pure refactor) |
| Feedback | none — regression-only step |
| Exit | full existing suite green with **zero** other files touched; new tests for the two extracted params green; `flutter analyze` clean |

### Step 15.2 — `DayGridTopChromeRow` (day label + actions + date picker), built in isolation

**Goal:** the new §14.3 row — day label (`DateTimeHuman.humanDate`) leading, `HomeTopRightActionsRow` trailing — built and tested standalone, **not yet wired into `AuthorizedRoute`**. Includes the §14.7 (C16) tap-to-pick-date behavior on the label, since it lives on the same widget.

| | |
|---|---|
| New files | `lib/components/dayGridTopChromeRow.dart` |
| Tests first | `test/day_grid_top_chrome_row_test.dart` — renders today's label as "Today" (via `DateTimeHuman.humanDate`), a future/past date as its localized date; layout-toggle/go-to-today/search/settings taps invoke the right callbacks; go-to-today icon hidden when the shown day is today (mirrors current `HomeTopRightActions.isViewingToday` rule); tapping the day label invokes a mockable `showDatePicker` seam (inject via a constructor param so the test doesn't need the real platform dialog) and, given a non-null result, invokes a `onDateSelected(DateTime)` callback with that date — the widget itself does not know about `UiDateManagerBloc` (kept for step 15.3/15.4 wiring, testable in isolation here) |
| Logging | `daygrid_date_picker_opened` on tap, `daygrid_date_picker_selected` when a date comes back (both fire from this widget's callback path — see §14.7) |
| Feedback | none yet (not reachable from the app) |
| Exit | widget tests green in isolation, incl. the date-picker seam; not referenced by `AuthorizedRoute` yet (verified by grep/diff — this step must not change `AuthorizedRoute.dart`) |

### Step 15.3 — Wire the `Column` composition (the actual fix)

**Goal:** the §14.4 branch in `AuthorizedRoute.renderAuthorizedUserPageView()`; `DailyTileList`'s `CarouselOptions.height` becomes flexible for the grid-mode caller.

| | |
|---|---|
| Touched | `AuthorizedRoute.dart` (Daily+grid branch → `Column([DayGridTopChromeRow, _ribbonCarousel(...), Expanded(_buildTileList(...))])`; all other combinations keep the existing `Stack`), `dailyTileList.dart` (`CarouselOptions.height` accepts an override; default keeps `MediaQuery.of(context).size.height` for existing/list callers) |
| Tests first | `test/daygrid_chrome_layout_test.dart` — pump the Daily page in grid mode inside a bounded-height test harness: `DayGridTopChromeRow` and the ribbon/tab are laid out above the grid (assert `dy` ordering via `tester.getTopLeft`/`getBottomLeft`, not just presence); the grid's own viewport `Rect` never overlaps the chrome's `Rect`; no `RenderFlex`/overflow exceptions at a short test viewport (e.g. 480px tall) with the ribbon expanded. Separately: pump Daily **list** mode and Weekly/Monthly and assert the widget tree still contains the original `Stack` (e.g. via `find.byType(Stack)` ancestor check on `HomeTopRightActions`) — **regression proof that non-grid paths are untouched** |
| Logging | `debugPrint` (debug-only) if the `Expanded` region resolves to a non-positive height (defensive assert — should never happen once `CarouselOptions.height` is fixed, but cheap to catch a regression) |
| Feedback | none new — this is a visual-correctness fix, not a new user action. Watch existing `daygrid_ribbon_expanded` / `daygrid_layout_toggled` continue to fire normally post-change (confirms the new composition didn't break the interactions it rehosts) |
| Exit | new layout test green; full existing suite green (esp. `ribbon_tab_test.dart`, `daygrid_layout_swap_test.dart`, banner/pinned-header tests, `tile_carousel_test.dart` — all **unmodified**); `flutter analyze` clean |

### Step 15.4 — Day summary entry point (C17) + date-picker wiring (C16)

**Goal:** connect the two new §14.6/§14.7 behaviors end-to-end: `DayGridTopChromeRow.onDateSelected` dispatches `DateChangeEvent` to `UiDateManagerBloc` (mirroring `DayRibbonCarousel.onDateButtonTapped`); `DayGridPage` mounts `DaySummaryHeader` for today's day-page only (C17 default).

| | |
|---|---|
| Touched | `AuthorizedRoute.dart` (wire `DayGridTopChromeRow.onDateSelected` → `UiDateManagerBloc.add(DateChangeEvent(...))`), `dayGridPage.dart` (mount `DaySummaryHeader` above `DayGridBannerStrip` when `dayIndex == Utility.currentTime().universalDayIndex`) |
| Tests first | `test/daygrid_date_picker_navigation_test.dart` — selecting a date from the (mocked) picker dispatches `DateChangeEvent` with the right `selectedDate`/`previousSelectedDate`/`dateChangeTrigger`; a null picker result dispatches nothing. `test/daygrid_day_summary_entry_test.dart` — today's `DayGridPage` renders `DaySummaryHeader` and tapping it navigates to `TodayStatusScreen` with the expected `Timeline` (same assertion shape as any existing `DaySummaryHeader` navigation test); a non-today `DayGridPage` does **not** render `DaySummaryHeader` (C17 default). The grid-mode tag test additionally asserts the `daygrid_summary_opened` tag **actually fires on a real header tap** (observed via `DayGridPage.summaryOpenTagFireCount`, reset-then-tapped) AND that navigation still occurs on the same tap; the unit test asserts the returned debug line's `daygrid_<area>_<event>` shape + `dayIndex` payload |
| Logging | `daygrid_date_picker_selected` already fires from 15.2; `daygrid_summary_opened` fires on `DaySummaryHeader` tap **from grid mode only** (list mode's existing tap is unaffected/untagged — do not retrofit tagging onto list mode in this step). Seam: `DayGridPage.gridSummaryOpenTag(dayIndex)` (prints the `DayGrid::` debug line + `AnalysticsSignal.send('daygrid_summary_opened', {'dayIndex': ...})` + increments the production-inert `summaryOpenTagFireCount` seam). The grid mount site passes it as the new optional `DaySummaryHeader.onOpen`, which the header calls from its **own deepest tap recognizer** immediately before navigating (only for non-preview taps). This is the correct seam: an outer competing `GestureDetector.onTap` never fires (the header's deeper recognizer wins the tap arena — verified by a throwaway probe), and a raw `Listener.onPointerUp` would overcount (fires on any pointer-up, incl. long-press / drag-release that does not navigate). `onOpen` fires exactly once per real tap that also opens the summary, and `onOpen` is null for every other caller (list mode / preview), so the shared header is behaviour-identical for them |
| Feedback | **Conversion signals to watch:** date-picker open→select ratio (abandoned picker = wrong default `initialDate`/bounds); `daygrid_summary_opened` rate in grid mode vs. list mode's existing (untagged) baseline usage, as a rough parity check for C17 |
| Exit | both new test files green; full existing suite green (`DaySummaryHeader`'s own existing tests untouched — it is reused, not modified); `flutter analyze` clean |

### Step 15.5 — On-device QA + tutorial spotlight recheck

**Goal:** the one part of this addendum that can't be proven by widget tests alone — real device geometry and the tutorial overlay.

| | |
|---|---|
| Touched | none expected (verification step); fix-forward here only if QA finds a real bug, scoped back into 15.3's files |
| Manual checks | Short-viewport phone with the ribbon expanded (does a usable grid viewport remain?); tablet; a device with top safe-area insets; rotate/resize (foldables/split-screen) if available; toggle list ⇄ grid repeatedly and confirm no flash/jump; trigger the onboarding tutorial and confirm `TutorialKeys.topRightActionsKey` / `TutorialKeys.scheduleViewKey` spotlights land on the (now relocated) widgets correctly; open the date picker and pick a past/future date and confirm the carousel/grid/ribbon all follow; confirm the day summary opens from grid mode on today and is absent on other days (C17) |
| Logging | none new |
| Feedback | qualitative dogfood note in the tracker (§11 P5 row Notes) — record any device/geometry edge case found, even if not yet fixed |
| Exit | on-device checklist above completed and recorded in §11; any bugs found are filed as follow-up steps (not silently patched without going back through Red/Green/Refactor + approval) |

**P5 gate:** all five steps individually reviewed and approved by the user before commit;
independent engineer (or user) re-check of Step 15.5's manual checklist before marking §11's
P5 rows Done.

---

## 16. P6 — Visual redesign (mock 2026-09-11, decisions locked 2026-09-11, NOT implemented)

> Source: the three-state mock (1. Top of Day · 2. Mid Day scrolled · 3. Extended
> Events scrolled), image in `docs/assets/` (add when committed). Scope is **grid mode
> only** except Step 16.7 (bottom-nav labels), which is app-wide and committed on its own.
> Same review-before-commit policy as §14.8 / §15: **no step is committed without the
> user approving the diff.**

### 16.1 Decisions (C18–C27)

| # | Decision | Notes |
|---|---|---|
| **C18** | **Scroll-driven header collapse via a `center`-anchored `CustomScrollView`.** The big header (date, subtitle, day strip, banners) is a sliver placed *before* the `center` sliver, i.e. in **negative scroll extent** `[minScrollExtent, 0)`. The grid Stack is the `center` sliver and stays anchored at `pixels == 0`. | Chosen over threading a `contentTopInset` through the 9 `position.pixels` / `viewportDimension` call sites in `dayGridWidget.dart` (lines 744, 866, 914, 1084, 1135, 1156, 1168, 1171, 1585). With `center`, **none of the scroll↔time math changes** — `pixels` still equals grid-y. A header height change moves `minScrollExtent`, never the grid. The three auto-scroll paths already clamp to `0.0` (743/915/1584) so they can never reveal the header; the drag edge auto-scroll (1170) clamps to `minScrollExtent` and must be changed to `0.0` so a drag near the top edge does not pull the header down. Header reveal progress = `(-pixels / headerExtent).clamp(0, 1)`. |
| **C19** | List/grid toggle stays in the fixed top bar, left slot, in both header states. | Mock 1 omits it; treated as an omission. |
| **C20** | **Day-summary entry point moves to the fixed top bar, adjacent to the date pill, for ANY day.** Tapping it pushes `TodayStatusScreen(timeline: Timeline(dayStart, dayEnd))` for the *shown* day. | Supersedes C17's today-only `DaySummaryHeader` mount in `DayGridPage` (removed in Step 16.5). Verified 2026-09-11: `TodayStatusScreen` fetches `getTimelineSummary(widget.timeline)` directly (`todayStatusScreen.dart:74`) — no today-only assumption, no `ScheduleSummaryBloc` day-index coupling, so any-day is free. `daygrid_summary_opened` tag moves with it (payload gains `isToday`). List mode's `DaySummaryHeader` is untouched. |
| **C21** | Banner rows: **conflicts AND pending RSVP**, each its own full-width row (`N conflicts · Review →`, `N RSVPs · Respond →`), in the scrolling header. Extended tiles stay in the pinned card (`DayGridPinnedHeader`, already outside the scroll). | Reuse the three detectors `DayGridBannerStrip` already wires (`ConflictGroup.detectGroups`, `PendingRsvpBanner.detectPendingRsvpTiles`, `ExtendedTilesBanner.detectExtendedTiles`) and the same modals. `DayGridBannerStrip` chips are retired in grid mode. |
| **C22** | **No free-time blocks in the grid.** Rejected 2026-09-11. | Tap-to-add on empty space (C12–C14) stays as the affordance. `FreeSlot` model remains list-only. |
| **C23** | Day strip = `DayRibbonCarousel` **restyled compact** (circle day number + weekday abbrev, selected = filled primary), **swipeable**, laid out in the scrolling header. | Reuse the carousel + `DateChangeEvent` wiring; new compact `DayButton` variant behind a param so list/Weekly/Monthly ribbons are pixel-identical. `DayRibbonTab` (C2) is retired in grid mode only. |
| **C24** | **No glyph on the grid tile card** (revised 2026-09-11 after on-device review). Location / meeting-link details stay in the tap-out bottom sheet (`PreviewDetailsTileWidget`, which already renders the address row). The card shows accent bar + name + time range only. | Earlier draft put the location-type icon on the card; rejected on-device — it read as clutter and duplicated the sheet. No emoji extraction, no category icons either. |
| **C25** | Bottom-nav text labels (`Today` / `Tiler` / `Share`) under the icons. | App-wide, not grid-scoped — Step 16.7, its own commit. |
| **C26** | Initial landing unchanged: auto-scroll to the first tile hour / `defaultScrollHour` (header collapsed). The header is revealed by scrolling up; the top bar's date pill + summary button keep the collapsed state fully navigable. | Alternative (deferred): land at `minScrollExtent` (header visible) when the first tile starts within the first N hours. Revisit after on-device QA if the collapsed landing feels wrong. |
| **C27** | **No-snap contract** — §16.2 is normative for every step; Step 16.8 encodes it as tests. | |

### 16.2 No-snap contract (normative)

"Snap" = any single-frame, non-animated change of ≥ 4 px in the on-screen position of a
visible tile, hour line, or the grid viewport origin that the user did not cause with a
gesture. Verified-existing protections: `didUpdateWidget` keeps `pixels` on tile
refresh (`dayGridWidget.dart:575`, `DayGrid::scroll::keep`); stable carousel key across
`ScheduleLoadedState`; `ScheduleLoadingState` carries previous `subEvents` (no spinner
swap); `top`/`left` animate 300 ms; enter/exit animations.

Rules every P6 step must satisfy:

1. **Fixed top bar.** `DayGridTopChromeRow` never changes height. Its contents cross-fade
   (opacity only) by header-reveal progress. No `Visibility`/conditional children that
   change its extent.
2. **Header in negative extent (C18).** Anything in the scrolling header may change
   height freely — it moves `minScrollExtent`, not the grid. Inside the header, banner
   rows appear/disappear via `AnimatedSize` (200 ms) so the reveal area itself does not
   pop when the user *is* looking at it.
3. **Pinned card outside the scroll** (`DayGridPinnedHeader`) is the one chrome element
   that *does* shrink the grid viewport when it appears. Wrap in `AnimatedSize`; it is
   rare (an all-day tile appearing on the shown day) and the animation is the mitigation.
4. **Tile geometry animates in all four dimensions** — `top`, `left`, `width`, `height`
   — under the same 300 ms / `easeInOutCubic` / `mode == idle` / reduced-motion gate.
   (Today `width`/`height` are plain `Container` props inside the `AnimatedPositioned`.)
5. **Restyle never touches identity.** Tile `ValueKey('day_$dayIndex/<uniqueId>')`,
   `_TileLayout`, `_diffTiles`, `_lastLayoutById` are not modified by any paint step.
6. **Travel bands are not layout participants.** The in-column band draws *beneath*
   tiles (lower z, full column width); it never enters `OverlapColumns.assign`, so a
   travel recompute after settle cannot re-cluster tiles.
7. **Auto-scroll never reveals the header** (clamp lower bound `0.0` everywhere,
   including the drag edge-scroll top zone). Only a user pull-down reveals it.
8. **Day swap is the only full re-sync** (unchanged): a different `dayKey` gets a fresh
   grid and the initial scroll; same-day refreshes never re-sync.

### 16.3 Step-by-step implementation plan (TDD) — P6

Same Red → Green → Refactor loop, logging conventions, and per-step approval gate as §15.
Order is chosen risk-first: pure paint (biggest visual win, zero structural risk) → the
one structural change (scroll host) → new chrome → new rendering tiers → harness.

#### Step 16.1 — Grid body restyle (pure paint)

**Goal:** mock 2's look inside the grid: neutral hour lines and grey labels, narrower
gutter, distinct now-line accent, pastel tile cards, restyled pinned card. No layout,
identity, or gesture changes.

| | |
|---|---|
| Touched | `tileTimeCell.dart` (hour line `colorScheme.outlineVariant`-class token, 1 px; half-hour tick lighter), `timeOfDayTimeCell.dart` (label `onSurfaceVariant`, smaller), `dayGridWidget.dart` (now-line: keep `error` but add a 6 px dot at the gutter + 2 px line so it reads against grey lines; gutter width via `TileDimensions.timeOfDayCellWidth` — reduce only if the label still fits at the widest locale/AM-PM width), `tileGridWidget.dart` → `_TilerEventInnerGridWidget` (bg = tile color @ ~18 % alpha over `surface`; 3 px left accent bar in full tile color; no glyph (C24); title `onSurface` w600; second line `h:mm – h:mm` in `onSurfaceVariant` when `!tileContentCollapsed`; radius 12; the existing 32 px collapse threshold and the non-viable / dotted-border / preview treatments preserved), `dayGridPinnedHeader.dart` (card: tile color bg, white title, "All day" trailing, calendar glyph),  |
| Tests first | `test/daygrid_tile_card_style_test.dart` — time-range line present above the collapse threshold and absent below it; no icon rendered inside the card even when the tile has an address (C24); accent bar + tinted bg derive from the tile color (assert the tint math as a pure fn `TileCardStyle.from(color, scheme)`); dotted-border highlight and non-viable styling still applied. Existing `daygrid_adaptive_test.dart` (collapse threshold) and `daygrid_refresh_nowline_test.dart` (now-line keys) unchanged and green. |
| Logging | none (paint only) |
| Feedback | none new |
| Exit | all existing grid suites green **unmodified**; `flutter analyze` clean for touched files; on-device screenshot vs mock 2 (side-by-side) attached to the approval request |

#### Step 16.2 — Tile width/height transitions (no-snap rule 4)

**Goal:** close the existing gap where overlap re-clustering snaps neighbor widths.

| | |
|---|---|
| Touched | `tileGridWidget.dart` — replace the fixed `Container(height/width)` inside `AnimatedPositioned` with animated `width`/`height` on the `AnimatedPositioned` itself (same duration/curve/gates); `_RemovingTile` ghosts keep their last width |
| Tests first | extend `test/daygrid_transitions_test.dart` — adding an overlapping tile shrinks the existing tile's width over the 300 ms window (assert the width at t=150 ms is strictly between old and new); zero-duration under `disableAnimations` and while `mode != idle` |
| Exit | `daygrid_transitions_test.dart`, `daygrid_enter_exit_test.dart`, `daygrid_overlap_columns_test.dart`, all DnD tests green |

#### Step 16.3 — `CustomScrollView(center:)` host with an (initially empty) header slot (C18)

**Goal:** the single structural change, landed with **no visible difference** so it can
be verified purely by the existing suite: swap `SingleChildScrollView` for a
`center`-anchored `CustomScrollView`, add a `header` seam, and expose reveal progress.
The header itself is Step 16.4.

| | |
|---|---|
| Touched | `dayGridWidget.dart` — `SingleChildScrollView(padding: bottom)` → `CustomScrollView(controller, center: _gridCenterKey, slivers: [ if (header != null) SliverToBoxAdapter(header), SliverToBoxAdapter(key: _gridCenterKey, child: <existing Stack>), SliverToBoxAdapter(SizedBox(height: bottomClearance)) ])`; new ctor params `Widget? header`, `ValueChanged<double>? onHeaderRevealChanged` (progress `(-pixels / -minScrollExtent).clamp(0, 1)`, emitted from the scroll listener, deduped); drag edge auto-scroll top clamp `minScrollExtent` → `0.0` (line 1170); `RefreshIndicator` stays outermost (it triggers at `minScrollExtent`, i.e. after a full reveal — intended). `dayGridPage.dart` passes `header: null` for now. |
| Tests first | `test/daygrid_scroll_host_test.dart` — (a) with `header == null`, `minScrollExtent == 0` and every existing scroll assertion holds; (b) with a 240 px test header, `pixels == 0` still puts 12 AM at the top of the viewport (grid anchored), `minScrollExtent == -240`, auto-scroll-to-now / `_pendingScrollTo` / drag edge-scroll never go below `0.0`; (c) **the core no-snap test:** scroll to grid y = 600, then rebuild with a 300 px header — `pixels` still 600 and the tile at 10 AM has the same on-screen `Rect`; (d) pull-down reveals the header and `onHeaderRevealChanged` reports 0 → 1 monotonically; (e) `RefreshIndicator` still fires after a full reveal. The 4 grid tests that `find.byType(SingleChildScrollView)` (`daygrid_drag_persist_test`, `daygrid_layout_swap_test`, `daygrid_pinch_zoom_test`, `daygrid_widget_rebuild_test`) are re-pointed at `CustomScrollView` — **that finder swap is the only permitted edit to existing tests in P6.** |
| Logging | `DayGrid::scroll::reveal p=<0..1>` (debug, throttled to changes ≥ 0.05) |
| Exit | all 12+ grid suites green (4 with the finder edit only); pinch focal, tap-to-add, DnD, auto-scroll-to-now behave byte-identically on-device; `flutter analyze` clean |

#### Step 16.4 — `DayGridScrollHeader` (big date, subtitle, compact day strip, banner rows), in isolation

**Goal:** mock 1's header, built and tested standalone, not yet mounted.

| | |
|---|---|
| New files | `lib/components/dayGridScrollHeader.dart`; compact `DayButton` variant (`dayButton.dart`, param `compact: false` default → existing ribbons untouched) |
| Touched | `dayRibbonCarousel.dart` (`compact` passthrough; the `topMargin: 0` path already exists), `dayGridBannerStrip.dart` (detector logic factored into `DayGridAlerts.detect(tiles) → {conflictGroups, pendingRsvp, extended}` so the header and the pinned card share one pass; the chip renderer is deleted in Step 16.5) |
| Content | line 1: big date (`DateTimeHuman` prefix for Today/Tomorrow, e.g. "Today · Thu, Sep 11"); line 2 subtitle from the alert counts (`3 conflicts · 1 RSVP need attention` / `All clear`, l10n en+es); compact swipeable day strip (C23); banner rows (C21) each `AnimatedSize`-wrapped, tap → existing modal (conflict stack / `PendingRsvpModal`) |
| Tests first | `test/daygrid_scroll_header_test.dart` — subtitle pluralization + "All clear"; conflict row present iff conflicts, RSVP row iff pending RSVP, both when both; tapping rows opens the same modals list mode does (mock the navigator); day-strip tap dispatches `DateChangeEvent` exactly as `DayRibbonCarousel` (reuse `day_ribbon_carousel_test.dart` patterns); `compact: false` ribbons render pixel-identically (existing ribbon tests unmodified). |
| Logging | `daygrid_header_conflicts_tapped`, `daygrid_header_rsvp_tapped` |
| Exit | new tests green; not referenced by `dayGridPage.dart` yet (grep-verified) |

#### Step 16.5 — Top bar rework + mount the header + any-day summary (C19/C20) — the visible switch

**Goal:** wire it all: header mounted into the grid's negative extent; top bar becomes
`[toggle] [date pill ▾] [summary] … [search] [settings]`; the pill cross-fades by reveal
progress; summary opens `TodayStatusScreen` for the shown day; C17's today-only
`DaySummaryHeader` mount and the `DayGridBannerStrip` chips are retired from grid mode.

| | |
|---|---|
| Touched | `dayGridTopChromeRow.dart` (layout per above; pill = existing C16 picker seam + chevron, `Opacity` driven by a `ValueListenable<double>` reveal progress — at progress 1 (header fully visible) the pill fades to ~0 so the big date is not duplicated, at 0 it is fully visible; new summary `IconButton` → `Navigator.push(TodayStatusScreen(timeline: day))` + `daygrid_summary_opened {dayIndex, isToday}`), `dayGridPageBody.dart` (owns a `ValueNotifier<double> headerReveal`; forwards only the *current* day-page's `onHeaderRevealChanged`), `dayGridPage.dart` (pass `header: DayGridScrollHeader(...)`; remove the `DaySummaryHeader` mount + `DayGridBannerStrip`; keep `DayGridPinnedHeader` wrapped in `AnimatedSize`), `dayGridBannerStrip.dart` (delete the chip renderer, keep `DayGridAlerts`), `dayRibbonTab.dart` (no change — simply no longer used in grid mode) |
| Tests first | `test/daygrid_chrome_layout_test.dart` (extend; do not rewrite the legacy-Stack regression group): top bar height constant across reveal 0 → 1 and across today/non-today; pill opacity 1 at reveal 0, ≈0 at reveal 1; summary button present for today **and** for a non-today day, and pushes `TodayStatusScreen` with that day's timeline. `daygrid_day_summary_entry_test.dart` — retarget the C17 assertions at the new button ("renders for today" / "not for non-today" become "summary button for any day"). `daygrid_banner_strip_test.dart` — retarget at `DayGridAlerts` + header rows. List-mode `DaySummaryHeader` tests untouched. |
| Logging | `daygrid_summary_opened` (moved), `daygrid_date_picker_opened/selected` (unchanged) |
| Feedback | summary-open rate now split by `isToday` — the first signal on whether any-day summary earns its slot |
| Exit | all suites green; on-device: reveal/collapse is continuous (no threshold pop), no duplicate date at either end, toggle list ⇄ grid shows no flash |

#### Step 16.6 — Travel in-column band tier

**Goal:** mock 2's `Travel • 24 min  2:00 – 2:24 PM` band inside the tile column for tall
enough travel windows; the existing gutter icon tier remains for short ones (mock 3).

| | |
|---|---|
| Touched | `travelBandWidget.dart` — new tier above `expandedHeightThreshold` (56 px): a full-column-width pastel band (tertiary-tinted bg, car glyph, `Travel • N min`, time range) positioned at the travel window's `top(t)`/`height(d)`, **rendered in the `travelBandWidgets` layer beneath tiles** (rule 6); the P3 gutter pill is replaced by this band at that tier; tap-to-directions unchanged |
| Tests first | extend `test/daygrid_travel_band_test.dart` — tier selection by height (hairline < 18 / icon ≥ 18 / column band ≥ 56); band `Rect` spans the tile column; band is z-below any tile it overlaps; `OverlapColumns.assign` input unchanged with/without travel (rule 6); home-return no-directions rule preserved |
| Exit | travel + DnD suites green; settle-recompute on-device shows the band re-sizing without any tile re-clustering |

#### Step 16.7 — Bottom-nav labels (C25, app-wide, own commit)

| | |
|---|---|
| Touched | `homeBottomNav.dart` — `Text` label under each of the 3 items (`Today`/view label, `Tiler`, `Share`), l10n en+es; if the bar grows, the grid's `_computeEdgeScrollBottomClearance` already reads the real `Scaffold` bottom-bar height, so DnD bottom-edge clearance self-corrects |
| Tests first | `test/home_layout_test.dart` — extend the `HomeBottomNav` group with label assertions. The pre-existing failing `HomeFab always shows the chat icon` case is fixed in the same step: expect `Icons.auto_awesome`, matching `homeFab.dart:24`. |
| Exit | `home_layout_test.dart` fully green; grid DnD bottom-edge tests green |

#### Step 16.8 — No-snap regression harness + on-device QA

| | |
|---|---|
| New | `test/daygrid_no_snap_test.dart` — pump `GridDailyPageBody` at a bounded height, scroll the grid to y = 600, then for each perturbation assert `pixels` unchanged **and** every visible tile's `Rect` moves only via animation (sample at t = 0 / 150 / 300 ms; no ≥ 4 px jump at t = 0): (1) same-tile refresh, (2) add a non-overlapping tile, (3) add an overlapping tile (widths animate, rule 4), (4) remove a tile, (5) conflicts 3 → 0 (header shrinks; `minScrollExtent` changes, grid does not), (6) RSVP appears, (7) all-day tile appears (pinned card `AnimatedSize`), (8) `pxPerHour` change while `mode == zooming` (immediate by design — asserts the gate), (9) `now` ticks a minute. |
| Manual | short phone with the header revealed + 2 banner rows (is the grid still usable?); tablet; notch device; toggle list ⇄ grid ×10; pull-to-refresh from mid-day; DnD near the top edge (header must not reveal); tutorial spotlights (`topRightActionsKey` now spans 5 icons) |
| Exit | harness green; QA notes recorded in §11 P6 rows; C26 (initial landing) re-evaluated with a one-line verdict |

**P6 gate:** each step reviewed + approved before commit; 16.7 is committed separately from
the grid steps; §11 P6 rows flipped to Done only after 16.8's manual checklist is recorded.
