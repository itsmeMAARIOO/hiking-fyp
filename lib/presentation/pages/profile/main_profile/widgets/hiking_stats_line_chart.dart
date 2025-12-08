import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class HikingStatsLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> soloPoints;
  final List<Map<String, dynamic>> groupPoints;
  final Color colorSolo;
  final Color colorGroup;
  final String phase; // 'idle' | 'loading' | 'toChart'
  final double t; // animation progress 0..1
  final String period; // 'Month' | 'Year' | 'Week'

  const HikingStatsLineChart({
    super.key,
    required this.soloPoints,
    required this.groupPoints,
    required this.colorSolo,
    required this.colorGroup,
    this.phase = 'idle',
    this.t = 0,
    this.period = 'Month',
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeonChartPainter(
        soloPoints: soloPoints,
        groupPoints: groupPoints,
        colorSolo: colorSolo,
        colorGroup: colorGroup,
        phase: phase,
        t: t,
        period: period,
      ),
      size: const Size(double.infinity, 150),
    );
  }
}

class _NeonChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> soloPoints;
  final List<Map<String, dynamic>> groupPoints;
  final Color colorSolo;
  final Color colorGroup;
  final String phase;
  final double t;
  final String period;

  // Fixed styling colors
  static const Color gridColor = kDeepForest; // Subtle Grey-Green
  static const Color textColor = kDeepForest; // Light Blue-Grey

  _NeonChartPainter({
    required this.soloPoints,
    required this.groupPoints,
    required this.colorSolo,
    required this.colorGroup,
    required this.phase,
    required this.t,
    required this.period,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = const EdgeInsets.fromLTRB(30, 20, 20, 30);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // 1. Draw Grid
    _drawGridAndLabels(canvas, chartRect);

    if (phase == 'loading') {
      _drawLoadingCircle(canvas, chartRect, colorGroup, 0);
      _drawLoadingCircle(canvas, chartRect, colorSolo, pi / 2);
      return;
    }

    final drawGroup = groupPoints.isNotEmpty;
    final drawSolo = soloPoints.isNotEmpty;

    if (phase == 'toChart') {
      if (drawGroup) {
        _drawMorphPath(
          canvas,
          chartRect,
          groupPoints,
          colorGroup,
          t,
          behind: true,
        );
      }
      if (drawSolo) {
        _drawMorphPath(
          canvas,
          chartRect,
          soloPoints,
          colorSolo,
          t,
          behind: false,
        );
      }
      return;
    }

    if (drawGroup) {
      _drawSmoothPath(
        canvas,
        chartRect,
        groupPoints,
        colorGroup,
        isFilled: true,
      );
    }
    if (drawSolo) {
      _drawSmoothPath(canvas, chartRect, soloPoints, colorSolo, isFilled: true);
    }
  }

  void _drawGridAndLabels(Canvas canvas, Rect rect) {
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final maxY = _calculateMaxY();

    // Y Axis
    for (int i = 0; i <= 3; i++) {
      final value = (maxY * i / 3).round();
      final y = rect.bottom - (i / 3) * rect.height;

      // Dashed Grid
      final p1 = Offset(rect.left, y);
      final p2 = Offset(rect.right, y);
      _drawDashedLine(canvas, p1, p2, gridColor);

      // Labels
      if (i > 0) {
        // Don't draw 0 to keep it clean
        textPainter.text = TextSpan(text: '$value', style: textStyle);
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(rect.left - textPainter.width - 8, y - textPainter.height / 2),
        );
      }
    }

    final now = DateTime.now();
    if (period == 'Week') {
      final week = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      for (int i = 0; i < 7; i++) {
        final x = rect.left + (i / 6) * rect.width;
        textPainter.text = TextSpan(text: week[i], style: textStyle);
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, rect.bottom + 8),
        );
      }
    } else if (period == 'Month') {
      final end = now.day;
      final positions = <int>[1, ((end + 1) ~/ 2), end];
      for (int i = 0; i < positions.length; i++) {
        final idx = positions[i] - 1;
        final x = rect.left + (idx / max(1, end - 1)) * rect.width;
        final label = positions[i].toString();
        textPainter.text = TextSpan(text: label, style: textStyle);
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, rect.bottom + 8),
        );
      }
    } else {
      final count = max(soloPoints.length, groupPoints.length);
      if (count > 1) {
        final labelsToShow = [0, (count / 2).round(), count - 1];
        for (int idx in labelsToShow) {
          if (idx >= 0 && idx < count) {
            String label = '';
            if (idx < soloPoints.length) {
              label = (soloPoints[idx]['label'] ?? '').toString();
            } else if (idx < groupPoints.length) {
              label = (groupPoints[idx]['label'] ?? '').toString();
            }
            if (label.length > 3) label = label.substring(0, 3);
            final x = rect.left + (idx / (count - 1)) * rect.width;
            textPainter.text = TextSpan(text: label, style: textStyle);
            textPainter.layout();
            double dx = x - textPainter.width / 2;
            if (idx == 0) dx = rect.left;
            if (idx == count - 1) dx = rect.right - textPainter.width;
            textPainter.paint(canvas, Offset(dx, rect.bottom + 8));
          }
        }
      }
    }
  }

  void _drawLoadingCircle(
    Canvas canvas,
    Rect rect,
    Color color,
    double phaseShift,
  ) {
    final center = Offset(
      rect.left + rect.width / 2,
      rect.top + rect.height / 2,
    );
    final radius = min(rect.width, rect.height) * 0.25;
    final sweep = 2 * pi * (0.2 + 0.8 * (t % 1));
    final start = phaseShift + 2 * pi * (t % 1);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..addArc(Rect.fromCircle(center: center, radius: radius), start, sweep);
    canvas.drawPath(path, paint);
  }

  void _drawMorphPath(
    Canvas canvas,
    Rect rect,
    List<Map<String, dynamic>> points,
    Color color,
    double progress, {
    required bool behind,
  }) {
    final target = _computeOffsets(rect, points);
    if (target.isEmpty) return;
    final center = Offset(
      rect.left + rect.width / 2,
      rect.top + rect.height / 2,
    );
    final radius = min(rect.width, rect.height) * 0.25;
    final circle = List<Offset>.generate(target.length, (i) {
      final ang = 2 * pi * (i / max(1, target.length)) + (behind ? 0 : pi / 2);
      return Offset(
        center.dx + radius * cos(ang),
        center.dy + radius * sin(ang),
      );
    });
    final e = Curves.easeInOut.transform(progress.clamp(0, 1));
    final blended = List<Offset>.generate(target.length, (i) {
      final c = i < circle.length ? circle[i] : center;
      final t = target[i];
      return Offset(c.dx * (1 - e) + t.dx * e, c.dy * (1 - e) + t.dy * e);
    });
    _drawPathFromOffsets(canvas, blended, rect, color);
  }

  List<Offset> _computeOffsets(Rect rect, List<Map<String, dynamic>> points) {
    final maxY = _calculateMaxY();
    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final yVal = (points[i]['y'] as int? ?? 0).toDouble();
      final x = rect.left + (i / max(1, points.length - 1)) * rect.width;
      final y = rect.bottom - (yVal / maxY) * rect.height;
      offsets.add(Offset(x, y));
    }
    return offsets;
  }

  void _drawPathFromOffsets(
    Canvas canvas,
    List<Offset> offsets,
    Rect rect,
    Color color,
  ) {
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final c1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final c2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
    }
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  void _drawSmoothPath(
    Canvas canvas,
    Rect rect,
    List<Map<String, dynamic>> points,
    Color color, {
    bool isFilled = false,
  }) {
    final maxY = _calculateMaxY();
    final path = Path();
    final offsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final yVal = (points[i]['y'] as int? ?? 0).toDouble();
      final x = rect.left + (i / (points.length - 1)) * rect.width;
      final y = rect.bottom - (yVal / maxY) * rect.height;
      offsets.add(Offset(x, y));
    }

    if (offsets.isEmpty) return;

    path.moveTo(offsets.first.dx, offsets.first.dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // 1. Gradient Fill
    if (isFilled) {
      final fillPath = Path.from(path);
      fillPath.lineTo(rect.right, rect.bottom);
      fillPath.lineTo(rect.left, rect.bottom);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // 2. Neon Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawPath(path, glowPaint);

    // 3. Core Line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    var max = (p2 - p1).distance;
    var dashWidth = 4.0;
    var dashSpace = 4.0;
    double current = 0;
    while (current < max) {
      canvas.drawLine(
        p1 + (p2 - p1) * (current / max),
        p1 + (p2 - p1) * (min(current + dashWidth, max) / max),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  int _calculateMaxY() {
    int maxY = 1;
    for (final p in [...soloPoints, ...groupPoints]) {
      maxY = max(maxY, (p['y'] as int? ?? 0));
    }
    if (maxY <= 5) return 5;
    return ((maxY + 4) ~/ 5) * 5;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
