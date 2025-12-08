import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/services/history_service.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';

class SoloTrailDetailsPage extends StatefulWidget {
  const SoloTrailDetailsPage({super.key});

  @override
  State<SoloTrailDetailsPage> createState() => _SoloTrailDetailsPageState();
}

class _SoloTrailDetailsPageState extends State<SoloTrailDetailsPage> {
  Map<String, dynamic>? _trail;
  bool _loading = true;

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
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      _trail = await HistoryService.fetchSoloTrail(trailId);
    } catch (e) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    (_trail?['trailName'] ?? 'Solo Trail').toString();
    final isOnline = Provider.of<DashboardProvider>(context).isOnline;
    return Scaffold(
      backgroundColor: kLightCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !isOnline
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kDeepTeal.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kDeepForest.withOpacity(0.08),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.wifi_off_rounded,
                                    color: kDeepForest,
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'No Connection',
                                    style: TextStyle(
                                      color: kDeepForest,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Please try again later.',
                                style: TextStyle(
                                  color: kDeepForest,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : (_loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildDetails(),
                          )),
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
        ? DateFormat('d MMM yyyy, HH:mm').format(start.toLocal())
        : '-';
    final endStr = end != null
        ? DateFormat('d MMM yyyy, HH:mm').format(end.toLocal())
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.play_arrow_rounded,
          title: 'Start',
          value: startStr,
        ),
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
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

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
