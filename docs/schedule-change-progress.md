# Schedule changes — progress report

Updated October 11, 2026.
Branch: `feature/scheduleChangeFeed`, implementation based on `c97e2b69`. The user approved a snapshot commit for branch testing; publication and merge to `main` remain pending.
Next steps: [schedule-change-implementation-plan.md](schedule-change-implementation-plan.md).

Related design documents:

- [schedule-change-motion-plan.md](schedule-change-motion-plan.md): how changes are *shown* (motion, chips, colour cues).
- [schedule-operation-ui-flow-plan.md](schedule-operation-ui-flow-plan.md): how writes are *owned* (admission, pending / uncertain / failed, recovery).

This report covers both, as they now run as one system.

---

## 1. Where we are, in one paragraph

Every schedule-changing request now goes through one owner, `ScheduleBloc`. The bloc:

- admits one write at a time;
- shows what is running ("Completing · Gym");
- settles the write on the server's HTTP response;
- holds the write as *uncertain* when the outcome can't be known.

When the server's schedule revision changes, the bloc turns it into a single `ScheduleChange`, attributed to the write that caused it. The day grid and both daily lists read that change and play it as motion:

- Moved tiles lift, slide and land in batches of three.
- Tiles that leave the view hand off to an edge chip.
- Colour cues mark what moved, what conflicts and what free time opened.
- A "Plan updated" chip summarises the change and opens a before/after view.

A per-device **Schedule updates** setting (Off / Minimal / Detailed) controls how much motion plays.

---

## 2. Branches and commits

| Commit | Date | Branch of origin | What it delivered |
|---|---|---|---|
| `ba3f129f` | Oct 8 | feature/uiDelayedRender | Schedule diff, change tracker, Schedule updates setting, summary chip and sheet, grid choreography, gutter rail, edge chips, list anchor and flights, colour cues. |
| `de7dcb2b` | Oct 9 | feature/uiDelayedRender | Chips placed above the nav bar and clear of the FAB; one combined chip for tiles moved to other days. |
| `70cabeaa` | Oct 9 | feature/uiDelayedRender | Free-time band shows only the freed slices; before/after view in "What changed"; localized numbers and durations; opaque light-mode chip; longer cue hold (Detailed only). |
| `35d8ebdb`, `0b805f33` | Oct 9 | feature/uiDelayedRender | UI refresher on schedule change; macOS clean-up. |
| `c7aa15f5` | Oct 9 | feature/uiDelayedRender | Remaining schedule-changing saves recorded as user changes. |
| `3b611298`, `ff8fb0df` | Oct 9 | feature/uiDelayedRender | 9 stale tests fixed; localized day abbreviations; opaque light inverse surface; red conflict cue; "Moved from" label; cross-fade for a replaced day; grid tiles shrink into their edge chip; moved cue switched to the accent colour. |
| `4fdad582`, `147d6147` | Oct 11 | bug/updateAfterAsyncProcess | Writes owned by `ScheduleBloc` with bounded evaluation feedback (pending / uncertain / failed), persisted journal, recovery. Also: the closed-sheet Complete fix and the blocked message naming the running change. |
| `3e8e55b2` | Oct 11 | merge | Motion work merged into the evaluation lifecycle; conflicts resolved in favour of `runScheduleChange`. |
| `2c554653` | Oct 11 | bug/updateAfterAsyncProcess | `ScheduleChangeFeed`: one change per new revision, attributed from the lifecycle. All hand-wired attribution (`beginChange`, `PendingScheduleChange`) removed. |
| `c97e2b69` | Oct 11 | bug/updateAfterAsyncProcess | `ScheduleNoticeBus` / `ScheduleNoticeSurface`: notices show where the user is looking; the calendar arbitrates its top and bottom slots. |

`feature/uiDelayedRender` is fully contained in the current branch. No further work is planned on it.

---

## 3. How it fits together

