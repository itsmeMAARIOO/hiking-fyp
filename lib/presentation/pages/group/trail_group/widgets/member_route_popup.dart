import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MemberRoutePopup extends StatelessWidget {
  final LatLng currentLocation;
  final LatLng memberLocation;
  final String memberName;

  const MemberRoutePopup({
    super.key,
    required this.currentLocation,
    required this.memberLocation,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Route to $memberName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: FlutterMap(
                  options: MapOptions(
                    center: _midpoint(currentLocation, memberLocation),
                    zoom: 14,
                    maxZoom: 18, // allow deep zoom; tiles upscale beyond native
                    minZoom: 3,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.hikingapp',
                      maxNativeZoom:
                          19, // OSM provides tiles up to 19; upscale beyond
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [currentLocation, memberLocation],
                          strokeWidth: 4,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation,
                          width: 56,
                          height: 56,
                          builder: (context) => _markerIcon(
                            icon: Icons.person_pin_circle,
                            color: Colors.green,
                            label: 'You',
                          ),
                        ),
                        Marker(
                          point: memberLocation,
                          width: 56,
                          height: 56,
                          builder: (context) => _markerIcon(
                            icon: Icons.location_on,
                            color: Colors.redAccent,
                            label: memberName,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _markerIcon({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ],
    );
  }

  LatLng _midpoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }
}
