import 'package:flutter/material.dart';

class LocationDisplay extends StatelessWidget {
  final Map<String, double> location;

  const LocationDisplay({super.key, required this.location});

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
          const Text(
            "Current Location",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.location_pin,
                    size: 16,
                    color: Color(0xFF16A085),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Coordinates",
                    style: TextStyle(fontSize: 10, color: Color(0xFF8B7355)),
                  ),
                  Text(
                    "${location['latitude']!.toStringAsFixed(4)}, ${location['longitude']!.toStringAsFixed(4)}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.terrain, size: 16, color: Color(0xFF16A085)),
                  const SizedBox(height: 4),
                  const Text(
                    "Altitude",
                    style: TextStyle(fontSize: 10, color: Color(0xFF8B7355)),
                  ),
                  Text(
                    "${location['altitude']} ft",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Icon(
                    Icons.navigation,
                    size: 16,
                    color: Color(0xFF16A085),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Accuracy",
                    style: TextStyle(fontSize: 10, color: Color(0xFF8B7355)),
                  ),
                  Text(
                    "±${location['accuracy']} m",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
