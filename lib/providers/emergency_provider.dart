import 'package:flutter/material.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SOS ACTIVATED. Emergency alert sent to contacts and authorities.',
          ),
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SOS Deactivated')));
    }
  }

  void toggleFallDetection(bool enabled) {
    _fallDetectionEnabled = enabled;
    notifyListeners();
  }

  void showFirstAid(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Opening offline first aid guide...\n• Basic wound care\n• Hypothermia\n• Snake bite\n• Emergency signaling',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void callEmergency(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling local emergency services (911)...'),
      ),
    );
  }
}
