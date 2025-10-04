// lib/core/constants/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get mongoUrl => dotenv.env['MONGO_URI'] ?? '';
  static String get openWeatherApi => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static String get usersCollection => "users"; // safe constant
  static String get checkinCollection => "checkins"; // safe constant
}
