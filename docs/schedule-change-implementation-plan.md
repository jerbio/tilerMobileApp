# Schedule changes — step-by-step implementation plan

Updated October 11, 2026.
Starting point: `feature/scheduleChangeFeed` at `c97e2b69`. The original full suite there had 2304 passing, 4 skipped and 6 failing tests.
Current implementation baseline: **2354 passing, 4 skipped, 0 failing**. The implementation snapshot is approved for commit for branch testing; device, translation and backend review gates remain open. See §6 for evidence and remaining work.
Current state of the work: [schedule-change-progress.md](schedule-change-progress.md).

This plan covers the remaining work, from the current state to a reviewed merge into `main`. It is test-driven, and nothing is committed without your approval.

---

## 1. Tracker

Status keys:

- ☐ not started
- ◐ in progress
- ⏸ awaiting your review
- ✔ approved and committed
- ✖ dropped

| # | Step | Phase | Status | Tests (red → green) | Device check | Your review | Commit |
|---|---|---|---|---|---|---|---|
| 1 | Repair the 6 grid drag-gesture tests | 1 Stabilize | ⏸ | 6 failures → 25 passing | n/a | ☐ | — |
| 2 | Network loss mid-request shows *uncertain*, not *failed* | 1 Stabilize | ◐ | 12 transport tests passing | pending fault injection | ☐ | — |
| 3 | Every blocked path tells the user why | 1 Stabilize | ◐ | 5 path tests + existing notice tests passing | pending | ☐ | — |
| 10 | Uncertainty informs but no longer locks the app | 1 Stabilize | ⏸ | 14 red → 15 passing; 7 contract tests updated; told-once follow-up 4 red → 5 passing; background follow-up 1 red → passing | pending (L3′, L6′, L9, L10) | ☐ | — |
| 4 | Device verification pass | 2 Verify | ◐ | n/a | staging smoke pass; matrix open | ☐ | — |
| 5 | Translations and string review | 3 Polish | ◐ | 8 locale coverage tests passing | pending; native review open | ☐ | — |
| 6 | Retire `userDrag`, retain current motion | 3 Polish | ◐ | grid attribution + tracker/summary tests passing | pending | decision approved; diff review open | — |
| 7 | Cross-fade a replaced day on background refresh too | 3 Polish | ◐ | 13 list-flight tests passing | pending | ☐ | — |
| 8 | Diagnose "N added · N removed" after a re-optimize | 3 Polish | ◐ | 3 churn tests passing | backend cause unconfirmed | ☐ | — |
| 9 | Merge hygiene and pull request to `main` | 4 Ship | ◐ | 2354 passing, 4 skipped | final matrix pending | testing commit approved; publication and merge pending | — |

Order:

- Steps 1–3 and 10 come before the device pass, so it tests the finished behaviour. Step 10 was added on October 12 and is listed after Step 3.
- Steps 5–8 are independent of each other and can be reordered.
- Step 9 is last.

---

## 2. Working agreement

### 2.1 The loop for every step

1. **Red.** Write the step's new-behavior tests first. Run them and save failures caused by the intended behavior gap. Existing passing tests may serve as compatibility checks for behavior that must stay unchanged; do not invent a failure or change the contract merely to turn them red.
2. **Green.** Make the smallest change that turns them green. Leave unrelated code alone.
3. **Refactor.** Tidy with the tests green. Match the surrounding code, and keep design-document identifiers (phase or step numbers) out of code comments.
4. **Full suite.** Run `flutter test`. The result must be at or better than the baseline:
   - pass count up or equal;
   - the failure list a subset of the known failures.
   Compare failures by exact test identity; document any new skip or intentional count change. Counts alone cannot establish that a regression did not occur.
   Update the baseline in §5 when it improves.
5. **Analyzer.** Run `flutter analyze` on the touched files. No new errors or warnings.
6. **Logging.** Confirm the log lines listed for the step appear, by running the step's tests with output, or on device.
7. **Device check.** When the step lists one, you or I run it, with logs captured (§4).
8. **Review gate.** I stop and present:
   - the diff summary;
   - the red and green test output;
   - the full-suite result;
   - the device notes;
   - anything I'm unsure of.
   The step moves to ⏸.
9. **Commit only on your explicit "commit" / "approved".**
   - Exclude `pubspec.lock`, generated plugin files and `lib/constants.dart` unless you ask.
   - Use accurate contributor attribution; do not hard-code a different assistant's identity.
   - Record the hash in the tracker and mark ✔.
10. **Feedback.** Your comments go in the step's feedback log. Changes they ask for go back to step 1 of this loop, as a new red test when they're behavioural.

### 2.2 Rules

- **No commits without approval.** That includes "small" fixes, and test-only or docs-only changes.
- **No pushes, PRs or merges without approval.** This applies to step 9 too.
- **Visible behaviour changes go through the review gate even when every test is green.**
- **Scope.** A problem found outside the step's scope is reported and added to the tracker, not fixed in passing.
- **Branch.** Work stays on the existing `feature/scheduleChangeFeed` checkout. Record a branch mismatch before starting; do not switch branches without agreement.

### 2.3 Step template

Each step below uses these headings:

- **Goal**
- **Evidence**
- **Red** (tests to write first)
- **Green** (implementation outline)
- **Logging**
- **Device check**
- **Review checklist**
- **Done when**
- **Feedback log**

---

## 3. Steps

### Phase 1 — Stabilize

#### Step 1 — Repair the 6 grid drag-gesture tests

**Goal.** `test/daygrid_drag_gesture_test.dart` passes again, without weakening what it checks.

