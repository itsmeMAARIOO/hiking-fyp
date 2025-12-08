import 'package:flutter/material.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/services/fall_detection_service.dart';

class EmergencyButton extends StatefulWidget {
  const EmergencyButton({super.key});

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _rotationController]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: emergencyProvider.sosActive
                            ? [
                                Colors.red.shade300.withOpacity(0.3),
                                Colors.red.shade600.withOpacity(0.1),
                                Colors.red.shade300.withOpacity(0.3),
                              ]
                            : [
                                kSoftMint.withOpacity(0.3),
                                kMediumSage.withOpacity(0.1),
                                kSoftMint.withOpacity(0.3),
                              ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Middle pulse ring
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: emergencyProvider.sosActive
                          ? Colors.red.withOpacity(0.1)
                          : kMediumSage.withOpacity(0.1),
                      border: Border.all(
                        color: emergencyProvider.sosActive
                            ? Colors.red.withOpacity(0.3)
                            : kMediumSage.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Main button with glassmorphic effect
                GestureDetector(
                  onTap: () => emergencyProvider.triggerSOS(context),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: emergencyProvider.sosActive
                            ? [Colors.red.shade700, Colors.red.shade900]
                            : [kDeepForest, kDeepTeal],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: emergencyProvider.sosActive
                              ? Colors.red.withOpacity(0.4)
                              : kDeepForest.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Inner glow
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Icon or inline countdown
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (emergencyProvider.isCountingDown)
                              Text(
                                '${emergencyProvider.countdownRemaining}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              )
                            else
                              Icon(
                                emergencyProvider.sosActive
                                    ? Icons.close_rounded
                                    : Icons.warning_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              emergencyProvider.sosActive ||
                                      emergencyProvider.isCountingDown
                                  ? "CANCEL"
                                  : "SOS",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.sensors_rounded, size: 18, color: kDeepTeal),
                  SizedBox(width: 8),
                  Text(
                    'Sensitivity',
                    style: TextStyle(
                      fontSize: 13,
                      color: kDeepTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ThemeRadio(
                    label: 'Low',
                    selected:
                        emergencyProvider.fallSensitivity ==
                        FallSensitivity.low,
                    onTap: () => emergencyProvider.setFallSensitivity(
                      FallSensitivity.low,
                    ),
                  ),
                  const SizedBox(width: 26),
                  _ThemeRadio(
                    label: 'Medium',
                    selected:
                        emergencyProvider.fallSensitivity ==
                        FallSensitivity.medium,
                    onTap: () => emergencyProvider.setFallSensitivity(
                      FallSensitivity.medium,
                    ),
                  ),
                  const SizedBox(width: 26),
                  _ThemeRadio(
                    label: 'High',
                    selected:
                        emergencyProvider.fallSensitivity ==
                        FallSensitivity.high,
                    onTap: () => emergencyProvider.setFallSensitivity(
                      FallSensitivity.high,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeRadio extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ThemeRadio> createState() => _ThemeRadioState();
}

class _ThemeRadioState extends State<_ThemeRadio>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = kDeepTeal;
    final accent = kMediumSage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(2, 5),
                      ),
                    ],
                    border: widget.selected
                        ? Border.all(color: accent, width: 2)
                        : null,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: widget.selected ? 1.0 : 0.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.selected ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kDeepTeal,
          ),
        ),
      ],
    );
  }
}
