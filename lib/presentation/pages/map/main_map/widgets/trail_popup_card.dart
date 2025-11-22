import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class TrailPopupCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double? rating;
  final double distanceKm;
  final VoidCallback onNavigate;
  final VoidCallback onOfflineMap;
  final VoidCallback? onSave;
  final bool isSaved;
  final bool isSaving;

  const TrailPopupCard({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.distanceKm,
    required this.onNavigate,
    required this.onOfflineMap,
    this.onSave,
    this.isSaved = false,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12), // Floating effect
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // =================================================
          // 1. IMMERSIVE IMAGE HEADER
          // =================================================
          Stack(
            children: [
              // The Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallback(),
                        )
                      : _buildFallback(),
                ),
              ),

              // The Gradient Overlay (Makes text readable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8), // Dark bottom
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // The Drag Handle (Top Center)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // Save Button (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onSave,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isSaved ? Colors.amber : Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),

              // The Title & Rating (Bottom Left of Image)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating != null ? rating!.toStringAsFixed(1) : "N/A",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.directions_walk,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // =================================================
          // 2. ACTION BUTTONS AREA
          // =================================================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Offline Map Button (Light)
                Expanded(
                  child: TextButton.icon(
                    onPressed: onOfflineMap,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text("Offline Map"),
                    style: TextButton.styleFrom(
                      foregroundColor: kDeepForest,
                      backgroundColor: kMediumSage.withOpacity(0.15),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Navigate Button (Dark/Primary)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      "Navigate",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDeepTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: kDeepTeal.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  Widget _buildFallback() {
    return Container(
      color: kDeepForest,
      child: Center(
        child: Icon(
          Icons.forest,
          color: Colors.white.withOpacity(0.2),
          size: 60,
        ),
      ),
    );
  }
}
