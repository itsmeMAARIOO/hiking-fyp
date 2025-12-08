import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/services/history_service.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/chat/chat_tab.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/library/library_tab.dart';
import 'widgets/group_path_replay_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';

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
  List<MemberPath> _memberPaths = [];
  DateTime? _start;
  DateTime? _end;

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
      // fetch path replay
      final replay = await HistoryService.fetchGroupPathReplay(groupId);
      final trail = replay['trail'] as Map<String, dynamic>?;
      final startRaw = trail?['startTime'];
      final endRaw = trail?['endTime'];
      if (startRaw is String) _start = DateTime.parse(startRaw);
      if (endRaw is String) _end = DateTime.parse(endRaw);
      final ms = (replay['members'] as List?) ?? [];
      _memberPaths = ms.map((m) {
        final mm = Map<String, dynamic>.from(m as Map);
        final rawPts = (mm['path'] as List?) ?? [];
        final pts = <PathPoint>[];
        for (final p in rawPts) {
          if (p is Map) {
            final lat = _toDouble(p['lat']);
            final lng = _toDouble(p['lng']);
            final tsRaw = p['timestamp'];
            if (lat != null && lng != null && tsRaw != null) {
              final ts = DateTime.tryParse(tsRaw.toString());
              if (ts != null) {
                pts.add(PathPoint(lat: lat, lng: lng, timestamp: ts));
              }
            }
          }
        }
        return MemberPath(
          userId: (mm['userId'] ?? '').toString(),
          name: (mm['name'] ?? 'Member').toString(),
          profileImage: (mm['profileImage'] ?? '').toString(),
          path: pts,
        );
      }).toList();
    } catch (e) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    (_group?['groupName'] ?? 'Group Trail').toString();
    final isOnline = Provider.of<DashboardProvider>(context).isOnline;
    return Scaffold(
      backgroundColor: kLightCream,
      body: SafeArea(
        child: Column(
          children: [
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: kDeepTeal.withOpacity(0.6),
        indicator: BoxDecoration(
          color: kMediumSage,
          borderRadius: BorderRadius.circular(10),
        ),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline)),
          Tab(icon: Icon(Icons.group_outlined)),
          Tab(icon: Icon(Icons.chat_bubble_outline)),
          Tab(icon: Icon(Icons.photo_library_outlined)),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final trail = _group?['activeTrail'] as Map<String, dynamic>?;
    final trailName = (trail?['trailName'] ?? '').toString();
    final startRaw = trail?['startTime'];
    final endRaw = trail?['endTime'];
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
          _InfoCard(
            icon: Icons.landscape_rounded,
            title: 'Trail Name',
            value: trailName.isNotEmpty ? trailName : 'Unnamed Trail',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.play_arrow_rounded,
            title: 'Start',
            value: startStr,
          ),
          const SizedBox(height: 12),
          _InfoCard(icon: Icons.stop_rounded, title: 'End', value: endStr),
          const SizedBox(height: 16),
          if (_memberPaths.isNotEmpty || fallbackPoints.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Path Replay',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kDeepTeal,
                  ),
                ),
                const SizedBox(height: 8),
                GroupPathReplayMap(
                  members: _memberPaths,
                  startTime: _start ?? (start ?? DateTime.now()),
                  endTime: _end ?? (end ?? DateTime.now()),
                  fallbackPoints: fallbackPoints,
                ),
              ],
            ),
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

  Widget _buildMembers() {
    final members = (_group?['members'] as List?) ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (_, i) {
        final m = members[i] as Map<String, dynamic>;
        String name = (m['name'] ?? '').toString();
        final userObj = m['userId'];
        if (userObj is Map<String, dynamic>) {
          name = (userObj['name'] ?? name).toString();
        }
        final role = (m['role'] ?? '').toString();
        final status = (m['status'] ?? '').toString();
        final avatar = _resolveAvatar(m);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kWarmWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kSoftMint.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kMediumSage.withOpacity(0.15),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? const Icon(Icons.person_rounded, color: kMediumSage)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: kDeepTeal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.isNotEmpty ? role : 'member',
                      style: TextStyle(
                        fontSize: 12,
                        color: kDeepTeal.withOpacity(0.6),
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
    return ChatTab(
      groupId: groupId,
      groupName: groupName,
      currentUserId: uid,
      currentUserName: uname,
    );
  }

  Widget _buildLibrary() {
    if (_group == null) return const SizedBox();
    final groupId = (_group!['_id'] ?? '').toString();
    final groupName = (_group!['groupName'] ?? '').toString();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userId ?? '';
    final uname = auth.userName ?? '';
    return LibraryTab(
      groupId: groupId,
      groupName: groupName,
      currentUserId: uid,
      currentUserName: uname,
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoCard({
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
              color: kMediumSage.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kMediumSage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: kDeepTeal.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kDeepTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
