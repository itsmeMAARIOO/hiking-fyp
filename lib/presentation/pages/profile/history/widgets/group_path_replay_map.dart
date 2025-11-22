import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class GroupPathReplayMap extends StatefulWidget {
  final List<MemberPath> members;
  final DateTime startTime;
  final DateTime endTime;
  final List<LatLng> fallbackPoints;

  const GroupPathReplayMap({
    super.key,
    required this.members,
    required this.startTime,
    required this.endTime,
    this.fallbackPoints = const [],
  });

  @override
  State<GroupPathReplayMap> createState() => _GroupPathReplayMapState();
}

class _GroupPathReplayMapState extends State<GroupPathReplayMap> {
  final MapController _mapController = MapController();
  late final Map<String, Color> _memberColors;
  late final List<Color> _palette;
  LatLng? _initialCenter;
  double? _initialZoom;

  @override
  void initState() {
    super.initState();
    _palette = [
      kMediumSage,
      kDeepForest,
      Colors.orange,
      kDeepTeal,
      Colors.purple,
      Colors.blueGrey,
      Colors.indigo,
    ];
    _memberColors = {};
    for (int i = 0; i < widget.members.length; i++) {
      _memberColors[widget.members[i].userId] = _palette[i % _palette.length];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = _computeBounds();
      if (bounds != null) {
        final cz = _centerZoomForBounds(bounds);
        _initialCenter = cz.center;
        _initialZoom = cz.zoom;
        try {
          _mapController.move(_initialCenter!, _initialZoom!);
        } catch (_) {}
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final polylines = _fullPolylines();
    final bounds = _computeBounds();
    final center = _initialCenter ?? bounds?.center ?? const LatLng(4.2105, 101.9758);
    final zoom = _initialZoom ?? (bounds == null ? 6 : 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: center,
                zoom: zoom,
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
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                if (polylines.isEmpty && widget.fallbackPoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.fallbackPoints,
                        color: kMediumSage,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    if (widget.members.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.members.map((m) {
        final color = _memberColors[m.userId] ?? kMediumSage;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: kWarmWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                m.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kDeepTeal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Polyline> _fullPolylines() {
    final lines = <Polyline>[];
    for (final m in widget.members) {
      final pts = m.path.map((p) => LatLng(p.lat, p.lng)).toList(growable: false);
      if (pts.length >= 2) {
        lines.add(
          Polyline(
            points: pts,
            color: _memberColors[m.userId] ?? kMediumSage,
            strokeWidth: 4,
          ),
        );
      }
    }
    return lines;
  }

  LatLngBounds? _computeBounds() {
    final all = <LatLng>[];
    for (final m in widget.members) {
      for (final p in m.path) {
        all.add(LatLng(p.lat, p.lng));
      }
    }
    if (widget.fallbackPoints.isNotEmpty) {
      all.addAll(widget.fallbackPoints);
    }
    if (all.isEmpty) return null;
    final minLat = all.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
    final maxLat = all.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
    final minLng = all.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
    final maxLng = all.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  _CenterZoom _centerZoomForBounds(LatLngBounds b) {
    final center = LatLng(
      (b.southWest.latitude + b.northEast.latitude) / 2.0,
      (b.southWest.longitude + b.northEast.longitude) / 2.0,
    );
    final latSpan = (b.northEast.latitude - b.southWest.latitude).abs();
    final lonSpan = (b.northEast.longitude - b.southWest.longitude).abs();
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
    } else if (span < 1.0) {
      zoom = 11;
    } else {
      zoom = 10;
    }
    return _CenterZoom(center, zoom);
  }
}

class MemberPath {
  final String userId;
  final String name;
  final String? profileImage;
  final List<PathPoint> path;
  MemberPath({
    required this.userId,
    required this.name,
    required this.profileImage,
    required this.path,
  });

  PathPoint? pointAtOrBefore(DateTime t) {
    PathPoint? last;
    for (final p in path) {
      if (p.timestamp.isAfter(t)) break;
      last = p;
    }
    return last;
  }

  Iterable<PathPoint> pointsUpTo(DateTime t) {
    return path.where((p) => !p.timestamp.isAfter(t));
  }
}

class PathPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;
  PathPoint({required this.lat, required this.lng, required this.timestamp});
}

class _CenterZoom {
  final LatLng center;
  final double zoom;
  const _CenterZoom(this.center, this.zoom);
}