import 'package:tiler_app/components/vibeChat/MessageList.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/data/VibeChat/ChatSessionExecutionMode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';

void main() {
  test('plan action hydration retains grouped targets', () {
    final action = VibeAction.fromJson({
      'id': 'plan',
      'type': 'TileShare_Update_Plan',
      'tileShareResult': {
        'State': 'NotAttempted',
        'Operation': 'UpdatePlan',
        'Review': {
          'Items': [
            {'ProjectId': 'p'},
            {'ProjectId': 'p', 'TiletteId': 't'}
          ]
        }
      }
    });
    expect(action.type, ActionType.tileShareUpdatePlan);
    expect((action.tileShareResult!['Review']['Items'] as List).length, 2);
  });
  test('composite update hydration preserves field presence and exact review',
      () {
    final review = {
      'State': 'NotAttempted',
      'ReviewToken': 'combined',
      'Review': {
        'Operation': 'UpdateTilette',
        'UpdatesName': true,
        'UpdatesNotes': false,
        'Name': 'Renamed'
      }
    };
    final action = VibeAction.fromJson({
      'id': 'a',
      'type': 'TileShare_Update_Tilette',
      'tileShareResult': review
    });
    expect(action.type, ActionType.tileShareUpdateTilette);
    expect(action.copyWith().tileShareResult, review);
    expect(action.toJson()['tileShareResult'], review);
  });
  test(
      'project links resolve to the configured web host without double encoding',
      () {
    final url = resolveVibeChatLink('/tileshare/TileShareCluster%2Bid');
    expect(url.toString(),
        'https://${Constants.tilerDomain}/tileshare/TileShareCluster%2Bid');
    expect(resolveVibeChatLink('https://example.test/page').toString(),
        'https://example.test/page');
  });
  test('project detail links preserve both encoded IDs', () {
    final url =
        resolveVibeChatLink('/tileshare/Cluster%2Bid/tilette/Template%2Bid');
    expect(url.toString(),
        'https://${Constants.tilerDomain}/tileshare/Cluster%2Bid/tilette/Template%2Bid');
  });
  test('project details are recognized as an informational action', () {
    final action = VibeAction.fromJson({
      'id': 'details',
      'type': 'tileshare_get_project',
      'status': 'executed'
    });
    expect(action.type, ActionType.tileShareGetProject);
    expect(action.tileShareResult, isNull);
  });
  test('project discovery is recognized as an informational action', () {
    final action = VibeAction.fromJson({
      'id': 'search',
      'type': 'tileshare_search_projects',
      'status': 'executed'
    });
    expect(action.type, ActionType.tileShareSearchProjects);
    expect(action.status, ActionStatus.executed);
    expect(action.tileShareResult, isNull);
  });
  test(
      'confirmation is the default and unrelated state changes retain the chosen mode',
      () {
    const state = VibeChatState();
    expect(
        state.chatSessionExecutionMode, ChatSessionExecutionMode.confirmFirst);
    final automatic = state.copyWith(
        chatSessionExecutionMode: ChatSessionExecutionMode.autoAct);
    expect(
        automatic.copyWith(step: VibeChatStep.sending).chatSessionExecutionMode,
        ChatSessionExecutionMode.autoAct);
    expect(automatic, isNot(state));
  });
  test('action hydration and copying retain the exact server review', () {
    final review = {
      'State': 'NotAttempted',
      'ActionId': 'a',
      'ReviewToken': 'exact',
      'Review': {'Name': 'Launch', 'Tilettes': []}
    };
    final action = VibeAction.fromJson({
      'id': 'a',
      'type': 'TileShare_Create_Project',
      'tileShareResult': review
    });
    expect(action.copyWith().tileShareResult, review);
    expect(action.toJson()['tileShareResult'], review);
  });
}
