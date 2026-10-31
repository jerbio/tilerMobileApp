# Schedule operation UI flow plan

Updated October 11, 2026. Status: evaluation-based implementation with baseline initialization and bounded recovery; device verification remains outstanding.

## Agreed behavior

> **Updated October 12, 2026.** An *uncertain* write no longer blocks other writes. The app re-reads the schedule on its own and acknowledges a change, the uncertainty card can be dismissed, and requests are still never resent. Implementation and tests: Step 10 in [schedule-change-implementation-plan.md](schedule-change-implementation-plan.md).

A schedule-changing request starts only after at least one nonempty analysis or evaluation hash and its observation time are available. The status endpoint can return an evaluation without an analysis; either hash supplies a baseline. Null and empty optional hashes are equivalent when comparing revisions, and a response with neither hash cannot admit a write. Its pending feedback survives GET, local reload, revision changes, calendar navigation, and app resume. Its own successful 2xx response or confirmed failure settles it. A fixed deadline also ends the hold without claiming success.

The calendar remains visible while the change runs. Complete, Delete, Start Now, Pause, Resume, Defer, and Revise retain action-specific transient feedback. While a write is in flight (pending), another schedule write is rejected before it is sent. A write whose outcome is unknown (uncertain) does not block: reads, navigation and new writes all proceed. Re-tapping the same action on the same tile while it is unconfirmed asks first ("… may already have gone through. Send it again?"); declining sends nothing.

The backend has no idempotency key. ScheduleRevision detects changes to schedule data; it does not identify which request finished. Changed hashes preserve a live pending request. For an interrupted/uncertain request, a fresh revision observed after its original start can release the hold when either hash differs from its saved baseline. This records reconciliation, not confirmed success of that particular request.

## Ownership

[ScheduleBloc](../lib/bloc/schedule/schedule_bloc.dart) owns request admission, identity, outcome, and the pending lifecycle. [ScheduleEvaluationState](../lib/bloc/schedule/schedule_state.dart) carries that lifecycle together with the current calendar snapshot. [ScheduleRevisionCubit](../lib/bloc/schedule/schedule_revision_cubit.dart) retains its existing responsibility for detecting changed schedule hashes.

There is no separate operation cubit or global operation host. The previous `ScheduleOperationCubit` and `ScheduleOperationHost` are retired. [ScheduleEvaluation](../lib/bloc/schedule/schedule_evaluation.dart) is an immutable request record, and its store is a persistence helper, not another state owner.

| Component | Responsibility |
| --- | --- |
| ScheduleBloc | Initialize a fresh baseline, serialize preparation, reserve one mutation, enforce its deadline, and project evaluation into calendar emissions. |
| ScheduleEvaluationState | Current tiles, timelines, view, request phase, action kind, captured event name/count, and independent fetching flag. |
| ScheduleRevisionCubit | Detect analysisId/evaluationId changes, record the observation time, and check freshness after changes or recovery. |
| AppApi | Admit schedule writes before authentication/location/request preparation; retain the bloc after the initiating widget closes. |
| RetryHttpClient | Report the original transport response to the owning bloc and send mutations once. |
| Calendar renderers | Render existing content plus compact evaluation feedback, keeping the calendar mounted. |

## Request lifecycle

