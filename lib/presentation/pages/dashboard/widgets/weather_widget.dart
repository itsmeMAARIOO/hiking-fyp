import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/temparature_animation.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/utils/loading_helper.dart';
import '../../../../data/models/weather_model.dart';
import '../../../../services/weather_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late Animation<Offset> _slideAnimation;
  TextStyle _apple(TextStyle base) => GoogleFonts.inter(textStyle: base);

  @override
  void initState() {
    super.initState();
    weatherService = WeatherService();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
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
      _animationController.forward();
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
          _animationController.forward();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isOffline = true;
          isLoading = false;
        });
        _animationController.forward();
        return;
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
      _animationController.forward();
    }
  }

  WeatherCondition getWeatherCondition(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return WeatherCondition(
        icon: Icons.wb_sunny_rounded,
        conditionText: 'Sunny',
        description: 'Perfect day for hiking!\nClear skies ahead.',
        iconColor: kDeepGrey,
      );
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle')) {
      return WeatherCondition(
        icon: Icons.cloudy_snowing,
        conditionText: 'Rainy',
        description: 'Rain expected.\nConsider waterproof gear.',
        iconColor: kDeepGrey,
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildWeatherContent(),
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (isLoading) {
      return _buildGradientContainer(
        colors: const [kWeatherRainy, kDeepBlue],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingHelper(imagePath: ImageLocation.loading, size: 60),
              const SizedBox(height: 16),
              Text(
                "Fetching weather...",
                style: _apple(
                  TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isOffline) {
      return _buildGradientContainer(
        colors: const [kWeatherCloudy, kDeepTeal],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.signal_wifi_off_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Offline Mode",
                      style: _apple(
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Weather data unavailable. Stay safe on the trail!",
                      style: _apple(
                        TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: loadWeather,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kWeatherRainy, kDeepBlue],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Try Again",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final weatherCondition = getWeatherCondition(weather!.condition);

    return _buildGradientContainer(
      colors: [kDeepTeal, kDeepForest],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CURRENT WEATHER",
                        style: _apple(
                          TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather!.location,
                        style: _apple(
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Weather condition badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        weatherCondition.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        weatherCondition.conditionText.toUpperCase(),
                        style: _apple(
                          const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                weatherCondition.description,
                textAlign: TextAlign.left,
                style: _apple(
                  TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Main content
            Row(
              children: [
                // Temperature section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedTemperatureWidget(
                        temperatureF: weather!.temperature,
                        temperatureC: temperatureC,
                        isFahrenheit: isFahrenheit,
                        weatherIcon: weatherCondition.icon,
                        onTap: () {
                          setState(() {
                            isFahrenheit = !isFahrenheit;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Stats section
                Column(
                  children: [
                    _buildWeatherStat(
                      Icons.water_drop_rounded,
                      "${weather!.humidity}%",
                      "Humidity",
                      Colors.white,
                    ),
                    const SizedBox(height: 16),
                    _buildWeatherStat(
                      Icons.air_rounded,
                      "${weather!.windSpeed} mph",
                      "Wind",
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientContainer({
    required Widget child,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWeatherStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: _apple(
                    TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get temperatureC => ((weather!.temperature - 32) * 5 / 9);
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
