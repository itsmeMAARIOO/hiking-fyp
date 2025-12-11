import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:get/get.dart';
import 'package:hikingapp/services/fall_detection_service.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hikingapp/config/api_config.dart';

class EmergencyProvider extends ChangeNotifier {
  bool _sosActive = false;
  bool _fallDetectionEnabled = true;
  FallSensitivity _fallSensitivity = FallSensitivity.medium;
  bool _emergencyMode = false;
  bool _isSendingLocation = false;

  // Alarm player (looped)
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();

  EmergencyProvider();

  // Inline countdown state
  Timer? _countdownTimer;
  int _countdownRemaining = 0;
  bool _isCountingDown = false;

  bool get sosActive => _sosActive;
  bool get fallDetectionEnabled => _fallDetectionEnabled;
  FallSensitivity get fallSensitivity => _fallSensitivity;
  bool get emergencyMode => _emergencyMode;
  bool get isCountingDown => _isCountingDown;
  int get countdownRemaining => _countdownRemaining;
  bool get isSendingLocation => _isSendingLocation;

  void triggerSOS(BuildContext context) {
    // If alarm is active, tapping cancels it
    if (_sosActive) {
      _stopAlarm();
      _sosActive = false;
      _emergencyMode = false;
      notifyListeners();
      return;
    }

    // If countdown is running, tapping cancels
    if (_isCountingDown) {
      _countdownTimer?.cancel();
      _isCountingDown = false;
      _countdownRemaining = 0;
      notifyListeners();
      return;
    }

    // Start 3-second inline countdown
    _isCountingDown = true;
    _countdownRemaining = 3;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      _countdownRemaining -= 1;
      if (_countdownRemaining <= 0) {
        t.cancel();
        _isCountingDown = false;
        notifyListeners();
        await _startAlarm();
      } else {
        notifyListeners();
      }
    });
  }

  void toggleFallDetection(bool enabled) {
    _fallDetectionEnabled = enabled;
    if (enabled) {
      _ensureFallDetectionListener();
    } else {
      _tearDownFallDetectionListener();
    }
    notifyListeners();
  }

  void setFallSensitivity(FallSensitivity s) {
    _fallSensitivity = s;
    if (_fallService != null) {
      _fallService!.setSensitivity(s);
    }
    notifyListeners();
  }

  void showFirstAid(BuildContext context) {
    Get.toNamed(AppRoutes.firstAid);
  }

  Future<void> callEmergency(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '999');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      SnackbarHelper.showError('Error', 'Unable to open dialer');
    }
  }

  Future<void> shareLocation(BuildContext context) async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      SnackbarHelper.showError('Error', 'User not logged in');
      return;
    }

    final contacts = profile.emergencyContacts
        .where((c) => (c['share'] ?? 'false') == 'true')
        .toList();
    if (contacts.isEmpty) {
      SnackbarHelper.showError(
        'Error',
        'No contacts enabled for location sharing',
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        SnackbarHelper.showError('Error', 'Location permission required');
        return;
      }
    }

    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      SnackbarHelper.showError('Error', 'Unable to get current location');
      return;
    }

    final base = ApiConfig.baseUrl;
    final startUrl = Uri.parse('$base/emergency/share/start');
    final payload = {
      'userId': userId,
      'contacts': contacts
          .map((c) => {'name': c['name'], 'email': c['email']})
          .toList(),
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };
    try {
      _isSendingLocation = true;
      notifyListeners();
      final resp = await http.post(
        startUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final emailSent = data['emailSent'] == true;
        final emailError = (data['emailError'] ?? '') as String;
        if (emailSent) {
          SnackbarHelper.showSuccess(
            'Location Sharing',
            'Email sent to selected contacts',
          );
        } else {
          final msg = emailError.isNotEmpty
              ? 'Email not sent: $emailError'
              : 'Email not sent';
          SnackbarHelper.showError('Location Sharing', msg);
        }
      } else {
        SnackbarHelper.showError('Error', 'Failed to start location sharing');
      }
    } catch (_) {
      SnackbarHelper.showError('Error', 'Network error starting sharing');
    } finally {
      _isSendingLocation = false;
      notifyListeners();
    }
  }

  Future<void> shareEmergencyLocation(BuildContext context) async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      SnackbarHelper.showError('Error', 'User not logged in');
      return;
    }

    final contacts = profile.emergencyContacts
        .where((c) => (c['share'] ?? 'false') == 'true')
        .toList();
    if (contacts.isEmpty) {
      SnackbarHelper.showError(
        'Emergency Location',
        'No contacts enabled for location sharing',
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        SnackbarHelper.showError('Error', 'Location permission required');
        return;
      }
    }

    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      SnackbarHelper.showError('Error', 'Unable to get current location');
      return;
    }

    final base = ApiConfig.baseUrl;
    final startUrl = Uri.parse('$base/emergency/share/start');
    final payload = {
      'userId': userId,
      'contacts': contacts
          .map((c) => {'name': c['name'], 'email': c['email']})
          .toList(),
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': DateTime.now().toIso8601String(),
      'emergency': true,
      'subject': 'EMERGENCY LOCATION ALERT',
      'theme': 'red',
    };
    try {
      _isSendingLocation = true;
      notifyListeners();
      final resp = await http.post(
        startUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final emailSent = data['emailSent'] == true;
        final emailError = (data['emailError'] ?? '') as String;
        if (emailSent) {
          SnackbarHelper.showSuccess(
            'Emergency Location',
            'Sent to selected contacts',
          );
        } else {
          final msg = emailError.isNotEmpty
              ? 'Email not sent: $emailError'
              : 'Email not sent';
          SnackbarHelper.showError('Emergency Location', msg);
        }
      } else {
        SnackbarHelper.showError('Error', 'Failed to start sharing');
      }
    } catch (_) {
      SnackbarHelper.showError('Error', 'Network error starting sharing');
    } finally {
      _isSendingLocation = false;
      notifyListeners();
    }
  }

  Future<void> shareSoloStartLocation(
    BuildContext context, {
    String? trailName,
    String? trailDescription,
    DateTime? expectedEndTime,
  }) async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      SnackbarHelper.showError('Error', 'User not logged in');
      return;
    }

    final contacts = profile.emergencyContacts
        .where((c) => (c['share'] ?? 'false') == 'true')
        .toList();
    if (contacts.isEmpty) {
      SnackbarHelper.showError(
        'Solo Start',
        'No contacts enabled for notifications',
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        SnackbarHelper.showError('Error', 'Location permission required');
        return;
      }
    }

    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      SnackbarHelper.showError('Error', 'Unable to get current location');
      return;
    }

    final base = ApiConfig.baseUrl;
    final startUrl = Uri.parse('$base/solo/notify/start');
    final payload = {
      'userId': userId,
      'contacts': contacts
          .map((c) => {'name': c['name'], 'email': c['email']})
          .toList(),
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': DateTime.now().toIso8601String(),
      'trailName': trailName,
      'trailDescription': trailDescription,
      'expectedEndTime': expectedEndTime?.toIso8601String(),
    };
    try {
      _isSendingLocation = true;
      notifyListeners();
      final resp = await http.post(
        startUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final emailSent = data['emailSent'] == true;
        final emailError = (data['emailError'] ?? '') as String;
        if (emailSent) {
          SnackbarHelper.showSuccess(
            'Solo Hike',
            'Notification sent to selected contacts',
          );
        } else {
          final msg = emailError.isNotEmpty
              ? 'Email not sent: $emailError'
              : 'Email not sent';
          SnackbarHelper.showError('Solo Hike', msg);
        }
      } else {
        SnackbarHelper.showError('Error', 'Failed to send notification');
      }
    } catch (_) {
      SnackbarHelper.showError('Error', 'Network error sending notification');
    } finally {
      _isSendingLocation = false;
      notifyListeners();
    }
  }

  Future<void> _startAlarm() async {
    _sosActive = true;
    _emergencyMode = true;
    notifyListeners();

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ap.ReleaseMode.loop);
      await _audioPlayer.play(ap.AssetSource('sounds/alarm2.mp3'));
      // Show a silent ongoing notification; tap navigates to Emergency page
      await NotificationService.silentNotification(
        title: 'Emergency Triggered',
        body: 'Tap to open Emergency page',
      );
      final ctx = Get.context;
      if (ctx != null) {
        await shareEmergencyLocation(ctx);
      }
    } catch (_) {
      SnackbarHelper.showError('Alarm', 'Unable to play alarm sound');
    }
  }

  void _stopAlarm() {
    try {
      _audioPlayer.stop();
    } catch (_) {}
    // Remove ongoing notification when SOS stops
    NotificationService.cancelEmergencyNotification();
  }

  // --- Fall Detection wiring ---
  FallDetectionService? _fallService;
  StreamSubscription<bool>? _fallSub;
  bool _fallListenerAttached = false;

  Future<void> _ensureFallDetectionListener() async {
    if (_fallListenerAttached && _fallService?.isRunning == true) return;
    _fallService ??= FallDetectionService();
    _fallService!.enableDebug = true;
    await _fallService!.init();
    await _fallService!.setSensitivity(_fallSensitivity);
    _fallSub?.cancel();
    _fallSub = _fallService!.fallStream.listen((isFalling) {
      if (!_fallDetectionEnabled) return;
      if (isFalling) {
        final ctx = Get.context;
        if (ctx != null) {
          triggerSOS(ctx);
        } else {
          _isCountingDown = false;
          _countdownRemaining = 0;
          _startAlarm();
        }
      }
    });
    _fallListenerAttached = true;
  }

  void _tearDownFallDetectionListener() {
    try {
      _fallSub?.cancel();
      _fallSub = null;
      _fallListenerAttached = false;
      _fallService?.dispose();
      _fallService = null;
    } catch (_) {}
  }

  // Default audio context is sufficient for mobile; custom context removed
}
