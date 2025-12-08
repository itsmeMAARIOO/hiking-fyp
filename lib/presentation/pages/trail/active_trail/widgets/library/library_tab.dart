import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hikingapp/services/chat_service.dart';

class LibraryTab extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;
  final String currentUserName;

  const LibraryTab({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final ChatService _chat = ChatService();
  final List<Map<String, dynamic>> _images = [];
  final Set<String> _pendingIds = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _chat.connectSocket(
      groupId: widget.groupId,
      onNewMessage: (payload) {
        final imageUrl = (payload['imageUrl'] ?? '').toString();
        if (imageUrl.isNotEmpty) {
          final incomingId = payload['_id']?.toString();
          final exists = _images.any((m) => m['_id']?.toString() == incomingId);
          if (!exists) {
            setState(() => _images.add(Map<String, dynamic>.from(payload)));
          }
        }
      },
      onDeleteMessage: (id) {
        setState(() => _images.removeWhere((m) => m['_id']?.toString() == id));
      },
    );
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final msgs = await _chat.fetchMessages(widget.groupId);
      final imgs = msgs.where(
        (m) => (m['imageUrl'] ?? '').toString().isNotEmpty,
      );
      setState(
        () => _images.addAll(imgs.map((e) => Map<String, dynamic>.from(e))),
      );
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _chat.disconnect();
    super.dispose();
  }

  Future<void> _takePhotoAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;
    try {
      final file = File(picked.path);
      // Add a pending placeholder tile immediately
      final pendingId = 'pending-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _pendingIds.add(pendingId);
        _images.add({
          '_id': pendingId,
          'userId': widget.currentUserId,
          'imageUrl': '',
          'isPending': true,
        });
      });

      final created = await _chat.uploadImage(
        groupId: widget.groupId,
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        imageFile: file,
      );
      // Replace the pending tile with the created message
      final incomingId = created['_id']?.toString();
      setState(() {
        final idx = _images.indexWhere((m) => m['_id'] == pendingId);
        if (idx >= 0) {
          _images[idx] = Map<String, dynamic>.from(created);
        } else {
          if (!_images.any((m) => m['_id']?.toString() == incomingId)) {
            _images.add(Map<String, dynamic>.from(created));
          }
        }
        _pendingIds.remove(pendingId);
      });
    } catch (_) {
      // Remove pending tile on failure
      setState(() {
        _images.removeWhere((m) => m['isPending'] == true);
        _pendingIds.clear();
      });
    }
  }

  Future<void> _downloadImage(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _deleteImage(String id) async {
    try {
      await _chat.deleteMessage(
        groupId: widget.groupId,
        messageId: id,
        userId: widget.currentUserId,
      );
      // Optimistically remove immediately
      setState(() => _images.removeWhere((m) => m['_id']?.toString() == id));
    } catch (_) {}
  }

  Future<void> _openImageViewer(Map<String, dynamic> item) async {
    final url = item['imageUrl']?.toString() ?? '';
    final id = item['_id']?.toString() ?? '';
    final isOwner = item['userId']?.toString() == widget.currentUserId;
    if (url.isEmpty) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Tap outside to close
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: const SizedBox.expand(),
                ),
              ),
              // Image centered, no inner black box
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 4,
                      child: Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              // Minimalist action icons at top-right
              Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TopRightIcon(
                        icon: Icons.download_outlined,
                        onTap: () => _downloadImage(url),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        _TopRightIcon(
                          icon: Icons.delete_outline,
                          onTap: () async {
                            await _deleteImage(id);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                      const SizedBox(width: 8),
                      _TopRightIcon(
                        icon: Icons.close,
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _images.isEmpty
                      ? _LibraryEmptyState(onCapture: _takePhotoAndUpload)
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _images.length,
                          itemBuilder: (_, i) {
                            final item = _images[i];
                            final url = item['imageUrl']?.toString() ?? '';
                            final isPending = item['isPending'] == true;
                            if (isPending) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return GestureDetector(
                              onTap: () => _openImageViewer(item),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url, fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      heroTag: 'library_capture_fab',
                      onPressed: _takePhotoAndUpload,
                      tooltip: 'Capture photo',
                      backgroundColor: kDeepForest,
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: kLightCream,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRightIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopRightIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _LibraryEmptyState extends StatefulWidget {
  final VoidCallback onCapture;
  const _LibraryEmptyState({required this.onCapture});

  @override
  State<_LibraryEmptyState> createState() => _LibraryEmptyStateState();
}

class _LibraryEmptyStateState extends State<_LibraryEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => SizedBox(
                  width: 100,
                  height: 100,
                  child: Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kMediumSage.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: kMediumSage,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kMediumSage.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'No photos yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kDeepTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share your first trail memory',
            style: TextStyle(fontSize: 13, color: kDeepTeal.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
