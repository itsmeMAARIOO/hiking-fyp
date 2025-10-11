class GroupMember {
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final String role;
  final String status;
  final DateTime lastUpdated;
  final String? distance;
  final String? groupName;

  GroupMember({
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.role,
    required this.status,
    required this.lastUpdated,
    this.distance,
    this.groupName,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Hiker',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'active',
      lastUpdated:
          DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      distance: json['distance']?.toString(),
      groupName: json['groupName'],
    );
  }

  void operator [](String other) {}
}
