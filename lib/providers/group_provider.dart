import 'package:flutter/material.dart';

class GroupMember {
  final int id;
  final String name;
  final String status;
  final String lastSeen;
  final String location;
  final bool isOnline;

  GroupMember({
    required this.id,
    required this.name,
    required this.status,
    required this.lastSeen,
    required this.location,
    required this.isOnline,
  });
}

class GroupProvider with ChangeNotifier {
  final List<GroupMember> _members = [
    GroupMember(
      id: 1,
      name: 'Sarah Johnson',
      status: 'hiking',
      lastSeen: '2 mins ago',
      location: 'Mt. Wilson Trail',
      isOnline: true,
    ),
    GroupMember(
      id: 2,
      name: 'Mike Chen',
      status: 'resting',
      lastSeen: '5 mins ago',
      location: 'Observation Point',
      isOnline: true,
    ),
    GroupMember(
      id: 3,
      name: 'Emma Davis',
      status: 'offline',
      lastSeen: '1 hour ago',
      location: 'Last known: Base Camp',
      isOnline: false,
    ),
  ];

  List<GroupMember> get members => _members;

  int get onlineCount => _members.where((m) => m.isOnline).length;

  void sendGroupAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert sent to all group members')),
    );
  }

  void addMember(GroupMember member) {
    _members.add(member);
    notifyListeners();
  }
}
