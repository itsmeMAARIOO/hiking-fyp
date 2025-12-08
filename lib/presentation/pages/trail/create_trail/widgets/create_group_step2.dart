import 'package:flutter/material.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'hiker_card_widgets.dart'; // Assumed to contain HikerInviteCard

// --- Color Palette & Constants (Used by the UI) ---
const Color kBackgroundColor = Color(0xFFA0D5B9);
const Color kPrimaryColor = Color(0xFF6BAF89);
const Color kDarkPrimaryColor = Color(0xFF3E7B5B);
const Color kTextColor = Color(0xFF1C3F3F);
const Duration kAnimationDuration = Duration(milliseconds: 300);

// --- Main Step Widget ---

class Step2InviteHikers extends StatelessWidget {
  final GroupProvider provider;
  final List<GroupMember> selectedHikers;
  final bool isScanning;
  final VoidCallback onScan;
  final Function(GroupMember) onToggleSelection;

  const Step2InviteHikers({
    super.key,
    required this.provider,
    required this.selectedHikers,
    required this.isScanning,
    required this.onScan,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Relying on the imported GroupProvider model
    final hikers = provider.nearbyMembers;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),

          // --- Scan Button ---
          Center(
            child: AnimatedContainer(
              duration: kAnimationDuration,
              curve: Curves.easeOut,
              width: 180,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isScanning ? 35 : 16),
                gradient: isScanning
                    ? null // No gradient while loading
                    : const LinearGradient(
                        colors: [kPrimaryColor, kDarkPrimaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isScanning ? Colors.grey[400] : null,
                boxShadow: isScanning
                    ? null
                    : [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isScanning ? null : onScan,
                  borderRadius: BorderRadius.circular(isScanning ? 35 : 16),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: kAnimationDuration,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                      child: isScanning
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              key: ValueKey('scan'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.radar_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Scan Nearby',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- List Status & Selected Count ---
          if (hikers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Found ${hikers.length} Hikers | ${selectedHikers.length} Selected',
                style: const TextStyle(
                  color: kDarkPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

          // --- List Content ---
          if (hikers.isEmpty && !isScanning)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No nearby hikers found yet.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Using HikerInviteCard from the assumed 'hiker_card_widgets.dart' import
            ...hikers.map((hiker) {
              final isSelected = selectedHikers.any(
                (h) => h.userId == hiker.userId,
              );
              return HikerInviteCard(
                hiker: hiker,
                isSelected: isSelected,
                onTap: () => onToggleSelection(hiker),
              );
            }).toList(),
        ],
      ),
    );
  }
}
