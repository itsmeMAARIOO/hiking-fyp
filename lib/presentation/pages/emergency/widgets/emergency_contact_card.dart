import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_controller.dart';
import 'package:hikingapp/presentation/widgets/app_action_dialog.dart';

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
        icon: Icons.person_add_rounded,
        message: 'Add a trusted contact for emergencies.',
        cancelText: 'CANCEL',
        confirmText: 'ADD',
        confirmColor: kDeepTeal,
        cancelResult: 'cancel',
        confirmResult: 'confirm',
        infoCard: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTextField(
                controller: nameCtrl,
                label: 'Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: emailCtrl,
                label: 'Email',
                icon: Icons.email,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: phoneCtrl,
                label: 'Phone',
                icon: Icons.phone,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 20),
            ],
          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      scrollPadding: const EdgeInsets.only(bottom: 100),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kDeepTeal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final contacts = profile.emergencyContacts;
        final isMax = contacts.length >= 5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: Color(0xFFFF6B35),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kDeepForest,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isMax
                        ? null
                        : () async {
                            final result = await _showAddContactDialog(context);
                            if (result != null) {
                              await controller.addEmergencyContact(
                                name: result['name']!,
                                email: result['email']!,
                                phone: result['phone']!,
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMax
                            ? Colors.grey.shade300
                            : kDeepTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMax
                              ? Colors.transparent
                              : kDeepTeal.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: isMax ? Colors.grey : kDeepTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMax ? 'MAX 5' : 'ADD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isMax ? Colors.grey : kDeepTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Contacts List ---
            if (contacts.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = contacts[index];
                  final isSharing = (c['share'] ?? 'false') == 'true';
                  final phoneNumber = c['phone'] ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isSharing
                            ? kMediumSage.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: kDeepTeal.withOpacity(0.1),
                                child: Text(
                                  (c['name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kDeepTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          c['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: kDeepForest,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          c['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      phoneNumber,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Actions (Call & Delete)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.phone_rounded,
                                      color: kMediumSage,
                                      size: 22,
                                    ),
                                    tooltip: 'Call Contact',
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _makePhoneCall(phoneNumber),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    tooltip: 'Remove Contact',
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final res = await showDialog<String>(
                                        context: context,
                                        builder: (_) => AppActionDialog(
                                          title: 'DELETE CONTACT',
                                          icon: Icons.delete_forever_rounded,
                                          message: "Remove '${c['name']}'?",
                                          cancelText: 'CANCEL',
                                          confirmText: 'DELETE',
                                          confirmColor: Colors.redAccent,
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
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),

                          // Location Sharing Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isSharing
                                        ? Icons.location_on
                                        : Icons.location_off,
                                    size: 16,
                                    color: isSharing
                                        ? kMediumSage
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isSharing
                                        ? "Sharing Location"
                                        : "Location Hidden",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSharing
                                          ? kMediumSage
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),

                              // --- NEW CUSTOM SWITCH ---
                              StyledSwitch(
                                value: isSharing,
                                onChanged: (val) async {
                                  Provider.of<ProfileProvider>(
                                    context,
                                    listen: false,
                                  ).setContactShare(index, val);
                                  await controller.toggleContactShare(
                                    index,
                                    val,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.security_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                "No Emergency Contacts",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kDeepForest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add trusted contacts to share your location during emergencies.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ---  SWITCH WIDGET ---
class StyledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const StyledSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final activeColor = kMediumSage;
    final inactiveColor = Colors.grey.shade400;
    final activeBg = kMediumSage.withOpacity(0.2);
    final inactiveBg = Colors.grey.shade100;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? activeColor : inactiveColor,
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: activeColor,
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: value ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: inactiveColor,
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? activeColor.withOpacity(0.5)
                      : inactiveColor.withOpacity(0.5),
                  border: Border.all(
                    color: value ? activeColor : inactiveColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
