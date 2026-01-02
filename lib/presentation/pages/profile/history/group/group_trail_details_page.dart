import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/services/history_service.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/chat/chat_tab.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/library/library_tab.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';

class GroupTrailDetailsPage extends StatefulWidget {
  const GroupTrailDetailsPage({super.key});

  @override
  State<GroupTrailDetailsPage> createState() => _GroupTrailDetailsPageState();
}

class _GroupTrailDetailsPageState extends State<GroupTrailDetailsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _group;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final args = Get.arguments ?? {};
    final groupId = (args['groupId'] ?? '').toString();
    if (groupId.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      _group = await HistoryService.fetchGroupDetails(groupId);
    } catch (e) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    (_group?['groupName'] ?? 'Group Trail').toString();
    final isOnline = Provider.of<DashboardProvider>(context).isOnline;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                CommonHeader(
                  title: (_group?['groupName'] ?? 'Group Trail').toString(),
                  showBack: true,
                ),
                _buildTabBar(),
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
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildDetails(),
                                  _buildMembers(),
                                  _buildChat(),
                                  _buildLibrary(),
                                ],
                              )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kDeepTeal, Color(0xFF2B8A7E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kDeepTeal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: kDeepTeal.withOpacity(0.6),
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline, size: 20)),
          Tab(icon: Icon(Icons.group_outlined, size: 20)),
          Tab(icon: Icon(Icons.chat_bubble_outline, size: 20)),
          Tab(icon: Icon(Icons.photo_library_outlined, size: 20)),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final trail = _group?['activeTrail'] as Map<String, dynamic>?;
    final startRaw = trail?['startTime'];
    final endRaw = trail?['endTime'];
    DateTime? start;
    DateTime? end;
    try {
      if (startRaw is String) {
        start = DateTime.parse(startRaw).subtract(const Duration(hours: 8));
      }
      if (endRaw is String) end = DateTime.parse(endRaw);
    } catch (_) {}
    final startStr = start != null
        ? DateFormat('d MMM yyyy, HH:mm').format(start.toLocal())
        : '-';
    final endStr = end != null
        ? DateFormat('d MMM yyyy, HH:mm').format(end.toLocal())
        : '-';

    final trailDescription = (trail?['trailDescription'] ?? '').toString();

    // Build fallback points from trail path
    final fallbackPoints = <LatLng>[];
    final rawPath = (trail?['path'] as List?) ?? [];
    for (final p in rawPath) {
      if (p is Map) {
        final lat = _toDouble(p['lat']);
        final lng = _toDouble(p['lng']);
        if (lat != null && lng != null) {
          fallbackPoints.add(LatLng(lat, lng));
        }
      }
    }
    if (fallbackPoints.isEmpty) {
      final members = (_group?['members'] as List?) ?? [];
      for (final m in members) {
        if (m is Map) {
          final lat = _toDouble(m['latitude']);
          final lng = _toDouble(m['longitude']);
          if (lat != null && lng != null) {
            fallbackPoints.add(LatLng(lat, lng));
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          const SizedBox(height: 24),
          if (fallbackPoints.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        center: fallbackPoints.isNotEmpty
                            ? fallbackPoints.last
                            : const LatLng(0, 0),
                        zoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            if (fallbackPoints.isNotEmpty)
                              Marker(
                                width: 45,
                                height: 45,
                                point: fallbackPoints.last,
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
            ),
          const SizedBox(height: 24),

          if (trailDescription.isNotEmpty) ...[
            _SectionHeader(
              title: 'Description',
              icon: Icons.description_rounded,
              isMain: true,
            ),
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
          const _SectionHeader(title: "Timeline", icon: Icons.timeline_rounded),
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
      ),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    if (v is Map && v['\$numberDouble'] != null) {
      return double.tryParse(v['\$numberDouble'] as String);
    }
    return null;
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
                color: isStart ? kDeepForest : Colors.white,
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

  Widget _buildMembers() {
    final members = (_group?['members'] as List?) ?? [];
    if (members.isEmpty) {
      return const Center(child: Text("No members"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: members.length + 1, // +1 for header
      separatorBuilder: (ctx, index) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (i == 0) {
          return const _SectionHeader(
            title: "Group Members",
            icon: Icons.groups_rounded,
          );
        }
        final index = i - 1;
        final m = members[index] as Map<String, dynamic>;
        String name = (m['name'] ?? '').toString();
        final userObj = m['userId'];
        if (userObj is Map<String, dynamic>) {
          name = (userObj['name'] ?? name).toString();
        }
        final role = (m['role'] ?? '').toString();
        final status = (m['status'] ?? '').toString();
        final avatar = _resolveAvatar(m);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kSoftMint.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kDeepTeal.withOpacity(0.05),
                  shape: BoxShape.circle,
                  image: avatar != null
                      ? DecorationImage(
                          image: NetworkImage(avatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kDeepTeal,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kDeepTeal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kDeepTeal.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kSoftMint.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kDeepTeal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChat() {
    if (_group == null) return const SizedBox();
    final groupId = (_group!['_id'] ?? '').toString();
    final groupName = (_group!['groupName'] ?? '').toString();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userId ?? '';
    final uname = auth.userName ?? '';
    return Column(
      children: [
        Expanded(
          child: ChatTab(
            groupId: groupId,
            groupName: groupName,
            currentUserId: uid,
            currentUserName: uname,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLibrary() {
    if (_group == null) return const SizedBox();
    final groupId = (_group!['_id'] ?? '').toString();
    final groupName = (_group!['groupName'] ?? '').toString();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userId ?? '';
    final uname = auth.userName ?? '';
    return Column(
      children: [
        Expanded(
          child: LibraryTab(
            groupId: groupId,
            groupName: groupName,
            currentUserId: uid,
            currentUserName: uname,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String? _resolveAvatar(Map<String, dynamic> m) {
    final pi = m['profileImage'];
    if (pi is String && pi.isNotEmpty) return pi;
    final userObj = m['userId'];
    if (userObj is Map<String, dynamic>) {
      final upi = userObj['profileImage'];
      if (upi is String && upi.isNotEmpty) return upi;
    }
    return null;
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
