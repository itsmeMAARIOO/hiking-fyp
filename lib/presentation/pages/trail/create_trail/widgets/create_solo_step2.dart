import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';

class SoloNotifyStep extends StatelessWidget {
  const SoloNotifyStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final contacts = profile.emergencyContacts;
        if (contacts.isEmpty) {
          return Container(
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
              'No emergency contacts added',
              style: TextStyle(
                color: kDeepForest.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Notify Emergency Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kDeepForest,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(contacts.length, (i) {
                final c = contacts[i];
                final enabled = (c['share'] ?? 'false') == 'true';
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
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: Color(0xFFFF6B35),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (c['name'] ?? '').isEmpty
                                  ? 'Contact'
                                  : (c['name'] ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kDeepForest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ...(() {
                              final email = (c['email'] ?? '').trim();
                              final phone = (c['phone'] ?? '').trim();
                              return [
                                if (email.isNotEmpty)
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
                                if (phone.isNotEmpty)
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
                              ];
                            })(),
                          ],
                        ),
                      ),
                      Switch(
                        value: enabled,
                        activeColor: kMediumSage,
                        onChanged: (v) {
                          profile.setContactShare(i, v);
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