```
 UI action (complete, revise, drag, edit, add, …)
        │
        ▼
 ScheduleBloc.runScheduleChange(kind, eventName, affectedTileIds)
   ├─ needs a fresh baseline revision (≤ 30 s old) → fetches status if not
   ├─ reserves one ScheduleEvaluation (pending) → blocks other writes
   ├─ records the cause with ScheduleChangeTracker (kind → origin)
   └─ runs the request in a zone that names this change and its bloc
        │
        ▼
 AppApi.sendPostRequest → scheduleMutationKind(method, path)  (allow-list)
        │   nested API calls join the same evaluation
        ▼
 RetryHttpClient → ScheduleBloc.observeScheduleResponse
   ├─ 2xx            → settle (success) → refresh the schedule
   ├─ 4xx            → failed (dismissible card)
   └─ 408/5xx/timeout/transport → uncertain (Refresh card, deadline)
        │
        ▼
 New schedule state with a new revision (analysisId, evaluationId)
        │
        ▼
 ScheduleChangeFeed.observe  (in ScheduleBloc.onChange, before any widget)
   └─ one ScheduleChange{revision, attribution, before, after} per new revision
        │
        ├─▶ ScheduleChangeScope / ScheduleChangeConsumer
        │      ├─ DayGridWidget        → GridChoreography + GridStepPlayer
        │      ├─ EnhancedTileBatch    → ListMotion (anchor, flights, cues)
        │      └─ EnhancedWithinNowBatch → ListMotion
        └─▶ ScheduleChangeSummaryHost  → "Plan updated" chip, sheet, before/after

 ScheduleNoticeBus ──▶ ScheduleNoticeSurface
   top slot:    evaluation card ("Completing · Gym"), then "N Tiles moving"
   bottom slot: "Plan updated" chip, taken over by interruptions
   interruptions ("Finish the current schedule change (…)") → the surface the
   user is looking at (an open tile sheet), else the root overlay
```

### 3.1 How the cause of a change is decided

| Write kind (`ScheduleChangeKind`) | Motion origin | Effect on motion |
|---|---|---|
| revise, shuffle | `tilerRevise` | Full choreography in Detailed. |
| add | `userAdd` | The new tile is the subject; others step around it. |
| complete | `userComplete` | Subject is the completed tile when exactly one. |
| edit, delete, defer, startNow, pause, resume, settings, accept | `userEdit` | Knock-on moves are stepped; the subject settles at once. |
| (no write claimed the revision) | `refresh` | Capped at Minimal: no choreography, no chips. |

Supporting rules:

- A write that fails or expires withdraws its claim, so it can't mislabel a later revision.
- A pending claim older than 2 minutes is dropped.
- The effective motion mode is the lowest of three caps: the user setting, OS reduced motion (which caps it at Off) and origin (`refresh` caps it at Minimal).

---

## 4. What is built

### 4.1 Write lifecycle (evaluation)

Full detail: [schedule-operation-ui-flow-plan.md](schedule-operation-ui-flow-plan.md). Headlines:

- **Admission.** One write at a time. A second tap is refused before anything is sent, and the user is told what is still running.
- **Baseline.** A write needs known revision hashes observed within the last 30 s. Otherwise the app fetches status first, with a 30 s initialization timeout and no lock while it waits.
- **Outcome.**
  - 2xx settles the write.
  - Explicit rejection marks it failed.
  - Timeout, transport loss, 408 or 5xx leave it uncertain until a changed revision, a late response or the 180 s deadline.
- **Persistence.** The journal survives a process restart and is validated before it restores a lock. Writes are never replayed.
- **Ownership across screens.** A request made as part of a change finds its bloc through the change itself, so closing the sheet that started it no longer breaks it.

### 4.2 Change detection

- `ScheduleChangeFeed` produces one `ScheduleChange` per new known revision. It also accepts states that are still evaluating, so a read that lands before the write settles still animates, and the loaded state that follows produces nothing.
- `ScheduleDelta` diffs one day by `uniqueId`. Third-party tiles match on `thirdpartyId`. It provides:
  - change kinds: moved, resized, movedAndResized, movedToOtherDay, movedFromOtherDay, added, removed;
  - travel changes and clusters;
  - batches of 3, with at most 3 batches;
  - tiers: none, single, batched, compressed, dayEmptied, dayFilled;
  - free-time gained, including the exact freed slices;
  - new conflicts;
  - "mostly replaced";
  - the anchor tile.

