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
  bool isFahrenheit = true;

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

      final fetchedWeather = await weatherService.fetchWeatherByCoords(
        position.latitude,
        position.longitude,
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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 4,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Current Weather",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(weather!.location),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedTemperatureWidget(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Humidity: ${weather!.humidity}%"),
                  Text("Wind: ${weather!.windSpeed} mph"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
