import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class SoloLiveMap extends StatefulWidget {
  final double height;

  const SoloLiveMap({super.key, this.height = 220});

  @override
  State<SoloLiveMap> createState() => _SoloLiveMapState();
}

class _SoloLiveMapState extends State<SoloLiveMap> {
  final MapController _mapController = MapController();
  Timer? _updateTimer;
  LatLng? _lastCenter;

  @override
  void initState() {
    super.initState();

    // Position the map to the latest location after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<MapProvider>(context, listen: false);
      final loc = _getCurrentLatLng(provider);
      if (loc != null) {
        _lastCenter = loc;
        try {
          _mapController.move(loc, 15.0);
        } catch (_) {}
      }
    });

    // Throttle map panning to current location every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final provider = Provider.of<MapProvider>(context, listen: false);
      final loc = _getCurrentLatLng(provider);
      if (loc != null) {
        _lastCenter = loc;
        try {
          if (mounted) {
            _mapController.move(loc, _mapController.zoom);
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  LatLng? _getCurrentLatLng(MapProvider provider) {
    final current = provider.currentLocation;
    if (current != null) {
      final lat = current['latitude'];
      final lon = current['longitude'];
      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    // Fallback to minimized solo stats last location
    final lastLat = provider.soloLastLat;
    final lastLon = provider.soloLastLon;
    if (lastLat != null && lastLon != null) {
      return LatLng(lastLat, lastLon);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        final center = _getCurrentLatLng(provider) ?? _lastCenter ?? const LatLng(3.1390, 101.6869);

        final points = provider.trailPoints
            .map((p) {
              final lat = p['latitude'];
              final lon = p['longitude'];
              if (lat == null || lon == null) return null;
              return LatLng(lat, lon);
            })
            .whereType<LatLng>()
            .toList();

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: center,
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
                if (points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 5.0,
                        color: kMediumSage,
                        borderStrokeWidth: 2.0,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),
                if (center != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 36,
                        height: 36,
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}