**Evidence.**

- A drop now goes through `ScheduleBloc.runScheduleChange`, which needs a known revision observed within 30 s.
- The test's `_RecordingScheduleBloc` starts in `ScheduleInitialState` with no revision. The drop therefore triggers a status fetch (`mutation_initialization_started`, `revisionKnown:false`), and the fake API's `update` is never reached within the test's single `pump()`.
- The ghost-snap test fails at line 597 (`updateCount` 0, expected 1). The auto-scroll tests then fail at line 876 (`api.captured!` is null).
- Exact reproduced failures: ghost snapping to 10:30; top-edge auto-scroll; jitter above the grid; jitter below the grid; bottom-edge auto-scroll; bottom-edge reach behind the bottom navigation. Full names and red output are saved in `build/schedule-change-verification/2026-10-11/schedule-drag-red.txt`.

**Red.**

- These tests are already red. Record the current output.
- Add one new test: "a drop with an unknown baseline commits once the baseline is known". It asserts that the update isn't sent before the baseline arrives, and is sent exactly once after.

**Green.**

- Give `_RecordingScheduleBloc` a known baseline: seed a `ReloadLocalScheduleEvent` with a known `ScheduleStatus`, or a fake `scheduleApi.getScheduleStatus`.
- Pump until the admitted request runs.
- No product change is expected. If one turns out to be needed, it goes through the review gate as a separate item.

**Logging.** Each drop shows:

- `DayGrid::drag::commit`;
- `mutation_reserved` with `kind: edit`;
- `transport_mutation_observed` (or, with the fake API, `mutation_callback_completed`).

**Device check.** None; this is test-only.

**Review checklist.**

- No assertion was removed or loosened.
- The new test covers the unknown-baseline drop.

**Done when.** The drag file is green, the full suite shows 0 known failures, and the baseline is updated.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

#### Step 2 — Network loss mid-request shows *uncertain*, not *failed*

**Goal.** If the connection drops, times out or resets after a write was sent, the user sees "Confirmation unavailable" with Refresh, as the lifecycle intends. They must not see "Schedule change failed", because the server may have applied the change.

**Evidence.**

- `AppApi._sendPostRequest` catches every error and rethrows it as `TilerError('Network error: …')`.
- `runScheduleChange` only treats `SocketException`, `TimeoutException` and `http.ClientException` as uncertain. Every wrapped transport error therefore lands as *failed*.
- The HTTP-layer observer usually marks the write uncertain first. The exceptions are errors raised by the `.timeout(requestTimeout)` in `_sendPostRequest` itself, and paths where the observer isn't attached.

**Red.** In `schedule_evaluation_flow_test.dart`, or a new `schedule_transport_errors_test.dart`, write tests through a real `AppApi` subclass with a controlled HTTP client:

1. A `SocketException` after send leaves the phase `uncertain`, not `failed`.
2. An `http.ClientException` after send also leaves it `uncertain`.
3. A request-level timeout after send leaves it `uncertain`.
4. A server rejection (HTTP 400) is still `failed`.
5. An error *before* send (for example, no auth) is still `failed`, and sends nothing.

**Green.**

- Keep the original error type available to the bloc. Two options:
  - (a) rethrow transport exceptions unwrapped from `_sendPostRequest`, keeping `TilerError` only for messages shown to users; or
  - (b) make `TilerError` carry the `cause`, and have `runScheduleChange` inspect it.
- (b) touches fewer callers that `catch (TilerError)`. I'll propose the choice at review with the caller list.
- Implementation choice: (b). Preserve `TilerError` across both catch layers and retain its original `cause`, excluded from JSON serialization. Both POST and PUT request-level timeout handlers now attach `TimeoutException` causes. Regression coverage also includes HTTP 408/500, pre-send authentication failure, late 2xx and response-body loss after confirmed 2xx.

**Logging.**

- `mutation_uncertain` with `reason: callback_transport_error` and `errorType`.
- Add the original exception type as `causeType` when it was wrapped.

**Device check.** Start Complete, then switch the emulator to airplane mode before the response arrives. Expect the Refresh card, not "failed". Reconnect and tap Refresh; expect a read, no replayed write, and the card clearing on a changed revision.

**Review checklist.**

- Callers that showed the "Network error" message still show a sensible message.
- No write is retried.

**Done when.** Tests 1–5 pass, the full suite is at baseline, and the device check is OK.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

#### Step 3 — Every blocked path tells the user why

**Goal.** When a write is refused because another is running, the user always sees the notice naming the running change.

**Evidence.** These paths check `scheduleChangesBlocked` and stop silently, or throw without a message:

- `lib/routes/authenticatedUser/forecast/tileProcrastinate.dart:76`: returns `Future.error(ScheduleChangeBlocked())`.
- `lib/services/notifications/localNotificationService.dart:127`: `return;`
- `lib/services/api/integrationsApi.dart:85`: throws.

**Red.** Widget or unit tests that put the bloc in a blocked state, then trigger each path:

1. Defer a single tile while blocked: the interruption notice is published with the change label, the picker stays open, and no request is sent.
2. Notification Complete while blocked: a notice is shown on next app open (or the root overlay), and nothing is sent.
3. Integration write while blocked: the caller receives `ScheduleChangeBlocked`, and the screen shows the notice.

**Green.**

- Route all three through `scheduleChangesAllowed(context)`, or the `ScheduleNoticeBus.interrupt` equivalent where there is no context (the notification service).
- The notification-click path does have a mounted app context. It uses the same guard before showing a progress toast. A notice arriving before resume is held in memory until resume, displayed for four seconds, and discarded if its context, request, account or blocking state is no longer current. It is not persisted across process termination.

