import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hikingapp/config/api_config.dart';

class ChatService {
  IO.Socket? _socket;

  String get _base => ApiConfig.baseUrl;

  String get _origin {
    // strip trailing /api for socket origin
    return _base.endsWith('/api')
        ? _base.substring(0, _base.length - 4)
        : _base;
  }

  Future<List<dynamic>> fetchMessages(String groupId) async {
    final url = Uri.parse('$_base/chat/$groupId/messages');
    final resp = await http.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to fetch messages: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> sendText({
    required String groupId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    final url = Uri.parse('$_base/chat/$groupId/text');
    final resp = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'userId': userId,
            'userName': userName,
            'text': text,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to send text: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> uploadImage({
    required String groupId,
    required String userId,
    required String userName,
    required File imageFile,
  }) async {
    final url = Uri.parse('$_base/chat/$groupId/images');
    final req = http.MultipartRequest('POST', url);
    req.fields['userId'] = userId;
    req.fields['userName'] = userName;
    req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await req.send().timeout(const Duration(seconds: 20));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to upload image: ${resp.statusCode}');
  }

  void connectSocket({
    required String groupId,
    required void Function(Map<String, dynamic> payload) onNewMessage,
    void Function(String id)? onDeleteMessage,
    void Function(Map<String, dynamic> payload)? onMessageSeen,
  }) {
    disconnect();
    final origin = _origin;
    _socket = IO.io(
      origin,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );
    _socket!.onConnect((_) {
      _socket!.emit('join', {'groupId': groupId});
    });

    _socket!.on('chat:new', (data) {
      try {
        if (data is Map<String, dynamic>) {
          onNewMessage(data);
        } else if (data is Map) {
          onNewMessage(Map<String, dynamic>.from(data));
        }
      } catch (_) {}
    });

    _socket!.on('chat:delete', (data) {
      try {
        final id = (data is Map && data['_id'] != null)
            ? data['_id'].toString()
            : data?.toString();
        if (id != null && onDeleteMessage != null) {
          onDeleteMessage(id);
        }
      } catch (_) {}
    });

    if (onMessageSeen != null) {
      _socket!.on('chat:seen', (data) {
        try {
          if (data is Map<String, dynamic>) {
            onMessageSeen(data);
          } else if (data is Map) {
            onMessageSeen(Map<String, dynamic>.from(data));
          }
        } catch (_) {}
      });
    }
    _socket!.connect();
  }

  void emitSeen(String groupId, String messageId, String userId) {
    if (_socket != null) {
      _socket!.emit('chat:seen', {
        'groupId': groupId,
        'messageId': messageId,
        'userId': userId,
      });
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
    required String userId,
  }) async {
    final url = Uri.parse('$_base/chat/$groupId/messages/$messageId');
    final resp = await http
        .delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      return;
    }
    throw Exception('Failed to delete message: ${resp.statusCode}');
  }
}