### 4.3 Motion and cues

| Area | Detailed | Minimal | Off |
|---|---|---|---|
| Grid: lift, slide, land in batches of 3, cause first | ✔ | one 300 ms slide | jump |
| Grid: outline at the old spot ("Moved to 7:20 PM"), gutter rail | ✔ | — | — |
| Grid: tile shrinks toward its edge chip as it leaves the view | ✔ | — | — |
| List: anchor tile keeps its screen position | ✔ animated | ✔ animated | ✔ jump |
| List: moved rows fly from old row to new (FLIP overlay) | ✔ | — | — |
| List: "Moved from 6:00 PM" on tiles arriving from off screen | ✔ | — | — |
| Edge chips for tiles moved above/below the view or to other days (one combined day chip) | ✔ | ✔ | ✔ (no delay) |
| Colour cues (1 s hold, 300 ms fade) | ✔ | — | — |
| Day mostly replaced: one cross-fade | ✔ | ✔ | — |
| "Plan updated" chip, *What changed* sheet, Before & after view | ✔ | ✔ | ✔ |
| Travel and free-slot durations count up | ✔ | ✔ | — |

Colour cues:

| Cue | Light | Dark | Meaning |
|---|---|---|---|
| Moved | `#6750A4` (accent) | `#B3C2F2` | Tiler moved this tile (also used for the outline, rail and labels). |
| Conflict | `#D11819` | `#FF6B6B` | The tile now overlaps another it didn't, or became late. |
| Free time | `#1C9466` | `#3CC28C` | Time freed by the change (freed slices only). |
| Travel | `#C98200` | `#F0A92A` | Travel into a tile changed; shown before the tiles it pushed. |

### 4.4 Setting

**Settings → Schedule updates** offers Detailed (default), Minimal and Off.

- The setting is stored per device under the key `scheduleUpdateMode`.
- Changing it sends the analytics event `schedule_update_mode_changed {from, to}`.

### 4.5 Localization

- Every new string exists in all 9 locales (en, de, el, es, fr, it, ja, nl, pt).
- Counts use the locale's number format.
- Durations use one short style per language, e.g. `5 Std 39 min`, `5時間39分`, `2 T 3 Std`.
- **Exception:** `scheduleChangesBlockedBy` exists in en and es only; the other locales fall back to English.

---

## 5. Bugs found and fixed

| Symptom | Cause | Fix | Commit | Test |
|---|---|---|---|---|
| "Schedule change failed" every time Complete was tapped from the tile sheet. | The sheet closed while the app fetched a fresh baseline. The request then asked the closed sheet's context for the bloc, which threw, and nothing was sent (failed after 5 ms with `errorType: FlutterError`). | Requests made for a change find the bloc through the change's zone; a gone context returns "no bloc" instead of throwing. | `147d6147` | `schedule_change_closed_screen_test.dart` |
| A blocked second write said only "Finish the current schedule change…". | No detail passed. | Names the running change: "(Completing · Gym)". | `147d6147` | `schedule_changes_blocked_message_test.dart` |
| Moved and conflict cues looked the same. | Moved used the brand primary, which is red. | Moved uses the accent purple. | `ff8fb0df` | `schedule_change_flash_test.dart` |
| An invalid "+16 min free" band in the grid. | The band tinted the whole merged gap. | Only the freed slices are tinted. | `70cabeaa` | `schedule_delta_test.dart` |
| Chips hidden behind the nav bar or overlapping the FAB. | The `extendBody` inset was ignored. | `ScheduleChipInsets` shared by both views. | `de7dcb2b` | `schedule_chip_placement_test.dart` |
| Light-mode chip was translucent. | The theme's `inverseSurface` was `black54`. | Opaque chip colours, then an opaque light inverse surface app-wide. | `70cabeaa`, `3b611298` | — |
| Highlights disappeared too soon. | The hold was too short. | Hold of 1000 ms, Detailed only. | `70cabeaa` | `schedule_change_flash_test.dart` |
| "2d 3h" was English in every language. | Hard-coded in `Utility.toHuman`. | `durationDaysHoursShort` / `durationDaysShort`. | `3b611298` | `schedule_change_numbers_l10n_test.dart` |
| Many edits animated as background refreshes. | Each flow had to call `beginChange` by hand. | Attribution derived from the write lifecycle. | `2c554653` | `schedule_evaluation_flow_test.dart` |
| A blocked message showed behind the open tile sheet. | The SnackBar was attached to the calendar scaffold. | Notice bus routes it to the visible surface. | `c97e2b69` | `schedule_notice_test.dart` |

