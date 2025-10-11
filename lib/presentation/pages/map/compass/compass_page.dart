import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  double? _heading;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  Future<void> _initCompass() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      FlutterCompass.events?.listen((event) {
        setState(() {
          _heading = event.heading;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permission denied. Cannot access compass."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Compass",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (!_hasPermission) {
            return _buildPermissionRequest();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildCalibratingScreen();
          }

          if (snapshot.hasError) {
            return _buildErrorScreen();
          }

          if (!snapshot.hasData || snapshot.data!.heading == null) {
            return _buildNoDataScreen();
          }

          double direction = snapshot.data!.heading ?? 0;
          double northOffset = direction * (math.pi / 180) * -1;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Degree display
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${direction.toStringAsFixed(1)}°",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getDirectionLabel(direction),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Compass with detailed dial
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer detailed compass dial
                    Container(
                      width: 320,
                      height: 320,
                      child: CustomPaint(
                        painter: DetailedCompassDialPainter(
                          direction: direction,
                        ),
                      ),
                    ),

                    // Rotating needle
                    Transform.rotate(
                      angle: northOffset,
                      child: Container(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // North needle (red)
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 4,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.redAccent,
                                      Colors.red.shade700,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // South needle (white)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 3,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Center assembly
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade900,
                                border: Border.all(
                                  color: Colors.grey.shade600,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Cardinal directions overlay
                    ..._buildCardinalDirectionsOverlay(),
                  ],
                ),

                // Additional precision info
                Container(
                  margin: const EdgeInsets.only(top: 40),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPrecisionInfo("PRECISION", "High"),
                      _buildPrecisionInfo(
                        "BEARING",
                        "${direction.toStringAsFixed(1)}°",
                      ),
                      _buildPrecisionInfo("ACCURACY", "±0.5°"),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            const Text(
              "Location Permission Required",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Grant location permission to use the compass feature",
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initCompass,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Grant Permission"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibratingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 20),
          Text(
            "Calibrating Compass...",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Move your device in a figure-8 pattern",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "Compass Error",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compass_calibration_rounded,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            "Compass Unavailable",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCardinalDirectionsOverlay() {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    const angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];

    return List.generate(8, (index) {
      return Transform.rotate(
        angle: (angles[index] * math.pi / 180),
        child: Align(
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, -152),
            child: Transform.rotate(
              angle: (-angles[index] * math.pi / 180),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: directions[index] == 'N'
                      ? Colors.red.withOpacity(0.9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  directions[index],
                  style: TextStyle(
                    color: directions[index] == 'N'
                        ? Colors.white
                        : Colors.grey.shade300,
                    fontSize: directions[index].length == 1 ? 14 : 10,
                    fontWeight: directions[index] == 'N'
                        ? FontWeight.bold
                        : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPrecisionInfo(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getDirectionLabel(double degree) {
    if (degree >= 337.5 || degree < 22.5) return "NORTH";
    if (degree >= 22.5 && degree < 67.5) return "NORTHEAST";
    if (degree >= 67.5 && degree < 112.5) return "EAST";
    if (degree >= 112.5 && degree < 157.5) return "SOUTHEAST";
    if (degree >= 157.5 && degree < 202.5) return "SOUTH";
    if (degree >= 202.5 && degree < 247.5) return "SOUTHWEST";
    if (degree >= 247.5 && degree < 292.5) return "WEST";
    if (degree >= 292.5 && degree < 337.5) return "NORTHWEST";
    return "";
  }
}

class DetailedCompassDialPainter extends CustomPainter {
  final double direction;

  DetailedCompassDialPainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerCirclePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final minorTickPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final tinyTickPaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw outer circle
    canvas.drawCircle(center, radius, outerCirclePaint);

    // Draw inner circles for reference
    for (int i = 1; i <= 3; i++) {
      final innerRadius = radius * 0.2 * i;
      canvas.drawCircle(
        center,
        innerRadius,
        Paint()
          ..color = Colors.white10
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Draw degree markers - every 1 degree with different sizes
    for (int i = 0; i < 360; i++) {
      final angle = i * math.pi / 180;
      final isMajor = i % 90 == 0; // N, E, S, W
      final isMedium = i % 45 == 0; // NE, SE, SW, NW
      final isMinor = i % 10 == 0; // Every 10 degrees
      final isTiny = i % 5 == 0; // Every 5 degrees
      final isMicro = i % 1 == 0; // Every degree

      double tickLength = 0;
      Paint? tickPaint;

      if (isMajor) {
        tickLength = 25;
        tickPaint = majorTickPaint;
      } else if (isMedium) {
        tickLength = 20;
        tickPaint = majorTickPaint..strokeWidth = 1.5;
      } else if (isMinor) {
        tickLength = 15;
        tickPaint = minorTickPaint;
      } else if (isTiny) {
        tickLength = 10;
        tickPaint = minorTickPaint..strokeWidth = 0.8;
      } else if (isMicro) {
        tickLength = 6;
        tickPaint = tinyTickPaint;
      }

      if (tickPaint != null) {
        final start = Offset(
          center.dx + (radius - tickLength) * math.cos(angle),
          center.dy + (radius - tickLength) * math.sin(angle),
        );

        final end = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );

        canvas.drawLine(start, end, tickPaint);
      }

      // Draw numbers for major and minor markers
      if (isMinor && i % 30 == 0) {
        // Every 30 degrees
        final textOffset = Offset(
          center.dx + (radius - 40) * math.cos(angle) - 10,
          center.dy + (radius - 40) * math.sin(angle) - 8,
        );

        textPaint.text = TextSpan(
          text: i.toString(),
          style: TextStyle(
            color: i == 0 ? Colors.redAccent : Colors.white70,
            fontSize: 12,
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.w500,
          ),
        );
        textPaint.layout();
        textPaint.paint(canvas, textOffset);
      }
    }

    // Draw cardinal direction lines
    final linePaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 360; i += 45) {
      final angle = i * math.pi / 180;
      final endX = center.dx + (radius - 30) * math.cos(angle);
      final endY = center.dy + (radius - 30) * math.sin(angle);

      canvas.drawLine(center, Offset(endX, endY), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
