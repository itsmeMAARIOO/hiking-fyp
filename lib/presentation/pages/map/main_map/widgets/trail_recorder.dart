import 'package:flutter/material.dart';

class TrailRecorder extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final List<dynamic> trailPoints;

  const TrailRecorder({
    super.key,
    required this.isRecording,
    required this.onStart,
    required this.onStop,
    required this.trailPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with improved design
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E7B5B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: const Color(0xFF3E7B5B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Trail Recorder",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C3F3F),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Enhanced Record Button
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: isRecording
                ? LinearGradient(
                    colors: [const Color(0xFFFF6B6B), const Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [const Color(0xFF3E7B5B), const Color(0xFF4CAF89)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isRecording ? onStop : onStart,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isRecording ? "STOP RECORDING" : "START RECORDING",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // // Enhanced Trail Stats
        // if (trailPoints.isNotEmpty) ...[
        //   const SizedBox(height: 20),
        //   Container(
        //     padding: const EdgeInsets.all(16),
        //     decoration: BoxDecoration(
        //       color: const Color(0xFFF8FAF9),
        //       borderRadius: BorderRadius.circular(12),
        //       border: Border.all(
        //         color: const Color(0xFF6BAF89).withOpacity(0.2),
        //       ),
        //     ),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceAround,
        //       children: [
        //         _buildStatItem(
        //           icon: Icons.flag_rounded,
        //           label: "Points",
        //           value: "${trailPoints.length}",
        //         ),
        //         _buildStatItem(
        //           icon: Icons.linear_scale_rounded,
        //           label: "Distance",
        //           value: "2.4 mi",
        //         ),
        //         _buildStatItem(
        //           icon: Icons.timer_rounded,
        //           label: "Duration",
        //           value: "45:12",
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
        // const SizedBox(height: 8),
      ],
    );
  }

  // Widget _buildStatItem({
  //   required IconData icon,
  //   required String label,
  //   required String value,
  // }) {
  //   return Column(
  //     children: [
  //       Container(
  //         padding: const EdgeInsets.all(8),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFF6BAF89).withOpacity(0.1),
  //           shape: BoxShape.circle,
  //         ),
  //         child: Icon(icon, size: 16, color: const Color(0xFF3E7B5B)),
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w700,
  //           color: Color(0xFF1C3F3F),
  //         ),
  //       ),
  //       const SizedBox(height: 2),
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 11,
  //           color: const Color(0xFF1C3F3F).withOpacity(0.6),
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