---

## 6. Tests

Original full suite at `c97e2b69`: **2304 passed, 4 skipped, 6 failed**. Final pre-commit snapshot: **2354 passed, 4 skipped, 0 failed**. The initial 170 focused schedule tests, 81 app-feedback tests and 39 blocked-Shuffle/notice/editor/layout tests also passed at their respective checkpoints. Flutter 3.44.4 / Dart 3.12.2. Evidence and exact remaining gates are recorded in the implementation plan §6.

The original 6 failures in `test/daygrid_drag_gesture_test.dart` were repaired by giving the fake bloc a known revision. A new test confirms an unknown-baseline drop waits and commits once. The file now has 25 passing tests, including `userEdit` attribution and subject settling.

Skipped tests:

- `tile_share_activity_test`: needs the backend `WagTapWeb` fixtures checked out next to the app.
- Three pre-existing skips: analytics send is a no-op, add-tile live acceptance needs credentials, and the location picker contract awaits its widget.

| Suite | Tests | Covers |
|---|---|---|
| `schedule_evaluation_flow_test.dart` | 39 | Admission, outcomes, recovery, journal, feedback card, mid-evaluation reads. |
| `schedule_change_closed_screen_test.dart` | 2 | Requests whose screen closed still reach the bloc. |
| `schedule_changes_blocked_message_test.dart` | 3 | Blocked message naming the running change. |
| `schedule_notice_test.dart` | 7 | Notice bus, slot arbitration, message over an open sheet. |
| `schedule_revision_cubit_test.dart` | 8 | Revision detection and freshness. |
| `schedule_change_tracker_test.dart` | 16 | Claiming, withdrawing and expiring attributions. |
| `schedule_delta_test.dart` | 35 | Classification, batches, tiers, anchor, gaps, conflicts, replacement. |
| `schedule_motion_test.dart` | 14 | Setting persistence, cubit, mode resolver table. |
| `schedule_change_summary_test.dart` | 20 | Chip, sheet, tier delays. |
| `schedule_change_flash_test.dart` | 14 | Cue timing in grid and list; conflict cue. |
| `schedule_change_before_after_test.dart` | 3 | Before & after view. |
| `schedule_chip_placement_test.dart` | 3 | Nav bar and FAB clearance. |
| `schedule_change_numbers_l10n_test.dart` | 6 | Locale numbers and durations. |
| `daygrid_step_changes_test.dart` | 10 | Grid choreography plan and playback. |
| `daygrid_handoff_test.dart` | 14 | Edge chips, rail, shrink into chip. |
| `daily_list_anchor_test.dart` | 8 | Anchor preservation. |
| `daily_list_flights_test.dart` | 11 | Flights, "Moved from", cross-fade, chips. |
| `schedule_transport_errors_test.dart` | 12 | Wrapped POST/PUT causes, request-level timeout, 400/408/500, pre-send failure, late 2xx and body loss after confirmation. |
| `schedule_blocked_paths_test.dart` | 5 | Defer, notification and connect refusal; deferred background notices and obsolete-hold discard. |
| `schedule_change_strings_test.dart` | 8 | Explicit ARB coverage and required placeholders in every non-English locale. |
| `schedule_identity_churn_test.dart` | 3 | Candidate shared-parent counts, unchanged added/removed semantics, once-per-day logging without event contents. |

The list-flight suite now has 13 tests; the grid drag-gesture suite has 25. The earlier counts above describe the initial implementation.

Run commands:

```bash
flutter test
```

