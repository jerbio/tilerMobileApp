# TileShare Redesign — Design & Tracking

> Status: **Design rev 2.5, 2026-10-01 — informed by the design mocks (§3). Decisions T1–T7, T12, T14, T20 locked by the product owner; T8–T11, T13, T15–T19 proposed. Backend `Mode` field confirmed; Class recipients are added per task by the client for now (O9 resolved); open concerns in §10. **Implemented so far: Steps 9.1–9.5 (R0 complete; the Attention list is behind `--dart-define=TILESHARE_V2=true`).**
> Last updated: 2026-09-29
> Owner: _TBD_
> Related (outside this repo): `prod/tileShareDetails.md` (mobile feature overview), backend `prod/WagTapWeb/TilerFront` (branch `feature/tileShareActivity`).
> Process (same as the DayGrid work): **TDD (Red → Green → Refactor), stop after each step and present the diff, never `git commit`/push until the owner says "commit".** Updates must animate, never snap (T11).

Living document for the TileShare UI overhaul. Companion to
[daygrid-view-design.md](daygrid-view-design.md) (same conventions: decision
table, step-by-step TDD plan, tracker, change log). Use §11 (tracker) and §12
(change log) to record progress.

---

## 1. Background & goal

TileShare lets one user hand work to other people: a sender creates a **cluster**
of one or more **tilettes** (tasks) and invites **recipients** by email/phone;
each recipient accepts or declines, and an accepted tilette becomes real tiles on
their schedule. The feature works end to end but the UI grew screen by screen:
status is invisible in lists, the recipient's core decision is buried, three
near-identical detail screens carry ~900 duplicated lines, and half the model
(Notes, Address, Schedule pattern) is unreachable.

**Goal:** (a) a person sees at a glance **what needs their attention** and can
act from the list, (b) an owner sees how each cluster is going, (c) the three
ways of sharing — **Broadcast, Project, Class** — are first-class and visibly
different, (d) the details the model already supports ship, (e) the screens
share one structure instead of three copies.

## 2. Current state (verified 2026-09-29)

### 2.1 Domain

