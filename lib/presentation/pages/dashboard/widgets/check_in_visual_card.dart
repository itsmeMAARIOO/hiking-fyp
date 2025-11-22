import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/checkin_success_animation.dart';

class CheckInVisualCard extends StatefulWidget {
  final bool isLoading;
  final bool celebrate;
  final DateTime? lastCheckIn;
  final VoidCallback onCheckIn;
  final bool showTime;
  final bool showButton;

  const CheckInVisualCard({
    super.key,
    required this.isLoading,
    required this.celebrate,
    required this.lastCheckIn,
    required this.onCheckIn,
    this.showTime = true,
    this.showButton = true,
  });

  @override
  State<CheckInVisualCard> createState() => _CheckInVisualCardState();
}

class _CheckInVisualCardState extends State<CheckInVisualCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), // Slightly smoother rotation
    );
  }

  @override
  void didUpdateWidget(CheckInVisualCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadingController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _glassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            // -----------------------------------------------------
            // LEFT SIDE — TEXT INFO
            // -----------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LAST CHECK-IN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCheckInTime(widget.lastCheckIn),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // -----------------------------------------------------
            // RIGHT SIDE — FROSTED BUTTON
            // -----------------------------------------------------
            if (widget.showButton) _buildCheckInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    const double size = 70;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Loading Arc (Behind or Around)
          if (widget.isLoading)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _loadingController.value * 2 * pi,
                    child: CustomPaint(
                      painter: _LoadingRingPainter(
                        color: Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            ),

          // 2. The Main Button
          CheckInSuccessAnimation(
            trigger: widget.celebrate,
            child: Container(
              width:
                  size *
                  0.8, // Slightly smaller than container to allow loading ring space
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2), // Frosted glass look
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onCheckIn,
                  customBorder: const CircleBorder(),
                  splashColor: Colors.white.withOpacity(0.3),
                  child: Center(
                    // 3. Gradient Icon
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [kDeepForest, kDeepTeal], // Reverse of BG
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Icon(Icons.location_on_rounded, size: size * 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FORMATTING LOGIC ---
  String _formatCheckInTime(DateTime? dt) {
    if (dt == null) return 'Start your hike';
    // Adjusting logic: removed manual +8 hours assuming local time is handled elsewhere
    // If you need UTC+8 specifically, keep the .add(Duration(hours: 8))
    final adjusted = dt;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // PadLeft helper
    String two(int n) => n.toString().padLeft(2, '0');

    final day = two(adjusted.day);
    final mon = months[adjusted.month - 1];
    final time = '${two(adjusted.hour)}:${two(adjusted.minute)}';

    // Cleaner format: "12 Oct, 08:30"
    return '$day $mon, $time';
  }

  // --- CONTAINER DESIGN ---
  Widget _glassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28), // Softer corners
        boxShadow: [
          BoxShadow(
            color: kDeepForest.withOpacity(0.3), // Colored shadow matches theme
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kDeepForest.withOpacity(0.9),
                  kDeepOrange.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// --- PAINTER FOR LOADING SPINNER ---
class _LoadingRingPainter extends CustomPainter {
  final Color color;
  final double width;

  _LoadingRingPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius fits strictly within the size
    final radius = (size.width / 2) - 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    // Create a gradient shader for the spinner itself
    final rect = Rect.fromCircle(center: center, radius: radius);
    paint.shader = SweepGradient(
      colors: [Colors.transparent, color.withOpacity(0.1), color],
      stops: const [0.0, 0.5, 1.0],
      startAngle: 0.0,
      endAngle: pi * 2,
      transform: const GradientRotation(-pi / 2), // Start from top
    ).createShader(rect);

    // Draw full circle with gradient
    canvas.drawArc(rect, 0, pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _LoadingRingPainter old) => true;
}
