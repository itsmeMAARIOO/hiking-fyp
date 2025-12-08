import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class CheckInInterestingCard extends StatefulWidget {
  final bool isLoading;
  final bool celebrate;
  final bool failed;
  final DateTime? lastCheckIn;
  final VoidCallback onCheckIn;

  const CheckInInterestingCard({
    super.key,
    required this.isLoading,
    required this.celebrate,
    required this.failed,
    required this.lastCheckIn,
    required this.onCheckIn,
  });

  @override
  State<CheckInInterestingCard> createState() => _CheckInInterestingCardState();
}

class _CheckInInterestingCardState extends State<CheckInInterestingCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _successController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _successController, curve: Curves.easeInOut),
        );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void didUpdateWidget(CheckInInterestingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate && !oldWidget.celebrate) {
      _successController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onCheckIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 130,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.failed
                ? [Colors.red.shade700, Colors.red.shade400]
                : widget.celebrate
                    ? [kDeepForest, Colors.green.shade600]
                    : [kDeepTeal, kDeepForest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: (widget.failed
                      ? Colors.red.shade700
                      : (widget.celebrate ? Colors.green : kDeepForest))
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                Icons.verified_user_outlined,
                size: 140,
                color: Colors.white.withOpacity(0.05),
              ),
            ),

            if (!widget.celebrate && !widget.failed)
              Positioned(
                left: 24,
                top: 35,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.3 * _pulseController.value,
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (widget.celebrate && !widget.failed)
              Positioned(
                left: 5,
                top: 15,
                child: AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(100, 100),
                      painter: RipplePainter(
                        progress: _rippleAnimation.value,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: widget.celebrate
                        ? _scaleAnimation
                        : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.failed
                          ? Colors.white
                          : (widget.celebrate ? kSoftMint : Colors.white),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: kDeepForest,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(
                            widget.failed
                                ? Icons.error_outline_rounded
                                : (widget.celebrate
                                    ? Icons.check_rounded
                                    : Icons.fingerprint),
                            color: widget.failed
                                ? Colors.red.shade700
                                : kDeepForest,
                            size: 32,
                          ),
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: widget.failed
                        ? _buildTextContent(
                            key: const ValueKey('Failed'),
                            label: "Check-In",
                            title: "Failed to Check In",
                            titleColor: Colors.white,
                            subtitle: "No connection is found",
                          )
                        : widget.celebrate
                            ? _buildTextContent(
                                key: const ValueKey('Success'),
                                label: "We Got You",
                                title: "Log Successful",
                                titleColor: Colors.white,
                                subtitle:
                                    _formatCheckInTime(widget.lastCheckIn),
                              )
                            : _buildTextContent(
                                key: const ValueKey('Idle'),
                                label: "Joining Group?",
                                title: "Tap to Check In",
                                titleColor: Colors.white,
                                subtitle:
                                    _formatCheckInTime(widget.lastCheckIn),
                              ),
                  ),
                ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white30,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent({
    required Key key,
    required String label,
    required String title,
    required Color titleColor,
    required String subtitle,
  }) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: kSoftMint,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  String _formatCheckInTime(DateTime? dt) {
    if (dt == null) return "No logs yet";
    final adjusted = dt.toUtc().add(const Duration(hours: 8));
    return "${adjusted.hour.toString().padLeft(2, '0')}:${adjusted.minute.toString().padLeft(2, '0')} • ${adjusted.day}/${adjusted.month}";
  }
}

class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withOpacity((1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1.0 - progress);

    final double maxRadius = size.width;
    final double radius = maxRadius * progress;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
