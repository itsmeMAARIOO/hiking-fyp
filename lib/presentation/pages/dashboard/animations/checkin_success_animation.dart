import 'package:flutter/material.dart';

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

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _glow = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          clipBehavior: Clip.none,
          children: [
            // Glow effect behind the widget (doesn't affect layout)
            Positioned.fill(
              child: Positioned.fill(
                child: IgnorePointer(
                  // ensure it doesn’t block touches
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(
                            _controller.value * 0.5,
                          ),
                          blurRadius: _glow.value,
                          spreadRadius: _glow.value / 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // The actual child (scaled, but layout-safe)
            Transform.scale(scale: _scale.value, child: child),
          ],
        );
      },
    );
  }
}
