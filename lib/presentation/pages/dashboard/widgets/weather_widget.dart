import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/services/weather_service.dart';
import 'package:hikingapp/data/models/weather_model.dart';

// --- LOCAL THEME CONSTANTS ---
// Defined here to ensure the specific "Mint & Air" look works instantly
const Color kDarkSlate = Color(0xFF263238);
const Color kSoftMint = Color(0xFFa0d5b9);

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  Weather? weather;
  late WeatherService weatherService;
  bool isLoading = true;
  bool isOffline = false;
  bool isFahrenheit = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    weatherService = WeatherService();

    // Initial entrance animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    loadWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadWeather() async {
    setState(() {
      isLoading = true;
      isOffline = false;
    });
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
      return;
    }
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isOffline = true;
            isLoading = false;
          });
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final fetchedWeather = await weatherService.fetchWeatherByCoords(
        position.latitude,
        position.longitude,
      );
      setState(() {
        weather = fetchedWeather;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
    }
  }

  WeatherCondition getWeatherCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return WeatherCondition(
        icon: Icons.wb_sunny_rounded,
        conditionText: 'Sunny',
        description: 'Perfect day for hiking!\nClear skies ahead.',
        iconColor: kDeepOrange,
      );
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle')) {
      return WeatherCondition(
        icon: Icons.cloudy_snowing,
        conditionText: 'Rainy',
        description: 'Rain expected.\nConsider waterproof gear.',
        iconColor: kDeepBlue,
      );
    } else if (lowerCondition.contains('cloud') ||
        lowerCondition.contains('overcast')) {
      return WeatherCondition(
        icon: Icons.cloud_rounded,
        conditionText: 'Cloudy',
        description: 'Partly cloudy.\nGreat hiking conditions.',
        iconColor: kDeepGrey,
      );
    } else if (lowerCondition.contains('storm') ||
        lowerCondition.contains('thunder')) {
      return WeatherCondition(
        icon: Icons.flash_on_rounded,
        conditionText: 'Stormy',
        description: 'Storm warning.\nConsider postponing hike.',
        iconColor: kDeepGrey,
      );
    } else {
      return WeatherCondition(
        icon: Icons.cloud_rounded,
        conditionText: condition,
        description: 'Good conditions for outdoor activities.',
        iconColor: kDeepGrey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || isOffline) {
      return _buildWeatherContent();
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildWeatherContent(),
    );
  }

  Widget _buildWeatherContent() {
    if (isLoading) {
      return _buildPlaceholder(
        const CircularProgressIndicator(color: kDeepForest),
      );
    }
    if (isOffline) {
      return _buildPlaceholder(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kDeepForest.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.wifi_off_rounded, color: kDeepForest, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'No Connection',
                    style: TextStyle(
                      color: kDeepForest,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Please try again later.',
                style: TextStyle(
                  color: kDeepForest,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final weatherCondition = getWeatherCondition(weather!.condition);
    final tempF = weather!.temperature;
    final tempC = (tempF - 32) * 5 / 9;

    return Container(
      width: double.infinity,
      height: 290, // Tall hero size to fill screen
      padding: const EdgeInsets.all(24),
      decoration: _etherealDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: Location & Icon ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationTag(weather!.location),
              Icon(weatherCondition.icon, size: 36, color: kDeepForest),
            ],
          ),

          const Spacer(),

          // --- 3D FLIP TEMPERATURE SECTION ---
          // Tap to swap F and C with a Scoreboard Flip animation
          GestureDetector(
            onTap: () => setState(() => isFahrenheit = !isFahrenheit),
            child: Container(
              color: Colors.transparent, // Ensures hit test works
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                // Use a nice bouncy curve for the flip landing
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                // The Builder creates the 3D Rotation
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // Rotate from -90deg (top) to 0deg (flat)
                  final rotateAnim = Tween<double>(
                    begin: -math.pi / 2,
                    end: 0.0,
                  ).animate(animation);

                  return AnimatedBuilder(
                    animation: rotateAnim,
                    child: child,
                    builder: (context, child) {
                      final val = rotateAnim.value;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspective
                          ..rotateX(val),
                        child: FadeTransition(
                          opacity: animation, // Fade in while flipping
                          child: child,
                        ),
                      );
                    },
                  );
                },
                // We switch between two layouts based on isFahrenheit
                child: isFahrenheit
                    ? _buildTempRow(
                        key: const ValueKey('F_Active'),
                        mainVal: tempF.toStringAsFixed(0),
                        mainUnit: "°F",
                        subVal: tempC.toStringAsFixed(0),
                        subUnit: "C",
                      )
                    : _buildTempRow(
                        key: const ValueKey('C_Active'),
                        mainVal: tempC.toStringAsFixed(0),
                        mainUnit: "°C",
                        subVal: tempF.toStringAsFixed(0),
                        subUnit: "F",
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Condition & Description ---
          Text(
            weatherCondition.conditionText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kDarkSlate,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            weatherCondition.description,
            style: TextStyle(
              fontSize: 14,
              color: kDarkSlate.withOpacity(0.7),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // --- Bottom Stats ---
          Row(
            children: [
              _stat(Icons.water_drop_rounded, "${weather!.humidity}%"),
              const SizedBox(width: 24),
              _stat(Icons.air_rounded, "${weather!.windSpeed} mph"),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build the row with Active Left / Inactive Right
  Widget _buildTempRow({
    required Key key,
    required String mainVal,
    required String mainUnit,
    required String subVal,
    required String subUnit,
  }) {
    return Row(
      key: key, // Important for AnimatedSwitcher
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // 1. THE ACTIVE UNIT (Left, Big, Bold)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mainVal,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: kDarkSlate,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                mainUnit,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kDarkSlate.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Divider
        Text(
          "/",
          style: TextStyle(
            fontSize: 30,
            color: kDarkSlate.withOpacity(0.2),
            fontWeight: FontWeight.w300,
          ),
        ),

        const SizedBox(width: 12),

        // 2. THE INACTIVE UNIT (Right, Small, Faded)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "$subVal°$subUnit",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: kDarkSlate.withOpacity(0.3), // Faded
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTag(String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: kDeepForest.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kDeepForest.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            location.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String txt) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kDeepForest.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          txt,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kDeepForest,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Widget child) {
    return Container(
      height: 320,
      decoration: _etherealDeco(),
      child: Center(child: child),
    );
  }

  // The "Mint & Air" Decoration
  BoxDecoration _etherealDeco() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [kSoftMint.withOpacity(0.3), Colors.white.withOpacity(0.4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: kDeepForest.withOpacity(0.08),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class WeatherCondition {
  final IconData icon;
  final String conditionText;
  final String description;
  final Color iconColor;

  WeatherCondition({
    required this.icon,
    required this.conditionText,
    required this.description,
    required this.iconColor,
  });
}
