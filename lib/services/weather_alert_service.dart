import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hikingapp/services/weather_service.dart';
import 'package:hikingapp/services/notification_service.dart';

class WeatherAlertService {
  static bool _enabled = false;

  static Future<void> enable() async {
    if (_enabled) return;
    _enabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_alerts_enabled', true);

    await _captureAndSaveLocation();

    // Clear any previous schedules before reconfiguring to avoid duplicates
    await BackgroundFetch.stop();

    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 120,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onFetch,
    );

    await BackgroundFetch.start();

    // Rely on OS-managed fetch cadence; no explicit repeating alarm
    await _checkAndNotify();
  }

  static Future<void> disable() async {
    _enabled = false;
    await BackgroundFetch.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_alerts_enabled', false);
  }

  static Future<void> _onFetch(String taskId) async {
    await _checkAndNotify();
    BackgroundFetch.finish(taskId);
  }

  static Future<void> _checkAndNotify() async {
    // Respect a 2-hour quiet period between alerts
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTs = await _loadLastNotifyTs();
    if (lastTs != null &&
        (now - lastTs) < const Duration(hours: 2).inMilliseconds) {
      return;
    }

    final (double? latSaved, double? lonSaved) = await _loadSavedCoords();
    double? lat = latSaved;
    double? lon = lonSaved;

    if (lat == null || lon == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = pos.latitude;
        lon = pos.longitude;
        await _saveCoords(lat, lon);
      } catch (_) {
        return;
      }
    }

    try {
      final weather = await WeatherService().fetchWeatherByCoords(lat!, lon!);
      if (weather == null) return;
      final cond = weather.condition.toLowerCase();
      final isSunny = cond.contains('sunny') || cond.contains('clear');
      if (!isSunny) {
        await NotificationService.invitationNotification(
          title: 'Weather Alert',
          body: 'Bad weather. Stay home',
        );
        await _saveLastNotifyTs(now);
      }
    } catch (_) {}
  }

  static Future<void> _captureAndSaveLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _saveCoords(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  static Future<void> _saveCoords(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weather_lat', lat);
    await prefs.setDouble('weather_lon', lon);
  }

  static Future<(double?, double?)> _loadSavedCoords() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('weather_lat');
    final lon = prefs.getDouble('weather_lon');
    return (lat, lon);
  }

  static Future<int?> _loadLastNotifyTs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('weather_last_notify_ts');
  }

  static Future<void> _saveLastNotifyTs(int ts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weather_last_notify_ts', ts);
  }
}

void weatherBackgroundFetchHeadless(HeadlessTask task) async {
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
    return;
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('weather_alerts_enabled') ?? false;
    if (enabled) {
      await WeatherAlertService._checkAndNotify();
    }
  } catch (_) {}
  BackgroundFetch.finish(task.taskId);
}