**Logging.** `mutation_blocked` with `requestedKind` and `reason` for each.

**Device check.** Start a revise and, while it runs:

- defer a tile;
- complete it from a notification;
- toggle a calendar integration.

Each shows the "Finish the current schedule change (…)" notice where you're looking.

**Review checklist.** Wording and placement of each notice.

**Done when.** Tests pass and the device check is OK.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

#### Step 10 — Uncertainty informs but no longer locks the app

Added October 12, 2026 at your request. It runs after Step 3 and before the Step 4 device pass, because it changes what L2, L3 and L6 expect.

**Goal.** When a write's outcome is unknown, the user is told exactly as today, and is free to use the rest of the app. That includes starting another schedule change.

- The app keeps checking, by reads only, whether the schedule changed, and acknowledges the change when it sees it.
- The uncertainty card can be dismissed.
- The unconfirmed request is never resent. Only the user can try again, as a new request.

**Evidence (current behaviour at `d62a505a`).**

- `ScheduleEvaluation.blocksChanges` is true for *pending and uncertain*. An uncertain write therefore refuses every other schedule write until it is confirmed, the revision changes, or the 180 s deadline passes.
- The uncertain card has Refresh but no close button. Only *failed* has one (`dismissEvaluationFailure`).
- Nothing polls by itself while a write is uncertain. A revision is only re-checked:
  - on Refresh, app resume or connectivity recovery;
  - in the short 0.5 / 1 / 2 s retry burst after a *successful* change.
- The release notice says "Check your schedule before making another change", which no longer fits once uncertainty stops blocking.

**Behaviour to build.**

| # | Rule |
|---|---|
| U1 | **Same communication.** The uncertain card keeps its title ("Confirmation unavailable"), action and target ("Completing · Gym"), explanation and Refresh button. Screens that started the write still get the uncertain message, never "failed" and never a Retry button. |
| U2 | **No lock while uncertain.** Only *pending* blocks other writes. Reads, navigation, editing drafts and new schedule writes all proceed while a write is uncertain. |
| U3 | **A new write while uncertain.** <ul><li>It always fetches a fresh baseline first. That fetch is also a reconciliation check, so a changed revision acknowledges the old write before the new one starts.</li><li>If the old write is still unresolved, it moves to the background: its baseline, start time, deadline and live response listener are kept, and the card switches to the new pending write.</li><li>The background write keeps reconciling, and its outcome arrives as a notice (U5, U6, U9).</li></ul> |
| U4 | **Active reconciliation, reads only.** <ul><li>On becoming uncertain, check the schedule status immediately.</li><li>Then every 5 s for the first 30 s, then every 15 s until the deadline.</li><li>Also check on app resume, connectivity recovery and Refresh.</li><li>Pause while the app is in the background or offline. Only one check runs at a time.</li></ul> |
| U5 | **Acknowledge a changed schedule.** When a status observed after the write started differs from its baseline: <ul><li>load the new schedule (the existing revision-driven read);</li><li>clear the card;</li><li>play the change as that write's change (the cause is kept, not withdrawn);</li><li>show a short notice: *"Your schedule was updated after Completing · Gym. Check that it looks right."*</li></ul>This acknowledges the update without claiming the request succeeded. |
| U6 | **Late answers still count.** A late 2xx settles the write with a brief *"Completing · Gym went through"* and a refresh. A late 4xx shows *"Completing · Gym failed"* (dismissible). This applies to background writes too. |
| U7 | **Dismissible.** The uncertain card gets a close (×) button. <ul><li>Dismissing hides only the card. Reconciliation continues, and U5, U6 and U9 notices still appear.</li><li>The dismissal is remembered for that request, including after a restart, so the card doesn't reappear for it.</li><li>The top slot is then free for other notices, such as "N Tiles moving".</li></ul> |
| U8 | **Never resend.** No automatic retry, ever, including after reconnecting or restarting. A user re-tap is a new request with its own admission. |
| U9 | **Deadline.** At 180 s from the original start: <ul><li>polling stops;</li><li>the card (if shown) clears;</li><li>the notice reads *"Couldn't confirm Completing · Gym. Check your schedule."*</li></ul>The cause is withdrawn so a later revision plays as a background refresh, and the next write still fetches a fresh baseline. |
| U10 | **Restart.** A restored uncertain write doesn't lock either. It resumes polling for its *remaining* time and keeps its dismissed state. |

**Decisions (approved October 12, 2026).**

1. **Re-attempting the same action on the same tile while it is unresolved.** Approved: ask first, with *"Completing Gym may already have gone through. Complete it again?"* (Cancel / Complete again).
2. **Polling cadence.** Approved: 5 s for the first 30 s, then 15 s until the deadline, as status-only reads.
3. **Unresolved writes kept in the background.** Approved: up to 3, oldest released first with the U9 notice. The journal changes from one record to a list.

**Red (tests to write first).** Add these to `schedule_evaluation_flow_test.dart`, or a new `schedule_uncertain_unlock_test.dart`:

