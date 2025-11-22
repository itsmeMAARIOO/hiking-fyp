import 'package:flutter/material.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:hikingapp/services/chat_service.dart';
// import 'package:hikingapp/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/trail_provider.dart';

import '../../../../../styles/colors.dart';

class ChatTab extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;
  final String currentUserName;

  const ChatTab({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _SenderAvatar extends StatelessWidget {
  final String? url;
  final String name;
  const _SenderAvatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final hasNetworkAvatar =
        url != null && url!.isNotEmpty && url!.startsWith('http');
    final String initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: hasNetworkAvatar ? null : kSoftMint,
      backgroundImage: hasNetworkAvatar ? NetworkImage(url!) : null,
      child: hasNetworkAvatar
          ? null
          : Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kDeepTeal,
              ),
            ),
    );
  }
}

class _ChatTabState extends State<ChatTab> {
  final ChatService _chat = ChatService();
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _chat.connectSocket(
      groupId: widget.groupId,
      onNewMessage: (payload) {
        final isImage = (payload['imageUrl'] ?? '').toString().isNotEmpty;
        if (isImage) return; // do not show images in chat
        if (!_messages.any((m) => m['_id'] == payload['_id'])) {
          setState(() => _messages.add(payload));
          _deferredScrollToBottom();
        }
      },
    );
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final msgs = await _chat.fetchMessages(widget.groupId);
      final textOnly = msgs.where(
        (m) => ((m['imageUrl'] ?? '').toString().isEmpty),
      );
      setState(
        () =>
            _messages.addAll(textOnly.map((e) => Map<String, dynamic>.from(e))),
      );
      _deferredScrollToBottom();
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _chat.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    try {
      await _chat.sendText(
        groupId: widget.groupId,
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        text: text,
      );
      setState(() {
        _textController.clear();
      });
      _deferredScrollToBottom();
    } catch (_) {}
  }

  void _deferredScrollToBottom() {
    // Ensure scrolling occurs after the next frame so ListView has updated
    void performScroll() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final target = pos.maxScrollExtent;

      if (!pos.hasPixels || !pos.haveDimensions) {
        // If dimensions not ready, retry shortly
        Future.delayed(const Duration(milliseconds: 50), performScroll);
        return;
      }

      final distance = target - pos.pixels;
      if (distance <= 0) return; // already at bottom

      // Use jump for large distances, animate for smaller ones
      if (distance < 300) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      performScroll();
      // Re-check once more after a short delay in case list grows further
      Future.delayed(const Duration(milliseconds: 100), performScroll);
    });
  }

  String? _avatarUrlFor(Map<String, dynamic> msg) {
    String? avatarUrl;
    // Try direct fields
    final dynamic pi = msg['profileImage'];
    if (pi is String && pi.isNotEmpty) {
      avatarUrl = pi;
    } else {
      // Try nested user objects on the message
      final dynamic userIdObj = msg['userId'];
      if (userIdObj is Map<String, dynamic>) {
        final dynamic upi = userIdObj['profileImage'];
        if (upi is String && upi.isNotEmpty) avatarUrl = upi;
      }
      final dynamic userObj = msg['user'];
      if (avatarUrl == null && userObj is Map<String, dynamic>) {
        final dynamic upi2 = userObj['profileImage'];
        if (upi2 is String && upi2.isNotEmpty) avatarUrl = upi2;
      }
    }

    // Fallback: look up from GroupProvider by userId
    if (avatarUrl == null) {
      final String uid = (msg['userId']?.toString() ?? '').toString();
      try {
        final gp = Provider.of<GroupProvider>(context, listen: false);
        // nearbyMembers typed
        final m1 = gp.nearbyMembers.firstWhere(
          (m) => m.userId == uid,
          orElse: () => GroupMember(
            userId: '',
            name: '',
            latitude: 0,
            longitude: 0,
            role: '',
            status: '',
            lastUpdated: DateTime.now(),
          ),
        );
        if (m1.userId.isNotEmpty &&
            m1.profileImage != null &&
            m1.profileImage!.isNotEmpty) {
          avatarUrl = m1.profileImage;
        }

        // activeGroup may have populated members
        if (avatarUrl == null && gp.activeGroup != null) {
          final dynamic members = gp.activeGroup!['members'];
          if (members is List) {
            for (final m in members) {
              try {
                if (m is Map<String, dynamic>) {
                  String? mid;
                  String? mAvatar;
                  final dynamic mUserId = m['userId'];
                  if (mUserId is String) {
                    mid = mUserId;
                  } else if (mUserId is Map<String, dynamic>) {
                    final dynamic idObj = mUserId['_id'] ?? mUserId['id'];
                    if (idObj is String) mid = idObj;
                    if (idObj is Object) mid = idObj.toString();
                    final dynamic upi = mUserId['profileImage'];
                    if (upi is String && upi.isNotEmpty) mAvatar = upi;
                  }
                  // Also check direct profileImage
                  final dynamic directPi = m['profileImage'];
                  if (mAvatar == null &&
                      directPi is String &&
                      directPi.isNotEmpty) {
                    mAvatar = directPi;
                  }
                  if (mid == uid && mAvatar != null && mAvatar.isNotEmpty) {
                    avatarUrl = mAvatar;
                    break;
                  }
                }
              } catch (_) {}
            }
          }
        }
      } catch (_) {
        // Provider not available; ignore
      }
    }
    return avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMine =
                          (msg['userId']?.toString() ?? '') ==
                          widget.currentUserId;
                      final currentUid = (msg['userId']?.toString() ?? '');
                      final prevUid = i > 0
                          ? (_messages[i - 1]['userId']?.toString() ?? '')
                          : '';
                      final nextUid = i < _messages.length - 1
                          ? (_messages[i + 1]['userId']?.toString() ?? '')
                          : '';
                      final isGroupStart = i == 0 || prevUid != currentUid;
                      final isGroupEnd =
                          i == _messages.length - 1 || nextUid != currentUid;
                      final avatarUrl = _avatarUrlFor(msg);
                      final userName = (msg['userName'] ?? 'Unknown')
                          .toString();
                      return Padding(
                        padding: EdgeInsets.only(
                          top: isGroupStart ? 10 : 2,
                          bottom: isGroupEnd ? 10 : 2,
                        ),
                        child: Row(
                          mainAxisAlignment: isMine
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMine && isGroupEnd) ...[
                              _SenderAvatar(url: avatarUrl, name: userName),
                              const SizedBox(width: 8),
                            ] else if (!isMine && !isGroupEnd) ...[
                              const SizedBox(
                                width: 40,
                              ), // indent to align with avatar space
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMine && isGroupStart)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 2,
                                        bottom: 4,
                                      ),
                                      child: Text(
                                        userName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  _ChatBubble(msg: msg, isMine: isMine),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Input bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendText,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final bool isMine;
  const _ChatBubble({required this.msg, required this.isMine});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _showTime = false;

  String _formatMyt(dynamic raw) {
    String created = '';
    try {
      DateTime? utc;
      if (raw is String && raw.isNotEmpty) {
        utc = DateTime.parse(raw).toUtc();
      } else if (raw is Map) {
        final d = raw['\$date'];
        if (d is Map && d['\$numberLong'] != null) {
          final millis = int.parse(d['\$numberLong'].toString());
          utc = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
        } else if (d is String) {
          utc = DateTime.parse(d).toUtc();
        }
      } else if (raw is int) {
        utc = DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
      }
      final myt = utc?.add(const Duration(hours: 8));
      if (myt != null) {
        created = DateFormat('d MMM, h:mm a').format(myt);
      }
    } catch (_) {}
    return created;
  }

  @override
  Widget build(BuildContext context) {
    final text = (widget.msg['text'] ?? '').toString();
    (widget.msg['userName'] ?? 'Unknown').toString();
    final created = _formatMyt(widget.msg['createdAt']);

    final bubbleColor = widget.isMine ? kMediumSage : Colors.white;
    final textColor = widget.isMine ? Colors.white : Colors.black87;
    final border = Border.all(
      color: widget.isMine ? kMediumSage : kSoftMint.withOpacity(0.6),
      width: widget.isMine ? 0 : 1,
    );
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(widget.isMine ? 16 : 4),
      bottomRight: Radius.circular(widget.isMine ? 4 : 16),
    );

    final timeStyle = TextStyle(
      color: widget.isMine ? Colors.white70 : Colors.grey[600],
      fontSize: 10,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: GestureDetector(
        onTap: () => setState(() => _showTime = !_showTime),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: widget.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(color: textColor, fontSize: 14)),
                if (_showTime && created.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(created, style: timeStyle),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
