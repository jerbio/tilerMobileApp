import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createShareForm.dart';

/// Project creation: the share's name, deadline and tilettes on one screen,
/// sent with no one on them; the owner assigns them later on the board, or
/// never (owner, 9.20).
class CreateProjectScreen extends CreateShareForm {
  const CreateProjectScreen({
    super.key,
    required super.source,
    required super.onCreated,
    super.now,
    super.pickDuration,
    super.pickDate,
    super.pickTime,
    super.editNotes,
  }) : super(mode: TileShareMode.project);
}
