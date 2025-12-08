import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hikingapp/config/api_config.dart';
import '../data/models/first_aid_guide.dart';

class FirstAidService {
  static final String _base = "${ApiConfig.baseUrl}/first-aid";

  Future<List<FirstAidGuide>> fetchGuides(String userId) async {
    try {
      final url = Uri.parse('$_base/$userId');
      final resp = await http.get(url);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final list = (data['notes'] as List?) ?? [];
        return list
            .map((e) => FirstAidGuide.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<FirstAidGuide> addNote({
    required String userId,
    required String title,
    required String content,
  }) async {
    final url = Uri.parse(_base);
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'content': content,
      }),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);
      final note = Map<String, dynamic>.from(data['note'] ?? {});
      return FirstAidGuide.fromJson(note);
    }
    throw Exception('Failed to save note');
  }

  Future<void> deleteGuide({
    required String userId,
    required String id,
  }) async {
    final url = Uri.parse('$_base/$userId/$id');
    await http.delete(url);
  }

  Future<void> updateNote({
    required String userId,
    required String id,
    required String title,
    required String content,
  }) async {
    final url = Uri.parse('$_base/$id');
    await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content}),
    );
  }

  Future<List<Map<String, dynamic>>> fetchStandardGuides() async {
    try {
      final url = Uri.parse('$_base/guides');
      final resp = await http.get(url);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['guides'] as List?) ?? [];
        return list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
