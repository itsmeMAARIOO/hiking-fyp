import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Ensure this is imported
import 'app.dart';
import 'package:hikingapp/services/notification_service.dart';
import 'package:hikingapp/services/weather_alert_service.dart';
import 'package:background_fetch/background_fetch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await NotificationService.initialize();

  BackgroundFetch.registerHeadlessTask(weatherBackgroundFetchHeadless);

  runApp(const MyApp());
}