```bash
flutter test test/schedule_evaluation_flow_test.dart test/schedule_change_closed_screen_test.dart test/schedule_notice_test.dart
```

---

## 7. Logging and diagnostics

### 7.1 Capturing logs

- **Debug builds** log by default.
- **Profile and release builds** need `--dart-define=TILER_SCHEDULE_LOGS=true`.
- On the Android emulator, run this, then repeat the action:

```bash
adb logcat -c
```

```bash
adb logcat | grep -E "ScheduleFlow|DayGrid::|DailyList::|POST REQUEST|Error in injectRequestParams"
```

Capture from app start through the failing action, so journal restoration and baseline fetches are included. `adb` is under `%LOCALAPPDATA%\Android\Sdk\platform-tools`.

### 7.2 Log sources

| Prefix | Source | What it tells you |
|---|---|---|
| `[ScheduleFlow] {"event": …}` | `schedule_diagnostics.dart` (bloc, HTTP client, revision cubit, recovery monitor) | Request lifecycle, reads, revisions, journal, connectivity. No credentials, hashes, bodies or tile contents. |
| `DayGrid::steps <origin>: 3+3+1 tiles` | `dayGridWidget.dart` | A change was stepped in the grid, with batch sizes. |
| `DayGrid::handoff later:2 nextDay:1` | `dayGridWidget.dart` | Edge chips queued. |
| `DayGrid::drag::lift/hold/drop/commit/settle/rollback` | `dayGridWidget.dart` | Drag-to-reschedule stages. |
| `DailyList::anchor`, `DailyList::handoff` | `listAnchor.dart`, `listMotion.dart` | List anchor correction and chips. |
| `Sending / Called / Concluded Sending POST REQUEST <path> Code: <n>` | `appApi.dart` | Raw request progress and HTTP status. |

### 7.3 Symptom → log signature

| Symptom | Look for | Meaning |
|---|---|---|
| "Schedule change failed" immediately | `mutation_callback_error` with `sent:false` and a small `ageMs`, followed by `mutation_finished success:false` | The request threw before sending. The `errorType` names the class; check the nearby `Error in injectRequestParams` lines. |
| "Schedule change failed" after a wait | `mutation_response` with `status` 4xx | The server rejected the write. |
| "Confirmation unavailable" / Refresh card | `mutation_uncertain` with a `reason` (`response_timeout`, `transport_error`, `http_response_unconfirmed`) | Outcome unknown; see the lifecycle doc's table. |
| Write never shows as pending | `transport_mutation_observed` with `lifecycleAttached:false` | A write reached HTTP without bloc ownership; its endpoint may be missing from `scheduleMutationKind`. |
| A second action refused | `mutation_blocked` with `reason` | Another write is pending or initializing. |
| A change didn't animate | No `DayGrid::steps` after `revision_changed` | The change was attributed as refresh, the mode is not Detailed, or the tier is compressed, emptied or filled. |
| Slow start before the request | `mutation_initialization_started` → `ready` gap | The baseline was stale (>30 s) and had to be fetched. |

### 7.4 Analytics events

| Event | Fields |
|---|---|
| `schedule_update_mode_changed` | from, to |
| `schedule_change_summary_shown` | origin, moved, movedToOtherDays, … (counts) |
| `schedule_change_details_opened` | origin |
| `daygrid_handoff_tapped` | direction |
| `daily_list_handoff_tapped` | direction |

---

## 8. Decisions on record

- **Undo:** none, because the backend has no support.
- **Per-tile reasons:** none, because the server gives none. The sheet shows `old → new`, plus a travel cause when the diff shows one.
- **Identity:** tiles are matched by `uniqueId`, which is `thirdpartyId` for third-party tiles. A new id is a new tile.
- **Anchor:** chosen per change from the incoming delta; nothing is stored.
- **Batching:** batches of 3, at most 3 batches. Larger changes fall back to a compressed transition plus the chip.
- **Defaults:** Detailed by default. Background refreshes never get full choreography.
- **Drag attribution (October 11, 2026):** retire unused `userDrag`; keep `userEdit` plus the dropped tile's subject id. Immediate settling and knock-on motion stay unchanged.
- **Cue colours:** red means *conflict* only; moves use the accent.
- **Detection:** schedule-write detection lives at the HTTP layer as an allow-list (`scheduleMutationKind`), because it also drives the write lock. A new schedule-writing endpoint must be added there.
- **No replay:** writes are never retried automatically, and releasing an uncertain hold doesn't claim success.
- **Code hygiene:** no design-document identifiers (phase or step ids) in code comments.
- **Commits:** never committed without the user's explicit approval (see the plan's working agreement).

