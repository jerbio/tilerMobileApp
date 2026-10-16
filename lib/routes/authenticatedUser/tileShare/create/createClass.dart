import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createShareForm.dart';

/// Class creation shares the details, people and send lifecycle with Broadcast.
/// Tilettes are staged locally before the people step and sent in one request.
class CreateClassScreen extends CreateShareForm {
  const CreateClassScreen({
    super.key,
    required super.source,
    required super.onCreated,
    super.now,
    super.pickDuration,
    super.pickDate,
    super.pickTime,
  }) : super(mode: TileShareMode.class_);
}
