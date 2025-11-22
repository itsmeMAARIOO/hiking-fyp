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

class _HikingStatsCardState extends State<HikingStatsCard> {
  late final ProfileController _controller;
  int? _selectedYearLocal;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userId != null) {
        _controller.setUserId(auth.userId!);
        await _controller.loadHikingStats('Year');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final totalHikes = provider.soloTotalFiltered + provider.groupTotalFiltered;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kDeepTeal,
                    ),
                  ),
                ),
                _YearScrollBox(
                  years: provider.availableYears,
                  selectedYear:
                      provider.selectedYear ??
                      _selectedYearLocal ??
                      DateTime.now().year,
                  onSelected: (y) async {
                    _selectedYearLocal = y;
                    provider.setHikingStats(
                      solo: provider.soloStats,
                      group: provider.groupStats,
                      soloTotal: provider.soloTotalFiltered,
                      groupTotal: provider.groupTotalFiltered,
                      years: provider.availableYears,
                      year: y,
                    );
                    await _controller.loadHikingStats('Year');
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: const [
                _LegendItem(label: 'Solo', color: kMediumSage),
                SizedBox(width: 12),
                _LegendItem(label: 'Group', color: kDeepForest),
              ],
            ),

            const SizedBox(height: 4),

            // Divider like in reference
            Divider(
              color: kDeepTeal.withOpacity(0.1),
              height: 20,
              thickness: 1,
            ),

            const SizedBox(height: 4),

            // Chart
            SizedBox(
              height: 200,
              child: provider.soloStats.isEmpty && provider.groupStats.isEmpty
                  ? const _EmptyState()
                  : HikingStatsLineChart(
                      soloPoints: provider.soloStats,
                      groupPoints: provider.groupStats,
                    ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  value: provider.soloTotalFiltered,
                  label: 'Total Solo',
                  color: kMediumSage,
                ),
                _MiniStat(
                  value: provider.groupTotalFiltered,
                  label: 'Total Group',
                  color: kDeepForest,
                ),
                _MiniStat(
                  value: totalHikes,
                  label: 'Combined',
                  color: kDeepTeal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: kDeepTeal.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kWarmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSoftMint.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'Month', child: Text('Month')),
          DropdownMenuItem(value: 'Year', child: Text('Year')),
          DropdownMenuItem(value: 'All time', child: Text('All time')),
        ],
      ),
    );
  }
}

class _YearScrollBox extends StatelessWidget {
  final List<int> years;
  final int selectedYear;
  final ValueChanged<int> onSelected;
  const _YearScrollBox({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    final displayYears = years.isEmpty
        ? List.generate(6, (i) => DateTime.now().year - i)
        : years;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kWarmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSoftMint.withOpacity(0.3)),
      ),
      child: DropdownButton<int>(
        value: selectedYear,
        onChanged: (y) {
          if (y != null) onSelected(y);
        },
        underline: const SizedBox(),
        items: displayYears
            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
            .toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_rounded,
            color: kDeepTeal.withOpacity(0.3),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No data this week',
            style: TextStyle(color: kDeepTeal.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
