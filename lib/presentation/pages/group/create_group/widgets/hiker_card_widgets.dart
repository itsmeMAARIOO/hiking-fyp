import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hikingapp/data/models/group_model.dart';

// --- Modern Nature-Inspired Color Palette ---
// Soft mint green for backgrounds and subtle elements
const Color kSoftMint = Color(0xFFA0D5B9);
// Medium sage green for primary interactive elements
const Color kMediumSage = Color(0xFF6BAF89);
// Deep forest green for emphasis and important actions
const Color kDeepForest = Color(0xFF3E7B5B);
// Deep teal for text and icons
const Color kDeepTeal = Color(0xFF1C3F3F);
// Warning colors for alerts and groups
const Color kWarningColor = Color(0xFFFFA726);
const Color kWarningDark = Color(0xFFE65100);
// Info colors for distance indicators
const Color kInfoColor = Color(0xFF42A5F5);
const Color kInfoLight = Color(0xFF64B5F6);

// Animation duration for consistent feel
const Duration kAnimationDuration = Duration(milliseconds: 400);

class HikerInviteCard extends StatelessWidget {
  final GroupMember hiker;
  final bool isSelected;
  final VoidCallback onTap;

  const HikerInviteCard({
    super.key,
    required this.hiker,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure null-safety for distance parsing.
    final distance = double.tryParse(hiker.distance ?? '0') ?? 0;

    return AnimatedContainer(
      duration: kAnimationDuration,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? kDeepForest : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? kDeepForest.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 16 : 10,
            offset: Offset(0, isSelected ? 6 : 3),
            spreadRadius: isSelected ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: kSoftMint.withOpacity(0.3),
              highlightColor: kSoftMint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _buildAvatar(isSelected),
                    const SizedBox(width: 18),
                    Expanded(child: _buildHikerInfo()),
                    const SizedBox(width: 14),
                    _buildDistanceInfo(distance, hiker.lastUpdated),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isSelected) {
    return AnimatedContainer(
      duration: kAnimationDuration,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected 
              ? [kDeepForest, kMediumSage]
              : [kSoftMint.withOpacity(0.5), kMediumSage.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? kDeepForest.withOpacity(0.3)
                : kMediumSage.withOpacity(0.2),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: isSelected ? 1 : 0,
          ),
        ],
      ),
      child: Icon(
        Icons.person_4_rounded,
        color: isSelected ? Colors.white : kDeepTeal,
        size: 28,
      ),
    );
  }

  Widget _buildHikerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hiker.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDeepTeal,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        if (hiker.groupName != null && hiker.groupName!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kWarningColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kWarningColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_rounded, size: 14, color: kWarningDark),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'In: ${hiker.groupName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: kWarningDark,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDistanceInfo(double distance, DateTime? lastUpdated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getDistanceColors(distance),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _getDistanceColors(distance)[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${distance.toStringAsFixed(2)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getTimeAgo(lastUpdated),
          style: TextStyle(
            fontSize: 12,
            color: kDeepTeal.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Color> _getDistanceColors(double distance) {
    // Near (Green) - up to 0.5km
    if (distance < 0.5) {
      return [kDeepForest, kMediumSage];
      // Medium (Orange/Warning) - up to 2.0km
    } else if (distance < 2.0) {
      return [kWarningDark, kWarningColor];
      // Far (Blue/Info) - beyond 2.0km
    } else {
      return [kInfoColor, kInfoLight];
    }
  }

  // Handle nullable DateTime for lastUpdated
  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'long ago';
    }
  }
}

class ConfirmMemberCard extends StatelessWidget {
  final GroupMember hiker;

  const ConfirmMemberCard({super.key, required this.hiker});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kSoftMint.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: kSoftMint.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // --- Avatar ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kDeepForest, kMediumSage],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kDeepForest.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),

                // --- Info ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hiker.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: kDeepTeal,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Invitation Status
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 14,
                            color: kDeepTeal.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 13,
                              color: kDeepTeal.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- Status Tag (Invited) ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kMediumSage, kDeepForest],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kMediumSage.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Invited',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