1. Uncertain doesn't block: `scheduleChangesBlocked` is false, and a second write is admitted and sent.
2. Pending still blocks: a second write is refused with the "Finish the current schedule change (…)" notice.
3. A new write while uncertain fetches a fresh baseline first. A changed revision acknowledges the old write before the new one is reserved.
4. A superseded uncertain write keeps reconciling. A later late 2xx or changed revision produces its notice without disturbing the new pending card.
5. Polling: on entering uncertain, a status check runs at once and then on the agreed cadence (fake clock). It stops at the deadline, on acknowledgement and on a late answer, and pauses while suspended.
6. Polling never sends a mutation. The request count to every mutation endpoint stays at 1 across polls, reconnects and restarts.
7. A changed revision during polling refreshes the schedule, clears the card and shows the acknowledgement notice. The change is attributed to the write: `ScheduleChange.attribution.origin` is `userComplete` for a Complete.
8. Deadline: the notice shows, polling stops, the cause is withdrawn, and the next write fetches a fresh baseline.
9. Dismiss: the × hides the card, polling continues, a later acknowledgement still shows its notice, and the card stays hidden after a rebuild and after a restart.
10. Screens that started the write show the uncertain message, never "failed" and never Retry.
11. (Decision 1) Re-tapping the same action on the same unresolved tile asks first. Cancel sends nothing; confirm sends exactly one new request.
12. Restart with a stored uncertain write: no lock, polling resumes with the remaining time, dismissed state kept.

Existing tests that assert uncertain blocks writes are updated to the new contract, and each such change is listed at review.

**Green (outline).**

- `ScheduleEvaluation.blocksChanges` becomes true for `pending` only.
- `ScheduleBloc`:
  - keeps a small list of unresolved writes alongside the active evaluation;
  - forces a fresh baseline when admitting a write while any is unresolved;
  - a reconciliation timer drives `ScheduleRevisionCubit` status checks on the U4 cadence, and reuses its suspend and resume;
  - the release path splits into acknowledged (revision changed or late 2xx), failed (late 4xx) and unconfirmed (deadline).
- Journal: a list of records, with a `dismissed` flag on each.
- `ScheduleEvaluationFeedback`: a close button in the uncertain phase, calling a new `dismissUncertainty()`.
- `ScheduleNoticeBus`: the acknowledgement, late-answer and deadline notices.
- New strings in all 9 locales:
  - acknowledged;
  - went through;
  - failed late;
  - couldn't confirm;
  - the re-attempt confirmation.
- `scheduleChangeHoldEnded` is retired, because it tells the user not to make another change.

**Logging.**

| Event | Fields |
|---|---|
| `reconcile_scheduled` / `reconcile_attempt` | `requestId`, `attempt`, `delayMs`, `remainingMs` |
| `mutation_acknowledged` | `reason`: `revision_changed` or `late_response` |
| `mutation_superseded` | old and new request ids, and whether the baseline fetch changed |
| `uncertain_dismissed` | `requestId` |
| `mutation_released_unconfirmed` | `reason: deadline_expired` (existing) |
| `mutation_blocked` | must never appear with `activePhase: uncertain` |

**Device check.**

- **L3′.** Complete a tile, then go offline before the response. The uncertain card appears.
  1. Dismiss it.
  2. Complete a different tile: it is admitted.
  3. Reconnect. The first write is acknowledged or confirmed by notice.
  4. Logs show exactly one request per tap, with `reconcile_attempt` lines between them.
- **L6′.** Use a short timeout, keep the server's schedule unchanged, and wait past it. The "Couldn't confirm" notice appears, and the app was usable throughout.
- **L9 (new).** While uncertain, re-tap Complete on the same tile. The confirmation is asked, and Cancel sends nothing.

**Review checklist.**

- Wording of the new notices and the confirmation.
- The polling cadence.
- The behaviour when a new write supersedes an uncertain one.
- No path resends a request.

**Done when.**

- Tests 1–12 pass, and the full suite is at baseline, with every changed existing test listed.
- `docs/schedule-operation-ui-flow-plan.md` is updated to the new contract.
- The device checks pass.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| 2026-10-12 | Uncertain should communicate as before but not lock the app; actively re-check for a schedule change and acknowledge it; make the card dismissible; never resend, only the user re-attempts. | Step 10 added. |
| 2026-10-12 | Decisions: ask before re-attempting the same action; re-check at 5 s for 30 s then 15 s; keep up to 3 unresolved writes. | Recorded; red tests can start. |
| 2026-10-12 | Implementation. | Red: 14 of 15 new tests failed for the intended reasons (lock still applied, no re-reads, repeat blocked instead of asked, no close button, no outcome notices, Retry offered while uncertain); the 15th (pending still blocks) is a compatibility check. Green: all 15 pass, stable over 5 runs; full suite 2369 passed, 4 skipped, 0 failed. Awaiting review. |
| 2026-10-12 | The "not sure" message arrives before the schedule is checked, so two messages sometimes come back to back. | Confirmed on device: uncertain and acknowledged in the same millisecond (22:12:53.546, 22:21:59.737). Fixed by checking once before telling; see "Told once" below. |
| 2026-10-12 | The sequence still occurred after Start Now (screenshots at 10:40 and 10:41). | Device log: the app was backgrounded at 22:40:38, Android aborted its connection at 22:40:42 ("Software caused connection abort"), and the check before telling timed out while the app was away (22:40:45), so "unconfirmed" was decided then; the change was seen at 22:41:03. Fix: decide only once the app is back in the foreground; see "Background" below. |

---

### Phase 2 — Verify

#### Step 4 — Device verification pass

**Goal.** Confirm on a device what tests can't: timing, look and real network behaviour.

**How.**

- Android emulator against the local staging server, with a debug build so logs are on.
- Capture logs per scenario (§4) and save each as `logs/<date>-<scenario>.txt`. These are local only and are not committed.
- Record the result in the table below.
- A failure becomes a new step, with a red test written first.
- Record build/version, scenario owner and evidence. Re-run affected scenarios after Steps 5–8 and after integrating `main`; the initial pass is not the release pass.
- Add OS reduced motion, large text, screen-reader access to status/Refresh, busy-schedule profile-mode timing, and the supported-platform coverage agreed for release.
- An untested or failed row remains open. A follow-up ticket must name severity, owner, acceptance criteria and whether it blocks release; creating a ticket does not itself satisfy the release gate.

