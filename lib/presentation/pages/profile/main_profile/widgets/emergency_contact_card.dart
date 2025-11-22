import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_controller.dart';
import 'package:hikingapp/presentation/widgets/app_action_dialog.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';

class EmergencyContactCard extends StatelessWidget {
  final ProfileController controller;
  const EmergencyContactCard({super.key, required this.controller});

  Future<Map<String, String>?> _showAddContactDialog(
    BuildContext context,
  ) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AppActionDialog(
        title: 'ADD CONTACT',
        icon: Icons.emergency_rounded,
        message: 'Enter the contact details to add.',
        cancelText: 'CANCEL',
        confirmText: 'ADD',
        confirmColor: kDeepForest,
        cancelResult: 'cancel',
        confirmResult: 'confirm',
        infoCard: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
      ),
    );
    if (res == 'confirm') {
      if (nameCtrl.text.trim().isEmpty ||
          emailCtrl.text.trim().isEmpty ||
          phoneCtrl.text.trim().isEmpty) {
        return null;
      }
      return {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<ProfileProvider>(
          builder: (context, profile, _) {
            final contacts = profile.emergencyContacts;
            return Row(
              children: [
                const Icon(
                  Icons.emergency_rounded,
                  color: Color(0xFFFF6B35),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kDeepTeal,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: contacts.length >= 5
                            ? Colors.grey.withOpacity(0.3)
                            : kDeepTeal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: contacts.length >= 5
                          ? null
                          : () async {
                              final result = await _showAddContactDialog(
                                context,
                              );
                              if (result != null) {
                                await controller.addEmergencyContact(
                                  name: result['name']!,
                                  email: result['email']!,
                                  phone: result['phone']!,
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: contacts.length >= 5
                              ? LinearGradient(
                                  colors: [
                                    Colors.grey.shade400,
                                    Colors.grey.shade500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [kDeepTeal, kDeepForest],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: contacts.length >= 5
                                ? Colors.grey.shade300!
                                : kMediumSage.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<ProfileProvider>(
          builder: (context, profile, _) {
            final contacts = profile.emergencyContacts;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox.shrink(),
                const SizedBox(height: 12),
                if (contacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kMediumSage.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'No emergency contacts. Add up to 5 for safety.',
                      style: TextStyle(
                        color: kDeepForest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final c = contacts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kMediumSage.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: kDeepTeal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['name'] ?? '',
                                    style: const TextStyle(
                                      color: kDeepForest,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c['email'] ?? '',
                                    style: TextStyle(
                                      color: kDeepForest.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c['phone'] ?? '',
                                    style: const TextStyle(color: kDeepTeal),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: (c['share'] ?? 'false') == 'true',
                              onChanged: (val) async {
                                final provider = Provider.of<ProfileProvider>(context, listen: false);
                                provider.setContactShare(index, val);
                                final ok = await controller.toggleContactShare(index, val);
                                if (!ok) {
                                  SnackbarHelper.showError('Error', 'Unable to save sharing preference');
                                }
                              },
                              activeColor: kMediumSage,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: kFreshRed),
                              onPressed: () async {
                                final res = await showDialog<String>(
                                  context: context,
                                  builder: (_) => AppActionDialog(
                                    title: 'DELETE CONTACT',
                                    icon: Icons.delete_outline_rounded,
                                    message:
                                        "Delete '${c['name'] ?? 'this contact'}'? This cannot be undone.",
                                    cancelText: 'CANCEL',
                                    confirmText: 'DELETE',
                                    confirmColor: kFreshRed,
                                    cancelResult: 'cancel',
                                    confirmResult: 'confirm',
                                  ),
                                );
                                if (res == 'confirm') {
                                  await controller.removeEmergencyContact(
                                    index,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
