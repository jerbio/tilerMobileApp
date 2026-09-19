// Where a search result's Edit goes (2026-09-19).
//
// The search API returns two different kinds of row under one shape: a
// Tiler row's `id` is a CALENDAR EVENT (the series), while a Google or
// Microsoft row's `thirdPartyEventId` is a SUB-EVENT (one occurrence). The
// redesigned screens are keyed the same way — Tile details loads a calendar
// event, Edit Tile loads a sub-event — so a Tiler row must open Tile details
// and a provider row Edit Tile. Sending a Tiler row to Edit Tile asked the
// sub-event endpoint for a series id and failed to load.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tileUI/searchResultDestination.dart';
import 'package:tiler_app/data/calendarSearch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailSubmission.dart';

CalendarSearchItem item({
  required String source,
  String id = 'cal-1',
  String? thirdPartyEventId,
  String? thirdPartyUserId,
}) =>
    CalendarSearchItem(
      id: id,
      name: 'Dentist',
      start: 0,
      end: 1,
      source: source,
      sourceKind: parseCalendarSearchSource(source),
      isReadOnly: false,
      capabilities: const CalendarSearchCapabilities(),
      thirdPartyEventId: thirdPartyEventId,
      thirdPartyUserId: thirdPartyUserId,
    );

void main() {
  test('a Tiler row opens Tile details on its calendar event', () {
    final Widget? w = searchResultEditorFor(item(source: 'tiler', id: 'cal-9'));
    expect(w, isA<TileDetailRoute>());
    final TileDetailRoute route = w as TileDetailRoute;
    expect(route.target, TileDetailTarget.calendarEvent('cal-9'));
    expect(route.loadSubEvents, isTrue);
  });

  test('a Google row opens Edit Tile on its provider sub-event', () {
    final Widget? w = searchResultEditorFor(item(
        source: 'google',
        id: 'ignored',
        thirdPartyEventId: 'g-sub-1',
        thirdPartyUserId: 'gcal-user'));
    expect(w, isA<EditTileRoute>());
    final EditTileRoute route = w as EditTileRoute;
    expect(route.tileId, 'g-sub-1');
    expect(route.tileSource, TileSource.google);
    expect(route.thirdPartyUserId, 'gcal-user');
  });

  test('a Microsoft row maps to the outlook source', () {
    final EditTileRoute route = searchResultEditorFor(item(
        source: 'microsoft',
        thirdPartyEventId: 'ms-sub-1',
        thirdPartyUserId: 'ms-user')) as EditTileRoute;
    expect(route.tileId, 'ms-sub-1');
    expect(route.tileSource, TileSource.outlook);
  });

  test('a row without a usable id opens nothing', () {
    expect(searchResultEditorFor(item(source: 'tiler', id: '')), isNull);
    expect(
        searchResultEditorFor(item(source: 'google', thirdPartyEventId: null)),
        isNull);
    expect(searchResultEditorFor(item(source: 'google', thirdPartyEventId: '')),
        isNull);
  });
}
