import 'package:flutter/material.dart';

class LoadingHelper extends StatefulWidget {
  final String imagePath;
  final double size;

  const LoadingHelper({super.key, required this.imagePath, this.size = 50});

  @override
  State<LoadingHelper> createState() => _LoadingHelperState();
}

class _LoadingHelperState extends State<LoadingHelper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.2,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Image.asset(
        widget.imagePath,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
