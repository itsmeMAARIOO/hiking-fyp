import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'widgets/location_display.dart';
import 'widgets/map_tools.dart';
import 'widgets/main_map_widget.dart';

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
          Container(decoration: BoxDecoration(color: kDeepForest)),

          // Main Content with layered design
          SafeArea(
            child: Column(
              children: [
                // Header matching create group page style
                CommonHeader(
                  title: 'Explorer',
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
                                child: MainMapWidget(mapController: _mapController),
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
            child: TrailRecorderButton(
              isRecording: mapProvider.isRecording,
              isActive: _showTrailRecorder,
              animationController: _buttonAnimationController,
              scaleAnimation: _buttonScaleAnimation,
              onTap: () => _togglePanel('trail'),
            ),
          ),

          Positioned(
            right: 25,
            bottom: bottomPadding + 25,
            child: MapToolsButton(
              isActive: _showMapTools,
              animationController: _buttonAnimationController,
              scaleAnimation: _buttonScaleAnimation,
              onTap: () => _togglePanel('tools'),
            ),
          ),

          // Animated Overlay Panels
          if (_showTrailRecorder)
            Positioned(
              left: 25,
              bottom: bottomPadding + 100,
              child: TrailRecorderPanel(
                panelAnimation: _panelAnimation,
                isRecording: mapProvider.isRecording,
                onStart: () {
                  Get.toNamed(AppRoutes.soloTrailName);
                  _togglePanel('trail');
                },
                onStop: () {
                  mapProvider.stopRecording(context);
                  _togglePanel('trail');
                },
                trailPoints: mapProvider.trailPoints,
              ),
            ),

          if (_showMapTools)
            Positioned(
              right: 25,
              bottom: bottomPadding + 100,
              child: MapToolsPanel(panelAnimation: _panelAnimation),
            ),
        ],
      ),
    );
  }

}
