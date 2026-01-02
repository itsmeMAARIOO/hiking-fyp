import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:intl/intl.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';

class HealthCardPage extends StatefulWidget {
  const HealthCardPage({super.key});

  @override
  State<HealthCardPage> createState() => _HealthCardPageState();
}

class _HealthCardPageState extends State<HealthCardPage> {
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final userId = auth.userId ?? profile.userId;
    if (userId == null) {
      setState(() => _error = 'User not found');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() => _user = data);
      } else {
        setState(() => _error = 'Failed to fetch user data');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                const CommonHeader(title: 'Health Card', showBack: true),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final isOnline = Provider.of<DashboardProvider>(context).isOnline;
    if (!isOnline) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  border: Border.all(color: Colors.white, width: 1.5),
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
                    Icon(Icons.wifi_off_rounded, color: kDeepForest, size: 24),
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
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kDeepTeal));
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: kDeepTeal, fontWeight: FontWeight.w600),
        ),
      );
    }
    final u = _user ?? {};
    final name = (u['name'] ?? '').toString();
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone'] ?? '').toString();
    final profileImage = (u['profileImage'] ?? '').toString();
    final contacts = (u['emergencyContacts'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kDeepTeal.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: kDeepTeal.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kSoftMint.withOpacity(0.3),
                    border: Border.all(width: 2, color: kDeepTeal),
                    image: (() {
                      final provider = _resolveAvatarProvider(profileImage);
                      return provider == null
                          ? null
                          : DecorationImage(image: provider, fit: BoxFit.cover);
                    })(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Unknown Hiker' : name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kDeepTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _infoRow(
                        Icons.email_rounded,
                        email.isEmpty ? '-' : email,
                      ),
                      _infoRow(
                        Icons.phone_rounded,
                        phone.isEmpty ? '-' : phone,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _infoBlock(
                    'Date of Birth',
                    _formatDob(u['dateOfBirth']),
                    Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoBlock(
                    'Gender',
                    (u['gender'] ?? '-').toString(),
                    Icons.person_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _infoBlock(
                    'Weight',
                    u['weightKg'] != null ? '${u['weightKg']} kg' : '-',
                    Icons.line_weight_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoBlock(
                    'Height',
                    u['heightCm'] != null ? '${u['heightCm']} cm' : '-',
                    Icons.height,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoBlock(
                    'Blood Type',
                    (u['bloodType'] ?? '-').toString(),
                    Icons.bloodtype_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoBlock(
                    'Allergic',
                    _formatAllergies(u['allergies']),
                    Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: kDeepTeal,
              ),
            ),
            const SizedBox(height: 8),
            if (contacts.isEmpty)
              Text(
                'No emergency contacts added',
                style: TextStyle(color: kDeepTeal.withOpacity(0.6)),
              )
            else
              Column(
                children: contacts.map((c) {
                  final m = (c as Map).map(
                    (key, value) => MapEntry('$key', value),
                  );
                  final cn = (m['name'] ?? '').toString();
                  final ce = (m['email'] ?? '').toString();
                  final cp = (m['phone'] ?? '').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kSoftMint.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kMediumSage.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          color: kDeepTeal,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cn,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kDeepTeal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ce,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kDeepTeal.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cp.isEmpty ? '-' : cp,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kDeepTeal.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: kDeepTeal, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kDeepForest,
          ),
        ),
      ],
    );
  }

  String _formatDob(dynamic raw) {
    if (raw == null) return '-';
    try {
      if (raw is String && raw.isNotEmpty) {
        final s = raw.trim();
        final parsed = DateTime.tryParse(s);
        if (parsed != null) {
          return DateFormat('dd-MMM-yyyy').format(parsed.toLocal());
        }
        final ms = int.tryParse(s);
        if (ms != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(ms);
          return DateFormat('dd-MMM-yyyy').format(dt.toLocal());
        }
      } else if (raw is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(raw);
        return DateFormat('dd-MMM-yyyy').format(dt.toLocal());
      } else if (raw is Map && raw['\$date'] != null) {
        final d = raw['\$date'];
        if (d is int) {
          final dt = DateTime.fromMillisecondsSinceEpoch(d);
          return DateFormat('dd-MMM-yyyy').format(dt.toLocal());
        }
        if (d is Map && d['\$numberLong'] != null) {
          final ms = int.tryParse(d['\$numberLong'].toString());
          if (ms != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ms);
            return DateFormat('dd-MMM-yyyy').format(dt.toLocal());
          }
        }
      }
    } catch (_) {}
    return (raw is String && raw.isNotEmpty) ? raw : '-';
  }

  Widget _infoBlock(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSoftMint.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kMediumSage.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kDeepTeal, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: kDeepTeal.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: kDeepForest,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAllergies(dynamic allergies) {
    if (allergies == null) return 'None';
    if (allergies is String) {
      final s = allergies.trim();
      return s.isEmpty ? 'None' : s;
    }
    if (allergies is List) {
      final list = allergies
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return list.isEmpty ? 'None' : list.join(', ');
    }
    return 'None';
  }

  ImageProvider? _resolveAvatarProvider(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage(ImageLocation.climber);
    }
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    if (path.startsWith('file://')) {
      final p = path.replaceFirst('file://', '');
      return FileImage(File(p));
    }
    // If it's an asset path string
    return AssetImage(path);
  }
}
