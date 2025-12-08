import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/auth_provider.dart';

class SoloLiveMap extends StatefulWidget {
  final double height;
  // Provide group members to render markers on the map.
  final List<Map<String, dynamic>> members;
  // Optional focus target to center the map when a member is selected.
  final double? focusLat;
  final double? focusLon;
  // Trigger to fit viewport to all member markers when incremented.
  final int showAllTrigger;

  const SoloLiveMap({
    super.key,
    this.height = 220,
    this.members = const [],
    this.focusLat,
    this.focusLon,
    this.showAllTrigger = 0,
  });

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
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = auth.userId;
        final focus = (widget.focusLat != null && widget.focusLon != null)
            ? LatLng(widget.focusLat!, widget.focusLon!)
            : null;

        // Determine map center preference: focus if provided, otherwise current user location
        final center =
            focus ??
            _getCurrentLatLng(provider) ??
            _lastCenter ??
            const LatLng(3.1390, 101.6869);

        // Current user location marker remains independent of focus center
        final currentLoc = _getCurrentLatLng(provider) ?? _lastCenter;

        final points = provider.trailPoints
            .map((p) {
              final lat = p['latitude'];
              final lon = p['longitude'];
              if (lat == null || lon == null) return null;
              return LatLng(lat, lon);
            })
            .whereType<LatLng>()
            .toList();

        // Build member markers from provided list
        final memberMarkers = widget.members
            .map((m) {
              // Skip current user markers by userId when available
              final String? uid = _extractUserId(m);
              if (currentUserId != null && uid == currentUserId) {
                return null;
              }
              final lat = _parseDouble(m['latitude']);
              final lon = _parseDouble(m['longitude']);
              if (lat == null || lon == null) return null;
              final point = LatLng(lat, lon);
              // Skip current user marker here (it renders separately as red nav icon)
              if (currentLoc != null &&
                  (currentLoc.latitude == point.latitude &&
                      currentLoc.longitude == point.longitude)) {
                return null;
              }
              final name = (m['name'] ?? m['userName'] ?? 'M').toString();
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
              // Resolve profile image URL from different data shapes
              String? avatarUrl;
              final dynamic pi = m['profileImage'];
              if (pi is String && pi.isNotEmpty) {
                avatarUrl = pi;
              } else if (m['userId'] is Map<String, dynamic>) {
                final Map<String, dynamic> userObj =
                    m['userId'] as Map<String, dynamic>;
                final dynamic upi = userObj['profileImage'];
                if (upi is String && upi.isNotEmpty) {
                  avatarUrl = upi;
                }
              }
              final bool hasNetworkAvatar =
                  avatarUrl != null &&
                  avatarUrl.isNotEmpty &&
                  avatarUrl.startsWith('http');
              final isFocused =
                  focus != null &&
                  (focus.latitude == point.latitude &&
                      focus.longitude == point.longitude);
              return Marker(
                point: point,
                width: 38,
                height: 38,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFocused ? kMediumSage : kDeepForest,
                    border: Border.all(
                      color: isFocused ? Colors.white : Colors.white70,
                      width: isFocused ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kDeepTeal.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    backgroundImage: hasNetworkAvatar
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: hasNetworkAvatar
                        ? null
                        : Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              );
            })
            .whereType<Marker>()
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
                  urlTemplate:
                      "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
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
                if (memberMarkers.isNotEmpty)
                  MarkerLayer(markers: memberMarkers),
                if (currentLoc != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLoc,
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

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is Map && value['\$numberDouble'] != null) {
      return double.tryParse(value['\$numberDouble'] as String);
    }
    return null;
  }

  String? _extractUserId(Map<String, dynamic> m) {
    final dynamic direct = m['userId'] ?? m['id'];
    if (direct is String && direct.isNotEmpty) return direct;
    if (direct is Map<String, dynamic>) {
      final dynamic nested = direct['_id'] ?? direct['id'];
      if (nested is String && nested.isNotEmpty) return nested;
      return nested?.toString();
    }
    final dynamic userObj = m['user'];
    if (userObj is Map<String, dynamic>) {
      final dynamic nested = userObj['_id'] ?? userObj['id'];
      if (nested is String && nested.isNotEmpty) return nested;
      return nested?.toString();
    }
    return direct?.toString();
  }

  @override
  void didUpdateWidget(covariant SoloLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a new focus is provided, center the map smoothly
    if (widget.focusLat != null && widget.focusLon != null) {
      final target = LatLng(widget.focusLat!, widget.focusLon!);
      try {
        _mapController.move(target, _mapController.zoom);
        _lastCenter = target;
      } catch (_) {}
    }

    // When the external 'show all' trigger changes, adjust center/zoom to cover all members
    if (widget.showAllTrigger != oldWidget.showAllTrigger) {
      final points = widget.members
          .map((m) {
            final lat = _parseDouble(m['latitude']);
            final lon = _parseDouble(m['longitude']);
            if (lat == null || lon == null) return null;
            return LatLng(lat, lon);
          })
          .whereType<LatLng>()
          .toList();

      if (points.isNotEmpty) {
        try {
          double minLat = points.first.latitude;
          double maxLat = points.first.latitude;
          double minLon = points.first.longitude;
          double maxLon = points.first.longitude;
          for (final p in points) {
            if (p.latitude < minLat) minLat = p.latitude;
            if (p.latitude > maxLat) maxLat = p.latitude;
            if (p.longitude < minLon) minLon = p.longitude;
            if (p.longitude > maxLon) maxLon = p.longitude;
          }
          final center = LatLng(
            (minLat + maxLat) / 2.0,
            (minLon + maxLon) / 2.0,
          );
          final latSpan = (maxLat - minLat).abs();
          final lonSpan = (maxLon - minLon).abs();
          final span = latSpan > lonSpan ? latSpan : lonSpan;
          double zoom;
          if (span < 0.005) {
            zoom = 16;
          } else if (span < 0.01) {
            zoom = 15;
          } else if (span < 0.05) {
            zoom = 14;
          } else if (span < 0.1) {
            zoom = 13;
          } else if (span < 0.5) {
            zoom = 12;
          } else {
            zoom = 11;
          }
          _mapController.move(center, zoom);
          _lastCenter = center;
        } catch (_) {}
      }
    }
  }
}
