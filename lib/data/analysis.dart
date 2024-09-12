import 'package:tiler_app/data/overview_item.dart';
import 'package:tiler_app/data/timeline.dart';

import 'driveTime.dart';

class Analysis {
  List<Timeline>? sleep;
  List<OverViewItem>? overview;
  List<DriveTime>? drivesTime;

  Analysis({this.sleep, this.overview, this.drivesTime});
}
