import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hikingapp/config/api_config.dart';

class OfflineMapViewerPage extends StatelessWidget {
  final String regionName;
  final String baseUrl; // e.g., "/offline-maps/<id>"
  final double neLat;
  final double neLng;
  final double swLat;
  final double swLng;

  const OfflineMapViewerPage({
    super.key,
    required this.regionName,
    required this.baseUrl,
    required this.neLat,
    required this.neLng,
    required this.swLat,
    required this.swLng,
  });

  LatLng get _center => LatLng((neLat + swLat) / 2.0, (neLng + swLng) / 2.0);

  String _tileBaseOrigin() {
    final api = ApiConfig.baseUrl; // e.g. https://<domain>/api
    final origin = api.endsWith('/api')
        ? api.substring(0, api.length - 4)
        : api; // strip trailing /api
    return '$origin$baseUrl';
  }

  @override
  Widget build(BuildContext context) {
    final origin = _tileBaseOrigin();

    return Scaffold(
      appBar: AppBar(title: Text(regionName)),
      body: FlutterMap(
        options: MapOptions(center: _center, zoom: 13),
        children: [
          TileLayer(
            urlTemplate: '$origin/{z}/{x}/{y}.png',
            tileProvider: NetworkTileProvider(),
            userAgentPackageName: 'com.example.hikingapp',
          ),
        ],
      ),
    );
  }
}
