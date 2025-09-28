import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/pages/map/widgets/location_display.dart';
import 'package:hikingapp/presentation/pages/map/widgets/map_tools.dart';
import 'package:hikingapp/presentation/pages/map/widgets/trail_recorder.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Trail Map",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "GPS Tracking & Navigation",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8B7355),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Map Placeholder
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF16A085),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.map, size: 48, color: Color(0xFF16A085)),
                    SizedBox(height: 12),
                    Text(
                      "Interactive Map View",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A085),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Real-time GPS tracking and trail visualization",
                      style: TextStyle(fontSize: 14, color: Color(0xFF8B7355)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Location Display
              LocationDisplay(location: mapProvider.currentLocation),

              // Trail Recorder
              TrailRecorder(
                isRecording: mapProvider.isRecording,
                onStart: () => mapProvider.startRecording(context),
                onStop: () => mapProvider.stopRecording(context),
                trailPoints: mapProvider.trailPoints,
              ),

              // Map tools
              MapTools(),
            ],
          ),
        ),
      ),
    );
  }
}