**Lifecycle scenarios** (from the lifecycle doc):

| # | Scenario | Expected | Result | Log file |
|---|---|---|---|---|
| L1 | Slow re-optimize; refresh, change dates and views, lock and unlock | Tiles and pending card stay; no full-screen loader | | |
| L2 | Complete, Delete, Start Now, edit, defer; close the sheet, try another write | Each shows its own card; second write refused with the notice | | |
| L3 | Lose connection before the response; reconnect | Uncertain card; reads work; no repeated write | | |
| L4 | Late 2xx | Card clears even if hashes are unchanged or the follow-up GET fails | | |
| L5 | Kill and relaunch mid-write; switch accounts | Restored hold only for the right account; no stray callbacks | | |
| L6 | Short operation timeout via the dart define; sleep past it | Hold ends, calendar stays, next write fetches a fresh baseline | | |
| L7 | Status request fails at write time | Nothing sent, no lock, a later attempt works | | |
| L8 | Wait more than 30 s, then Complete from the tile sheet | Completes (the earlier fix); `mutation_initialization_*` then a 2xx | | |

**Motion scenarios:**

| # | Scenario | Expected | Result | Log file |
|---|---|---|---|---|
| M1 | Re-optimize in grid and list, Detailed, light and dark | Batches of 3, purple moved cue, green freed slices, amber travel | | |
| M2 | Move a tile onto another | Both tiles get the red cue | | |
| M3 | Re-optimize moving a tile from off screen into view (list) | "Moved from {time}" label with the cue | | |
| M4 | A tile moving out of view (grid) | Shrinks toward the edge chip; chip appears | | |
| M5 | A day mostly replaced | One cross-fade, no cascade | | |
| M6 | Minimal and Off modes | Minimal: one slide, no cues. Off: instant. Chip still shows. | | |
| M7 | Evaluation card plus "N Tiles moving" | Card on top, banner beneath; chip at bottom above the nav bar and FAB | | |
| M8 | Blocked write from an open tile sheet | Notice on the sheet, not behind it | | |

**Done when.** Every row is OK, or has a follow-up step in the tracker.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

### Phase 3 — Polish

#### Step 5 — Translations and string review

**Goal.** No new string falls back to English. The strings I wrote myself are checked by a native speaker.

**Evidence.**

- The audit found 14 lifecycle keys present only in en and es, including `scheduleChangesBlockedBy`. All 98 missing translations have now been added across de, el, fr, it, ja, nl and pt.
- These strings were written by me rather than a translator:
  - motion strings: "Moved from", `durationDaysHoursShort` / `durationDaysShort`, and the Schedule updates labels;
  - their de, el, fr, it, ja, nl and pt versions.

**Red.** `schedule_change_strings_test.dart` checks explicit ARB key coverage, nonempty values and required placeholders in every non-English locale. Successful generation checks ICU syntax; existing number/duration tests check rendered formats. Translation quality is a separate native-speaker gate, not a comparison with English text.

**Green.** Add the 7 missing translations of `scheduleChangesBlockedBy`, then regenerate:

```bash
flutter gen-l10n
```

Review sheet: [schedule-change-string-review.csv](schedule-change-string-review.csv), 59 keys with English and every supported translation. Native review is pending; the user coordinates reviewers and records corrections.

**Logging.** None.

**Device check.** Switch the device to Japanese and German and repeat M1 and L2 briefly.

**Review checklist.** You send the sheet to reviewers. Corrections come back as a follow-up commit.

**Done when.** Tests pass and corrections are applied.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

#### Step 6 — Drag attribution: keep or retire `userDrag`

**Goal.** Decide how a grid drag is attributed, and make the code match.

**Evidence.**

- Drag writes are `ScheduleChangeKind.edit`, which `ScheduleBloc.originOf` maps to `userEdit`.
- `ScheduleChangeOrigin.userDrag` is never produced now.
- The dropped tile is still the subject, so it settles at once. Motion looks the same today.

**Decision for you.**

Decision recorded October 11, 2026: **retire `userDrag`; keep current motion**. Grid writes remain `ScheduleChangeKind.edit` / `userEdit`, with the dropped tile as subject. The enum and stale test references have been removed. Immediate subject settling and knock-on motion are unchanged.

- (a) Retire `userDrag`. This is the simplest option.
- (b) Add `ScheduleChangeKind.move` for grid drops and map it to `userDrag`. Only worth it if drags should behave differently from other edits, or for analytics.

**Red.**

- (a): a test that a grid drop's change is `userEdit` with the dropped tile as subject. Remove `userDrag` from the resolver tests.
- (b): a test that a grid drop is `userDrag` with the dropped tile as subject.

**Green.** Per the decision.

**Logging.** `mutation_reserved` with `kind` for a drop.

**Device check.** Drag a tile in Detailed: the dropped tile settles straight away, and its neighbours step.

**Done when.** The decision is recorded in the progress doc §8 and tests pass.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

#### Step 7 — Cross-fade a replaced day on background refresh too

**Goal.** A day whose tiles were mostly swapped looks the same in the list as in the grid, whatever caused it.

**Evidence.**

