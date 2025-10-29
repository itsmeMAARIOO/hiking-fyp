import 'package:flutter/material.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:hikingapp/presentation/styles/colors.dart';

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

                        // Icon
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              emergencyProvider.sosActive
                                  ? Icons.close_rounded
                                  : Icons.warning_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              emergencyProvider.sosActive ? "CANCEL" : "SOS",
                              style: TextStyle(
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

        const SizedBox(height: 24),

        // Status text with animated container
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: emergencyProvider.sosActive
                ? Colors.red.withOpacity(0.1)
                : kSoftMint.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: emergencyProvider.sosActive
                  ? Colors.red.withOpacity(0.3)
                  : kMediumSage.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emergencyProvider.sosActive
                    ? Icons.emergency
                    : Icons.touch_app_rounded,
                size: 18,
                color: emergencyProvider.sosActive
                    ? Colors.red.shade700
                    : kDeepForest,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  emergencyProvider.sosActive
                      ? 'Emergency alert active - Tap to cancel'
                      : 'Tap to trigger emergency alert',
                  style: TextStyle(
                    fontSize: 13,
                    color: emergencyProvider.sosActive
                        ? Colors.red.shade900
                        : kDeepTeal,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
