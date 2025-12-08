import 'dart:convert';

class FirstAidGuide {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  const FirstAidGuide({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static FirstAidGuide fromJson(Map<String, dynamic> json) {
    return FirstAidGuide(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  static String encodeList(List<FirstAidGuide> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<FirstAidGuide> decodeList(String raw) {
    final data = jsonDecode(raw);
    if (data is List) {
      return data
          .map((e) => FirstAidGuide.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}