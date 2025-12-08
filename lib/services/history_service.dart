import 'dart:convert';
import 'package:hikingapp/config/api_config.dart';
import 'package:http/http.dart' as http;

class HistoryService {
  static String get base => ApiConfig.baseUrl;

  static Future<List<Map<String, dynamic>>> fetchGroupHistory(
    String userId,
  ) async {
    final resp = await http
        .get(Uri.parse('$base/group/history/$userId'))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (data['groups'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Failed to fetch group history: ${resp.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchSoloHistory(
    String userId,
  ) async {
    final resp = await http
        .get(Uri.parse('$base/solo/history/$userId'))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (data['trails'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Failed to fetch solo history: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchGroupDetails(String groupId) async {
    final resp = await http
        .get(Uri.parse('$base/group/group/$groupId'))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(data['group'] ?? {});
    }
    throw Exception('Failed to fetch group details: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchSoloTrail(String trailId) async {
    final resp = await http
        .get(Uri.parse('$base/solo/trail/$trailId'))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(data['trail'] ?? {});
    }
    throw Exception('Failed to fetch solo trail: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchGroupPathReplay(
    String groupId,
  ) async {
    final resp = await http
        .get(Uri.parse('$base/group/path/$groupId'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data;
    }
    throw Exception('Failed to fetch path replay: ${resp.statusCode}');
  }

  static Future<void> deleteGroupHistory(String groupId) async {
    final resp = await http
        .delete(Uri.parse('$base/group/history/$groupId'))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete group history: ${resp.statusCode}');
    }
  }

  static Future<void> deleteSoloHistory(String trailId) async {
    final resp = await http
        .delete(Uri.parse('$base/solo/history/$trailId'))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete solo history: ${resp.statusCode}');
    }
  }
}
