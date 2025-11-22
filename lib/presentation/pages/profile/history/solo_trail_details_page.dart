import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/services/history_service.dart';

class SoloTrailDetailsPage extends StatefulWidget {
  const SoloTrailDetailsPage({super.key});

  @override
  State<SoloTrailDetailsPage> createState() => _SoloTrailDetailsPageState();
}

class _SoloTrailDetailsPageState extends State<SoloTrailDetailsPage> {
  Map<String, dynamic>? _trail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final args = Get.arguments ?? {};
    final trailId = (args['trailId'] ?? '').toString();
    if (trailId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing trailId';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _trail = await HistoryService.fetchSoloTrail(trailId);
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = (_trail?['trailName'] ?? 'Solo Trail').toString();
    return Scaffold(
      backgroundColor: kLightCream,
      body: SafeArea(
        child: Column(
          children: [
            CommonHeader(title: title, lastError: _error),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildDetails(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    final startRaw = _trail?['startTime'];
    final endRaw = _trail?['endTime'];
    DateTime? start;
    DateTime? end;
    try {
      if (startRaw is String) start = DateTime.parse(startRaw);
      if (endRaw is String) end = DateTime.parse(endRaw);
    } catch (_) {}
    final startStr = start != null
        ? DateFormat('d MMM yyyy, HH:mm').format(start!.toLocal())
        : '-';
    final endStr = end != null
        ? DateFormat('d MMM yyyy, HH:mm').format(end!.toLocal())
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(icon: Icons.play_arrow_rounded, title: 'Start', value: startStr),
        const SizedBox(height: 12),
        _InfoRow(icon: Icons.stop_rounded, title: 'End', value: endStr),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSoftMint.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kDeepForest.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kDeepForest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: kDeepTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}