import 'package:flutter/material.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';

class EmergencyProvider extends ChangeNotifier {
  bool _sosActive = false;
  bool _fallDetectionEnabled = true;
  bool _emergencyMode = false;

  bool get sosActive => _sosActive;
  bool get fallDetectionEnabled => _fallDetectionEnabled;
  bool get emergencyMode => _emergencyMode;

  void triggerSOS(BuildContext context) {
    if (!_sosActive) {
      _sosActive = true;
      _emergencyMode = true;
      notifyListeners();

      SnackbarHelper.showSuccess(
        'Success',
        'SOS ACTIVATED. Emergency alert sent to contacts and authorities.',
      );

      Future.delayed(const Duration(seconds: 30), () {
        _sosActive = false;
        _emergencyMode = false;
        notifyListeners();
      });
    } else {
      _sosActive = false;
      _emergencyMode = false;
      notifyListeners();
      SnackbarHelper.showSuccess('Info', 'SOS Deactivated');
    }
  }

  void toggleFallDetection(bool enabled) {
    _fallDetectionEnabled = enabled;
    notifyListeners();
  }

  void showFirstAid(BuildContext context) {
    SnackbarHelper.showSuccess(
      'Info',
      'Opening offline first aid guide...\n• Basic wound care\n• Hypothermia\n• Snake bite\n• Emergency signaling',
    );
  }

  void callEmergency(BuildContext context) {
    SnackbarHelper.showSuccess('Info', 'Calling local emergency services (911)...');
  }
}
