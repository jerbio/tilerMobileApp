import 'package:flutter/material.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareWorkWidgets.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/personAvatar.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/statusPill.dart';

class TiletteDetailPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const TiletteDetailPanel(
      {super.key, required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (action != null) action!,
            ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class TiletteDetailHero extends StatelessWidget {
  final DesignatedTile tile;
  final TileShareTemplate? template;
  final TileShareMode? mode;
  final InvitationStatus? response;
  const TiletteDetailHero(
      {super.key, required this.tile, this.template, this.mode, this.response});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = (tile.name ?? template?.name ?? '').trim();
    final modeName = TileShareModeBadge.labelOf(l, mode);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          [l.shareTilette, if (modeName != null) modeName]
              .join(' · ')
              .toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1.4)),
      const SizedBox(height: 12),
      Text(name.isEmpty ? l.clusterTitleFallback : name,
          key: const Key('tilette_detail_title'),
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ShareWorkMeta(
                durationMs: template?.durationInMs,
                dueMs: tile.endInMs ?? template?.end),
            if (response != null)
              TileShareStatusPill(
                  label: switch (response!) {
                    InvitationStatus.accepted => l.accepted,
                    InvitationStatus.declined => l.declined,
                    InvitationStatus.none => l.shareAwaitingResponse
                  },
                  tone: switch (response!) {
                    InvitationStatus.accepted => StatusPillTone.success,
                    InvitationStatus.declined => StatusPillTone.danger,
                    InvitationStatus.none => StatusPillTone.warning
                  }),
          ]),
    ]);
  }
}

class TilettePeoplePanel extends StatelessWidget {
  final TileShareTemplate? template;
  final String? assignmentId;
  final bool personal;
  final InvitationStatus? response;
  final List<RosterRow>? ownerRows;
  final Widget? action;
  final Widget? feedback;
  const TilettePeoplePanel(
      {super.key,
      this.template,
      this.assignmentId,
      this.personal = false,
      this.response,
      this.ownerRows,
      this.action,
      this.feedback});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final embedded = template?.designatedUsers
            ?.where(
                (p) => !personal || p.designatedTileTemplateId == assignmentId)
            .toList() ??
        [];
    final people = ownerRows == null
        ? [
            for (final person in embedded)
              (
                (person.userProfile?.fullName ??
                        person.displayedName ??
                        person.userProfile?.username ??
                        person.userProfile?.email ??
                        l.shareAssignedToYou)
                    .trim(),
                personal ? response : person.rsvpStatus,
                person.completionPercentage
              )
          ]
        : [
            for (final row in ownerRows!)
              for (final cell in row.cells)
                if (cell.tiletteId == template?.id && cell.isPresent)
                  (row.label, cell.rsvp, cell.completion)
          ];
    return TiletteDetailPanel(
        title: l.shareAssignedTo,
        action: action,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (people.isEmpty)
            Text(personal && ownerRows == null
                ? l.shareAssignedToYou
                : l.projectUnassigned),
          for (final person in people)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PersonAvatar(label: person.$1, radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(person.$1, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 6),
                            ShareWorkStatus(
                                response: person.$2, completion: person.$3),
                          ])),
                    ])),
          if (feedback != null) feedback!,
        ]));
  }
}

class TiletteOverviewContent extends StatelessWidget {
  final DesignatedTile tile;
  final TileShareTemplate? template;
  final InvitationStatus? response;
  final bool personal;
  final List<RosterRow>? ownerRows;
  final Widget? peopleAction;
  final Widget? peopleFeedback;
  final VoidCallback onNotes;
  final VoidCallback onComments;
  const TiletteOverviewContent(
      {super.key,
      required this.tile,
      this.template,
      this.response,
      this.personal = false,
      this.ownerRows,
      this.peopleAction,
      this.peopleFeedback,
      required this.onNotes,
      required this.onComments});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final completion = shareCompletion(tile.completionPercentage);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TilettePeoplePanel(
          template: template,
          assignmentId: tile.id,
          personal: personal,
          ownerRows: ownerRows,
          action: peopleAction,
          feedback: peopleFeedback,
          response: response),
      if (response == InvitationStatus.accepted && completion != null)
        TiletteDetailPanel(
            title: l.progress,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShareWorkStatus(response: response, completion: completion),
                  const SizedBox(height: 12),
                  ShareCompletionBar(
                      value: completion / 100, label: '${completion.round()}%'),
                ])),
      OutlinedButton.icon(
          key: const Key('tilette_read_notes'),
          onPressed: onNotes,
          icon: const Icon(Icons.description_outlined),
          label: Text(l.shareReadNotes)),
      OutlinedButton.icon(
          onPressed: onComments,
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(l.shareOpenDiscussion)),
    ]);
  }
}
