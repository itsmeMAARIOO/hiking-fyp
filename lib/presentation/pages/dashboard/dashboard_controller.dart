import 'package:geolocator/geolocator.dart';
import '../../../services/checkin_service.dart';

class DashboardController {
  final CheckInService checkInService;

  DashboardController(this.checkInService);

  Future<void> performCheckIn({
    required String? userId,
    required DateTime lastCheckIn,
  }) async {
    try {
      // Get current GPS position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await checkInService.saveCheckIn(
        userId: userId,
        checkinTime: DateTime.now(),
        lastCheckinTime: lastCheckIn,
        latitude: position.latitude,
        longitude: position.longitude,
        extraData: {'note': 'Triple-tap check-in'},
      );
    } catch (e) {
      rethrow;
    }
  }
}