1. A change that cannot start because the status cannot be read (server unavailable, unknown hashes, initialization timeout) sends nothing; the user is told once that it was not sent, with a safe Retry (`notSent` outcome). `runScheduleChange` checks for known, sufficiently recent hashes. Otherwise it fetches schedule status within a separate initialization timeout. Initialization failure sends no mutation and leaves no operation lock. Concurrent preparation attempts reject so two waiting callbacks cannot both proceed. A fresh cached baseline permits immediate reservation before invoking the request function.
2. Nested API and transport calls join the same evaluation through request-scoped ownership. They do not create additional pending records.
3. Reserve identity, kind, baseline hashes, baseline observation time, original start time, and absolute expiry. Capture the event's display name and affected event count when the command starts. Prefer names supplied by the initiating UI/API; resolve single IDs from the calendar snapshot when needed. Owned nested API calls can fill missing target details without replacing an already captured name or changing ownership/deadlines. Before sending, persist these details under the account scope, including the display name/count for recovery. Credentials and full request payloads are not persisted. The deadline covers preparation and the pending request; refresh and retry attempts cannot extend it.
4. A successful 2xx response settles the matching evaluation at the transport response boundary. Response-body parsing, background analysis, revision polling, and the following GET do not extend pending feedback.
5. Explicit client rejection becomes failed evaluation. Failure feedback persists through reads and can be dismissed; a new operation can proceed after confirmed failure.
6. Transport timeout/loss, HTTP 408, and server/gateway errors become uncertain because the mutation may have reached the server. Before anyone is told, the bloc reads the schedule once (at most 3 s, `uncertaintyGrace`) while the card still shows the action in progress; if it already changed, the write is only acknowledged. If the app is in the background or offline at that moment (the system drops connections a few seconds after the app leaves the foreground), the check waits until it returns, bounded by the deadline. The screen that sent it waits for that verdict, and the calendar skips an outcome a screen already told, so each change is announced once. Uncertainty informs but does not lock. The bloc then re-reads the schedule status at once, every 5 s for the first 30 s, then every 15 s until the deadline (status reads only; paused while the app is suspended). It resolves on:
   - a fresh changed revision observed after the start: the new schedule loads, plays as that write's change, and "Your schedule was updated after {change}. Check that it looks right." is shown;
   - a late confirmed response ("{change} went through.") or a late refusal ("{change} failed.");
   - the original absolute deadline ("Couldn't confirm {change}. Check your schedule.").

   A new write while one is uncertain first re-reads the schedule (acknowledging a change before it starts); a still-unresolved write then moves to the background with its listener and deadline, and keeps being checked. Up to 3 are kept; beyond that the oldest is let go with the deadline notice. Dismissing the uncertainty card also moves the write to the background, and that is remembered across restarts.
7. A late response from the original transport future can settle that same evaluation. It cannot settle another request or modify a new login session.
8. At expiry, clear pending feedback, admission lock, and the matching journal entry. Emit one loaded-calendar transition carrying the release reason; the outcome is published on `ScheduleBloc.outcomes`, and `ScheduleChangeOutcomeNotices` (in AuthorizedRoute) shows it where the user is looking. Local error messages also distinguish this from confirmed failure. Stop an awaiting local callback with an unconfirmed-outcome timeout. Require a fresh baseline before another explicit user write. An expired callback cannot later send a mutation or start a new operation through its old request scope. A confirmed 2xx cancels the operation deadline even if response-body handling continues.

Typed callback futures remain available to existing UI callers. Their errors are observed immediately and propagated with their original type; completion handlers no longer use a catchError callback that returns the wrong future type. Legacy `EvaluateSchedule(callBack: ...)` callers can hand over an already-managed future without registering a second request. New event callers can supply a request function so admission precedes execution.

Legacy editor `beginEvaluation` remains a presentation event, bounded by the initialization timeout. The actual API request supplies ownership; editor refresh/abandon events cannot clear a request owned by the bloc.

### Timing configuration

`ScheduleEvaluationConfig` can be passed to `ScheduleBloc`, or configured at build time:

| Dart define | Default | Purpose |
| --- | --- | --- |
| `TILER_SCHEDULE_OPERATION_TIMEOUT_SECONDS` | 180 | Maximum hold from the original request start, including preparation. |
| `TILER_SCHEDULE_INITIALIZATION_TIMEOUT_SECONDS` | 30 | Maximum wait for a known baseline before acquiring the operation lock. |
| `TILER_SCHEDULE_BASELINE_MAX_AGE_SECONDS` | 30 | Maximum age of a cached baseline when admitting a write. |

Durations must be valid and the two timeouts positive. Restoration uses the earlier of the saved deadline and original start plus the current configured timeout. Increasing configuration cannot extend an existing saved deadline. Wall-clock checks on refresh/recovery/admission enforce expiry after sleep even if the timer has not fired yet.

