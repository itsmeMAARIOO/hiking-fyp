import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuickActions extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onTrackingToggle;
  final VoidCallback onCheckIn;

  const QuickActions({
    super.key,
    required this.isTracking,
    required this.onTrackingToggle,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced Start/Stop Tracking button with gradient and shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isTracking
                      ? const Color(0xFFE74C3C).withOpacity(0.3)
                      : const Color(0xFF16A085).withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isTracking
                    ? const Color(0xFFE74C3C)
                    : const Color(0xFF16A085),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: onTrackingToggle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isTracking ? Icons.stop : Icons.play_arrow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isTracking ? "Stop Tracking" : "Start Tracking",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enhanced animated expansion with outdoor-themed colors
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: isTracking
                ? Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        // Check-in and Share buttons row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8B4513,
                                      ).withOpacity(0.2),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF8B4513,
                                    ), // Earth brown
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: onCheckIn,
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    "Check-in",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF16A085,
                                      ).withOpacity(0.2),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF16A085,
                                    ), // Forest green
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Get.snackbar(
                                      "Location Shared",
                                      "Your location has been shared with your hiking group",
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: const Color(0xFF16A085),
                                      colorText: Colors.white,
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      duration: const Duration(seconds: 3),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.share_location,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    "Share",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // // Emergency SOS button with safety orange
                        // const SizedBox(height: 12),
                        // Container(
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(12),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: const Color(0xFFFF6B35).withOpacity(0.3),
                        //         offset: const Offset(0, 3),
                        //         blurRadius: 10,
                        //         spreadRadius: 1,
                        //       ),
                        //     ],
                        //   ),
                        //   child: ElevatedButton.icon(
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: const Color(
                        //         0xFFFF6B35,
                        //       ), // Safety orange
                        //       foregroundColor: Colors.white,
                        //       padding: const EdgeInsets.symmetric(vertical: 16),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //       elevation: 0,
                        //     ),
                        //     onPressed: () {
                        //       Get.dialog(
                        //         AlertDialog(
                        //           title: const Text(
                        //             "Emergency SOS",
                        //             style: TextStyle(
                        //               color: Color(0xFFE74C3C),
                        //               fontWeight: FontWeight.bold,
                        //             ),
                        //           ),
                        //           content: const Text(
                        //             "This will send your location to emergency contacts and local authorities. Continue?",
                        //           ),
                        //           actions: [
                        //             TextButton(
                        //               onPressed: () => Get.back(),
                        //               child: const Text("Cancel"),
                        //             ),
                        //             ElevatedButton(
                        //               style: ElevatedButton.styleFrom(
                        //                 backgroundColor: const Color(
                        //                   0xFFE74C3C,
                        //                 ),
                        //               ),
                        //               onPressed: () {
                        //                 Get.back();
                        //                 Get.snackbar(
                        //                   "SOS Activated",
                        //                   "Emergency signal sent with your location",
                        //                   snackPosition: SnackPosition.TOP,
                        //                   backgroundColor: const Color(
                        //                     0xFFE74C3C,
                        //                   ),
                        //                   colorText: Colors.white,
                        //                   icon: const Icon(
                        //                     Icons.warning,
                        //                     color: Colors.white,
                        //                   ),
                        //                 );
                        //               },
                        //               child: const Text("Send SOS"),
                        //             ),
                        //           ],
                        //         ),
                        //       );
                        //     },
                        //     icon: const Icon(Icons.sos, size: 20),
                        //     label: const Text(
                        //       "Emergency SOS",
                        //       style: TextStyle(
                        //         fontSize: 15,
                        //         fontWeight: FontWeight.bold,
                        //         letterSpacing: 0.5,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