- The grid decides the cross-fade from the tile ids it renders, for any update.
- The list decides it in `ListMotion.beforeRows`, which returns early for `refresh` changes.
- Re-check first: the feed refactor (`2c554653`) may have changed this. If both already match, record that and mark the step ✖.

**Red.** In `daily_list_flights_test.dart`, add: "a day swapped for new tiles by a background refresh fades in as one". It drives a revision without an admitted write and expects the list opacity to drop and then return to 1.

**Green.** Evaluate `isMostlyReplaced` before the refresh early-return. The fade only runs when the mode animates; a refresh caps the mode at Minimal, which still animates.

**Logging.** Add `DailyList::crossfade origin=<origin>`, so device logs show it ran.

**Device check.** Re-optimize the same day from another device or the web, then return to the app.

**Done when.** Tests pass and the device check is OK.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

#### Step 8 — Diagnose "N added · N removed" after a re-optimize

**Goal.** Find out whether a re-optimize really adds and removes tiles, or the server re-ids sub-events. The chip and sheet must not mislead.

**Evidence.**

- A device run showed "4 Tiles added · 4 Tiles removed" after a re-optimize, with no apparent new tiles.
- Ids are stable by agreement, except that new sub-events get new ids.

**Red.**

1. A `ScheduleDelta` test: a removed and an added tile with the same calendar event id, name and duration on the same day are reported as such, so the diagnostic below can find them. This is not a behaviour change yet.
2. A test that the diagnostic line is emitted when such pairs exist.

**Green.**

- Log `[ScheduleFlow]` event `identity_churn` with `day`, `pairs` and `calendarEventIds` counts when added and removed tiles share a calendar event id. Log no ids or names. Counts are bounded by the smaller added/removed group per parent; this is a candidate diagnostic, not evidence that the tiles are identical.
- Then check with the backend whether a re-optimize re-ids sub-events.
- If it does, a follow-up step pairs them as *moved* (by calendar event id plus position). That would be a new design decision for you, because ids would no longer be the only identity.

**Logging.** The event above, emitted once per cached change/day delta when a summary consumer computes it.

**Device check.** Re-optimize a busy day a few times and look for `identity_churn`. A missing event does not prove server ids are stable; the response needs parent calendar-event ids and an added/removed overlap.

**Done when.** The cause is known and either fixed or written up as a backend ticket.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

### Phase 4 — Ship

#### Step 9 — Merge hygiene and pull request to `main`

**Goal.** A clean, reviewable PR from `feature/scheduleChangeFeed` to `main`.

**Checklist.**

- [ ] Full suite green, or only agreed known failures listed in the PR.
- [ ] `flutter analyze` clean of new issues. Decide on the old `peekDay` error in `tileDayGrid.dart`: fix it, or leave it with a note.
- [ ] Generated plugin files and `pubspec.lock`: you decide whether they belong in this PR.
- [ ] Untracked docs and `addTile/`: you decide what to include.
- [ ] Status lines updated in the docs:
  - `schedule-change-motion-plan.md` (its header still says "Plan only");
  - `schedule-operation-ui-flow-plan.md`;
  - this plan and the progress report.
- [ ] PR description: what changed, how to test (the step 4 tables), known gaps, logging guide link.
- [ ] Merge `main` in and re-run the suite.

**Done when.** The PR text is approved, opening is authorized, required checks and review pass, release-blocking findings are closed or explicitly accepted, and the reviewed PR is merged with your approval. Opening the PR is an intermediate milestone. Draft text: [schedule-change-pr-draft.md](schedule-change-pr-draft.md). No commit, push, PR or merge has been performed.

**Feedback log.**

| Date | Feedback | Action |
|---|---|---|
| | | |

---

## 4. Logging guide for this plan

- **Debug builds** log by default.
- **Profile and release builds** need `--dart-define=TILER_SCHEDULE_LOGS=true`.
- **Android emulator:**

```bash
adb logcat -c
```

```bash
adb logcat | grep -E "ScheduleFlow|DayGrid::|DailyList::|ScheduleChange::|POST REQUEST|injectRequestParams"
```

**What to look for:**

| You see | In the log | Next |
|---|---|---|
| "Schedule change failed" immediately | `mutation_callback_error` with `sent:false`, small `ageMs` | Read `errorType`. The request threw before sending; reproduce it in a test. |
| "Schedule change failed" after a wait | `mutation_response` with `status` 4xx | Server rejection; check the request in the backend logs. |
| Refresh card | `mutation_uncertain` with a `reason` | Expected after a timeout or transport loss; check that the hold ends (`mutation_released_unconfirmed` or `mutation_finished`). |
| Nothing pending shown for a write | `transport_mutation_observed` with `lifecycleAttached:false` | Add the endpoint to `scheduleMutationKind`, or route the call through an API with bloc access. |
| A change didn't animate | `revision_changed` but no `DayGrid::steps` | Check attribution (`refresh`?), the mode setting and the delta tier. |
| Slow start of a write | Long gap between `mutation_initialization_started` and `ready` | Stale baseline fetch; check the status endpoint latency. |

When filing a finding, include:

- the scenario id from step 4;
- the log excerpt from app start through the action;
- the device, locale, theme and Schedule updates mode;
- expected and actual behaviour.

---

## 5. Baseline record