## Reads, revision changes, and navigation

Every GET/local/view emission consults the current evaluation instead of a pending snapshot captured before the read. A read may update tiles and hashes while the resulting state remains evaluating. A read failure cannot turn the mutation into either success or failure.

GET preserves the bloc's current tiles when the caller omits `previousSubEvents`. A successful change starts a refresh with existing content retained. A refresh error uses the existing failed-loaded data state and does not reopen mutation evaluation.

The revision cubit's changes trigger data retrieval when the rendered revision differs. Reconciliation compares fresh observations to the saved baseline and original start; an unchanged hash retains uncertainty only until the deadline. Stale reads and mutation callbacks are checked against session generation so logout isolates their results.

Changing views preserves the API connection and evaluation instead of emitting initial state. A newly mounted daily, weekly, or monthly view requests its selected range if the current snapshot does not cover it. Existing data remains visible during that read. Summary loading alone does not replace an evaluating calendar with the full-screen Tiler loader.

The daily carousel key is initialized from an already-loaded snapshot and remains stable for data-only changes. A different day window can still legitimately remount it. Complete/Delete tests verify that normal GET and completion retain the same DayGridWidget state.

## UI entry points

[ScheduleEvaluationFeedback](../lib/components/scheduleEvaluationFeedback.dart) renders compact, calendar-local feedback in daily, weekly, and monthly views. Pending shows an action label and spinner. Confirmed failure shows a dismissible message. Uncertain shows an explanation, a read-only Refresh action and a close button; closing hides only the card. It does not cover the calendar with a full-screen logo/spinner.

The feedback identifies the last admitted command with a persistent action icon and target. Examples: a check icon with `Completing` / `Lunch`, a trash icon with `Deleting` / `Team planning`, or a revise icon with `Revising Schedule` / `Your schedule`. Bulk completion shows an event count; Defer All names `All events`. Creation, edit, Start Now, pause/resume, settings, and acceptance have distinct icons/labels. Uncertain/failed feedback keeps the command and target visible beneath its outcome label; it does not keep claiming that processing is still underway. A blocked second tap never replaces the admitted command's details.

Names are snapshots, so a calendar refresh, rename, removal, closed editor/search surface, or process restart cannot change which event the feedback describes. If no name is available, show `Event`, an event count, or the schedule scope. Names wrap up to two lines with a full-name tooltip. Refresh sits below the details to preserve text space on small screens. Display names are stored locally for recovery and omitted from diagnostics.

| Flow | Handling |
| --- | --- |
| Revise/reoptimize, shuffle | Schedule handlers reserve evaluation and await the owned request. GET cannot erase it. |
| Complete, delete, start now, pause/resume | Playback reserves the request and carries the typed future into existing callbacks. The calendar retains action-specific feedback after weekly details close. |
| Search complete/delete/start now | Reserve before closing search, retain provider references, propagate failures, and refresh the schedule once through the bloc. |
| Edit occurrence/series, RSVP | Existing submission UI remains; API admission supplies shared evaluation, and editor reloads preserve it. |
| Defer one | Retain picker pending feedback; block conflicting writes with an explicit error instead of a successful no-op. Failure leaves the picker open. |
| Defer all | Guard the picker action and reserve at the API entry point. Calendar feedback survives leaving the picker. |
| Complete selected tiles in Today Status | Guard admission, retain local progress, show failure for false results, and stop completion progress before the subsequent summary read. |
| Add tile | Reserve creation before request preparation; retain the form's existing result handling and calendar evaluation. |
| Calendar grid move | Reserve edit ownership before calling the API; retain existing position/drag behavior. |
| Notification completion | Use the same schedule bloc request ownership. |
| Other classified writes | Settings, schedule-affecting integration writes, designated tile acceptance, and Vibe execution use the same HTTP admission guard. |

Schedule status, getAutoResult/new-tile prediction, persona suggestions, previews, comments, and background analysis do not acquire schedule-mutation ownership.

