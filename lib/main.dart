import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart'; // root App widget
import 'package:hikingapp/services/notification_service.dart';
import 'package:hikingapp/services/weather_alert_service.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize local notifications and deep-link handling
  await NotificationService.initialize();

  BackgroundFetch.registerHeadlessTask(weatherBackgroundFetchHeadless);

  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('weather_alerts_enabled') ?? false;
  if (enabled) {
    await WeatherAlertService.enable();
  }

  runApp(const MyApp());
}
