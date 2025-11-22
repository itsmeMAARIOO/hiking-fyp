import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';

class MemberSelector extends StatelessWidget {
  final List<dynamic> members;
  final double? focusLat;
  final double? focusLon;
  final VoidCallback onShowAll;
  final void Function(double lat, double lon) onSelectMember;

  const MemberSelector({
    super.key,
    required this.members,
    required this.focusLat,
    required this.focusLon,
    required this.onShowAll,
    required this.onSelectMember,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.userId;

    final items = members
        .map<_MemberItem?>((m) => _resolveMember(m))
        .whereType<_MemberItem>()
        .where((item) => currentUserId == null || item.userId != currentUserId)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final isAllSelected = focusLat == null && focusLon == null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // First "Show All" chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onShowAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isAllSelected
                      ? kMediumSage
                      : kDeepTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAllSelected
                        ? Colors.white
                        : kDeepTeal.withOpacity(0.2),
                    width: isAllSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: kDeepForest,
                      child: Icon(Icons.groups, color: Colors.white, size: 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'All',
                      style: TextStyle(
                        color: kDeepTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Individual member chips
          ...items.map((item) {
            final name = item.name;
            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
            final lat = item.lat;
            final lon = item.lon;
            final isSelected = focusLat == lat && focusLon == lon;
            final String? avatarUrl = item.avatarUrl;
            final bool hasNetworkAvatar =
                avatarUrl != null &&
                avatarUrl.isNotEmpty &&
                avatarUrl.startsWith('http');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (lat != null && lon != null) {
                    onSelectMember(lat, lon);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kMediumSage
                        : kDeepTeal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : kDeepTeal.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected ? kDeepForest : kMediumSage,
                        foregroundColor: Colors.white,
                        backgroundImage: hasNetworkAvatar
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: hasNetworkAvatar
                            ? null
                            : Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color: kDeepTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is Map && value['\$numberDouble'] != null) {
      return double.tryParse(value['\$numberDouble'] as String);
    }
    return null;
  }

  _MemberItem? _resolveMember(dynamic m) {
    // Support GroupMember model objects
    if (m is GroupMember) {
      final double lat = m.latitude;
      final double lon = m.longitude;
      return _MemberItem(
        name: m.name,
        lat: lat,
        lon: lon,
        avatarUrl: m.profileImage,
        userId: m.userId,
      );
    }
    // Support Map shapes from populated group members or nearby hikers
    if (m is Map<String, dynamic>) {
      final double? lat = _parseDouble(m['latitude']);
      final double? lon = _parseDouble(m['longitude']);
      if (lat == null || lon == null) return null;
      String name = (m['name'] ?? m['userName'] ?? 'Member').toString();
      String? userId;
      String? avatarUrl;
      final dynamic pi = m['profileImage'];
      if (pi is String && pi.isNotEmpty) {
        avatarUrl = pi;
      } else {
        // Check nested user object
        final dynamic userIdObj = m['userId'];
        if (userIdObj is Map<String, dynamic>) {
          final dynamic upi = userIdObj['profileImage'];
          final dynamic uname = userIdObj['name'];
          final dynamic uid = userIdObj['_id'] ?? userIdObj['id'];
          if (upi is String && upi.isNotEmpty) avatarUrl = upi;
          if (uname is String && uname.isNotEmpty) name = uname;
          if (uid is String) userId = uid;
          if (uid is Object) userId = uid.toString();
        }
        final dynamic userObj = m['user'];
        if (avatarUrl == null && userObj is Map<String, dynamic>) {
          final dynamic upi2 = userObj['profileImage'];
          final dynamic uname2 = userObj['name'];
          final dynamic uid2 = userObj['_id'] ?? userObj['id'];
          if (upi2 is String && upi2.isNotEmpty) avatarUrl = upi2;
          if (uname2 is String && uname2.isNotEmpty) name = uname2;
          if (uid2 is String) userId = uid2;
          if (uid2 is Object) userId = uid2.toString();
        }
      }
      // If still no userId, try direct fields
      if (userId == null) {
        final dynamic uidDirect = m['userId'] ?? m['id'];
        if (uidDirect is String) userId = uidDirect;
        if (uidDirect is Object) userId = uidDirect.toString();
      }
      return _MemberItem(
        name: name,
        lat: lat,
        lon: lon,
        avatarUrl: avatarUrl,
        userId: userId ?? '',
      );
    }
    return null;
  }
}

class _MemberItem {
  final String name;
  final double? lat;
  final double? lon;
  final String? avatarUrl;
  final String userId;
  _MemberItem({
    required this.name,
    required this.lat,
    required this.lon,
    this.avatarUrl,
    required this.userId,
  });
}
