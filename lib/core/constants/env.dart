// lib/core/constants/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get mongoUrl => dotenv.env['MONGO_URL'] ?? '';
  static String get usersCollection => "users"; // safe constant
}
