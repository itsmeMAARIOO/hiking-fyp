import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/presentation/pages/map/compass/compass_page.dart';
import 'package:hikingapp/presentation/pages/map/main_map/widgets/trail_recorder.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/pages/map/offline/offline_area_picker_page.dart';
import 'package:hikingapp/presentation/pages/map/offline/offline_map_viewer_page.dart';

class MapTools extends StatelessWidget {
  const MapTools({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> manageOfflineMaps() async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.userId;
      if (userId == null || userId.isEmpty) {
        SnackbarHelper.showError(
          'Login Required',
          'Please login to manage offline maps',
        );
        return;
      }

      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/offline-map/list?userId=$userId'),
        );
        if (res.statusCode != 200) {
          final data = jsonDecode(res.body);
          SnackbarHelper.showError(
            'Failed',
            data['error'] ?? 'Unable to load maps',
          );
          return;
        }
        final data = jsonDecode(res.body);
        List<dynamic> maps = (data['maps'] ?? []) as List<dynamic>;

        await showDialog(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setState) {
                return AlertDialog(
                  title: const Text('Offline Maps'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: maps.isEmpty
                        ? const Text('No offline maps yet')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: maps.length,
                            itemBuilder: (context, index) {
                              final m = maps[index] as Map<String, dynamic>;
                              final status = m['status'] ?? 'pending';
                              final progress =
                                  '${m['downloaded'] ?? 0}/${m['tileCount'] ?? 0}';
                              return ListTile(
                                title: Text(m['regionName'] ?? 'Unnamed'),
                                subtitle: Text(
                                  'Status: $status  •  Tiles: $progress',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status == 'completed' &&
                                        (m['baseUrl'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Get.to(
                                            () => OfflineMapViewerPage(
                                              regionName:
                                                  (m['regionName'] ?? 'Map')
                                                      .toString(),
                                              baseUrl: (m['baseUrl'] ?? '')
                                                  .toString(),
                                              neLat: (m['neLat'] ?? 0.0) * 1.0,
                                              neLng: (m['neLng'] ?? 0.0) * 1.0,
                                              swLat: (m['swLat'] ?? 0.0) * 1.0,
                                              swLng: (m['swLng'] ?? 0.0) * 1.0,
                                            ),
                                          );
                                        },
                                        child: const Text('Open'),
                                      ),
                                    TextButton(
                                      onPressed: () async {
                                        final id = m['_id'];
                                        final del = await http.delete(
                                          Uri.parse(
                                            '${ApiConfig.baseUrl}/offline-map/delete/$id',
                                          ),
                                        );
                                        if (del.statusCode == 200) {
                                          setState(() => maps.removeAt(index));
                                          SnackbarHelper.showSuccess(
                                            'Deleted',
                                            'Offline map deleted',
                                          );
                                        } else {
                                          SnackbarHelper.showError(
                                            'Delete Failed',
                                            del.body,
                                          );
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
      } catch (e) {
        SnackbarHelper.showError('Error', e.toString());
      }
    }

    void downloadOfflineMap() {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Maps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Get.to(() => const OfflineAreaPickerPage());
                    },
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Download New Area'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3E7B5B), Color(0xFF6BAF89)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3E7B5B).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Map Tools",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C3F3F),
                    ),
                  ),
                  Text(
                    "Essential navigation tools",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6BAF89),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Enhanced Buttons Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnhancedToolButton(
                icon: Icons.download_done_rounded,
                title: "Offline Maps",
                color: Color(0xFF3E7B5B),
                onPressed: () {
                  Get.to(() => const OfflineAreaPickerPage());
                },
                iconGradient: const LinearGradient(
                  colors: [Color(0xFF3E7B5B), Color(0xFF4CAF89)],
                ),
              ),
              _buildEnhancedToolButton(
                icon: Icons.explore_rounded,
                title: "Compass",
                color: Color(0xFF6BAF89),
                onPressed: () {
                  Get.to(() => const CompassPage());
                },
                iconGradient: const LinearGradient(
                  colors: [Color(0xFF6BAF89), Color(0xFF8BC34A)],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Decorative Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF6BAF89).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedToolButton({
    required IconData icon,
    required String title,
    required Color color,
    required Gradient iconGradient,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        // Main Button Container
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with gradient
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: iconGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class TrailRecorderButton extends StatelessWidget {
  final bool isRecording;
  final bool isActive; // controls scale when panel is visible
  final AnimationController animationController;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;

  const TrailRecorderButton({
    super.key,
    required this.isRecording,
    required this.isActive,
    required this.animationController,
    required this.scaleAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? scaleAnimation.value : 1.0,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isRecording
                    ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                    : [const Color(0xFF3E7B5B), const Color(0xFF6BAF89)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (isRecording
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF3E7B5B))
                          .withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRecording
                                ? Icons.radio_button_checked
                                : Icons.alt_route_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          if (isRecording) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MapToolsButton extends StatelessWidget {
  final bool isActive; // controls scale when panel is visible
  final AnimationController animationController;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;

  const MapToolsButton({
    super.key,
    required this.isActive,
    required this.animationController,
    required this.scaleAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? scaleAnimation.value : 1.0,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1C3F3F), Color(0xFF2C5D5D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1C3F3F).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: const Center(
                  child: Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TrailRecorderPanel extends StatelessWidget {
  final Animation<double> panelAnimation;
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final List<dynamic> trailPoints;

  const TrailRecorderPanel({
    super.key,
    required this.panelAnimation,
    required this.isRecording,
    required this.onStart,
    required this.onStop,
    required this.trailPoints,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: panelAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - panelAnimation.value) * 20),
          child: Opacity(
            opacity: panelAnimation.value,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C3F3F).withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TrailRecorder(
                  isRecording: isRecording,
                  onStart: onStart,
                  onStop: onStop,
                  trailPoints: trailPoints,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MapToolsPanel extends StatelessWidget {
  final Animation<double> panelAnimation;

  const MapToolsPanel({super.key, required this.panelAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: panelAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - panelAnimation.value) * 20),
          child: Opacity(
            opacity: panelAnimation.value,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C3F3F).withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const MapTools(),
              ),
            ),
          ),
        );
      },
    );
  }
}