## Connection drops, sleep, and process restart

Existing lifecycle/connectivity monitoring continues to suspend and recover revision checks. Existing calendar resume refreshes still run, preserving active evaluation. Network availability is a reason to check freshness, not proof that a mutation completed.

Mutation replay is never automatic. GET can retry with a fresh connection. Refreshing that connection does not close a client still carrying a pending write; retired clients close after their active response streams finish.

When its account is bound, a saved request is validated and staged for a fresh revision check. No restored lock is acquired until the hashes and timing are usable. Missing/unknown hashes, missing timestamps, future start times, expired deadlines, malformed records, and legacy identity-only records cannot restore a lock. Fresh changed hashes discard the interrupted hold; unchanged hashes restore uncertainty for the remaining time, using the original start rather than the restart time. Account identity comes from backend scope and JWT subject claims when available. Logout/login reset admission, timers, observation freshness, and in-flight initialization. Journal cleanup does not delay a confirmed 2xx or override its result.

**Recovery limit:** changed hashes and elapsed time do not prove that this particular request finished. Releasing the hold is the agreed bounded UI recovery policy. It does not cancel a server operation or replay a mutation; another explicit user write could overlap backend work still running after expiry. Exact request-outcome recovery would require an additional backend contract.

## Diagnosing a persistent Refresh prompt

Local console diagnostics use the `[ScheduleFlow]` prefix. They are enabled in debug builds; profile/release builds can opt in with `--dart-define=TILER_SCHEDULE_LOGS=true`. Capture the console from app startup through the schedule action and a Refresh tap so journal restoration and the original request are included.

Logs include local request identity, action kind, phase, original elapsed time, remaining deadline, baseline readiness, initialization progress, HTTP status, read generation/outcome, revision-check attempts, and lifecycle/connectivity events. They omit credentials, account identifiers, hash values, request bodies, tile contents, and raw error messages. Transport errors include their type and socket error code where available.

| Log event/fields | Interpretation |
| --- | --- |
| `mutation_initialization_started/ready/failed` | A baseline was needed before admission; failed initialization leaves no operation lock. |
| `mutation_restore_staged`, `mutation_restore_discarded` | Startup is checking a saved record or rejecting invalid/expired metadata. |
| `journal_loaded`, `mutation_restored_uncertain` | An unresolved persisted request restored the lock; `liveResponseAttached: false` means this process has no original response future to await. |
| `mutation_released_unconfirmed`, `reason: revision_changed/deadline_expired/unresolved_limit` | Reconciliation or expiry ended the hold without claiming a successful response; `background: true` for a superseded or dismissed write. |
| `reconcile_attempt`, `reconcile_scheduled` (`delayMs`), `reconcile_failed`, `reconcile_paused`, `reconcile_stopped` | Status re-reads while a write is unconfirmed. They never send the write. |
| `mutation_acknowledged`, `reason: revision_changed/late_response` | An unconfirmed write was acknowledged by a changed schedule or by its own late 2xx. |
| `mutation_superseded`, `uncertain_dismissed`, `mutation_restore_background` | An unconfirmed write moved to (or was restored into) the background. |
| `mutation_reattempt_asked`, `mutation_reattempt_declined` | The user was asked before repeating an unconfirmed change, and declined. |
| `mutation_uncertain`, `reason: response_timeout` | The response deadline expired; the original transport listener is still attached for a late response. |
| `mutation_uncertain`, `reason: transport_error` | Transport failed; inspect `errorType` and `socketCode`. |
| `mutation_uncertain`, `reason: http_response_unconfirmed` | HTTP 408 or a server/gateway failure left the write outcome uncertain; inspect `status`. |
| `transport_mutation_observed`, `lifecycleAttached: false` | A mutation reached the HTTP client without shared schedule ownership. |
| `ui_refresh_requested` followed by `read_succeeded` and `read_finished`, `stillUncertain: true` | The GET worked, but the original write is still unconfirmed. The Refresh prompt is not evidence that the GET failed. |
| `read_failed` or `revision_check_failed` | Data retrieval/status polling failed; inspect error type and retry attempts. |
| `mutation_response`, `late: true`, followed by `mutation_finished`, `success: true` | A late successful response resolved the original request. |
| `mutation_finish_ignored` or `read_ignored` | A delayed result no longer owns the active request/read/session. |

