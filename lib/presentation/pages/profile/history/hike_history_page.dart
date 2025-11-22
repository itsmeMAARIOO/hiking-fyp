import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/services/history_service.dart';

class HikeHistoryPage extends StatefulWidget {
  const HikeHistoryPage({super.key});

  @override
  State<HikeHistoryPage> createState() => _HikeHistoryPageState();
}

class _HikeHistoryPageState extends State<HikeHistoryPage> {
  late String _type;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = (Get.arguments?['type'] ?? 'group').toString();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'User not found';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_type == 'solo') {
        _items = await HistoryService.fetchSoloHistory(userId);
      } else {
        _items = await HistoryService.fetchGroupHistory(userId);
      }
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = _type == 'solo' ? 'Solo Hike History' : 'Group Hike History';
    return Scaffold(
      backgroundColor: kLightCream,
      body: SafeArea(
        child: Column(
          children: [
            CommonHeader(title: title, lastError: _error),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _type == 'solo'
                          ? _SoloItemCard(item: _items[i])
                          : _GroupItemCard(item: _items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape_rounded, color: kMediumSage, size: 48),
          const SizedBox(height: 12),
          Text(
            'No history yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kDeepTeal.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _GroupItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final groupName = (item['groupName'] ?? '').toString();
    final trailName = (item['activeTrail']?['trailName'] ?? '').toString();
    final endRaw = item['activeTrail']?['endTime'];
    DateTime? end;
    try {
      if (endRaw is String) end = DateTime.parse(endRaw);
      if (endRaw is Map && endRaw['\$date'] != null) {
        final d = endRaw['\$date'];
        if (d is Map && d['\$numberLong'] != null) {
          end = DateTime.fromMillisecondsSinceEpoch(
            int.parse(d['\$numberLong'] as String),
          );
        }
      }
    } catch (_) {}
    final endStr = end != null
        ? DateFormat('d MMM yyyy, HH:mm').format(end!.toLocal())
        : '-';
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.groupTrailDetails,
          arguments: {'groupId': (item['_id'] ?? '').toString()},
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                color: kMediumSage.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: kMediumSage),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trailName.isNotEmpty ? trailName : 'Unnamed Trail',
                    style: TextStyle(
                      fontSize: 13,
                      color: kDeepTeal.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: kDeepTeal.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kDeepTeal),
          ],
        ),
      ),
    );
  }
}

class _SoloItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SoloItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final trailName = (item['trailName'] ?? '').toString();
    final endRaw = item['endTime'];
    DateTime? end;
    try {
      if (endRaw is String) end = DateTime.parse(endRaw);
      if (endRaw is Map && endRaw['\$date'] != null) {
        final d = endRaw['\$date'];
        if (d is Map && d['\$numberLong'] != null) {
          end = DateTime.fromMillisecondsSinceEpoch(
            int.parse(d['\$numberLong'] as String),
          );
        }
      }
    } catch (_) {}
    final endStr = end != null
        ? DateFormat('d MMM yyyy, HH:mm').format(end!.toLocal())
        : '-';
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.soloTrailDetails,
          arguments: {'trailId': (item['_id'] ?? '').toString()},
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
              child: const Icon(Icons.terrain_rounded, color: kDeepForest),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trailName.isNotEmpty ? trailName : 'Unnamed Trail',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: kDeepTeal.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kDeepTeal),
          ],
        ),
      ),
    );
  }
}
