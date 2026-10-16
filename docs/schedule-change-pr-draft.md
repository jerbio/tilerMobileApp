# Draft PR — Preserve uncertain schedule outcomes and complete schedule-change feedback

Target: `feature/scheduleChangeFeed` → `main`. Snapshot commit approved for branch testing. PR publication and merge remain pending approval.

Schedule requests that lose their connection or hit an AppApi timeout after sending now retain the "Confirmation unavailable" state. `TilerError` preserves its original local cause through both catch layers, while keeping the wire format unchanged. HTTP rejection still fails; late successful responses settle the original hold, and writes are never replayed.

Notification completion and calendar connect now explain a blocked write using the running change's label. Background notices wait for resume and discard obsolete requests/accounts. Integration connect preserves the list instead of replacing the notice with a generic failure. The defer guard runs before its progress toast.

Editors now keep live schedule progress visible above the form, with the spinner surrounding the action glyph. Blocked saves, RSVP and tile actions name the running change; action dialogs recheck admission before submission. Shuffle and Defer All keep the preview sheet open and show the running change there when blocked. Failures name the operation and target, retain useful validation details and suppress retries for unconfirmed writes. The same message audit covers schedule actions, chat, forecast, settings, notes, comments and onboarding. Nine new message keys are translated in all nine locales.

Day replacements from background refresh cross-fade in the list, respecting reduced motion. Grid drops retain `userEdit` attribution and immediate subject settling; the unused `userDrag` origin is removed. Fourteen missing lifecycle strings are added in seven locales. Counts-only parent-ID churn diagnostics help investigate misleading added/removed summaries without changing tile identity.

Validation: 2354 Flutter tests passed, 4 existing skips; the feedback refinements passed 81 focused tests, and the blocked Shuffle follow-up passed 39 focused tests. Core feedback/editor analysis is clean; final analysis across 57 targets has 23 existing warning/info findings and no errors. Android x64 debug APK built and installed before the feedback follow-up; staging calendar startup, pending re-optimize feedback, HTTP 200 settlement and a three-tile grid batch were observed on the emulator. The feedback follow-up still needs device verification. Local logs and screenshots: `build/schedule-change-verification/2026-10-11/`.

Before merge: complete the device/accessibility/performance/platform matrix, native translation review and backend identity investigation; resolve or explicitly accept the pre-existing `peekDay` analyzer error and native-library compatibility warning. Integrate `main`, re-run checks and obtain final review. See [implementation plan](schedule-change-implementation-plan.md) and [translation review sheet](schedule-change-string-review.csv).

Exclude unrelated generated plugin changes, existing untracked add/edit-tile material, credentials, constants and local verification evidence from this PR. Only the required generated localization outputs accompany the schedule changes.