| Date | Commit | Passed | Skipped | Failed | Failing tests |
|---|---|---|---|---|---|
| 2026-10-11 | `c97e2b69` | 2304 | 4 | 6 | `daygrid_drag_gesture_test.dart` (6) |
| 2026-10-11 | working tree on `c97e2b69` | 2341 | 4 | 0 | none |
| 2026-10-11 | working tree with app feedback follow-up | 2352 | 4 | 0 | none |
| 2026-10-11 | pre-commit snapshot including blocked Shuffle fix | 2354 | 4 | 0 | none |
| 2026-10-12 | working tree on `d62a505a` with Step 10 | 2369 | 4 | 0 | none (15 new tests; same 4 skips) |
| 2026-10-12 | Step 10 with the told-once follow-up | 2374 | 4 | 0 | none (5 more tests; same 4 skips) |
| 2026-10-12 | plus the background follow-up | 2375 | 4 | 0 | none (1 more test; same 4 skips) |

## 6. Execution record — October 11, 2026

Flutter 3.44.4, Dart 3.12.2. Existing checkout retained; the implementation snapshot is approved for commit for branch testing. Local evidence is under [`build/schedule-change-verification/2026-10-11/`](../build/schedule-change-verification/2026-10-11/), which Git ignores.

- Automated checks: 170 focused tests passed; the full suite passed with 2341 tests and 4 existing skips. The six original drag failures were reproduced before the fixture repair. Transport, notification/connect feedback, refresh cross-fade, localization and churn failures were recorded before their fixes.
- Analysis: no source errors or new warnings in the touched scope. Ten existing warnings/info items remain. On Windows, passing `TilerError.dart` as an individual analysis target produces a path-case/part-library artifact; analyzing `lib/data/request` avoids it. The unrelated `peekDay` error remains a merge-hygiene decision.
- Build: Android x64 debug APK built, installed on `emulator-5554`, and launched against local staging at `10.0.2.2:44322`. Startup loaded the existing calendar. An Android 16 KB native-library compatibility dialog was dismissed for this run; native-library alignment is a separate release finding.
- Device smoke evidence: re-optimize initialized a stale baseline, retained existing tiles while pending, showed `Revising Schedule · Your schedule`, received HTTP 200 and released the hold. Logs showed a three-tile grid choreography batch. This covers parts of L1/M1 only, not the complete scenario matrix. Screenshots, UI dumps and schedule-only logs are local evidence.
- Translation review: 50-key CSV prepared; native review, Japanese/German device checks and corrections are pending.
- Backend investigation: candidate parent-ID churn detection is implemented; identity remains based on `uniqueId`. The backend cause of the earlier added/removed summary remains unconfirmed.
- Release gates: complete the device matrix and accessibility/performance/platform checks, resolve or accept the analyzer/native-library findings, finish native review and backend investigation, then review the draft PR and authorize commits/publication. No open finding is silently treated as release approval.

### App feedback follow-up

The pending spinner now surrounds the banner glyph. Edit Tile, Tile details and Add Tile keep the live evaluation card visible while their calendar is covered. Action/save/RSVP guards name the running change before opening dialogs or sending requests; destructive actions recheck admission after confirmation and pickers. Failure messages distinguish pending, uncertain and failed outcomes, identify the command and target, and suppress Retry for unconfirmed writes. Drafts survive progress transitions.

The audit also replaced generic errors in bulk completion, drag, defer, preview-add, calendar/settings/preferences, chat connection/history/send/recording/preview, forecast, notes, comments and onboarding. Useful server validation explanations remain; raw exception strings are not shown. Nine new message keys have translations in all nine locales and are included in the native-review CSV (59 keys total).

Validation: full suite **2352 passed, 4 existing skips, 0 failed**; 81 focused tests passed after the final refinements. Core feedback/editor/comment/onboarding analysis is clean; the broader settings/chat scan retains existing warnings and no source errors. `git diff --check` passes. The 11 new regressions cover blocked editor actions, admission races, draft preservation, phase-specific messages, retry suppression and retained validation detail. This follow-up has not been verified on a device; the earlier emulator evidence predates it. Evidence is saved beside the earlier logs as `operation-feedback-*.txt`.

### Blocked Shuffle follow-up

The preview sheet's Shuffle button bypassed the UI admission guard: it dispatched an event and closed the sheet, then the bloc silently rejected it while re-optimize was pending. Shuffle and Defer All now check admission before dispatch or navigation. An interruption surface on the preview sheet shows the running change there; blocked taps retain the sheet, draft and active request. Two new widget regressions exercise the actual modal buttons, verify visible feedback and unchanged request/draft state, and confirm Shuffle resumes after re-optimize completes. Validation: **39 focused tests passed**, scoped analysis is clean. Device verification is pending. Local evidence: `blocked-shuffle-*.txt` beside the earlier logs.

### Branch-testing commit

The user explicitly approved committing the relevant changes for branch testing. The snapshot includes schedule lifecycle and motion fixes, action-specific app feedback, translations, regression tests and related documentation. Generated platform/plugin files, unrelated drafts, local build evidence, `pubspec.lock` and constants are excluded. No push, PR publication or merge is authorized by this commit request.

Final pre-commit validation: **2354 passed, 4 existing skips, 0 failed**. Analysis of 57 targets has no errors and 23 existing warning/info findings; the wider scope includes unchanged notification/API code and test imports. Evidence: `pre-commit-full-suite.txt` and `pre-commit-analyze.txt`. This snapshot remains subject to the device, translation, accessibility/performance/platform and backend checks above.

### Step 10 — uncertainty no longer locks (October 12, 2026)

Evidence: [`build/schedule-change-verification/2026-10-12/`](../build/schedule-change-verification/2026-10-12/) (`uncertain-unlock-red.txt`, `uncertain-unlock-green.txt`, `uncertain-unlock-full-suite.txt`, `uncertain-unlock-analyze.txt`). Git ignores this folder.

**What changed**

