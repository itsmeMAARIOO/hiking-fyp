import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class HikingStatsLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> soloPoints;
  final List<Map<String, dynamic>> groupPoints;

  const HikingStatsLineChart({
    super.key,
    required this.soloPoints,
    required this.groupPoints,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        soloPoints: soloPoints,
        groupPoints: groupPoints,
      ),
      size: const Size(double.infinity, 180),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> soloPoints;
  final List<Map<String, dynamic>> groupPoints;

  _LineChartPainter({required this.soloPoints, required this.groupPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final padding = const EdgeInsets.fromLTRB(50, 16, 16, 36);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    _drawYAxis(canvas, chartRect);
    _drawXAxis(canvas, chartRect);

    _drawArea(canvas, chartRect, soloPoints, const Color(0xFF6BAF89).withOpacity(0.20));
    _drawArea(canvas, chartRect, groupPoints, const Color(0xFF3E7B5B).withOpacity(0.15));

    _drawLine(canvas, chartRect, soloPoints, kMediumSage);
    _drawLine(canvas, chartRect, groupPoints, kDeepForest);
  }

  void _drawYAxis(Canvas canvas, Rect chartRect) {
    final textStyle = TextStyle(
      color: kDeepTeal.withOpacity(0.6),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate max value for scaling
    final maxY = _calculateMaxY();

    // Y-axis labels and grid lines
    for (int i = 0; i <= 4; i++) {
      final value = (maxY * i / 4).round();
      final y = chartRect.bottom - (i / 4) * chartRect.height;

      // Draw grid line
      final gridPaint = Paint()
        ..color = kDeepTeal.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );

      // Draw Y-axis label
      textPainter.text = TextSpan(text: '$value', style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          chartRect.left - textPainter.width - 8,
          y - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawXAxis(Canvas canvas, Rect chartRect) {
    final textStyle = TextStyle(
      color: kDeepTeal.withOpacity(0.6),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final count = max(soloPoints.length, groupPoints.length);
    if (count == 0) return;
    final tickCount = 6;
    for (int i = 0; i < tickCount; i++) {
      final idx = ((i / (tickCount - 1)) * (count - 1)).round();
      final x = chartRect.left + (idx / max(1, count - 1)) * chartRect.width;
      final label = _labelAt(idx);
      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartRect.bottom + 10),
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Rect chartRect,
    List<Map<String, dynamic>> points,
    Color color,
  ) {
    if (points.isEmpty) return;

    final maxY = _calculateMaxY();
    final offsets = <Offset>[];

    final effectivePoints = points;

    for (int i = 0; i < effectivePoints.length; i++) {
      final y = (effectivePoints[i]['y'] as int) / max(1, maxY).toDouble();
      final x = i / max(1, effectivePoints.length - 1);
      final ox = chartRect.left + x * chartRect.width;
      final oy = chartRect.bottom - y * chartRect.height;
      offsets.add(Offset(ox, oy));
    }

    // Smooth cubic line
    final path = Path();
    path.moveTo(offsets.first.dx, offsets.first.dy);

    for (int i = 1; i < offsets.length; i++) {
      final p0 = offsets[i - 1];
      final p1 = offsets[i];
      final mx = (p0.dx + p1.dx) / 2;
      path.quadraticBezierTo(mx, p0.dy, p1.dx, p1.dy);
    }

    // Draw the line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, linePaint);

    // Draw data points as circles
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final offset in offsets) {
      canvas.drawCircle(offset, 4, dotPaint);
    }
  }

  void _drawArea(Canvas canvas, Rect chartRect, List<Map<String, dynamic>> points, Color color) {
    if (points.isEmpty) return;
    final maxY = _calculateMaxY();
    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final y = (points[i]['y'] as int? ?? 0) / max(1, maxY).toDouble();
      final x = i / max(1, points.length - 1);
      final ox = chartRect.left + x * chartRect.width;
      final oy = chartRect.bottom - y * chartRect.height;
      offsets.add(Offset(ox, oy));
    }
    if (offsets.isEmpty) return;
    final path = Path()
      ..moveTo(offsets.first.dx, chartRect.bottom);
    for (int i = 0; i < offsets.length; i++) {
      final o = offsets[i];
      path.lineTo(o.dx, o.dy);
    }
    path.lineTo(offsets.last.dx, chartRect.bottom);
    path.close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  List<Map<String, dynamic>> _ensureTwelveMonths(
    List<Map<String, dynamic>> points,
  ) {
    // If we have exactly 12 points, return as is
    if (points.length == 12) return points;

    // Otherwise create 12 months with zero values for missing months
    final List<Map<String, dynamic>> twelveMonths = [];
    for (int i = 0; i < 12; i++) {
      final existingPoint = points.firstWhere(
        (point) => point['x'] == i,
        orElse: () => {'x': i, 'y': 0},
      );
      twelveMonths.add(existingPoint);
    }
    return twelveMonths;
  }

  int _calculateMaxY() {
    int maxY = 1;
    for (final p in [...soloPoints, ...groupPoints]) {
      maxY = max(maxY, (p['y'] as int? ?? 0));
    }
    // Round up to nearest nice number for clean Y-axis labels
    if (maxY <= 5) return 5;
    if (maxY <= 10) return 10;
    if (maxY <= 20) return 20;
    if (maxY <= 50) return 50;
    return ((maxY + 9) ~/ 10) * 10;
  }

  String _labelAt(int idx) {
    final list = soloPoints.length >= groupPoints.length ? soloPoints : groupPoints;
    if (idx < 0 || idx >= list.length) return '';
    final l = (list[idx]['label'] ?? '').toString();
    return l;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
