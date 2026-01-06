import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hikingapp/config/api_config.dart';

class CheckInService {
  final baseUrl = ApiConfig.baseUrl;

  late final url = "$baseUrl/checkin";

  Future<void> saveCheckIn({
    required String? userId,
    required DateTime checkinTime,
    required DateTime? lastCheckinTime,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? extraData,
  }) async {
    if (userId == null) throw Exception('User ID cannot be null');

    final body = {
      'userId': userId,
      'checkinTime': checkinTime.toIso8601String(),
      'lastCheckinTime': lastCheckinTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'extraData': extraData ?? {},
    };

    print('Sending check-in to $url');
    print(body);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save check-in: ${response.body}');
    }
  }

  Future<DateTime?> fetchLastCheckIn(String userId) async {
    // Do NOT prepend http:// if baseUrl already includes protocol
    final response = await http.get(Uri.parse('$baseUrl/checkin/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final lastCheckinData = data['checkinTime'];

      if (lastCheckinData == null) return null;

      if (lastCheckinData is String) {
        return DateTime.parse(lastCheckinData);
      } else if (lastCheckinData is Map<String, dynamic>) {
        final millis = int.parse(lastCheckinData['\$date']['\$numberLong']);
        return DateTime.fromMillisecondsSinceEpoch(millis);
      } else {
        throw Exception('Unexpected checkinTime format: $lastCheckinData');
      }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch check-in: ${response.body}');
    }
  }
}
