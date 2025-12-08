import 'package:flutter/material.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_controller.dart';
import 'hiking_stats_line_chart.dart';

class HikingStatsCard extends StatefulWidget {
  const HikingStatsCard({super.key});

  @override
  State<HikingStatsCard> createState() => _HikingStatsCardState();
}

class _HikingStatsCardState extends State<HikingStatsCard>
    with SingleTickerProviderStateMixin {
  late final ProfileController _controller;
  String _selectedPeriodLocal = 'M';
  late final AnimationController _chartController;
  String _phase = 'idle';

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(context);
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userId != null) {
        _controller.setUserId(auth.userId!);
        await _controller.loadHikingStats('Year');
      }
    });
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);

    // --- Crisp Blue/Pink Palette ---
    const Color soloColor = Color.fromARGB(255, 235, 162, 90);
    const Color groupColor = kMediumSage;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kMediumSage.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kDeepForest.withOpacity(0.2), width: 1),
      ),
      // Removed the Stack and the blurred "glow" container.
      // Now it's just a clean Padding widget.
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kMediumSage.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // Use the new solo color for the icon accent
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: kDeepTeal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hiking Activity",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kDeepTeal.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          "Your progress over time",
                          style: TextStyle(fontSize: 12, color: kDeepForest),
                        ),
                      ],
                    ),
                  ],
                ),

                _DarkYearSelector(
                  period: _selectedPeriodLocal,
                  onToggle: (p) async {
                    final next = _nextPeriod(p);
                    setState(() {
                      _selectedPeriodLocal = next;
                      _phase = 'loading';
                    });
                    final mapped = _mapPeriod(next);
                    _chartController.duration = const Duration(
                      milliseconds: 900,
                    );
                    _chartController.repeat();
                    await _controller.loadHikingStats(mapped);
                    _chartController.stop();
                    setState(() {
                      _phase = 'toChart';
                    });
                    _chartController.duration = const Duration(
                      milliseconds: 700,
                    );
                    await _chartController.forward(from: 0);
                    setState(() {
                      _phase = 'idle';
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),
            Divider(height: 1, color: kDeepForest.withOpacity(0.4)),
            const SizedBox(height: 12),

            // Legend / Stats
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: "Solo Hikes",
                    accentColor: soloColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: kDeepForest.withOpacity(0.4),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: _StatColumn(
                      label: "Group Hikes",
                      accentColor: groupColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart
            SizedBox(
              height: 140,
              width: double.infinity,
              child: provider.soloStats.isEmpty && provider.groupStats.isEmpty
                  ? Center(
                      child: Text(
                        "No data available",
                        style: TextStyle(color: kDeepForest),
                      ),
                    )
                  : HikingStatsLineChart(
                      soloPoints: provider.soloStats,
                      groupPoints: provider.groupStats,
                      colorSolo: soloColor, // New Cyan
                      colorGroup: groupColor, // New Amber
                      phase: _phase,
                      t: _chartController.value,
                      period: _mapPeriod(_selectedPeriodLocal),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPERS ---

class _StatColumn extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _StatColumn({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: kDeepTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _DarkYearSelector extends StatelessWidget {
  final String period; // 'M', 'Y', 'W'
  final ValueChanged<String> onToggle;

  const _DarkYearSelector({required this.period, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(period),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDeepTeal.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              period,
              style: const TextStyle(
                color: kDeepForest,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.autorenew, size: 16, color: kDeepForest),
          ],
        ),
      ),
    );
  }
}

String _nextPeriod(String current) {
  switch (current) {
    case 'M':
      return 'Y';
    case 'Y':
      return 'W';
    case 'W':
    default:
      return 'M';
  }
}

String _mapPeriod(String p) {
  switch (p) {
    case 'M':
      return 'Month';
    case 'Y':
      return 'Year';
    case 'W':
      return 'Week';
    default:
      return 'Month';
  }
}
