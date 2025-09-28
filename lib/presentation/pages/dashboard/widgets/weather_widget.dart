import 'package:flutter/material.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final weather = {
      'condition': 'partly-cloudy',
      'temperature': 72,
      'humidity': 65,
      'windSpeed': 8,
      'location': 'Mt. Wilson Trail',
    };

    IconData getWeatherIcon() {
      switch (weather['condition']) {
        case 'sunny':
          return Icons.wb_sunny;
        case 'rainy':
          return Icons.cloud_circle;
        default:
          return Icons.cloud;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Current Weather",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          Text(
            "weather['location']!",
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B7355)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    getWeatherIcon(),
                    size: 24,
                    color: const Color(0xFF95A5A6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${weather['temperature']}°F",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.thermostat,
                        size: 16,
                        color: Color(0xFF8B7355),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Humidity: ${weather['humidity']}%",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B7355),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.air, size: 16, color: Color(0xFF8B7355)),
                      const SizedBox(width: 6),
                      Text(
                        "Wind: ${weather['windSpeed']} mph",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B7355),
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
