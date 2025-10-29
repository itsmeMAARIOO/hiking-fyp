import 'package:flutter/material.dart';

class AnimatedTemperatureWidget extends StatefulWidget {
  final double temperatureF;
  final double temperatureC;
  final bool isFahrenheit;
  final IconData weatherIcon;
  final VoidCallback onTap;

  const AnimatedTemperatureWidget({
    Key? key,
    required this.temperatureF,
    required this.temperatureC,
    required this.isFahrenheit,
    required this.weatherIcon,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedTemperatureWidget> createState() =>
      _AnimatedTemperatureWidgetState();
}

class _AnimatedTemperatureWidgetState extends State<AnimatedTemperatureWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedTemperatureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when temperature unit changes
    if (oldWidget.isFahrenheit != widget.isFahrenheit) {
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _triggerAnimation();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value < 0.5
                  ? 1.0
                  : _opacityAnimation.value,
              child: Row(
                children: [
                  Icon(widget.weatherIcon, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _buildTemperatureDisplay(),
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

  Widget _buildTemperatureDisplay() {
    final mainTemp = widget.isFahrenheit
        ? widget.temperatureF
        : widget.temperatureC;
    final swappedTemp = widget.isFahrenheit
        ? widget.temperatureC
        : widget.temperatureF;
    final mainUnit = widget.isFahrenheit ? '°F' : '°C';
    final swappedUnit = widget.isFahrenheit ? '°C' : '°F';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Main temperature
        Text(
          '${mainTemp.toStringAsFixed(1)}$mainUnit',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        // Swapped temperature (smaller)
        Text(
          '${swappedTemp.toStringAsFixed(1)}$swappedUnit',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
