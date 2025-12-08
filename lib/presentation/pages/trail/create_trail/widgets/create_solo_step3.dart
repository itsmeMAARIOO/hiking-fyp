import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';

class SoloConfirmStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final int? durationMinutes;

  const SoloConfirmStep({
    super.key,
    required this.nameController,
    required this.descriptionController,
    this.durationMinutes,
  });

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kMediumSage, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kDeepForest.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kDeepForest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final enabledContacts = profile.emergencyContacts
            .where((c) => (c['share'] ?? 'false') == 'true')
            .toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kMediumSage, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: kMediumSage.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      icon: Icons.flag_rounded,
                      label: 'Trail Name',
                      value: nameController.text.trim(),
                    ),
                    _infoRow(
                      icon: Icons.description_rounded,
                      label: 'Description',
                      value: descriptionController.text.trim(),
                    ),
                    _infoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Expected Duration',
                      value: (() {
                        final m = durationMinutes ?? 0;
                        if (m <= 0) return '-';
                        final h = m ~/ 60;
                        final mm = m % 60;
                        return h > 0
                            ? (mm > 0 ? '${h}h ${mm}m' : '${h}h')
                            : '${mm}m';
                      })(),
                    ),
                    Builder(
                      builder: (context) {
                        final m = durationMinutes ?? 0;
                        if (m <= 0) return const SizedBox.shrink();
                        final end = DateTime.now().add(Duration(minutes: m));
                        final s =
                            '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')} ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                        return _infoRow(
                          icon: Icons.event_available_rounded,
                          label: 'Expected End',
                          value: s,
                        );
                      },
                    ),
                    _infoRow(
                      icon: Icons.emergency_rounded,
                      label: 'Contacts to Notify',
                      value: '${enabledContacts.length}',
                    ),
                  ],
                ),
              ),

              if (enabledContacts.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Will Notify',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kDeepForest,
                  ),
                ),
                const SizedBox(height: 12),
                ...enabledContacts.map((c) {
                  final name = (c['name'] ?? '').toString();
                  final email = (c['email'] ?? '').toString();
                  final phone = (c['phone'] ?? '').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kDeepForest.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kMediumSage.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: kMediumSage,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : 'Contact',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: kDeepForest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (email.trim().isNotEmpty)
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kDeepForest.withOpacity(0.6),
                                  ),
                                ),
                              if (phone.trim().isNotEmpty)
                                Text(
                                  phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kDeepForest.withOpacity(0.6),
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
                            color: kMediumSage.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kMediumSage.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Enabled',
                            style: TextStyle(
                              color: kMediumSage,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kDeepForest.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'No contacts enabled for notifications',
                    style: TextStyle(
                      color: kDeepForest.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

