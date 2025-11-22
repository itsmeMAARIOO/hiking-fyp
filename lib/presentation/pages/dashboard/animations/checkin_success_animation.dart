import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart'; // Ensure this is imported

class CheckInSuccessAnimation extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const CheckInSuccessAnimation({
    super.key,
    required this.child,
    required this.trigger,
  });

  @override
  State<CheckInSuccessAnimation> createState() =>
      _CheckInSuccessAnimationState();
}

class _CheckInSuccessAnimationState extends State<CheckInSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Button "Pop" effect
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.15, // Slightly punchier pop
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Glow Pulse
    _glow = Tween<double>(
      begin: 0,
      end: 20, // Larger range for visibility
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
  }

  @override
  void didUpdateWidget(CheckInSuccessAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none, // Allow glow to expand beyond bounds
          children: [
            // --- 1. The Glow Effect ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape:
                      BoxShape.circle, // <--- CRITICAL FIX: Makes glow circular
                  boxShadow: [
                    // Inner intense glow (Orange)
                    BoxShadow(
                      color: kDeepForest.withOpacity(
                        (_controller.value * 0.6).clamp(0.0, 1.0),
                      ),
                      blurRadius: _glow.value,
                      spreadRadius: _glow.value * 0.5,
                    ),
                    // Outer soft halo (Forest/Teal) for depth
                    BoxShadow(
                      color: kDeepForest.withOpacity(
                        (_controller.value * 0.3).clamp(0.0, 1.0),
                      ),
                      blurRadius: _glow.value * 2,
                      spreadRadius: _glow.value,
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. The Button (Scaled) ---
            Transform.scale(scale: _scale.value, child: child),
          ],
        );
      },
    );
  }
}