---

## 9. Known gaps

Each has a step in the implementation plan.

1. Drag tests repaired; snapshot commit approved for branch testing. Final review remains open.
2. Wrapped transport causes and POST/PUT timeout causes now preserve uncertainty, covered by 12 transport tests; real-device fault injection remains open.
3. Single-tile defer, notification complete and integration connect now share explanatory guards. Background notices wait for resume and discard obsolete holds. Five path regressions pass; final device checks remain open.
4. Fourteen lifecycle strings were missing in each of 7 locales. All 98 translations were added and regenerated, with nine additional app-feedback keys translated in all nine locales; the [59-key review sheet](schedule-change-string-review.csv) still needs native review.
5. `userDrag` retirement approved and implemented; final drag device check remains open.
6. Unexplained "4 Tiles added · 4 Tiles removed" after a re-optimize: counts-only `identity_churn` diagnostics and tests are implemented. Backend cause remains unconfirmed; identity semantics have not changed.
7. Background-refresh list replacement cross-fade implemented and tested, including OS reduced motion; final device check remains open.
8. Android debug build/install/startup and staging re-optimize smoke checks passed. The complete device matrix remains open for:
   - the lifecycle checks (8 scenarios in the implementation plan);
   - the motion extras: accent cue, conflict cue, "Moved from", cross-fade, shrink;
   - the closed-sheet Complete fix;
   - notice routing, including the latest blocked Shuffle/Defer All fix;
   - spinner placement and editor progress/draft preservation.
9. Merge hygiene:
   - generated plugin files;
   - untracked docs;
   - the analyzer error in `tileDayGrid.dart` (`peekDay`), which predates this work;
   - the PR to `main`.
   - the emulator's Android 16 KB native-library compatibility warning, which needs a separate release decision.

---

## 10. File index

| Area | Files |
|---|---|
| Lifecycle | `lib/bloc/schedule/schedule_bloc.dart`, `schedule_evaluation.dart`, `schedule_diagnostics.dart`, `schedule_recovery_monitor.dart`, `schedule_revision_cubit.dart`, `lib/services/api/appApi.dart`, `retryHttpClient.dart` |
| Detection and attribution | `lib/bloc/schedule/schedule_change_feed.dart`, `schedule_change_tracker.dart`, `lib/components/scheduleChangeScope.dart`, `lib/services/scheduleDelta.dart` |
| Setting | `lib/services/scheduleMotionPreferences.dart`, `scheduleMotion.dart`, `lib/bloc/scheduleMotion/schedule_motion_cubit.dart`, `lib/routes/authenticatedUser/settings/scheduleUpdatesSetting.dart` |
| Grid motion | `lib/routes/authenticatedUser/calendarGrid/motion/*` (choreography, step player, ghost, rail, emphasis, handoff, chip, free-gap flash), `dayGridWidget.dart`, `tileGridWidget.dart`, `travelBandWidget.dart` |
| List motion | `lib/components/tilelist/dailyView/motion/*` (anchor, flights, motion, counting duration), `enhancedTileBatch.dart`, `enhancedWithinNowBatch.dart`, `tileConnectorLayout.dart` |
| Summary and notices | `lib/services/scheduleChangeSummary.dart`, `lib/components/tilelist/dailyView/scheduleChangeSummaryChip.dart`, `scheduleChangeSummaryHost.dart`, `scheduleChangeBeforeAfter.dart`, `lib/components/scheduleEvaluationFeedback.dart`, `lib/components/scheduleNotices/*`, `lib/components/scheduleChipInsets.dart` |
| Cues | `lib/services/changeFlash.dart` |
