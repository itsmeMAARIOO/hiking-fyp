import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;
import 'package:hikingapp/utils/snackbar_helper.dart';

class FallDetectionService {
  late Interpreter _interpreter;
  late StreamSubscription _accelSub;
  late StreamSubscription _gyroSub;

  bool _initialized = false;
  bool _running = false;
  bool enableDebug = true;
  bool _modelAvailable = false;

  // Hardcoded to max sensitivity (approx 100% confidence)
  final double _modelThreshold = 0.99999;
  // Heuristic thresholds kept for fallback if model is missing, but model is primary
  final double _freefallThreshold = 1.5;
  final double _impactThreshold = 36.0;

  final List<double> _accData = [0, 0, 0];
  final List<double> _gyroData = [0, 0, 0];
  final StreamController<bool> _fallStreamController =
      StreamController.broadcast();

  Stream<bool> get fallStream => _fallStreamController.stream;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/fall_detection_model_quant.tflite',
      );
      _modelAvailable = true;
      _initialized = true;
    } catch (e) {
      // fallback avoid app crash
      _initialized = true;
    }

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
          SnackbarHelper.showError('Fall Detection', 'Model run error: $e');
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

  int _consecutiveFallCount = 0;
  static const int _requiredConsecutiveFrames = 10;

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
        0.0,
      ],
    ];

    final output = List.filled(1, 0.0).reshape([1, 1]);
    _interpreter.run(input, output);

    final modelFallScore = output[0][0];
    final isCrossThreshold = modelFallScore > _modelThreshold;

    if (isCrossThreshold) {
      _consecutiveFallCount++;
    } else {
      _consecutiveFallCount = 0;
    }

    if (_consecutiveFallCount >= _requiredConsecutiveFrames) {
      // Trigger fall
      _fallStreamController.add(true);
    } else {
      _fallStreamController.add(false);
    }
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
