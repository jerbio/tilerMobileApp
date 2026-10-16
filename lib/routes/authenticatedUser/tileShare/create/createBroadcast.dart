import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createShareForm.dart';

export 'createShareForm.dart'
    show
        CreatePickDuration,
        OnShareCreated,
        defaultBroadcastLength,
        defaultShareDeadline;

/// Broadcast creation: one tilette, its deadline and its people.
class CreateBroadcastScreen extends CreateShareForm {
  const CreateBroadcastScreen({
    super.key,
    required super.source,
    required super.onCreated,
    super.now,
    super.pickDuration,
    super.pickDate,
    super.pickTime,
  }) : super(mode: TileShareMode.broadcast);
}