| Concept | Class | Notes |
|---|---|---|
| Cluster | `TileShareClusterData` ([lib/data/tileShareClusterData.dart](../lib/data/tileShareClusterData.dart)) | name, creator, `contacts` (from `truncatedUser` — **truncated**, `isMoreContact`), deadline, `isMultiTilette` (bool), `priority` (unused in UI) |
| Tilette | `TileShareTemplate` ([lib/data/tileShareTemplate.dart](../lib/data/tileShareTemplate.dart)) | `designatedUsers`, `miscData.userNote`, start/end/duration. **No address parsed.** |
| Recipient (owner's view) | `DesignatedUser` ([lib/data/designatedUser.dart](../lib/data/designatedUser.dart)) | `rsvpStatus`, `completionPercentage`, `userProfile` |
| Recipient's own copy | `DesignatedTile` ([lib/data/designatedTile.dart](../lib/data/designatedTile.dart)) | `invitationStatus` (string), `isTilable`, `isViable`, `completionPercentage`, `tilerEvent`, `clusterOwner` |
| Activity | `TileShareActivity(Page)` ([lib/data/tileShareActivity.dart](../lib/data/tileShareActivity.dart)) | **The client knows 14 event types; the server (source read 2026-09-29) also emits `cluster_invitation`, `assignment_completed` (+ `calendarEventId`), `assignment_reopened`, carries `targetUserId` on recipient events and `changedFields` / `deadlineBefore` / `deadlineAfter` on `tilette_edited`, supports a server-side `EventType` filter, per-event **dismissal** (`POST api/TileShare/Activity/Dismissal`, `DismissedOnly`), retention, and a separate `GET api/TileShare/Invitations`.** The client drops all of that (unknown type → “Activity updated”). |
| Requests | `TileShareClusterModel`, `ClusterTemplateTileModel`, `AddressModel` ([lib/data/request/](../lib/data/request/)) | `AddressData`, `Notes`, `SchedulePattern` on the cluster; `AddressData`, `NoteMiscData`, `OrderedIndex` on a tilette |
| Forecast | `ForecastResponse` ([lib/data/ForecastResponse.dart](../lib/data/ForecastResponse.dart)) | `isViable`, `conflicts`, `conflictingCount`, `riskCalendarEvents`, `deadlineSuggestion`, `peekDays[].unallocatedTime/subEvents` — single-tile request (duration + deadline) |

*The client's only structural switch is `isMultiTilette`:* `false` → the cluster
carries its own duration and contacts and the server makes one template; `true`
→ the cluster is a container and each tilette carries its own contacts.
**The backend now has an explicit cluster `mode` — `broadcast`, `class` or
`project` (confirmed 2026-09-29) — which the client does not parse or send yet**
(Step 9.1; details in O9).

### 2.2 Screens

```
Bottom-nav "Share" ─► TileShareRoute  (pushed '/TileShare', X to close, "+" in AppBar)
                      TabBar: Activity | Outbound (default) | Inbound
 Outbound row (swipe: edit / delete, no confirm) ─► TileShareDetailWidget
     ├ single ─► SingleTilette detail   (deadline, creator, contacts add/remove → API directly)
     └ multi  ─► MultiTilette detail    (header + tilette list ─► TileShareTemplateDetail: contacts, notes, deadline)
 Inbound row ─► InboxMultiTilette detail ─► DesignatedTileList
     └ DesignatedTileWidget: notes · comments (TiletteDetailScreen) · forecast · Accept/Decline
       └ after accept: completion % ─► TileDetailRoute.byDesignatedTileId
 Create: "+" ─► CreateTileShareClusterWidget ─ bento icon ─► pushes a 2nd CreateTileShareClusterWidget(multi)
 Other entries: deep link ?tileshareid=…, share icon on schedule cards → byDesignatedTileShareId
```

### 2.3 Findings that drive the redesign

1. **Lists show no status** ([tileShareSimpleWidget.dart](../lib/routes/authenticatedUser/tileShare/tileShareSimpleWidget.dart)): 12 px name, deadline, comma-joined contacts. No RSVP summary, progress, or "needs your response". `DesignatedUserCircle` exists but only renders in tilette rows.
2. **The recipient's decision is buried**; Accept/Decline are stacked buttons on a dense card; Accept silently runs `analyzeSchedule` + `buzzSchedule`; no undo, no confirm; forecast is a binoculars icon.
3. **Three near-duplicate detail screens** ([single](../lib/routes/authenticatedUser/tileShare/singleTiletteTileShareDetail.dart), [multi](../lib/routes/authenticatedUser/tileShare/multiTiletteTileShareDetail.dart), [inbox](../lib/routes/authenticatedUser/tileShare/inboxMultiTiletteTileShareDetail.dart)) with copied load/error/header code, `screenHeight − 400` layout arithmetic, and a bento *mode toggle* that pushes a second create screen.
4. **Model fields with no UI:** `Notes`, `AddressData`, `SchedulePattern` (cluster); `AddressData`, `NoteMiscData` (tilette — mapped by `NewTile.toClusterTemplateTileModel` but the add-tilette sheet has no inputs); `priority`.
5. **Schedule-card indicator is a placeholder:** two identical person icons ([enhancedTileCard.dart:1619](../lib/components/tileUI/enhancedTileCard.dart)).
6. **Fire-and-forget writes** (contact add/remove — [contact-input-field-improvements.md](contact-input-field-improvements.md) 3.3/3.5); swipe-to-dismiss deletes with no confirmation; every list row is re-keyed with a fresh `Utility.getUuid` on each build (defeats animation and resets swipe state); hard-coded English strings; dead code; stray `print`s.
7. **Chrome is out of step with Daily**; Activity is a peer tab of Sent/Received although it is a log of them.
8. **Test coverage:** only `tile_share_activity_test.dart` (+ comments API). Its canonical fixture is read from the backend repo by relative path (`../../WagTapWeb/…`).
9. **The activity client discards server data:** completions, invitations-to-me, what changed in an edit (incl. the old/new deadline), who was added (`targetUserId`) and per-event dismissal are all available from the server but unread. The feed clears itself on every reload (flash/jump).

## 3. Design mocks reviewed (2026-09-29)

Five images / eight screens (not stored in the repo). What we take and what we don't:

| Mock | Take | Don't / defer |
|---|---|---|
| **A. "How do you want to share this work?"** (4 mode cards) | Plain-language mode chooser, one-line descriptions, data-driven card list. | *Anyone can claim* and *Share as a plan* — no backend (T12). "You can change this later" — no mode conversion exists; do not promise it. |
| **B. Create collection** | Name / description (= `Notes`) / deadline; **total effort computed** from task durations; tasks list with drag handles (= `OrderedIndex`); "Add task". | Cover icon and Category — no field (T12). "Continue to share" step is our people step. |
| **C. Overview** and **D. Participants** (owner) | Summary card ("N tasks · effort · due"); participant rows (status pill, progress bar, decline reason, chevron); activity strip; Share link. | The two tabs largely repeat each other → merged (§5.4). Decline reason — no API field (T12). Message participants — no thread (T12). The mocks show a cluster-level % (and disagree: 50 % vs 38 %) → **no cluster-level progress ships** (T13). "Invited" is blue in one, amber in the other → one pill spec (§5.6). |
| **E. Attention** (inbox) | **The triage inbox**: a card per reason you must act, status pill, one clear CTA, filter chips. | The card's only action is "Check whether this fits" — we keep **inline Accept/Decline** as well (T3). The mock's bottom nav (Today / TileShare / Share) conflicts with T1 and duplicates Share → dropped; the pushed route keeps a back chevron. |
| **F. Person view** ("Marcus") | Cross-cluster view of one person with a privacy note. | New entity, no endpoint → later (T12). |
| **G. Check my schedule** | Verdict, requested-vs-available bar, per-day availability, Tiler's suggestion, *Accept anyway* / *Preview my plan*. | Per-day rows opening a day grid = v2. Multi-task modes need more than the single-tile forecast (O7). |

## 4. Decisions (T1–T25)

| # | Decision | Status / notes |
|---|---|---|
| **T1** | **Share stays a separate pushed route** (`/TileShare`, opened from the bottom-nav Share item and deep links). Own back/close affordance, **no bottom nav**. Chrome restyled to the Daily language (fixed 48 px bar, pill segmented control, same tokens). | Owner, 2026-09-29 |
| **T2** | **Three sharing modes, all first-class and visibly different:** **Broadcast** — every recipient has **their own instance of a task**. **Project** — everyone **shares one project** (one instance; tasks are worked by/assigned to people). **Class** — every recipient has **their own instance of a project** (a multi-task copy each). Shown everywhere by an icon + label (§5.5). | Owner, 2026-09-29. Backed by the cluster `mode` field: broadcast / class / project (request key `Mode`; confirmed 2026-09-29; O9). |
| **T3** | **Accept / Decline are available from the list** — on Attention invitation cards and on Clusters rows that are awaiting a response — and again on the invitation detail; the buttons follow the mode (T20). | Owner, 2026-09-29 |
| **T4** | ~~“See impact” = the Check-fit screen (verdict, requested-vs-available).~~ **Superseded by T21.** The owner showed the desktop flow - the backend's accept **preview** - and it replaces the forecast-derived verdict; a client-side Fits / Tight / Doesn't-fit guess on unverified semantics was built (9.10, 2026-10-01) and **withdrawn before commit**. | Owner, 2026-10-01 |
| **T5** | **Notes, Address (location) and Schedule pattern ship.** Notes + Address per tilette (Project/Class) or on the cluster (Broadcast); Schedule pattern is cluster-level per the request model. Settable at creation, editable after, visible to recipients. | Owner, 2026-09-29. Pattern contract unknown (O1). |
| **T6** | **Hub = two segments: _Attention_ and _Clusters_.** *Clusters* has a filter — **All · Shared with me · Created by me**. The raw activity log is an app-bar icon (and a section inside each cluster). | Owner, 2026-09-29. Label “Clusters” is the owner's word; user-facing wording to confirm (O6). |
| **T7** | **Attention is a derived, role-agnostic triage inbox** (mock E). Items: *Invitation* (I must respond — from `GET api/TileShare/Invitations`), *Changed* (`tilette_edited` on a cluster I am in, showing *what* changed), *At risk* (my accepted work no longer fits: `DesignatedTile.isViable == false`), *Completed* (`assignment_completed`), and for owners *Responses* (declined, invitation delivery failed/unknown). *(An owner-side “Behind” item was dropped together with cluster progress — T13.)* Chips: **All · Invitations · Changes · At risk · Responses**. One CTA per card; invitations also carry inline Accept/Decline. **Resolved = the server's per-event dismissal**, so it follows the user across devices. Default segment = Attention when it has items, otherwise the last-used one. | Proposed (O2, O11) |
| **T8** | **Accept/Decline are optimistic with Undo.** The item animates out/into its new place immediately; a snackbar offers Undo for ~5 s; the network call (and the `analyzeSchedule` + `buzzSchedule` follow-up on accept) commits when the snackbar closes and is flushed if the screen is left. Undo therefore never reaches the server. | Proposed (O3) |
| **T9** | **State moves out of widgets into cubits with injected APIs** — `TileShareAttentionCubit`, `TileShareClustersCubit`, `TileShareDetailCubit`, `TileSharePreviewCubit` — following the `TileShareActivityWidget.loader` precedent (default = live API, tests inject fakes). | Proposed |
| **T10** | **One detail scaffold**, mode-specific content: `TileShareDetailScaffold` owns loading/error/retry/app bar/activity entry; content = Broadcast / Class / Project (owner) and Commitment (recipient). The three old screens are retired. | Proposed |
| **T11** | **No-snap contract applies** (daygrid §16.2): refresh, filter switches, group/state changes, adds and removes animate; a reload never resets scroll or reorders rows in one frame; rows are keyed by cluster / designated-tile id. A `tileshare_no_snap_test` harness (mirroring `daygrid_no_snap_test`) is the gate. | Proposed |
| **T12** | **Later release (deferred, not in this plan):** *Anyone can claim*, *Share as a plan* (opt-in adoption), cover icon, category, decline reasons, Person (coach) view, **Message participants**, and a share link that *joins* a stranger. **Share link in this release = copy the existing deep link** (works for invited people). | Owner, 2026-09-29 (“later release”); Person view and Message/Share-link handling are my reading — correct me |
| **T13** | **No cluster-level progress ships.** Completion exists only per assignment (one recipient on one tilette) and the server has no cluster figure; the owner decided not to derive or ship one, nor any cross-tilette total. **Progress is shown per tilette / assignment only:** a Broadcast recipient row, a Class person's per-task segments, a Project task row (and a Broadcast recipient's own ring, which is their one tilette). What lists and headers show instead is the **RSVP status summary** — “3 of 5 accepted” — derived from the tilettes' assignments (`TileShareRsvpSummary`: Broadcast counts assignments, Class counts people, Project counts tilettes). | Owner, 2026-09-29 (“we should not ship TileCluster progress functionality”; earlier: “no way to evaluate the progress on the cluster, only on tilettes”) |
| **T14** | **Create = mode first, then only the steps the mode needs:** Broadcast 1 screen; Class 2 (details + tasks → people); Project 2 (details + tasks → people + who does which task). | Owner, 2026-09-29 (“Go with B”). |
| **T15** | **Activity is a first-class surface in three places, one component:** a *Recent activity* strip on cluster Overview (last 3, “View all”), the **feed route** (global from the hub's 🕘, scoped from “View all”), and the **source** for Attention's Changed / Completed / Responses items. One `TileShareActivityCubit` per scope. | Proposed |
| **T16** | **The client model catches up with the server:** `cluster_invitation`, `assignment_completed`, `assignment_reopened`; `targetUserId`; `changedFields` + `deadlineBefore/After` on `tilette_edited`; `calendarEventId` on completed/reopened (links to the scheduled tile). Parsing stays **allow-listed and schema-version-gated** exactly as today (privacy-conservative behaviour retained: no raw contact data, unknown future shapes degrade to “Activity updated”). | Proposed (O14: confirm deployed wire contract) |
| **T17** | **Rows are real sentences with an actor and a subject, localized (ICU):** “Sarah accepted Design review”, “Jordan moved the deadline from Fri to Mon”, “You added Marcus to Review PR”. “You” when `actorId` is the signed-in user; the subject of recipient events is resolved from `targetUserId` against the cluster's participants, else “a participant”. Actor avatar on every row; mode badge + cluster name on global-feed rows. | Proposed |
| **T18** | **Fan-out is grouped:** consecutive events with the same actor, type and cluster within ~60 s collapse into one row (“Participant added to 4 tasks”, “Accepted 4 tasks”), so Class mode's per-task events (O9) read as one action. Expanding shows the individual events. | Proposed |
| **T19** | **Feed behaviour:** refreshes **merge in place** (never clear-then-reload) and new rows animate in; access loss (401/403/404) still clears and explains; per-event **dismiss / undo** with a “Show dismissed” toggle (`DismissedOnly`); “History starts on {date}” from `historyAvailableFrom`; chips filter client-side over loaded pages (the server filter takes one `EventType` only); cursor paging with “Load more”. **App-lifecycle behaviour (e.g. clearing on app pause) is not part of this redesign and stays exactly as it is today.** Visibility is decided by the server (owner-only delivery/deletion events) — the UI never assumes both sides see the same feed. | Proposed |
| **T20** | **Accept all exists only in Class mode.** *Class:* the response is one commitment — **Accept all / Decline all** (the client updates every task the recipient holds, sequentially; one undoable action). *Project:* **per-task Accept / Decline only — never an Accept-all** (each task is separate work). *Broadcast:* a single Accept / Decline. Consequence for T3/T7 on Attention: Broadcast cards show Accept · Decline, Class cards show Accept all · Decline all, and a Project card reads “N tasks need your response” with **Review**, opening the commitment detail where each task has its own buttons. | Owner, 2026-09-29 (Accept all only in Class); the Attention consequences and “Class has no per-task accept” are my reading |
| **T21** | **“Check fit” becomes the accept preview**, the mobile version of the desktop *Tileshare Preview* → *Find Another Time* flow, built on the backend preview API: `POST api/DesignatedTile/Preview` (the schedule with the tile placed, its sessions, conflicts, `isViable`, `unsupportedReason`, `previewToken`), `POST …/Preview/Options` (up to 4 alternative viable start times per page, each with its own token; `nextOffset` for “Find another time”), `POST …/Preview/Revise` (re-preview with a chosen option or a lock), and **Accept = `POST api/DesignatedTile/status` carrying the `PreviewToken`** (409 when the schedule changed since). **One full-screen page**: a day strip on top (T24) and a draggable bottom sheet (preview → options in the same sheet), so the calendar stays in view while choosing. Choosing a slot **is not committing**; only Accept commits, and Accept **queues an operation** (client-made `OperationId`, a 32-hex GUID, so a retry is idempotent) that the client polls via `GET api/DesignatedTile/ResponseOperation` until it is `applied` / `completed` (or `rejected` / `needsReview`). | Owner, 2026-10-01 (sheet layout chosen) |
| **T22** | **Inline Accept skips the preview.** Accept / Accept all on a card or row (T3, T8, 9.6, 9.8) keep the fast path exactly as built - no token, optimistic with Undo. The preview is opt-in (“Check fit”). | Owner, 2026-10-01 |
| **T23** | **Class and Project skip the preview in v1.** The preview is per assignment (one task), so Class *Accept all* never previews, and there is no “task 1 of 4” stepper. The preview is reachable for a single task: a Broadcast invitation's “Check fit”, and later a per-task “Check fit” on a Project task row (R5). | Owner, 2026-10-01 |
| **T24** | **The day strip is `DayGridWidget(preview: true)`** (read-only, no tap-to-add, no zoom persistence) fed with the preview's blocks, with `selectedActionEntityId` = the proposed block, which the grid already draws dotted and scrolls into view. Needs a mapper from preview blocks (`id, name, start, end, isProposed, isFixed, placement`) to `SubCalendarEvent`, and a way to step between days (as `DayCast` does for the forecast peek). | Owner, 2026-10-01 |
| **T25** | **Locking a slot (fixed) stays off in v1 - an owner decision, not a server limit.** The server now reports `fixedSessions: true` on stored previews, but the client shows no lock control (`Revise` is used only to choose an option); turning it on later is a one-line client switch. The other capabilities (`alternatives`, `reviewedAcceptance`) are honoured as the server sends them (O19). | Owner, 2026-10-01 (lock off) |

## 5. Target experience

### 5.1 Modes at a glance

|  | One task | Many tasks |
|---|---|---|
| **Everyone has their own instance** | **Broadcast** | **Class** |
| **Everyone shares one instance** | _(claim-style — later)_ | **Project** |

| | Broadcast | Class | Project |
|---|---|---|---|
| Recipient gets | their own copy of the task | their own copy of the whole project | a role in one shared project |
| Owner sees | roster: RSVP status + each person's progress on the one task | roster: RSVP status + per-person, per-task progress segments | task board: who owns which task + each task's own progress |
| Progress shown | per recipient, on the one task | per person, per task (segments) — never one total | per task on the board — never one total |
| Accept means | I'll do this task | I'll do this project | I'll take part (and my tasks) |
| Backend `mode` | `broadcast` (legacy: `isMultiTilette == false`) | `class` | `project` (legacy: `isMultiTilette == true`) |

### 5.2 Hub — `TileShareRoute` (T1, T6)

```
┌ ‹  TileShare                              🕘   ＋ ┐  fixed 48 px bar: back, Activity, create
│ [ Attention ●3 | Clusters ]                       │  pill segmented control (Daily filter style)
│ (All)(Invitations)(Changes)(At risk)(Responses)   │  chips — Attention only
│ ┌ Launch Prep            [Invitation]  ⋯ ┐        │
│ │ Sarah invited you · Class · 4 tasks     │        │  mode badge on every card
│ │ 3h 30m · due Fri                        │        │
│ │ [ Accept all ][ Decline all ] Check fit │        │  T3 + T4
│ └─────────────────────────────────────────┘        │
│ ┌ Client research         [At risk]      ┐        │
│ │ 45 min no longer fits before Thursday   │        │
│ │ Review plan ›                           │        │
│ └─────────────────────────────────────────┘        │
└───────────────────────────────────────────────────┘
Clusters:  (All)(Shared with me)(Created by me)  → cluster cards, paged
```

- ＋ opens the create flow (§5.7). The Activity icon opens the existing `TileShareActivityWidget`.
- Empty states are actions ("Share a tile") on Clusters/Created by me and informational elsewhere; Attention empty = "You're all caught up".

### 5.3 Cards

**Attention card** — kind/mode glyph · name · one-line reason ("Sarah invited you", "Jordan changed the deadline", "Aisha declined — …") · `N tasks · effort · due` · status pill · CTA row.
- *Invitation:* Broadcast **Accept · Decline**; Class **Accept all · Decline all**; Project “N tasks need your response” + **Review** (T20) — plus “Check fit ›” (T3/T4).
- *Changed / At risk:* one CTA ("Review changes", "Review plan").
- *Responses (owner):* "View" / "Resend" (delivery failed) / "Reassign" (later).

**Cluster card** — mode badge (icon + label) · name · role line ("from @sarah" / "You") · due chip (urgent < 48 h) · and by mode and role:
- *Owner, Broadcast/Class:* avatar stack (`DesignatedUserCircle`, RSVP badges) + "3 of 5 accepted" — the RSVP summary is **derived from the tilettes' assignments** (T13), so it is loaded per visible card (O2), never read from the cluster. No progress % on the card.
- *Owner, Project:* one segment per task (accepted / pending / declined) + "3 of 4 tasks accepted"; a task's own progress is on its row in the detail, never rolled up.
- *Recipient:* my status pill + my task count. A **Broadcast** card also shows my progress ring — that is my one tilette's completion; Class and Project cards show no progress figure (per-task progress is in the detail). Pending invitations show the mode's buttons inline (T3/T20).
- Swipe (owner only): edit · delete — **delete confirms** and a failed delete restores the row.

### 5.4 Owner detail (T10)

Header summary card: mode badge, "N tasks · total effort · due …", location/pattern/notes (inline-editable). Tabs adapt to the mode:

| Mode | Tabs | Content |
|---|---|---|
| Broadcast | Overview · Participants | Overview = summary + top participants + last activities; Participants = roster (avatar, status pill, progress bar, resend/remove). |
| Class | Overview · Tasks · Participants | Tasks = the shared task list (reorderable); Participants = roster with **per-person segmented progress**; chevron → that person's task-by-task progress. |
| Project | Overview · Tasks · Participants | Tasks = board (task, duration, **assignee**, status); Participants = who is in and what each owns/completed. |

Overview never repeats a full list — it previews (top 3 participants, last 3 activities, "View all") and links into the tabs. Bottom action: **Share link** (copy deep link, T12). Recent-activity section reuses the activity feed scoped to the cluster.

### 5.5 Mode badge spec

One badge component used on every card, detail header and chooser: icon + label — *Broadcast* (radiating/one-to-many glyph), *Project* (kanban/shared-board glyph), *Class* (stacked-copies glyph). Accent colour per mode from the theme extension, never the tile colours. Labels localized (O6).

### 5.6 Status pill spec

One `TileShareStatusPill`: *Invited* (amber), *Partially accepted* (blue — Project: some tasks accepted), *Accepted* (green — `TileColors.acceptedTileShare`), *Declined* (neutral-red), *Changed* / *At risk* / *Due tomorrow* (attention amber/orange), *On track* (green), *Planned* (neutral). Light and dark from theme tokens; icon + text (not colour alone).

### 5.7 Create — mode first (T14)

`＋` → chooser sheet: three cards (**Broadcast** "Everyone gets their own copy of one task", **Class** "Everyone gets their own copy of a project", **Project** "Everyone works on one shared project"). Card list is data-driven so deferred modes can be added later (T12). Then:

| | Broadcast | Class | Project |
|---|---|---|---|
| Screens | 1 | 2 | 2 |
| Screen 1 | name · duration · deadline · people | name · description · deadline · tasks · total effort (computed) | name · description · deadline · tasks · total effort (computed) |
| Screen 2 | — | people | people + **assign each task** (≥ 1 assignee per task in v1, O10) |
| Optional (T5) | notes · location · schedule pattern | per task: notes · location | per task: notes · location |

Task add/edit sheet = the existing `NewTileShareSheetWidget`, extended (name, duration, notes, location; drag to reorder). Location reuses `AddTileLocationScreen`/`LocationSearchWidget`; pattern reuses `AddTileRepeatScreen` → `RepetitionData` (serialisation is O1). After Send the user lands on the new cluster's detail (delivery state visible from the `invitation_*` activity events).

### 5.8 Recipient detail — Commitment

Who sent it, mode badge, what/when/notes/location, the task list (Class/Project), **Accept / Decline** (Broadcast), **Accept all / Decline all** (Class) or per-task **Accept / Decline** (Project) — T20 —, **Check fit**; comments thread inline (reuse `TiletteDetailScreen`/`CommentsSection`); after accept: my progress (per task for Class), link to the scheduled tile(s) (`TileDetailRoute.byDesignatedTileId`).

### 5.9 Accept preview (T21-T25, replaces “Check fit”)

```
┌────────────────────────┐
│ ‹  Review fit        ✕ │
│ [ day strip  Wed 22 › ]│  DayGridWidget(preview: true): my tiles,
│  8 ░░ Sync             │  the proposed block dotted + scrolled into view,
│  9 ┌┄┄┄┄┄┄┄┐ ← proposed│  swipe for other days
│ 10 └┄┄┄┄┄┄┄┘           │
├────── drag handle ─────┤
│ Content & Marketing …  │  bottom sheet, draggable (two snaps)
│ From Jessica · 1 hr    │
│ Tiler chose: Fri 9am   │
│ [ View other times  › ]│  → the sheet grows into the options list
│ [ Accept ✓ ] [ Reject ]│
└────────────────────────┘
```

* **Preview sheet:** name, inviter, description, deadline and duration, the time Tiler chose, conflicts when it is not viable, **Accept** and **Reject** (Reject = decline). “View other times” appears only when `capabilities.alternatives` is true (O19).
* **Options in the same sheet:** up to 4 slots per page, “Find another time” loads the next page (`nextOffset`). Tapping a slot runs *Revise* and moves the dotted block on the strip - the impact is visible without leaving the page. **No lock control** while `capabilities.fixedSessions` is false (T25).
* **Commit:** Accept sends the current `previewToken`. A **409** (“your schedule changed”) reloads the preview and keeps the user's choice if it is still valid, else says so.
* **States:** a real skeleton while loading (the forecast is slow), `unsupportedReason` messages (`alreadyAccepted`, `missingFutureDeadline`, `unsupportedConstraints`) that fall back to plain Accept / Decline, not-viable = conflicts listed with “find another time” primary, `503` (server switch off) and other failures inline with Retry.
* **Entry:** “Check fit” on a Broadcast invitation (card, row, detail). Not on Class or Project in v1 (T23). Inline Accept never passes through it (T22).

### 5.10 Schedule integration

Shared tiles on the Daily grid/list/bottom sheet show the **real recipients'** avatars with RSVP badges (replacing the placeholder icons) and the mode badge on tap-through; opens the cluster detail. (Tiles are not blocks; the P9 occupancy rail is unaffected.)

### 5.11 Activity (T15–T19)

| Surface | Where | Content |
|---|---|---|
| **Overview strip** | owner detail Overview; commitment detail | last 3 rows (avatar · sentence · relative time) + “View all” |
| **Feed route** | 🕘 in the hub bar (global) and “View all” (scoped to a cluster/task) | day-grouped rows, chips **All · Responses · Changes · Delivery**, swipe/long-press dismiss (+ undo), “Show dismissed”, “History starts on …”, “Load more” |
| **Attention** | derived (T7) | Changed / Completed / Responses items, each opening its target |

**Sentence table** (English shown; ICU-localized, all keys in `.arb`). Visibility is the server's policy — the client renders what arrives.

| Event | Sentence | Opens |
|---|---|---|
| `cluster_created` | “{actor} created {cluster}” | cluster |
| `cluster_invitation` | “{actor} invited you to {cluster}” | commitment detail (Check fit) |
| `tilette_added` / `tilette_deleted` / `tilette_restored` | “{actor} added / deleted / restored {title}” | task (deleted: none) |
| `tilette_edited` | by `changedFields`: “{actor} moved the deadline of {title} from {before} to {after}” · “… renamed a task” · “… updated the notes” (several → “… updated {title}”) | task |
| `recipient_added` / `_removed` / `_restored` | “{actor} added / removed / restored {subject}” | participants |
| `invitation_sent` / `_send_failed` / `_send_unknown` (owner-only) | “Invitation sent by {channel}” · “Couldn't send the invitation by {channel} — Resend” · “Invitation status unknown — Resend if needed” | participant row |
| `assignment_accepted` / `_declined` | “{actor} accepted / declined {title}” | participant |
| `assignment_completed` / `_reopened` | “{actor} completed / reopened {title}” | the scheduled tile via `calendarEventId` |
| `cluster_deleted` (owner-only) | “{actor} deleted {cluster}” | none |
| unknown type / future schema | “Activity updated” | none |

Grouping (T18) and the mode-aware wording are pure functions (`ActivityRows.group`, `ActivitySentence.of`) so both are unit-tested without widgets.


## 6. Architecture

```
lib/routes/authenticatedUser/tileShare/
  tileShareRoute.dart                  hub shell (T1/T6): segmented Attention | Clusters, chips, Activity, ＋
  attention/  attentionList.dart, attentionCard.dart
  clusters/   clustersList.dart, clusterCard.dart
  fit/        checkFitScreen.dart
  detail/     tileShareDetailScaffold.dart, broadcastDetail.dart, classDetail.dart, projectDetail.dart, commitmentDetail.dart
  create/     createModeChooser.dart, createBroadcast.dart, createClass.dart, createProject.dart
  widgets/    modeBadge.dart, statusPill.dart, participantRow.dart
lib/bloc/tileShare/                     attention / clusters / detail / fit cubits (T9), *_state.dart
lib/data/tileShareMode.dart             enum + inference (T2)
lib/data/tileShareRsvpSummary.dart      pure RSVP status counts (T13)
lib/data/tileShareAttention.dart        pure derivation of Attention items (T7)
```

Old files are retired only after their replacement is wired (each step leaves the app working). API classes change only where §8 lists a gap.

## 7. No-snap & interaction rules (T11)

- Item moves (accept/decline/undo, resolve), deletes, filter switches and reloads animate; row keys are the cluster / designated-tile id (never a fresh UUID); pagination appends, pull-to-refresh merges by id; scroll offset and swipe state survive a reload.
- Optimistic actions (T8) roll back with an animation and a localized message — never a silent revert.
- Every failure shows a localized message with Retry; no raw exception text. Hard-coded strings are moved into `.arb` as touched.

## 8. Data & API touchpoints

| Need | Exists | Gap |
|---|---|---|
| Shared-with-me / created-by-me lists | `GET api/TileShareCluster` (`isOutbox` flag) → `truncatedUser` only; `GET api/DesignatedTile/designated` for the recipient's tiles | **no RSVP counts** (O2); “All” merges two paged sources (client merge-sort by deadline, each source paged independently) |
| Progress | per-assignment completion only: `completionPct` on `DesignatedUser` (owner's view of a tilette) and `completionPercent` on `DesignatedTile` (the recipient's own) | **no cluster-level figure, and none is derived or shipped** (T13, owner decision); completion is shown per tilette / assignment only |
| Mode | `Mode` (broadcast / class / project) on the backend; legacy `isMultiTilette` | client does not parse or send it yet (Step 9.1); request key is **`Mode`**; for Class the **client adds each participant to every task** for now (O9) |
| Accept / decline | `POST api/DesignatedTile/status` (`Id`, `Status`) | undo semantics unknown (O3) |
| Tilettes + recipients | `GET api/TileshareTemplate` → `designatedUsers` | address not parsed in `TileShareTemplate`; add `addressData` |
| Cluster notes / address / pattern | request: `Notes`, `AddressData`, `SchedulePattern` | **response not parsed** in `TileShareClusterData`; pattern format undefined (O1) |
| Tilette notes | request `NoteMiscData`; response `miscData.userNote` | none |
| Attention sources | `GET api/TileShare/Invitations` (pending assignments: `assignmentId`, `clusterId`, `tiletteId`, `name`, `clusterName`, `deadline`, `inviterName`; or grouped by cluster with `pendingCount`, no roster/history), activity feed, `DesignatedTile.isViable`, outbox | derivation cost (O2); Behind threshold (O11); the client has no `Invitations` API class yet |
| Accept preview | `POST api/DesignatedTile/Preview`, `…/Preview/Options`, `…/Preview/Revise`; accept = `POST api/DesignatedTile/status` with `PreviewToken`; recovery `GET api/DesignatedTile/Response` and `…/ResponseOperation` | **untracked, uncommitted backend work behind a server switch; `capabilities` all false** (O18); built against fixtures until deployed |
| Activity | `GET api/TileShare/Activity` (`ClusterId`, `TiletteId`, `EventType`, `PageSize` 1–100, `Cursor`, `DismissedOnly`) and `POST api/TileShare/Activity/Dismissal` (`EventId`, `IsDismissed`) | client sends no `EventType`/`DismissedOnly`/`PageSize`, has no dismissal call, and drops the new event fields (T16) |

## 9. Phased rollout & step-by-step plan (TDD)

Conventions: each step = **Red** tests first → **Green** → **Refactor**; run the touched suites + `flutter analyze` on touched files; present the diff and stop; commit only on “commit”. Fake APIs are injected through cubit constructors (T9). New tests: `test/tileshare_*_test.dart`.

| Phase | Theme | Steps |
|---|---|---|
| **R0** | Foundation (pure) | 9.1 mode + RSVP summary + fan-out plan · 9.2 attention derivation · 9.3 fixtures + seams |
| **R1** | Attention | 9.4 cubit · 9.5 list + cards + chips · 9.6 inline Accept/Decline + Undo |
| **R2** | Clusters | 9.7 cubit + filter · 9.8 cluster cards, delete-confirm |
| **R3** | Hub shell | 9.9 restyled route |
| **RA** | Activity (runs after R3; its pure model work is in 9.2) | 9.25 cubit + dismissal · 9.26 feed route · 9.27 overview strip · 9.28 sentences + l10n · 9.29 deep links |
| **R4** | Accept preview | 9.10 API + model + fixtures · 9.11 preview cubit · 9.11b preview page + entry points |
| **R5** | Detail | 9.12 scaffold · 9.13 Broadcast · 9.14 Class · 9.15 Project · 9.16 Commitment · 9.17 retire old |
| **R6** | Create | 9.18 chooser + Broadcast · 9.19 Class · 9.20 Project · 9.21 Notes + Address · 9.22 Schedule pattern (**blocked, O1**) |
| **R7** | Integration | 9.23 real avatars on schedule cards · 9.24 ~~Check-fit v2 (day grid peek)~~ - folded into 9.11b (T24) |

#### R0 — Foundation

| Step | New / touched | Tests first (`test/tileshare_*`) | Exit |
|---|---|---|---|
| 9.1 | `tileShareMode.dart` — `TileShareMode {broadcast, project, class_}` + `fromCluster(cluster)` (the backend `mode` when present, else the legacy mapping `!isMultiTilette` → broadcast, `isMultiTilette` → project; a missing `mode` never yields class). `Mode` is added to `TileShareClusterModel` (PascalCase, like its other fields; regenerate `tileShareClusterModel.g.dart` with build_runner) and parsed in `TileShareClusterData.fromJson` (tolerant of `mode` / `Mode`, values case-insensitive). `tileShareClassFanout.dart` — pure `ClassFanout.missing({tilettes, participants})` → the (participant, tilette) pairs that still need adding (identity by email / phone / username, idempotent). `tileShareRsvpSummary.dart` — RSVP status counts per mode (T13): `{total, accepted, declined, pending}` via `fromUsers` (Broadcast) / `fromClass` (people) / `fromTilettes` (Project) / `forCluster`; **counts only — no progress figure is derived or shipped**. | `rsvp_summary_test` — empty; all pending; mixed counts per mode; a Class person is accepted only when accepted on every task they hold; identity matching across tasks; tolerant of `tentative` and unknown status strings (`stringToInvitationStatus` used to throw — the pure layer must not). `mode_test` — resolution table incl. backend-`mode` precedence; an unknown or garbled `mode` string falls back to the legacy mapping; `Mode` round-trips in the request JSON (key `Mode`) and parses from the response under either `mode` or `Mode`, any value casing. `class_fanout_test` — nothing missing when complete; one participant missing on some tasks; a new task is missing everyone; identity matching by email, phone and username; duplicates ignored. | pure tests green |
| 9.2 | **Activity model v2** (`tileShareActivity.dart`): new types `cluster_invitation`, `assignment_completed`, `assignment_reopened`; `actorId`, `targetUserId`, `assignmentId`; `changedFields` + `deadlineBefore/After`; `calendarEventId` (T16; allow-listed, version-gated, as today). `tileShareAttention.dart` — `AttentionItems.derive({invitations, activity, received, now})` → typed items (Invitation, Changed, AtRisk, Completed, Declined, DeliveryFailed), sorted (urgency, then recency), de-duped per cluster, dismissed events excluded. `ActivityRows.group` (T18) and `ActivitySentence.of` (T17), pure. Port the backend's canonical fixture into `test/fixtures/` so the test no longer reads a sibling repo. | `activity_model_test` — each new type parses; `changedFields` + old/new deadline; unknown fields ignored; a future schema version degrades safely; no raw contact data ever surfaces. `attention_test` — each item type from a minimal fixture; expired invitation excluded; `isTilable == false` excluded; a dismissed event is excluded; delivery failed/unknown → owner item; dedupe; stable order. `activity_rows_test` — same actor/type/cluster within 60 s collapse, different actor or gap > 60 s do not, order preserved. `activity_sentence_test` — every type × (actor is me / other / unknown), edit sentences per `changedFields`, subject resolution with and without a participant match. | pure tests green |
| 9.3 | `test/helpers/tileshare_fixtures.dart`; API seams (`TileShareClustersSource`, `TileShareAttentionSources`, `TileShareDetailSource`, `TileShareFitSource`) with thin live adapters over `TileShareClusterApi` / `DesignatedTileApi` / `TileShareActivityApi` / `WhatIfApi`. | adapters delegate 1:1; fakes can fail on demand. | seams exist; no UI change |

#### R1 — Attention

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.4 | `tile_share_attention_cubit.dart` — loads **Invitations** (`GET api/TileShare/Invitations`), the **activity feed** and my received tiles (for At risk) in parallel, derives items, `resolve(id)` (an invitation acted on disappears; an activity item is **dismissed on the server**, optimistic), `refresh()` merges by id. New thin `TileShareInvitationsApi` behind the seam. | first load; one source failing keeps the others' items and surfaces the error; refresh never empties the list mid-load; dismissal is optimistic, rolls back on failure and can be undone; a dismissed item stays gone after a reload (server state). | cubit green; unused |
| 9.5 | `attention/attentionList.dart`, `attentionCard.dart`, chips (All · Invitations · Changes · At risk · Responses), `widgets/statusPill.dart`, `modeBadge.dart`; `AnimatedList` keyed by item id; route shows it behind a switch. | render order; chip filters + counts; card per type shows reason/meta/CTA; tap opens the target; chip switch animates (no first-frame jump); keys stable across refresh; "all caught up" empty state; dark + light. | on-device: Attention reads as a to-do list |
| 9.6 | inline **Accept/Decline** on Invitation cards: cubit `respond(id, status)` (T8: optimistic + deferred commit + rollback), Undo snackbar, flush on dispose. | accept removes the card immediately; Undo within the window makes **no request**; after the window the call fires once, then `analyzeSchedule` + `buzzSchedule` (accept only); failure restores the card with a localized message; leaving flushes; double-tap ignored while pending; decline never triggers analysis; mode rules (T20): a Broadcast card shows Accept · Decline, a Class card shows **Accept all · Decline all** (one undoable action updating every task the user holds), a Project card shows **Review** and no accept/decline buttons. Analytics: `tileshare_accept/decline/undo`. | on-device: decide from the list; Daily updates after accept |

#### R2 — Clusters

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.7 | `tile_share_clusters_cubit.dart` — filter `{all, sharedWithMe, createdByMe}`; two independently paged sources merged by deadline; `delete(id)` optimistic + rollback; per-card **RSVP summary derived from the tilettes** (`TileShareRsvpSummary.forCluster`), loaded lazily for visible rows and cached (O2); no cluster progress is shown (T13). | paging appends and de-dupes; filter switch keeps loaded pages; "All" merge order; delete restores on failure; lazy summary requested once per id; a failed fetch never blocks a card. | cubit green |
| 9.8 | `clusters/clustersList.dart`, `clusterCard.dart` (mode badge, role line, due chip, per-mode/role RSVP summary per §5.3, inline Accept/Decline for pending); confirm dialog on delete; stable keys. | Broadcast/Class/Project cards differ; owner vs recipient variants; RSVP text from fixtures; delete confirm (cancel keeps the row); swipe state survives refresh; "+N more" avatars; filter switch is animated; no-snap case. | suites green |

#### R3 — Hub shell

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.9 | `tileShareRoute.dart` — fixed 48 px bar (‹, title, Activity, ＋), pill segmented control **Attention \| Clusters** with count badge, chips/filter per segment, default-segment rule (T7), `＋` → chooser (until 9.18 the existing create route); Activity opens the feed as its own route. Old tabs removed. | default segment logic (Attention when non-empty, else last-used); badge count; filter chips per segment; Activity opens the feed; back pops with `false`; each segment keeps its own scroll offset. | chrome matches Daily |

#### RA — Activity (T15–T19)

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.25 | `tile_share_activity_cubit.dart` + seam `TileShareActivitySource` (activity, dismissal): scopes (global / cluster / tilette), cursor paging, **merge-in-place** refresh, clear only on access loss, generation guard (kept from today), optimistic dismiss + undo, `DismissedOnly` view, reload on `tileShareActivityChanges`, app-lifecycle (pause) behaviour left exactly as it is today (O13). `TileShareActivityApi` already has `EventType`, `PageSize`, `DismissedOnly` and `setDismissed` (added in 9.4). | first page; paging appends + de-dupes by `eventId`; refresh keeps rows visible and merges new ones on top; access loss clears with the explanation; dismiss rolls back on failure; undo restores; a mutation signal triggers one reload; stale responses are ignored. | cubit green |
| 9.26 | `activity/tileShareActivityFeed.dart` replaces `TileShareActivityWidget`: day headers, avatar + sentence rows (T17), grouping with expand (T18), chips, dismiss/undo, “Show dismissed”, “History starts on …”, Load more; `TileShareActivityButton` becomes the hub 🕘. | rows render sentences with actor avatar; grouped row expands; chips filter loaded pages; a refresh adds rows without moving existing ones in the first frame; swipe-dismiss + undo; empty / failed / denied states; dark + light. | on-device: the feed reads as a story |
| 9.27 | `activity/activityStrip.dart` — the Overview strip (last 3 + “View all”), used by the owner details (9.13–9.15) and the commitment detail (9.16). | shows ≤ 3 rows; “View all” opens the scoped feed; hidden when empty; updates in place after a mutation. | |
| 9.28 | Sentences + l10n: ICU strings for every type × perspective (en + es, as the rest of this work; other locales fall back to en until translated); replace the current single-label strings. | every event type renders in en and es; plural forms for grouped rows; no hard-coded English in the activity UI. | |
| 9.29 | Deep links from rows: task (template detail), cluster detail, participant row, scheduled tile via `calendarEventId` (`TileDetailRoute`); a target that is gone shows “Item no longer available” (kept) without navigating. | each row type opens the right route; unavailable targets stay put with the message; returning refreshes the feed once. | |


#### R4 — Accept preview (T21–T25)

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.10 | `data/tileSharePreview.dart` (response model: current / proposed blocks, sessions with `sessionKey` + `placement` + `isFixed`, conflicts, per-response `capabilities`, `unsupportedReason`, `previewToken` + `expiresAt`, `rangeStart/End`, options page with `optionId`s + `nextOffset`; the operation record), `services/api/tileSharePreviewApi.dart` (`preview`, `options`, `revise`, `accept` = `status` with `PreviewToken` + a generated `OperationId`, `operation(id)`, `response(id)`; envelope reader from 9.6; 404 / 409(reason) / 503 as typed errors; logging), a `TileSharePreviewSource` seam + live adapter, fake + JSON fixtures. | request shapes (route, verb, body keys incl. `Offset`, `SessionKey`, `OptionId`, `OperationId` 32-hex); parsing every field incl. missing / null and unknown `placement`; 409 carries its reason; 503 = unavailable; 404 = gone; logs carry route + status; `OperationId` is stable across a retry. | API + model green |
| 9.11 | `bloc/tileShare/tile_share_preview_cubit.dart` — load preview, options (paged), choose option (Revise), accept (queue + poll the operation), reject (decline, no token); capabilities per response; token + `expiresAt` bookkeeping; 409 handling by reason; stale guard. | loading → ready; unsupported reasons; not viable lists conflicts and offers no token actions; options append and de-dupe; choosing an option swaps token and proposed block; accept sends the latest token with one `OperationId` and polls `queued → applied → completed`; `rejected` / `needsReview` surface; `previewExpired` re-previews; `responseInProgress` joins the pending operation; a killed-and-reopened app recovers via `Response`; failure + retry; overlapping calls; close mid-flight. | cubit green |
| 9.11b | `preview/tileSharePreviewPage.dart` — day strip (`DayGridWidget(preview: true)` + block → `SubCalendarEvent` mapper + day stepping) over a draggable sheet (preview ↔ options); Accept / Reject; entry from “Check fit” on Broadcast cards, rows and detail. | strip shows the proposed block selected and scrolled in; sheet snaps; option tap moves the block (animated); Accept disabled while revising; every state from 9.11 renders; both themes, 320 px; card button opens the page. | on-device: proposed slot matches the desktop preview |

#### R5 — Detail

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.12 | `detail/tileShareDetailScaffold.dart` + `tile_share_detail_cubit.dart` (by-cluster / by-designated-id / by-data entry points, error + Retry, localized). `TileShareDetailWidget` becomes a thin router behind a switch. | loading → content; error + Retry; by-designated-id resolves the cluster; deep link `tileshareid` opens the right variant by mode + role; reload keeps content (no spinner flash). | suites green |
| 9.13 | `broadcastDetail.dart` — header (inline-editable), Overview · Participants, roster rows (`participantRow.dart`), resend/remove with optimistic rollback (fixes doc 3.3/3.5). | roster renders pill/progress; add/remove optimistic + rollback; concurrent adds serialize; delivery state from activity events; Overview previews don't repeat lists. | |
| 9.14 | `classDetail.dart` — Overview · Tasks · Participants; per-person **segmented** progress; person → task-by-task sheet. | segments per task; tasks reorder persists (`OrderedIndex`); person sheet lists their tasks; adding a person adds them to **every** task (fan-out through `DesignatedTileApi.addContact`, one call per task, serialized per cluster, idempotent against existing designated users); adding a task adds **every** participant to it; removing a person removes them from every task; a partial failure leaves the person marked *incomplete* with Retry and is never reported as success; on load, a participant missing from some tasks is flagged incomplete. Class offers **Accept all / Decline all** (T20): sequential `statusUpdate` per task the user holds; a partial failure leaves the rest pending with Retry. | |
| 9.15 | `projectDetail.dart` — Tasks board with assignee, reassign and each task's own progress (no rolled-up total, T13). | assignee shown; reassign round-trips; a task with no assignee is flagged (O10); there is **no Accept-all** anywhere on a Project — each task has its own Accept / Decline (T20). | |
| 9.16 | `commitmentDetail.dart` — recipient view (§5.8) + Check-fit entry; comments; post-accept progress + tile link. | actions as 9.6; comments mount once; Class shows my per-task progress; Project shows my tasks only; Accept all appears on Class only, per-task buttons on Project (T20). | |
| 9.17 | Retire `singleTilette…`, `multiTilette…`, `inboxMultiTilette…`, `TileShareListWidget`, `TileShareSimpleWidget` usages, `designatedTileListWidget` (if unused), dead helpers; remove the switches from 9.5/9.12. | no imports of retired files (grep-style test); `flutter analyze` clean of removed symbols; suites unchanged. | one code path per screen |

#### R6 — Create (T14 = B, locked)

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.18 | `create/createModeChooser.dart` + `createBroadcast.dart`; remove the bento toggle and the double-push/pop. | chooser routes per mode; validation (name ≥ 3, ≥ 1 person, duration > 0) gates Send; payload carries `Mode: broadcast`; success lands on the new cluster's detail; failure keeps the form. | |
| 9.19 | `createClass.dart` — details + tasks (add/edit sheet, drag reorder, computed total effort) → people. | ≥ 1 task and ≥ 1 person; effort sum; order → `OrderedIndex`; payload carries `Mode: class` and lists **every person on every task** (client fan-out at create); a create that fails part-way surfaces the error and keeps the form. | |
| 9.20 | `createProject.dart` — same tasks step → people + per-task assignment. | every task needs an assignee (O10); payload carries `Mode: project` and maps assignees per tilette; unassigned blocks Send. | |
| 9.21 | Notes + Address (T5): fields in Broadcast (cluster) and the task sheet (tilettes); parse `addressData`/`notes` in the models; reuse `AddTileLocationScreen`; show on cards/details/commitment; editable after creation (replaces the template-detail-only notes editor). | request JSON includes the fields; response parses them; location optional; recipients see notes + location; edit persists. | |
| 9.22 | Schedule pattern (T5) — **blocked on O1**: `AddTileRepeatScreen` → `RepetitionData` → `SchedulePattern`; “Repeats weekly on Mon, Wed” on cards/detail. | serialisation matches the contract fixture; none omits the field; localized strings. | |

#### R7 — Integration

| Step | New / touched | Tests first | Exit |
|---|---|---|---|
| 9.23 | `enhancedTileCard.dart` (`_buildAvatar`), grid card / bottom sheet, legacy `tile.dart` share icon → recipient avatars with RSVP badges (needs designated users on the sub-event payload — O4). | avatars reflect recipients/badges; “+N”; tap opens the right detail; grid/list parity. | |
| 9.24 | Check-fit v2: per-day rows open a `DayGridWidget(preview: true)` peek from the forecast response. | peek renders the forecast day; read-only; failure falls back to v1. | |

**Gate:** every step individually approved before commit; on-device checks recorded in §11.

## 10. Open concerns / decisions to settle

| # | Question | Default if unanswered |
|---|---|---|
| **O1** | **`SchedulePattern` contract** — only a string on the cluster request; nothing produces or reads it. Format (RRULE? Tiler repetition JSON?), does it recur per recipient, Broadcast-only? | Step 9.22 stays blocked. |
| **O2** | Lists and Attention need RSVP counts (accepted/declined/pending; tilette counts). `GET api/TileShareCluster` returns only `truncatedUser`, so the counts must be derived from each cluster's tilettes. Can the backend add summary fields, a batch endpoint, or an **attention endpoint**? | Client lazy-loads each visible card's tilettes (`GET api/TileshareTemplate` per cluster) and derives the counts, and derives Attention from its sources (works, N requests per page). |
| **O3** | Undo of accept/decline: does the server accept `Status: none`, and does un-accepting remove scheduled tiles? | T8 defers the commit so Undo never reaches the server. |
| **O4** | Does the sub-event payload carry designated users (real avatars on schedule cards), or only `tileShareDesignatedId`? | Fetch on demand, cache per id, degrade to a single glyph. |
| **O5** | Task ordering: display order only, or dependency (task 2 after 1)? | Display order only. |
| **O6** | User-facing vocabulary: *Clusters* (owner's word), *Attention*, *Broadcast / Project / Class*; the mocks say *collection / task / participant / commitment*. Pick one glossary (and translate it). | Clusters · Attention · Broadcast / Project / Class · task · participant. |
| **O7** | ~~Check fit for multi-task modes / forecast reliability~~ — **superseded by T21.** The forecast-derived verdict was withdrawn; the backend accept preview replaces it, per assignment (T23). | — |
| **O8** | ~~Accept semantics per mode~~ — **resolved (T20):** Accept all exists only in **Class**; **Project** is per task only. | Class Accept all = sequential `statusUpdate` per task the user holds until a bulk endpoint exists; Class has no per-task accept (my reading). |
| **O9** | **`Mode` — resolved.** The backend has a cluster **`Mode`** (broadcast / class / project): request key `Mode` (PascalCase like the other request fields), values lower-case. **Class recipients are added per task by the client for now** — a person must be added to every task of a Class (and a new task must receive every participant) through `DesignatedTileApi.addContact`, one call per (person × task). | Response key read as `mode` or `Mode`, values case-insensitive; a missing or unknown value falls back to the legacy mapping (`isMultiTilette` false → broadcast, true → project). Fan-out is **not atomic**: serialize per cluster (contact-input doc 3.5), skip pairs that already exist, mark a partly-added person *incomplete* with Retry, reconcile on load (`ClassFanout.missing`). “Each class” is read as “each task in the class”. Remove the fan-out when the server takes it over. |
| **O10** | Project tasks with no assignee (the future *claim* model): allowed in v1? | No — every task needs ≥ 1 assignee. |
| **O11** | ~~On-device seen-state~~ — **resolved by server-side dismissal** (`POST api/TileShare/Activity/Dismissal`). ~~Owner-side “Behind” definition~~ — **dropped**: it needed a cluster progress figure (T13). | — |
| **O12** | ~~Create flow A / B / C~~ — **resolved: B** (mode first, adaptive), owner 2026-09-29. | — |
| **O13** | ~~Clear on pause~~ — **out of scope** (owner, 2026-09-29): the feed's app-lifecycle behaviour is unrelated to this redesign and stays exactly as it is today. | — |
| **O14** | **Deployed backend state.** Backend `feature/tileShareActivity` was merged with master on 2026-09-29 with 42 uncommitted files; `cluster_invitation`, `assignment_completed`, `assignment_reopened` exist in the DTO and in real-DB tests (`assignment_started` appears once), but the domain constants file on disk (`My24HourTimerWPF`) lists only 7 types, so that checkout is stale. What is deployed, and are the wire strings final? | Treat the three new types as real; unknown or renamed strings degrade to “Activity updated”. |
| **O15** | **Notification multiplication.** `cluster_invitation` is cluster-level, but `invitation_sent/failed/unknown` are per assignment, and Class fan-out (O9) creates one assignment per (person × task). Does a Class send one invitation message per person, or one per task? | Ask before shipping Class create (9.19); group the owner-facing events (T18) either way. |
| **O17** | ~~Cluster progress source~~ — **resolved (owner, 2026-09-29): cluster-level progress does not ship.** The untracked backend `GET api/TileShareCluster/Progress` is not used by the client, and no client-side substitute is built (T13). | — |
| **O18** | **The preview backend is enabled but still untracked in git.** `TileSharePreviewController.cs`, `TileSharePreview.cs` and `TileShareScheduleOperations.cs` are uncommitted in the backend tree; the switch is the app setting `tileShareSchedulePreviewEnabledKey` (503 when off). Facts read from the code (2026-10-01): a preview token lives **15 minutes** (`expiresAt`; expiry is a 409 `previewExpired`); the window is **28 days**; accept queues an operation (states `Preview, Queued, Applied, Completed, Rejected, NeedsReview`, worker in `PostProcessingServer`); 409 reasons include `previewExpired, assignmentChanged, scheduleChanged, sessionsChanged, overlappingSessions, invalidSession, invalidProposal, responseInProgress, operationMismatch`; a recipient can recover an accepted response via `GET api/DesignatedTile/Response?id=` (returns `calendarId`). Not yet observed against a real response. | Build to these, tolerant of unknown fields; verify one real preview / options / revise / accept on a device before calling it done; watch for the contract still moving. |
| **O19** | ~~Do the options follow `capabilities.alternatives`?~~ **Resolved (2026-10-01).** Capabilities are **per response, not global**: the base envelope says all `false`, and `StoreAsync` overwrites them to all `true` exactly when the preview is **viable and stored** (a `previewToken` is issued, switch on). An unsupported or not-viable preview carries `false`, no token and no options. So "follow the flag" is the right rule and needs no product decision: options appear when there is a token. | Client reads `capabilities` from each response; no token = no options / revise / accept-with-token (plain Accept / Decline remain). |

## 11. Implementation tracking

| Phase | Step | Commit | Status | Notes |
|---|---|---|---|---|
| R0 | 9.1 Mode + RSVP summary + class fan-out plan | `fb8cd809` | Done | T2, T13, O9 - `tileShareMode.dart`, `tileShareRsvpSummary.dart` (`fromUsers`, `fromClass`, `fromTilettes`, `forCluster` - counts only), `tileShareClassFanout.dart`; `Mode` parsed + on the request model; tolerant invitation-status parsing; 30 tests. (Cluster progress removed 2026-09-29.) |
| R0 | 9.2 Activity model v2 + attention derivation + rows/sentences | `fb8cd809` | Done | T7, T16-T18 - `tileShareActivity.dart` (v2), `tileShareInvitation.dart`, `tileShareAttention.dart`, `tileShareActivityRows.dart`, `tileShareActivitySentence.dart`; backend fixtures copied to `test/fixtures/tileshare_activity/`; 93 tests (4 new suites + the existing activity suite) |
| R0 | 9.3 Fixtures + seams | `946f2a42` | Done | T9 - `lib/services/tileShare/tileShareSources.dart` (`TileShareClustersSource`, `TileShareAssignmentsSource`, `TileShareFitSource`), `liveTileShareSources.dart` (thin adapters over `TileShareClusterApi` / `ScheduleApi` / `WhatIfApi`), `test/helpers/tileshare_fixtures.dart` + `tileshare_fakes.dart` (in-memory sources with `failNext` / `hold`); 19 tests. Seams for Invitations, activity dismissal and share editing are added with 9.4 / 9.25 / 9.13, which first need them. |
| R1 | 9.4 Attention cubit (+ Invitations API) | `946f2a42` | Done | T7, O2, O14 - `TileShareAttentionCubit` + state, `TileShareInvitationsApi` (`GET api/TileShare/Invitations`), `TileShareActivityApi` extended (`PageSize` / `EventType` / `DismissedOnly`, `setDismissed`), `TileShareAttentionSources` seam + live adapter + fake; 45 new tests (cubit 28, HTTP-level API 13, live-adapter delegation 4 added to the seam suite of 23). Needs the backend branch `feature/tileShareActivity` deployed (O14). |
| R1 | 9.5 Attention list + cards + chips | `13962821` | Done (visual review pending) | T7, T11 - `attention/` (`attentionView`, `attentionCard`, `attentionCopy`, `attentionFilter`, `attentionTab`), `widgets/` (`statusPill`, `modeBadge`), `tileShareFlags.dart`; Attention tab on the existing route behind `--dart-define=TILESHARE_V2=true`; 53 l10n keys (en + es); 94 attention tests. Off-device renders reviewed; on-device check pending. |
| R1 | 9.6 Inline Accept/Decline + Undo | `92e343cb` | Done (off-device renders reviewed; on-device pending) | T3, T8, T20, O3 - `TileShareAttentionCubit.respond / undoResponse / flushPending` (+ `close` flushes), `AttentionRespondFailure`, card buttons, 11 l10n keys (en + es); 34 new tests (cubit 17, card 8, screen 9). Accept all is Class-only; Project and unknown-mode invitations are reviewed. |
| R2 | 9.7 Clusters cubit + filter | `b402c68b` | Done (logic only; no UI yet) | T6, T13, O2 - `TileShareClustersCubit` (`load/refresh/setFilter/loadMore/ensureSummary/retrySummary/delete/acknowledgeFailure`) + `TileShareClustersState` (`ClusterFilter`, `ClusterListItem`, `ClusterSource`, `ClusterDeleteFailure`); 37 tests. Rules: two sources paged independently by offset; one deadline order for every filter (soonest first, none last, ties by id); a cluster in both lists shows once as mine; filter switch requests nothing; RSVP summary lazy, once per cluster, **only for clusters I created**, failure never blocks the row; delete optimistic and hidden through a concurrent refresh. |
| R2 | 9.8 Cluster cards + list view + delete-confirm | `b402c68b` | Done (off-device renders reviewed; on-device pending; not yet reachable in the app - hub wiring is 9.9) | T3, T6, T11, T13, T20, O2 - `ClusterCard`, `ClusterCopy`, `TileShareClustersView`; `MyClusterStatus` (my status + task count per shared cluster) read by the cubit; shared `TileShareAnimatedCardList` / chip bar / banner / error / empty / skeleton extracted from the Attention view (Attention unchanged, its 51 UI tests still green); 33 l10n keys (en + es); 76 new tests (status 7, cubit 7, card 34, view 28). |
| R3 | 9.9 Hub shell | `7c69e910` | Done (off-device renders reviewed; on-device pending) | T1, T6, T7, T8 - `TileShareHub` (bar + Attention \| Clusters), `TileShareHubHost` (live wiring), `TileShareHubPreferences`, shared `undoSnackBar`; behind `--dart-define=TILESHARE_V2=true`, the route now shows the hub in place of the old tabs; `answerRevision` on the Attention state; 1 l10n key; 34 new tests (hub 27, route 2, preferences 3, cubit 2). |
| RA | 9.25 Activity cubit + dismissal | _TBD_ | Not started | T15, T19, O13 |
| RA | 9.26 Feed route | _TBD_ | Not started | T17–T19 |
| RA | 9.27 Overview strip | _TBD_ | Not started | T15 |
| RA | 9.28 Sentences + l10n | _TBD_ | Not started | T17 |
| RA | 9.29 Deep links | _TBD_ | Not started | |
| R4 | 9.10 Preview API + model + fixtures | _TBD_ | Not started | T21, O18 |
| R4 | 9.11 Preview cubit | _TBD_ | Not started | T21, T25 |
| R4 | 9.11b Preview page + entry points | _TBD_ | Not started | T22-T24 |
| R5 | 9.12 Detail scaffold | _TBD_ | Not started | T10 |
| R5 | 9.13 Broadcast detail | _TBD_ | Not started | |
| R5 | 9.14 Class detail | _TBD_ | Not started | O9: client fan-out |
| R5 | 9.15 Project detail | _TBD_ | Not started | O10 |
| R5 | 9.16 Commitment detail | _TBD_ | Not started | |
| R5 | 9.17 Retire old screens | _TBD_ | Not started | |
| R6 | 9.18 Chooser + Broadcast create | _TBD_ | Not started | T14 |
| R6 | 9.19 Class create | _TBD_ | Not started | O9: client fan-out |
| R6 | 9.20 Project create | _TBD_ | Not started | O10 |
| R6 | 9.21 Notes + Address | _TBD_ | Not started | T5 |
| R6 | 9.22 Schedule pattern | _TBD_ | **Blocked (O1)** | T5 |
| R7 | 9.23 Real avatars on schedule cards | _TBD_ | Not started | O4 |
| R7 | 9.24 Check-fit v2 (grid peek) | _TBD_ | Not started | T4 |

## 12. Change log

| Date | Author | Change |
|---|---|---|
| 2026-10-01 | _TBD_ | **R4 plan corrected after the owner said the backend preview and its capabilities are enabled.** Re-read the backend: (1) **capabilities are per response** - the base envelope says all false, `StoreAsync` sets all true when the preview is viable and stored (token issued), so **O19 is resolved** (options follow the flag; no product decision) and O18 becomes "enabled but untracked"; (2) **accept is an operation, not a single call** - `status` with `PreviewToken` + a client-made 32-hex `OperationId` queues it and the client polls `ResponseOperation` (`Queued, Applied, Completed, Rejected, NeedsReview`); the 15-minute token lifetime and the 409 reasons are now in O18; (3) a recipient can recover an accepted response via `Response?id=`. 9.10 / 9.11 rewritten to include the operation, polling, expiry and recovery. **Lock (T25) stays off by the owner's earlier decision** even though the server now supports it. No code change. |
| 2026-10-01 | _TBD_ | **R4 re-planned: Check fit becomes the accept preview (T21-T25); the forecast-derived verdict is withdrawn.** The owner asked why a fit engine existed with "no backend response" and then showed the desktop flow (Tileshare Preview -> Find Another Time). Checked the backend: the **preview API exists** (`TileSharePreviewController.cs`: `Preview`, `Preview/Options`, `Preview/Revise`, accept via `status` + `PreviewToken`) but is **untracked and switched off, with `capabilities` all false** (O18). The 9.10 fit model/cubit (uncommitted, 47 tests) guessed a Fits / Tight / Doesn't-fit verdict from `WhatIf/NewTile` with inferred semantics - **deleted, never committed**; I had noted the preview API in O7 but dismissed it too early. Owner decisions: **sheet layout** (day strip + draggable bottom sheet, T21), **inline Accept skips the preview** (T22), **Class and Project skip it** (T23), **`DayGridWidget(preview: true)` is the strip** (T24; it already dots and scrolls to `selectedActionEntityId`), **lock off** (T25). New steps: 9.10 API + model + fixtures, 9.11 preview cubit, 9.11b page + entry points; old 9.24 folded into 9.11b. Open: O18 (backend state), O19 (should the options follow `capabilities.alternatives`, false today?). No code change in this entry. |
| 2026-10-01 | _TBD_ | **Step 9.9 implemented (R3) - the hub shell.** `TileShareHub`: a 48 px bar (back -> pops `false`, title, Activity, create) over a two-segment control, **Attention** (with a count badge) and **Clusters**; both segments stay alive in an `IndexedStack` so each keeps its scroll offset, Clusters is only built and loaded when first visited, and a segment change fades (200 ms) rather than snaps. **Opening segment (T7):** Attention when it has items, otherwise the last-used segment (Attention when none stored); decided once Attention has loaded (an Attention that failed counts as empty), meanwhile Attention shows its skeleton; a segment the user picks by hand is never overridden and is the only thing remembered (`TileShareHubPreferences`, SharedPreferences). **Answering from a Clusters row goes through the Attention cubit** (one engine, one Undo, the shared `showTileShareUndoSnackBar`); the Clusters list reloads once the answer has been sent - new `answerRevision` on the Attention state, bumped when a send finishes, saved or refused; with no matching `invitation:<clusterId>` in Attention the row opens for review instead of doing nothing. After a screen opened from the hub closes, what it may have changed is reloaded (Attention, Clusters, both after create). `TileShareHubHost` builds the live APIs and both cubits and **waits for the signed-in user id before anything loads** (a short spinner) so Attention never flashes the user's own actions; `＋` opens today's create route until 9.18's chooser; Activity opens as its own route with a plain app bar. With the flag on, **the old tabs are gone** and `attentionTab.dart` (the 9.5 host) is deleted; with it off the route is exactly the released three tabs. Also fixed from the renders: the shared loading skeleton overflowed a short (landscape) screen - it now clips. Mutation-checked: removing the manual-choice guard fails its test. Renders (light, dark, 320 px, empty) reviewed. 34 new tests; TileShare suites 460 passing; full suite 8 pre-existing failures; analyze unchanged (458). **Open (O6):** the segment label "Clusters" is the owner's word, unchanged in es. |
| 2026-10-01 | _TBD_ | **Step 9.8 implemented (R2) - cluster cards, the Clusters list view, delete confirm.** (1) `MyClusterStatus.byCluster` turns my assignments into "my status + task count" per cluster; `TileShareClustersCubit` now takes an optional assignments source and reads up to 2 pages in the same load (failure logged, last-known kept, rows never blocked). (2) `ClusterCard`: Broadcast / Class / Project differ; owner = who it went to (initial avatars, `+N`, `...` when truncated) + "3 of 5 accepted" / "... people ..." / "... tasks ..." and, for a Project, one segment per task; recipient = who it is from, my status pill, my task count (Class/Project only), inline Accept / Decline (Class: Accept all / Decline all); **a Project only says "N tasks need your response"** (T20); deadline chip (urgent inside 48 h, "Overdue", none when completed); no progress figure anywhere (T13); a cluster with nobody counted shows no responses line (found in the render: it said "0 of 0 accepted"). (3) `TileShareClustersView`: chips All / Shared with me / Created by me, animated list keyed by id (a row that stays is the same element across a filter switch; leavers fade), lazy RSVP counts for built rows only (re-asked after a refresh), empty state per filter with "Share a tile" (not under Shared with me), error state vs banner judged on the sources the current filter shows, "Load more" footer with retry, delete = overflow menu -> confirm dialog -> optimistic removal, refusal brings it back with a message naming it. **Deviations for the owner to veto:** (a) the owner's *swipe* (edit, delete) became an overflow menu with Delete only - Edit has no destination until R6 and a swipe-to-delete fights the animated removal; (b) paging is a **Load more button**, not infinite scroll; (c) the card takes `onAccept/onDecline` callbacks and the view an `onAnswer` callback: **the answering engine (with Undo) stays in the Attention cubit**, and the hub (9.9) will route a Clusters row's answer to it (Attention item ids are `invitation:<clusterId>`) rather than duplicate it; after an answer the Clusters list must be refreshed by the hub; (d) the "Created by you" / "From ..." role and the mode name share one subtitle line. Also: the shared `TileShareStatusPill` now ellipsizes (a long Spanish label could overflow); `ClusterDeleteFailure` carries the name. Off-device renders (light, dark, 320 px, filters, delete dialog, banner, empty) reviewed. 76 new tests; TileShare suites 427 passing; full suite 8 pre-existing failures; analyze unchanged (458). |
| 2026-09-30 | _TBD_ | **Step 9.7 implemented (R2) - Clusters cubit (logic only).** `TileShareClustersCubit` over the `TileShareClustersSource` seam. Decisions made while building, for the owner to veto: (1) **one deadline order for all three filters**, not only All, so rows do not reorder when the chip changes (the server's own order is not assumed); (2) a cluster that both lists return is shown once, as *created by me*; (3) the **RSVP summary is requested only for clusters I created** - the recipient card (§5.3) shows my own status from my assignments (9.8), and a recipient may not be allowed the roster; (4) a **refresh restarts paging from the first page** while rows stay on screen, and cached counts stay shown until the next request replaces them; (5) a failed summary is marked on the row and is **not retried on its own** (`retrySummary`); (6) a failed extra page keeps the rows and sets `loadMoreFailed`. Logging built in from the start (`TileShareClusters: loaded created=N shared=M (failed: ...)`, refused delete, failed summary). One bug caught by the tests' timeouts: `whenComplete(() => map.remove(id))` returned the future it was completing and deadlocked. Not observed separately as Red (tests and cubit written together, then run). 37 new tests; full suite 8 pre-existing failures; analyze unchanged. |
| 2026-09-30 | _TBD_ | **Invitations contract corrected (found on-device): the unscoped call returns projects, not invitations.** Device log: `Invitations: the response had no "invitations" list (found: projects, nextCursor)`. Reading `TileShareInvitations.cs` in full (backend branch `feature/tileShareActivity`): with no `ClusterId`/`TiletteId`/`AssignmentId` the server returns a **per-project summary** `projects:[{clusterId, name, pendingCount}]`; only a scoped call returns per-task `invitations`. I had read only the second half and built the flat-list assumption on it. Fix (client-side, no backend change): `TileShareInvitationsApi.getInvitationProjects` (new) and `getInvitations` now requires `clusterId`; `LiveTileShareAttentionSources.invitations` reads the project summary (up to 5 pages), then each project's invitations (paged to the end so Class *Accept all* has every task; up to 10 pages per project, 6 projects in flight), and returns one flat first page. A failing project fails the whole source (a partial inbox is never shown as the whole one); cuts are logged. Cost: 1 + one call per project with pending invitations. **Open item O16 (backend):** a flat mode (or `assignmentIds` in the summary) would remove the N+1 - owner to decide. Also: the load log line now lists the activity by event type (`types={assignment_declined:1, ...}`) because `activity=4 -> 0 items` on the device cannot otherwise be told from a bug. 9 new tests (API 5, adapter 6 incl. cut-off and partial failure, cubit 1; replaced 1); TileShare suites 314 passing; full suite 8 pre-existing failures; analyze unchanged. |
| 2026-09-30 | _TBD_ | **Envelope fix, second bug (found on-device).** The first fix treated `Error.Code` as an integer, but the wire sends the string `"0"`, so every successful response was rejected as `server error 0 (SUCCESS)` (both sources failed). My test helper had the same wrong assumption, so it stayed green. The test helper now sends the real string code (Red first), and the reader accepts `"0"`, `0` and `0.0` as success; non-zero still fails with the server message. The existing `AppApi.isTilerRequestError` already compared against `'0'` - I should have looked there first. TileShare suites 161 passing. |
| 2026-09-30 | _TBD_ | **Root cause of the failing source, found with the new logs (on-device).** The console showed `activity failed: type 'Null' is not a subtype of type 'List<dynamic>'` and `invitations=0` with no failure. Both endpoints answer through the backend's `PrivateOkResponse` -> `PostBackData`, so the body is `{Error:{Code,Message}, Content:{items|invitations, nextCursor, ...}}`; my parsers read the top level. Activity hard-cast `items` (threw); Invitations defaulted a missing list to empty (**silently an empty inbox** - so `invitations=0` on that device was not trustworthy and real invitations may have been hidden). My fixtures and API tests had bare bodies, which is why tests never caught it. Fix: `readTileShareContent` (`lib/services/api/tileShareEnvelope.dart`) unwraps `Content`, accepts a bare map, turns a non-zero `Error.Code` into an error carrying the server message, and **fails loudly and logs when the expected list is missing** instead of treating it as empty. Both APIs use it. 8 new API tests (envelope, empty envelope, missing list, Tiler-level error for both endpoints); TileShare suites 160 passing; analyze unchanged. **Lesson recorded: API tests must use the real envelope; the fixtures under `test/fixtures/tileshare_activity` are the inner event objects only.** |
| 2026-09-30 | _TBD_ | **Diagnostic logging for Attention.** A failing source used to say only "Some updates couldn't load", so a failing Invitations call (most likely a 404 because the endpoint lives on backend branch `feature/tileShareActivity`, O14) could not be told from a 401 or a 500. Now: one tagged sink `TileShareLog.d(tag, message)` (`lib/services/tileShare/tileShareLog.dart`, default `Utility.debugPrint`, replaceable in tests, a throwing sink never breaks the caller). `TileShareInvitationsAccessException` / `TileShareActivityAccessException` carry `statusCode` and print it; the plain `StateError`s include `(HTTP <status>)`; both APIs log route + status on any non-2xx (dismissal also the event id) and nothing on success. The cubit logs every failing source with its error, one line per load (`loaded invitations=N activity=N received=N -> N items (failed: ...)`), the answer lifecycle (taken / undone / per-assignment ok or failed / schedule refresh failed) and refused dismissals; the host logs whether the signed-in user id was resolved. Filter the console on `TileShare`. 16 new tests (logger 3, API 6, cubit 7; two earlier cubit logging tests were replaced); gates unchanged (analyze 7 pre-existing errors, full suite 8 pre-existing failures). |
| 2026-09-30 | _TBD_ | **First on-device look (owner's screenshot, dark theme) - three fixes.** The Attention tab loads in the real app. It showed "Some updates couldn't load" **and** "You're all caught up" at once, the banner's Retry was dark red on a dark-red banner, and the cause of the failed source was invisible because the cubit swallowed errors. Now: with a failed source and nothing to show, the screen is a single "Some updates couldn't load" state with Retry (an empty list after a failure is not "all caught up"; it only reads as caught up once every source answered); the banner is only for a failure with items on screen and its Retry uses `onErrorContainer` (tested for contrast in both themes); and every failing source is logged as `TileShareAttention: <source> failed: <error>` so a source that keeps failing - e.g. the Invitations endpoint not being deployed yet (O14) - can be identified from the debug console. Confirmed by the screenshot: the route's app bar title renders correctly on a device, so the block glyphs in the off-device renders were a renderer artefact. |
| 2026-09-30 | _TBD_ | **Step 9.6 implemented (R1).** Inline answers on Attention invitation cards (T3, T8, T20). `respond(itemId, status)` hides the card at once and starts an undo window (5 s, `defaultUndoWindow`, injectable timer); `undoResponse` inside it sends nothing; after it the answers are sent **one after another** and, for an accept that saved at least one, the schedule is refreshed once (`afterAccept`). A refused answer comes back on the list (only the tasks that failed, for a Class), the saved ones stay answered; a failed schedule refresh is reported separately (`AttentionRespondFailureKind.scheduleRefresh`) and does not undo the answer. `flushPending()` and `close()` send a pending answer immediately, and the host closes the cubit **before** disposing the API clients so the send is not cut off. A second tap on a pending invitation is ignored. **T20 is enforced in the cubit, not only in the UI:** only a Broadcast or Class invitation with a known mode can be answered inline; a Class answers every task it holds; a Project (or an unknown mode) only offers Review. Buttons: Accept / Decline (Broadcast), Accept all / Decline all (Class), always with Review; they wrap on narrow screens. Analytics tags `tileshare_accept`, `tileshare_decline`, `tileshare_undo` (the call is injectable). Found while writing the tests: a `SnackBar` with an action does not time out by default, so the Dismiss message added in 9.5 stayed up until swiped - both messages now use `persist: false`. Rendered off-device and reviewed: the Undo message, the failure message, the partial-load banner and the open dismiss menu. **That review found the Undo action illegible** - the framework default is a muted colour that looks disabled, and the brand red is only ~1.2:1 on the light theme's translucent-black snack bar - so the colour is now chosen by contrast (brand colour where it reaches 3:1 on the bar, the theme's own on-inverse colour otherwise) and tested in both themes. Not included: the "Check fit" link on the card (Step 9.11). |
| 2026-09-29 | _TBD_ | **Step 9.5 implemented (R1) — first visible screen.** Attention inbox: chips **All / Invitations / Changes / At risk / Responses** with counts (Responses = declined + completed + delivery problems, so every item type is reachable from a chip other than All), cards (mode icon, cluster title, reason line, meta `mode · N tasks · Due date`, status pill, action, dismiss menu only for dismissible items), an animated list keyed by item id (cards grow/fade in and shrink/fade out; a card arriving above existing ones starts at zero height so nothing jumps; a refresh that changes nothing keeps every card element), skeleton, all-caught-up, filtered-empty, partial-failure banner and total-failure state with Retry, dismiss with Undo. Wired to the backend by `TileShareAttentionTab` (live sources, current user id from `UserApi.getUserProfile()` - assumed equal to the activity `actorId`) and shown as the first, opening tab of the existing Share route only with `--dart-define=TILESHARE_V2=true`. Cards open today's detail screens until 9.12. **Found by rendering off-device with the real fonts (not by tests):** the action label lost the app font (a bare `TextStyle` replaces a button's text style), the selected tab was invisible (default selected-label colour equals the primary app bar) and four tabs wrapped their labels, and an at-risk card repeated the task name because it knew no cluster title. Fixed: label built from the theme; `TabBar` given `onPrimary` label colours and made scrollable when Attention is on; the cubit now caches each cluster's name with its mode and `derive` takes `clusterTitles`. Also fixed a test-caught bug: a `PopupMenuButton` item with a `null` value counts as a cancelled menu, so Dismiss never fired. Not verified on a device; the route's own title row is existing code. |
| 2026-09-29 | _TBD_ | **Step 9.4 implemented (R1).** `TileShareAttentionCubit`: loads Invitations, the activity feed and my received tiles in parallel (paging bounded: 5 x 50 invitations, 3 x 50 events, 2 x 50 received tiles); one source failing keeps the others and is reported in `failedSources`, a failing refresh keeps that source's last-known data; refresh keeps the list on screen (`isRefreshing`, no empty flash); stale fetches are ignored (generation guard) and a closed cubit never emits. `resolve(itemId)`: an activity item is dismissed optimistically and sent to the server per event, and on failure only the events the server refused come back (`dismissFailure`, `acknowledgeFailure`); `undo(itemId)` restores and re-hides on failure; an invitation is hidden locally (the response itself is 9.6); an at-risk item is not dismissible. A dismissal survives a reload and a new session because the server stores it. Added beyond the written step: the cubit resolves and caches each cluster's mode (the Invitations endpoint has none; the T20 buttons need it), retrying failed lookups on the next load. New: `TileShareInvitationsApi`, `setDismissed` and the `PageSize` / `EventType` / `DismissedOnly` filters on `TileShareActivityApi` (moved up from 9.25), the `TileShareAttentionSources` seam with live adapter and fake (`failNextOn(prefix)` fails one specific call), plain constructors on the two page models, a recording HTTP client for API tests. **Dependency:** the Invitations and Dismissal endpoints are committed on the backend branch `feature/tileShareActivity` (pushed to origin) but not on master - until that ships they answer 404 and Attention degrades to the sources that work (O14). |
| 2026-09-29 | _TBD_ | **Step 9.3 implemented (R0).** Data seams the cubits will depend on (T9): `TileShareClustersSource` (clusters by inbox/outbox with paging, one cluster, a cluster's tilettes, delete), `TileShareAssignmentsSource` (my assignments, respond, and the post-accept analyze-then-buzz follow-up) and `TileShareFitSource` (forecast), each with a thin live adapter that delegates 1:1 and lets errors through. Test helpers: fixture builders (`tsCluster`, `tsTilette`, `tsAssignee`, `tsDesignatedTile`, `tsInvitation`, `tsActivity`, `tsForecast`) and in-memory fakes that page and keep state and can `failNext(error)` once or `hold()` / `release()` to expose loading states. Scoped down from the original 9.3 text: the Attention / Invitations / dismissal seams and the share-editing seam are NOT defined yet (no live API for the first two, and no consumer for either) - they arrive with 9.4 / 9.25 / 9.13. The proposed design gallery and a `TILESHARE_V2` flag were not built (owner: proceed as planned). |
| 2026-09-29 | _TBD_ | **Cluster progress removed (T13).** Owner: “we should not ship TileCluster progress functionality”. Removed `TileShareProgress` (`fromUsers`/`fromClass`/`fromTilettes`/`forCluster` with completion, `done`), the owner-side *Behind* Attention item (`CreatedShare`, `behindWindow`, `behindThreshold`) and every cluster/roll-up % from the cards, headers and steps. Replaced by the counts-only `TileShareRsvpSummary` (“3 of 5 accepted”); progress is shown per tilette/assignment only. O17 resolved (the untracked `GET api/TileShareCluster/Progress` is not used); O11 no longer needs a Behind definition. Reading applied: “cluster progress” = any cluster-level or cross-tilette aggregate, not only the untracked endpoint. The removed code/tests are archived outside the repo (scratchpad `archive_cluster_progress_2026-09-29`). |
| 2026-09-29 | _TBD_ | **Progress correction (T13, 9.1).** Owner: there is no way to evaluate progress on a cluster, only on tilettes. Verified in the backend source: completion is stored per assignment (`DesignatedTileTemplate.CompletionPercentage_DB`) and no committed endpoint aggregates it. This exposed a flaw in the 9.1 Class formula (a Class participant has one completion per task, not one overall): added `TileShareProgress.fromClass` (per person across their tasks, duration-weighted, accepted only when accepted on every task) and `forCluster(mode, tilettes)`; `ClassFanout.contactOfUser` made public for identity matching. List cards derive progress lazily from the tilettes; recipients see only their own progress. Recorded O17 (untracked backend `GET api/TileShareCluster/Progress` — flat mean) and extended O7 (untracked server-side accept preview). |
| 2026-09-29 | _TBD_ | **Step 9.2 implemented (R0).** Activity model v2 (new types `cluster_invitation` / `assignment_completed` / `assignment_reopened`; `actorId`, `targetUserId`, `assignmentId`, `tiletteTitle`, `calendarEventId`, `changedFields` + old/new deadline - allow-listed to name/deadline/note, range-checked, schema-version-gated; `title` now read only for the four title-carrying types, as the server sends it). Found in the feed source: the server also projects `tiletteTitle`, so completed events can name the task. New pure pieces: `TileShareInvitation(Page)`, `AttentionItems.derive` (seven item types, one per cluster+type, own actions excluded except delivery problems, dismissed excluded, urgency order, `behindWindow` 2 days / `behindThreshold` 50 %), `ActivityRows.group` (60 s neighbour-chain grouping), `ActivitySentence.of` (kind + actor/subject/task/channel; localized wording stays in 9.28). The backend's 15 canonical fixtures now live in `test/fixtures/tileshare_activity/` (BOM stripped) and `tile_share_activity_test.dart` reads them from there. Deliberately dropped from the Attention tests: the old `isTilable == false` rule - the Invitations endpoint already returns only pending, non-deleted invitations and does not expose it. |
| 2026-09-29 | _TBD_ | **Step 9.1 implemented (R0).** New pure `TileShareMode` (parse/wire/resolve, never guesses Class), `TileShareProgress` (T13 per-mode formulas), `ClassFanout` (missing pairs + participants union); `Mode` parsed from the response (`mode`/`Mode`) and added to `TileShareClusterModel` (sent only when explicit). Also fixed a latent crash: `DesignatedTile.stringToInvitationStatus` threw on any status other than accepted/declined/none (the server also sends `tentative`); it now maps `tentative` to pending and unknown to null. 36 new tests. Lesson: `build_runner --build-filter` still deleted 8 tracked `.g.dart` files (restored from git) - regenerate other generated files by hand or run the generator per package without `--delete-conflicting-outputs`. |
| 2026-09-29 | _TBD_ | **Rev 2.4.** Owner answers: clear-on-pause is unrelated to this redesign (O13 out of scope, behaviour untouched); **Accept all only in Class**, never in Project (T20; O8 resolved; Attention/detail/steps updated to match); desktop UI parity is out of scope (O16 and the desktop references removed). |
| 2026-09-29 | _TBD_ | **Rev 2.3 — Activity.** Owner pointed out Activity had not been designed. The backend source (branch `feature/tileShareActivity`) was read: the server already emits invitations (`cluster_invitation`, `GET api/TileShare/Invitations`), completions (`assignment_completed` / `_reopened` + `calendarEventId`), what-changed (`changedFields`, old/new deadline), `targetUserId`, per-event dismissal and a server `EventType` filter — none of which the client reads. This corrects the earlier gap analysis (which claimed no completion event and no what-changed). Added T15–T19, §5.11, phase RA (9.25–9.29), extended 9.2 / 9.4 (server dismissal replaces on-device seen-state), concerns O13–O16, and the *Partially accepted* pill. |
| 2026-09-29 | _TBD_ | **Rev 2.2.** Backend detail confirmed: the request key is `Mode` (capitalized). For Class, the client adds each participant to every task for now (O9 resolved): Step 9.1 gains the pure `ClassFanout.missing` planner; Steps 9.14 / 9.19 carry the fan-out rules (per-cluster serialization, idempotence, incomplete-with-Retry, reconcile on load). |
| 2026-09-29 | _TBD_ | **Rev 2.1.** Owner confirmed create flow **B** (T14 locked, O12 resolved) and that the backend has a cluster `mode` field (`broadcast` / `class` / `project`): O9 reduced to two residual questions (key/casing + back-fill; Class recipient semantics). Class steps 9.14 and 9.19 unblocked; Step 9.1 now also parses and sends `mode`. |
| 2026-09-29 | _TBD_ | **Rev 2.** Five design mocks reviewed (§3). Owner decisions recorded: three sharing modes — Broadcast (own instance of a task), Project (one shared project), Class (own instance of a project) (T2); hub = Attention + Clusters with a Shared-with-me / Created-by-me filter (T6); deferred to a later release: claim, plan, icon, category, decline reasons, Person view (T12). Added: Attention derivation (T7), Check-fit screen as See-impact v1 (T4), per-mode progress formula (T13), mode-first create (T14, assumed). Phases re-planned R0–R7 (24 steps). New blocking concern O9 (explicit `mode` / Class representation). |
| 2026-09-29 | _TBD_ | Rev 1: design drafted from a read of the current implementation (§2); decisions T1–T5 (pushed route; distinct kinds; accept/decline from the list; See impact with a redirect; Notes/Address/Pattern ship). |