- `ScheduleEvaluation.blocksChanges` is true for *pending* only. The new `awaitsOutcome` (pending or uncertain) drives deadlines and account pinning.
- `ScheduleBloc`:
  - keeps unconfirmed writes in a background list (cap 3, oldest let go with a notice);
  - re-reads the status on the agreed cadence with its own cancellable timers, paused and resumed by the recovery monitor;
  - re-reads before admitting a write while anything is unconfirmed;
  - asks `confirmReattempt` before repeating the same kind on the same tile (declining throws `ScheduleChangeDeclined` and sends nothing);
  - publishes `outcomes`: acknowledged, confirmed, failed or unconfirmed.
- Journal: background writes are stored under `<account>#background`, so dismissed writes stay hidden after a restart. A restored write found while another is in flight joins the background instead of replacing it.
- UI:
  - the uncertainty card has a close button (`dismissUncertainty`);
  - `ScheduleChangeOutcomeNotices` (in AuthorizedRoute) shows outcomes through the notice bus and provides the re-attempt dialog;
  - Retry stays hidden while the active write is uncertain.
- Strings: 9 new keys in all 9 locales. `scheduleChangeHoldEnded` is retired, because it told users not to make another change.

**Existing tests changed to the new contract** (no assertion loosened beyond the lock):

1. `HTTP 408/500 retains failure or uncertainty across reads`: `scheduleChangesBlocked` is false for 408/500 (was true).
2. `timeout and unchanged revision retain uncertainty…`: the phase stays uncertain; `scheduleChangesBlocked` is false (was true).
3. `a recovered account lock prevents the first new write from being sent` is renamed `a recovered unconfirmed write is checked in the background and does not block the first new write`: the write is sent and the restored one is in `unresolvedChanges`.
4. `restart restores an interrupted request as uncertain…`: `scheduleChangesBlocked` is false (was true).
5. `local failure feedback distinguishes an uncertain response`: not blocked while uncertain; after the deadline the message names the change ("Couldn't confirm Re-optimize · Your schedule…") instead of the retired text.
6. `operation_feedback_test` `an expired unconfirmed change does not offer replay`: expects the unnamed fallback `scheduleChangeUnconfirmedGeneric`; still no Retry.

**Found while implementing**

- A re-check finishing while the bloc closed could schedule another timer. A closing flag now stops it.
- The re-check's status read used `Future.timeout`, whose timer the bloc could not cancel. It now uses its own timer, cancelled on close.

**Open**

- Device checks L3′, L6′ and L9 (Step 10), and L2/L3/L6 re-run under the new contract (Step 4).
- The uncertainty body text still ends "This hold will end automatically", kept as agreed ("communication as before"). It may read oddly now that nothing is held.
- The new strings in de, el, fr, it, ja, nl and pt are machine-written and need the native review (Step 5).

#### Told once (follow-up, October 12, 2026)

**Problem.** When a write's outcome became unknown, the card and the screen that sent the write said "Confirmation unavailable" straight away. The first schedule read then often showed the change had applied (a read during the write had already seen it), so "Your schedule was updated…" followed immediately. The device logs show the two in the same millisecond.

**Change.**

- On an unknown outcome the bloc first reads the schedule once, bounded by `uncertaintyGrace` (3 s). Meanwhile the card keeps showing the action in progress.
  - If the schedule changed, the write is only acknowledged.
  - Otherwise the card turns to "unconfirmed" and the re-checks continue on the cadence (without repeating the read just made).
- The screen that sent the write waits for that verdict before it hears the error.
- The shared message helper tells the latest write's outcome (acknowledged, or gone through for a late 2xx during the check) and marks it told.
- The calendar's outcome notice waits 250 ms and skips an outcome a screen already told. Retry is hidden once an outcome is known.
- New log events: `mutation_confirming` (the check started; `mutation_uncertain` follows only if it stays unknown) and `mutation_confirm_read_failed`.

**Tests.** Five new tests in the "told once" group. Four were red first:

1. the caller hears before the check, and the card shows uncertain early;
2. an already-applied change is acknowledged only;
3. a late 2xx during the check is told as gone through;
4. the screen's message and the calendar notice are not both shown.

The fifth, that the check is bounded, is a compatibility check. The existing test "outcomes are told to the user" now uses one write per outcome, because a write resolves only once.

**Device check (L10).** Complete or re-optimize on a flaky connection. Expect one message per change: either "Confirmation unavailable" followed later by an outcome, or only "Your schedule was updated…".

#### Background (follow-up, October 12, 2026)

**Problem.** Android drops an app's connections a few seconds after it leaves the foreground. A schedule change sent just before the user switched away was cut off ("Software caused connection abort", after the server had applied it). The check before telling then ran while the app was still away; its read could not get through and timed out, so "unconfirmed" was decided. The change was acknowledged on return, giving the user two messages. The device log shows this for both Complete (22:39:01 paused, 22:39:06 abort) and Start Now (22:40:38, 22:40:42).

**Change.** If the outcome becomes unknown while re-checking is paused (the app is away or offline), the check waits until the app is back (`mutation_confirm_waiting_foreground`), bounded by the write's deadline. The card keeps the action in progress, and the sending screen waits for the verdict. On return the schedule is read once and the user is told once.

**Test.** "a change cut off while the app is in the background is checked when it returns, and told once": red (decided while away), then green. Full suite: 2375 passed, 4 skipped, 0 failed.

**Not addressed (separate decision).** The request itself is still lost when Android drops the connection. Keeping it alive in the background would need platform work (for example a short foreground task while a schedule change is in flight). That would avoid the uncertainty entirely in this case.
