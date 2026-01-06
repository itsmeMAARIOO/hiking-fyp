import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/services/history_service.dart';
import 'package:hikingapp/presentation/widgets/app_action_dialog.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';

class HikeHistoryPage extends StatefulWidget {
  const HikeHistoryPage({super.key});

  @override
  State<HikeHistoryPage> createState() => _HikeHistoryPageState();
}

class _HikeHistoryPageState extends State<HikeHistoryPage> {
  late String _type;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

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
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      if (_type == 'solo') {
        _items = await HistoryService.fetchSoloHistory(userId);
      } else {
        _items = await HistoryService.fetchGroupHistory(userId);
      }
    } catch (e) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = _type == 'solo' ? 'Solo Hike History' : 'Group Hike History';
    final isOnline = Provider.of<DashboardProvider>(context).isOnline;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                CommonHeader(
                  title: title,
                  showBack: true,
                  actions: [
                    if (_selectionMode)
                      IconButton(
                        tooltip: _selectedIds.isEmpty
                            ? 'Select items'
                            : 'Remove selected',
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : _performBatchDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                    IconButton(
                      tooltip: _selectionMode ? 'Done' : 'Select',
                      onPressed: _toggleSelectionMode,
                      icon: Icon(
                        _selectionMode
                            ? Icons.close_rounded
                            : Icons.check_box_outlined,
                        color: kDeepTeal,
                      ),
                    ),
                  ],
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
                            : _items.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _items.length,
                                itemBuilder: (_, i) {
                                  final item = _items[i];
                                  final id = (item['_id'] ?? '').toString();
                                  final selected = _selectedIds.contains(id);
                                  return _type == 'solo'
                                      ? _SoloItemCard(
                                          item: item,
                                          selectionMode: _selectionMode,
                                          isSelected: selected,
                                          onToggleSelect: () =>
                                              _toggleSelectItem(id),
                                        )
                                      : _GroupItemCard(
                                          item: item,
                                          selectionMode: _selectionMode,
                                          isSelected: selected,
                                          onToggleSelect: () =>
                                              _toggleSelectItem(id),
                                        );
                                },
                              )),
                ),
              ],
            ),
          ),
        ],
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

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelectItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _performBatchDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AppActionDialog(
        title: 'Remove $count item${count > 1 ? 's' : ''}?',
        icon: Icons.delete_outline_rounded,
        message:
            'This will remove the selected ${_type == 'solo' ? 'solo' : 'group'} hike${count > 1 ? 's' : ''} from your history. This action cannot be undone.',
        cancelText: 'CANCEL',
        confirmText: 'REMOVE',
        confirmColor: const Color(0xFFE74C3C),
      ),
    );
    if (result != 'confirm') return;

    int failures = 0;
    for (final id in _selectedIds.toList()) {
      try {
        if (_type == 'solo') {
          await HistoryService.deleteSoloHistory(id);
        } else {
          await HistoryService.deleteGroupHistory(id);
        }
        _items.removeWhere((e) => ((e['_id'] ?? '').toString()) == id);
      } catch (e) {
        failures++;
      }
    }
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });

    if (failures == 0) {
      SnackbarHelper.showSuccess('Removed', 'Selected history removed');
    } else {
      SnackbarHelper.showError(
        'Partial Failure',
        'Failed to remove $failures item${failures > 1 ? 's' : ''}',
      );
    }
  }
}

class _GroupItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  const _GroupItemCard({
    required this.item,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
  });

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
        ? DateFormat('d MMM yyyy, HH:mm').format(end.toLocal())
        : '-';
    return GestureDetector(
      onTap: () {
        if (selectionMode) {
          onToggleSelect();
        } else {
          Get.toNamed(
            AppRoutes.groupTrailDetails,
            arguments: {'groupId': (item['_id'] ?? '').toString()},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWarmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? kDeepForest.withOpacity(0.5)
                : kSoftMint.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
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
            selectionMode
                ? Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? kDeepForest
                        : kDeepTeal.withOpacity(0.6),
                  )
                : const Icon(Icons.chevron_right_rounded, color: kDeepTeal),
          ],
        ),
      ),
    );
  }
}

class _SoloItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  const _SoloItemCard({
    required this.item,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
  });

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
        ? DateFormat(
            'd MMM yyyy, HH:mm',
          ).format(end.subtract(const Duration(hours: 8)).toLocal())
        : '-';
    return GestureDetector(
      onTap: () {
        if (selectionMode) {
          onToggleSelect();
        } else {
          Get.toNamed(
            AppRoutes.soloTrailDetails,
            arguments: {'trailId': (item['_id'] ?? '').toString()},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWarmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? kDeepForest.withOpacity(0.5)
                : kSoftMint.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
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
            selectionMode
                ? Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? kDeepForest
                        : kDeepTeal.withOpacity(0.6),
                  )
                : const Icon(Icons.chevron_right_rounded, color: kDeepTeal),
          ],
        ),
      ),
    );
  }
}
