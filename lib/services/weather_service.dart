import 'dart:convert';
import 'package:hikingapp/core/constants/env.dart';
import 'package:http/http.dart' as http;
import '../data/models/weather_model.dart';

class WeatherService {
  Future<Weather?> fetchWeatherByCoords(double lat, double lon) async {
    final apiKey = Env.openWeatherApi;
    if (apiKey.isEmpty) {
      throw Exception('OpenWeather API key not found in environment.');
    }

    final url = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'appid': apiKey,
      'units': 'imperial', // or 'metric' for Celsius
    });

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Weather.fromJson(data);
    } else {
      throw Exception('Weather fetch failed: ${res.statusCode} ${res.body}');
    }
  }
}
