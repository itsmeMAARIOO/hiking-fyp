import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/presentation/pages/map/compass/compass_page.dart';

class MapTools extends StatelessWidget {
  const MapTools({super.key});

  @override
  Widget build(BuildContext context) {
    void downloadOfflineMap() {
      SnackbarHelper.showSuccess('Info', 'Downloading offline map...');
    }

    void startNavigation() {
      SnackbarHelper.showSuccess('Info', 'Starting navigation...');
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
                onPressed: downloadOfflineMap,
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
              _buildEnhancedToolButton(
                icon: Icons.navigation_rounded,
                title: "Navigate",
                color: Color(0xFF1C3F3F),
                onPressed: startNavigation,
                iconGradient: const LinearGradient(
                  colors: [Color(0xFF1C3F3F), Color(0xFF2C5D5D)],
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
