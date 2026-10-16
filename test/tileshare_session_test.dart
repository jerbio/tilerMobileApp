import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/sessionProfile.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/services/tileShare/tileShareSession.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _Settings extends Mock implements DeviceSettingBloc {
  @override
  final SessionProfile sessionProfile = SessionProfile();
  @override
  Stream<DeviceSettingState> get stream => const Stream.empty();
  @override
  DeviceSettingState get state =>
      DeviceSettingLoaded(sessionProfile: sessionProfile, isDarkMode: false);
}

void main() {
  testWidgets('cached session identity determines ownership and my assignments',
      (tester) async {
    final settings = _Settings();
    settings.sessionProfile.userProfile = UserProfile()..id = 'me';
    String? id;
    await tester.pumpWidget(BlocProvider<DeviceSettingBloc>.value(
      value: settings,
      child: Builder(builder: (context) {
        id = tileShareSessionUserId(context);
        return const SizedBox();
      }),
    ));
    final cubit = TileShareDetailCubit(
      clusters: FakeTileShareClustersSource(outbox: [
        tsCluster('owned', creatorId: 'me'),
      ]),
      assignments: FakeTileShareAssignmentsSource([
        tsDesignatedTile('mine', clusterId: 'owned', ownerId: 'me'),
        tsDesignatedTile('someone-else', clusterId: 'owned', ownerId: 'other'),
      ]),
      target: const TileShareDetailTarget.cluster('owned'),
      currentUserId: () => id,
      ownerHint: false,
    );
    await cubit.load();
    expect(cubit.state.phase, DetailPhase.ready);
    expect(cubit.state.isOwner, isTrue);
    expect(cubit.state.mine.map((t) => t.id), ['mine']);
    await cubit.close();
  });

  testWidgets('missing session does not block a share load', (tester) async {
    String? id = 'unset';
    await tester.pumpWidget(Builder(builder: (context) {
      id = tileShareSessionUserId(context);
      return const SizedBox();
    }));
    expect(id, isNull);
    final cubit = TileShareDetailCubit(
      clusters: FakeTileShareClustersSource(inbox: [tsCluster('shared')]),
      target: const TileShareDetailTarget.cluster('shared'),
      currentUserId: () => id,
      ownerHint: false,
    );
    await cubit.load();
    expect(cubit.state.phase, DetailPhase.ready);
    expect(cubit.state.isOwner, isFalse);
    await cubit.close();
  });

  testWidgets('session replacement does not reuse a previous account id',
      (tester) async {
    final settings = _Settings();
    String? id;
    Future<void> read() => tester.pumpWidget(
          BlocProvider<DeviceSettingBloc>.value(
            value: settings,
            child: Builder(builder: (context) {
              id = tileShareSessionUserId(context);
              return const SizedBox();
            }),
          ),
        );
    settings.sessionProfile.userProfile = UserProfile()..id = 'first';
    await read();
    expect(id, 'first');
    settings.sessionProfile.userProfile = null;
    await read();
    expect(id, isNull);
    settings.sessionProfile.userProfile = UserProfile()..id = 'second';
    await read();
    expect(id, 'second');
  });
}
