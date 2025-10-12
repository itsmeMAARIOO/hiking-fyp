import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'widgets/location_display.dart';
import 'widgets/trail_recorder.dart';
import 'widgets/map_tools.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  bool _showTrailRecorder = false;
  bool _showMapTools = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _panelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.addListener(() {
        if (mapProvider.currentLocation != null) {
          _mapController.move(
            LatLng(
              mapProvider.currentLocation!['latitude']!,
              mapProvider.currentLocation!['longitude']!,
            ),
            _mapController.zoom,
          );
        }
      });
    });
  }

  void _togglePanel(String panelType) {
    setState(() {
      if (panelType == 'trail') {
        _showTrailRecorder = !_showTrailRecorder;
        _showMapTools = false;
      } else {
        _showMapTools = !_showMapTools;
        _showTrailRecorder = false;
      }
    });

    if (_showTrailRecorder || _showMapTools) {
      _buttonAnimationController.forward();
    } else {
      _buttonAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    mapProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient for smoother transition
          Container(decoration: const BoxDecoration(color: kDeepForest)),

          // Main Content with layered design
          SafeArea(
            child: Column(
              children: [
                // Header matching create group page style
                CommonHeader(
                  title: 'Trail Explorer',
                  subtitle: 'Discover hiking paths',
                  trailingWidget: Icon(
                    Icons.shield,
                    size: 32,
                    color: Colors.white,
                  ),
                ),

                // Map Section with rounded top container
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Location Display
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kDeepTeal.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: LocationDisplay(
                            location:
                                mapProvider.currentLocation ??
                                {
                                  'latitude': 0.0,
                                  'longitude': 0.0,
                                  'altitude': 0.0,
                                  'accuracy': 0.0,
                                },
                          ),
                        ),
                        // Map Container
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: kDeepTeal.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    center: mapProvider.currentLocation != null
                                        ? LatLng(
                                            mapProvider
                                                .currentLocation!['latitude']!,
                                            mapProvider
                                                .currentLocation!['longitude']!,
                                          )
                                        : const LatLng(3.1390, 101.6869),
                                    zoom: 15,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
                                      subdomains: const ['a', 'b', 'c'],
                                      userAgentPackageName:
                                          'com.example.hikingapp',
                                    ),
                                    if (mapProvider.trailPoints.isNotEmpty)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: mapProvider.trailPoints
                                                .map(
                                                  (point) => LatLng(
                                                    point['latitude']!,
                                                    point['longitude']!,
                                                  ),
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
                                              mapProvider
                                                  .currentLocation!['latitude']!,
                                              mapProvider
                                                  .currentLocation!['longitude']!,
                                            ),
                                            builder: (ctx) => Container(
                                              decoration: BoxDecoration(
                                                // color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
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
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Buttons - Positioned above navigation bar
          Positioned(
            left: 25,
            bottom: bottomPadding + 25,
            child: _buildTrailRecorderButton(mapProvider),
          ),

          Positioned(
            right: 25,
            bottom: bottomPadding + 25,
            child: _buildMapToolsButton(),
          ),

          // Animated Overlay Panels
          if (_showTrailRecorder)
            Positioned(
              left: 25,
              bottom: bottomPadding + 100,
              child: _buildTrailRecorderPanel(mapProvider),
            ),

          if (_showMapTools)
            Positioned(
              right: 25,
              bottom: bottomPadding + 100,
              child: _buildMapToolsPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildTrailRecorderButton(MapProvider mapProvider) {
    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _showTrailRecorder ? _buttonScaleAnimation.value : 1.0,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: mapProvider.isRecording
                    ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                    : [kDeepForest, kMediumSage],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (mapProvider.isRecording
                              ? const Color(0xFFFF6B6B)
                              : kDeepForest)
                          .withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _togglePanel('trail'),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            mapProvider.isRecording
                                ? Icons.radio_button_checked
                                : Icons.alt_route_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          if (mapProvider.isRecording) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapToolsButton() {
    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _showMapTools ? _buttonScaleAnimation.value : 1.0,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kDeepTeal, Color(0xFF2C5D5D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kDeepTeal.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _togglePanel('tools'),
                child: const Center(
                  child: Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrailRecorderPanel(MapProvider mapProvider) {
    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _panelAnimation.value) * 20),
          child: Opacity(
            opacity: _panelAnimation.value,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kDeepTeal.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TrailRecorder(
                  isRecording: mapProvider.isRecording,
                  onStart: () {
                    mapProvider.startRecording(context);
                    _togglePanel('trail');
                  },
                  onStop: () {
                    mapProvider.stopRecording(context);
                    _togglePanel('trail');
                  },
                  trailPoints: mapProvider.trailPoints,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapToolsPanel() {
    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _panelAnimation.value) * 20),
          child: Opacity(
            opacity: _panelAnimation.value,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kDeepTeal.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const MapTools(),
              ),
            ),
          ),
        );
      },
    );
  }
}
