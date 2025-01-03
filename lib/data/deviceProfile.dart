import 'package:tiler_app/data/deviceLocationProfile.dart';
import 'package:tiler_app/data/userProfile.dart';

class DeviceProfile {
  UserProfile? userProfile;
  DeviceLocationProfile? locationProfile;

  Map<String, dynamic> toJson() => {
        'userProfile': userProfile?.toJson(),
        // 'locationProfile':
      };
}
