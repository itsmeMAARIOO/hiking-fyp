import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/map_provider.dart';

class MainMapWidget extends StatelessWidget {
  final MapController mapController;

  const MainMapWidget({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: mapProvider.currentLocation != null
              ? LatLng(
                  mapProvider.currentLocation!['latitude']!,
                  mapProvider.currentLocation!['longitude']!,
                )
              : const LatLng(3.1390, 101.6869),
          zoom: 15,
          maxZoom: 17,
          minZoom: 3,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.hikingapp',
            maxNativeZoom: 17,
          ),
          if (mapProvider.trailPoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: mapProvider.trailPoints
                      .map(
                        (point) =>
                            LatLng(point['latitude']!, point['longitude']!),
                      )
                      .toList(),
                  strokeWidth: 5.0,
                  color: kMediumSage,
                  borderStrokeWidth: 2.0,
                  borderColor: Colors.white,
                ),
              ],
            ),
          if (mapProvider.currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 50,
                  height: 50,
                  point: LatLng(
                    mapProvider.currentLocation!['latitude']!,
                    mapProvider.currentLocation!['longitude']!,
                  ),
                  builder: (ctx) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 35,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
