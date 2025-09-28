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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Trail Recording",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isRecording ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRecording ? "Recording" : "Not Recording",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B7355),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isRecording ? onStop : onStart,
            icon: Icon(
              isRecording ? Icons.stop : Icons.circle,
              color: Colors.white,
            ),
            label: Text(isRecording ? "Stop Recording" : "Start Recording"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording
                  ? Colors.red
                  : const Color(0xFF16A085),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          if (trailPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text("Trail Points: ${trailPoints.length}"),
            const Text("Distance: 2.4 miles"),
          ],
        ],
      ),
    );
  }
}
