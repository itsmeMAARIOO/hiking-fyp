import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hikingapp/config/api_config.dart';

class SavedTrailService {
  static final String baseUrl = "${ApiConfig.baseUrl}/saved-trails";
  static final Map<String, List<Map<String, dynamic>>> _memoryStore = {};

  Future<void> saveTrail(String userId, Map<String, dynamic> trail) async {
    if (userId.isEmpty || (trail['placeId'] == null)) {
      throw Exception('Invalid trail payload');
    }
    try {
      final url = Uri.parse(baseUrl);
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'trail': trail}),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    } catch (_) {}
    final list = _memoryStore.putIfAbsent(userId, () => <Map<String, dynamic>>[]);
    final exists = list.any((t) => t['placeId'] == trail['placeId']);
    if (!exists) list.add(trail);
  }

  Future<List<Map<String, dynamic>>> fetchSavedTrails(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/$userId');
      final resp = await http.get(url);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final list = (data['trails'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_memoryStore[userId] ?? const []);
  }

  Future<void> deleteSavedTrail(String userId, String placeId) async {
    try {
      final url = Uri.parse('$baseUrl/$userId/$placeId');
      final resp = await http.delete(url);
      if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    } catch (_) {}
    final list = _memoryStore[userId];
    if (list != null) {
      list.removeWhere((t) => (t['placeId'] ?? '').toString() == placeId);
    }
  }
}