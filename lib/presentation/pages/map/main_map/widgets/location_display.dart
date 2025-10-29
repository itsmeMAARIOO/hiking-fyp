import 'package:flutter/material.dart';
import 'dart:math' as math;

class LocationDisplay extends StatefulWidget {
  final Map<String, double>? location;

  const LocationDisplay({super.key, this.location});

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.location == null) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFA0D5B9).withOpacity(0.15),
                  const Color(0xFF6BAF89).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFA0D5B9).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: OrganicPatternPainter(
                        animation: _pulseAnimation,
                      ),
                    ),
                  ),
                  // Glass morphism overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: _isExpanded ? 16 : 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactHeader(),
                        if (_isExpanded) ...[
                          const SizedBox(height: 16),
                          _buildExpandedContent(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF3E7B5B).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF6BAF89).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Color(0xFF1C3F3F),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6BAF89),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6BAF89).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GPS Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6BAF89),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.location!['latitude']!.toStringAsFixed(4)}°, ${widget.location!['longitude']!.toStringAsFixed(4)}°',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C3F3F),
                ),
              ),
            ],
          ),
        ),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF6BAF89).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: const Color(0xFF3E7B5B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.terrain,
                label: "Altitude",
                value: widget.location!['altitude']?.toStringAsFixed(0) ?? '0',
                unit: "ft",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.explore,
                label: "Accuracy",
                value: widget.location!['accuracy']?.toStringAsFixed(1) ?? '0',
                unit: "m",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildAccuracyBar(),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    String? unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFA0D5B9).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF3E7B5B), size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E7B5B).withOpacity(0.7),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3F3F),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6BAF89),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyBar() {
    final accuracy = widget.location!['accuracy'] ?? 0;
    final accuracyPercent = (accuracy / 50).clamp(0.0, 1.0);
    final color = Color.lerp(
      const Color(0xFF6BAF89),
      const Color(0xFFA0D5B9),
      accuracyPercent,
    )!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFA0D5B9).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.my_location, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'Signal Quality',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3E7B5B).withOpacity(0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Text(
                '${accuracy.toStringAsFixed(1)} m',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3F3F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA0D5B9).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor:
                          (1 - accuracyPercent) * 0.95 +
                          (0.05 * (_pulseAnimation.value - 0.95) / 0.1),
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFA0D5B9).withOpacity(0.15),
            const Color(0xFF6BAF89).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFA0D5B9).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6BAF89).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore,
                color: Color(0xFF3E7B5B),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Acquiring Location',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF1C3F3F),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Connecting to GPS...',
                style: TextStyle(
                  fontSize: 9,
                  color: const Color(0xFF6BAF89),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrganicPatternPainter extends CustomPainter {
  final Animation<double> animation;

  OrganicPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6BAF89).withOpacity(0.04);

    final path = Path();

    for (var i = 0; i < 2; i++) {
      final offset = (animation.value + i * 0.4) * math.pi * 2;
      final x = size.width * (0.3 + i * 0.4);
      final y = size.height * 0.5 + math.sin(offset) * 15;

      path.addOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 40 + math.sin(offset) * 8,
          height: 40 + math.cos(offset) * 8,
        ),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(OrganicPatternPainter oldDelegate) => true;
}
