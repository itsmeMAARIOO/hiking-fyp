import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FallSensitivity { low, medium, high }

class FallDetectionService {
  late Interpreter _interpreter;
  late StreamSubscription _accelSub;
  late StreamSubscription _gyroSub;

  bool _initialized = false;
  bool _running = false;
  bool enableDebug = true;
  bool _modelAvailable = false;

  FallSensitivity _sensitivity = FallSensitivity.medium;
  double _modelThreshold = 0.5;
  double _freefallThreshold = 2.5;
  double _impactThreshold = 28.0;

  final List<double> _accData = [0, 0, 0];
  final List<double> _gyroData = [0, 0, 0];
  final StreamController<bool> _fallStreamController =
      StreamController.broadcast();

  Stream<bool> get fallStream => _fallStreamController.stream;

  Future<void> setSensitivity(FallSensitivity s) async {
    _sensitivity = s;
    _applySensitivity();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fall_sensitivity', s.name);
    } catch (_) {}
  }

  void _applySensitivity() {
    switch (_sensitivity) {
      case FallSensitivity.low:
        _modelThreshold = 0.92;
        _freefallThreshold = 1.5;
        _impactThreshold = 36.0;
        break;
      case FallSensitivity.medium:
        _modelThreshold = 0.55;
        _freefallThreshold = 2.5;
        _impactThreshold = 28.0;
        break;
      case FallSensitivity.high:
        _modelThreshold = 0.35;
        _freefallThreshold = 3.8;
        _impactThreshold = 20.0;
        break;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/fall_detection_model.tflite',
      );
      _modelAvailable = true;
      _initialized = true;
    } catch (e) {
      // On web or missing model, initialization can fail. Don't crash the app.

      // Continue with fallback; still mark initialized so sensors can subscribe
      _initialized = true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('fall_sensitivity');
      if (saved != null) {
        switch (saved) {
          case 'low':
            _sensitivity = FallSensitivity.low;
            break;
          case 'high':
            _sensitivity = FallSensitivity.high;
            break;
          default:
            _sensitivity = FallSensitivity.medium;
        }
      }
    } catch (_) {}
    _applySensitivity();

    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      _accData[0] = event.x;
      _accData[1] = event.y;
      _accData[2] = event.z;
      try {
        if (_modelAvailable) {
          _runModel();
        } else {
          _runFallbackHeuristic();
        }
      } catch (e) {
        if (enableDebug) {
          SnackbarHelper.showError('Fall Detection', '❌ Model run error: $e');
        }
      }
    });

    _gyroSub = gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroData[0] = event.x;
      _gyroData[1] = event.y;
      _gyroData[2] = event.z;
    });

    _running = true;
  }

  void _runModel() {
    final input = [
      [
        _accData[0],
        _accData[1],
        _accData[2],
        _gyroData[0],
        _gyroData[1],
        _gyroData[2],
        0.0,
        0.0,
        0.0,
      ],
    ];

    final output = List.filled(1, 0.0).reshape([1, 1]);
    _interpreter.run(input, output);

    final modelFall = output[0][0] > _modelThreshold;

    bool finalFall = modelFall;
    if (_sensitivity == FallSensitivity.low ||
        _sensitivity == FallSensitivity.high) {
      final mag = math.sqrt(
        _accData[0] * _accData[0] +
            _accData[1] * _accData[1] +
            _accData[2] * _accData[2],
      );
      final now = DateTime.now();
      const windowMs = 800;
      if (_freefallAt == null && mag < _freefallThreshold) {
        _freefallAt = now;
      }
      bool heuristicFall = false;
      if (_freefallAt != null) {
        final elapsed = now.difference(_freefallAt!).inMilliseconds;
        if (elapsed <= windowMs && mag > _impactThreshold) {
          heuristicFall = true;
          _freefallAt = null;
        } else if (elapsed > windowMs) {
          _freefallAt = null;
        }
      }
      if (_sensitivity == FallSensitivity.low) {
        finalFall = modelFall && heuristicFall;
      } else {
        finalFall = modelFall || heuristicFall;
      }
    }

    _fallStreamController.add(finalFall);
  }

  void dispose() {
    try {
      _accelSub.cancel();
      _gyroSub.cancel();
    } catch (_) {}
    _running = false;
    _fallStreamController.close();
  }

  bool get isRunning => _running;

  // --- Fallback heuristic: freefall followed by impact within window ---
  DateTime? _freefallAt;
  void _runFallbackHeuristic() {
    final mag = math.sqrt(
      _accData[0] * _accData[0] +
          _accData[1] * _accData[1] +
          _accData[2] * _accData[2],
    );

    final now = DateTime.now();
    final freefallThreshold = _freefallThreshold; // ~0.25g
    final impactThreshold = _impactThreshold; // ~2.85g
    const windowMs = 800; // ms

    if (_freefallAt == null && mag < freefallThreshold) {
      _freefallAt = now;
    }

    if (_freefallAt != null) {
      final elapsed = now.difference(_freefallAt!).inMilliseconds;
      if (elapsed <= windowMs && mag > impactThreshold) {
        _fallStreamController.add(true);
        _freefallAt = null;
      } else if (elapsed > windowMs) {
        _freefallAt = null; // reset after window
        _fallStreamController.add(false);
      } else {
        _fallStreamController.add(false);
      }
    } else {
      _fallStreamController.add(false);
    }
  }
}