The Refresh action remains a calendar read. Its revision can reconcile an interrupted hold, but it does not erase a live pending operation or replay a write.

## Verification

October 11, 2026 follow-up: AppApi preserves local transport causes through `TilerError`, including both POST/PUT request timeout handlers. Twelve transport regressions cover uncertainty, rejection, pre-send failure, late success and body loss after a confirmed 2xx. Blocked notification/connect paths now publish the running change's label; background interruptions wait for resume and discard obsolete holds. Editors retain live progress and drafts; the spinner surrounds the glyph. Shuffle/Defer All retain the preview sheet and show the running change when blocked. App errors identify the attempted operation. The final pre-commit suite has 2354 passing tests, 4 existing skips and no failures. Android debug build/install and staging re-optimize smoke checks passed before the feedback refinements; the full device matrix remains open. See [implementation plan §6](schedule-change-implementation-plan.md#6-execution-record--october-11-2026).

The 166-test focused automated suite passed after adding captured command details and action icons. It covers schedule evaluation, revision/recovery, editor submissions/refresher, day-grid persistence/rebuild/date navigation, deferral, Today Status completion/recovery, onboarding prefetch, API contracts, and search interactions. After filling editor deletion/deferral name gaps, all 77 affected editor/schedule tests passed. Dart analysis found no new errors; existing warnings remain.

[Schedule evaluation regression tests](../test/schedule_evaluation_flow_test.dart) exercise:

- Pending Complete/Delete through GET, local reload, view change, and failed reads.
- Calendar data retained when refresh callers omit their snapshot.
- Conflicting writes rejected before execution; nested calls retain one owner.
- 2xx completion before response-body or hash updates.
- Rejection, uncertainty, late responses, and no mutation replay.
- Logout isolation and persisted account recovery before the next write.
- Fast typed failure before its UI event attaches an error handler.
- Uncertain local failure messages and rejection of retries inside the original request scope.
- GET retry without canceling a pending write's connection.
- Actual Completing/Deleting feedback and the same mounted daily grid through GET and completion.
- Unknown/stale baseline initialization, serialized preparation, and initialization timeout without a mutation lock.
- Valid recovery with original timestamps and remaining deadline; invalid, expired, future-dated, and legacy records discarded.
- Changed hashes preserving live pending operations and releasing interrupted operations without replay.
- Expiry with unchanged hashes, refresh without deadline extension, and wall-clock expiry before the timer fires.
- Expired preparation prevented from sending later, and 2xx preventing timeout during subsequent body handling.
- A single unconfirmed-release transition and honest local feedback after the hold ends.
- Captured command names preserved through refresh/rename and restoration, with nested API enrichment and correct bulk CSV counts.
- Action icons and target names/counts retained in pending, uncertain, and failed feedback, including long names at a 320-pixel width.

Automated verification does not replace these device checks:

1. Delay reoptimize; refresh, navigate dates/views, and wake the phone. Verify existing tiles and pending feedback remain, with no full-screen logo reload.
2. Repeat for Complete, Delete, Start Now, edit save, and deferral; close the initiating surface and attempt another mutation.
3. Lose the connection before the mutation response; reconnect and verify uncertainty, read availability, and no repeated mutation request.
4. Deliver a late 2xx; verify feedback clears even when hashes are unchanged or the follow-up GET fails.
5. Terminate/relaunch during a mutation, and switch accounts; verify unresolved records and late callbacks remain isolated.
6. Configure a short operation timeout, keep hashes unchanged, and sleep past the deadline. Verify the hold ends, the calendar remains mounted, and the next explicit write obtains a fresh baseline.
7. Start without known hashes or with a status request that fails. Verify no write is sent and no lock persists; a later initialized attempt can proceed.
