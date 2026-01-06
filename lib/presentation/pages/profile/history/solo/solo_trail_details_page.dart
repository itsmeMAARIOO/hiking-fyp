import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/services/history_service.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                CommonHeader(
                  title: (_trail?['trailName'] ?? 'Solo Trail').toString(),
                  showBack: true,
                ),
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
        ],
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
        ? DateFormat(
            'd MMM yyyy, HH:mm',
          ).format(end.subtract(const Duration(hours: 8)).toLocal())
        : '-';

    final trailDescription = (_trail?['trailDescription'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionHeader(
                title: 'Trail Spot',
                icon: Icons.map_rounded,
                isMain: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMapSection(),
        const SizedBox(height: 24),

        if (trailDescription.isNotEmpty) ...[
          _SectionHeader(title: 'Description', icon: Icons.description_rounded),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSoftMint.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: kDeepTeal.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              trailDescription,
              style: const TextStyle(
                fontSize: 15,
                color: kDeepTeal,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        _SectionHeader(title: "Timeline", icon: Icons.timeline_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kSoftMint.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: kDeepTeal.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTimeRow(
                time: startStr,
                label: 'Started',
                isStart: true,
                isLast: false,
              ),
              _buildTimeRow(
                time: endStr,
                label: 'Ended',
                isStart: false,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTimeRow({
    required String time,
    required String label,
    required bool isStart,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: kPureWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isStart ? kDeepForest : kDeepOrange,
                  width: 3,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: kDeepTeal.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kDeepTeal.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kDeepTeal,
                ),
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    final lat = _trail?['latestLatitude'];
    final lng = _trail?['latestLongitude'];

    if (lat == null || lng == null) return const SizedBox.shrink();

    final point = LatLng(
      lat is num ? lat.toDouble() : 0.0,
      lng is num ? lng.toDouble() : 0.0,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(center: point, zoom: 15),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 45,
                      height: 45,
                      point: point,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: kFreshRed,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isMain;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMain
                ? kDeepForest.withOpacity(0.12)
                : kDeepTeal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: isMain ? 24 : 20,
            color: isMain ? kDeepForest : kDeepTeal,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isMain ? 22 : 18,
            fontWeight: FontWeight.w800,
            color: kDeepTeal,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
