import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/temparature_animation.dart';
import 'package:hikingapp/utils/loading_helper.dart';
import '../../../../data/models/weather_model.dart';
import '../../../../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Weather? weather;
  late WeatherService weatherService;
  bool isLoading = true;
  bool isOffline = false;
  bool isFahrenheit = false;

  @override
  void initState() {
    super.initState();
    weatherService = WeatherService();
    loadWeather();
  }

  Future<void> loadWeather() async {
    setState(() {
      isLoading = true;
      isOffline = false;
    });

    print("Checking connectivity...");
    final connectivityResult = await Connectivity().checkConnectivity();
    print("Connectivity: $connectivityResult");

    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
      return;
    }

    try {
      print("Checking location permissions...");
      LocationPermission permission = await Geolocator.checkPermission();
      print("Permission status: $permission");

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
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isOffline = true;
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Got position: ${position.latitude}, ${position.longitude}");

      final fetchedWeather = await weatherService.fetchWeatherByCoords(
        position.latitude,
        position.longitude,
      );
      print(
        "Weather fetched: ${fetchedWeather?.temperature}°F, ${fetchedWeather?.condition}",
      );

      setState(() {
        weather = fetchedWeather;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
    }
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'rain':
      case 'rainy':
        return Icons.cloud_circle;
      case 'clouds':
      case 'partly-cloudy':
        return Icons.cloud;
      default:
        return Icons.cloud;
    }
  }

  // Temperature conversion
  double get temperatureC => ((weather!.temperature - 32) * 5 / 9);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: LoadingHelper(
          imagePath: ImageLocation.loading, // your PNG asset
          size: 50,
        ),
      );
    }

    if (isOffline) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.signal_wifi_off, color: Colors.orange, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "No Connection!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Oh no, there is no internet connection. You are on your own on the trail. Be safe!",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E7B5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_rounded,
                  color: Color(0xFF3E7B5B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Current Weather",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3F3F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weather!.location,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF1C3F3F).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Fixed layout with proper constraints
          Row(
            children: [
              // Temperature Section - Wrapped in Expanded to prevent overflow
              Expanded(
                child: AnimatedTemperatureWidget(
                  temperatureF: weather!.temperature,
                  temperatureC: temperatureC,
                  isFahrenheit: isFahrenheit,
                  weatherIcon: getWeatherIcon(weather!.condition),
                  onTap: () {
                    setState(() {
                      isFahrenheit = !isFahrenheit;
                    });
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Weather Stats Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Humidity with icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop_rounded,
                        color: const Color(0xFF3E7B5B),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${weather!.humidity}%",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C3F3F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wind speed with icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.air_rounded,
                        color: const Color(0xFF3E7B5B),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${weather!.windSpeed}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C3F3F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
