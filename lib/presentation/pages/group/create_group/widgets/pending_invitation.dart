// // lib/presentation/widgets/pending_invitations_widget.dart
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:hikingapp/presentation/pages/group/trail_group/trail_group_page.dart';
// import 'package:hikingapp/providers/auth_provider.dart';
// import 'package:hikingapp/providers/group_provider.dart';
// import 'package:provider/provider.dart';

// // Modern nature-inspired color palette
// const Color kSoftMint = Color(0xFFE0F2E9);
// const Color kMediumSage = Color(0xFF97C1A9);
// const Color kDeepForest = Color(0xFF2C6E49);
// const Color kDeepTeal = Color(0xFF264E36);
// const Color kWarningColor = Color(0xFFFFA726);
// const Color kWarningDark = Color(0xFFE65100);
// const Color kInfoColor = Color(0xFF42A5F5);
// const Color kInfoLight = Color(0xFF64B5F6);

// // Animation duration
// const Duration kAnimationDuration = Duration(milliseconds: 600);

// class PendingInvitationsWidget extends StatefulWidget {
//   const PendingInvitationsWidget({super.key});

//   @override
//   State<PendingInvitationsWidget> createState() =>
//       _PendingInvitationsWidgetState();
// }

// class _PendingInvitationsWidgetState extends State<PendingInvitationsWidget> {
//   List<Map<String, dynamic>> _invitations = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchInvitations();
//   }

//   Future<void> _fetchInvitations() async {
//     setState(() => _isLoading = true);

//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final groupProvider = Provider.of<GroupProvider>(context, listen: false);

//     final invitations = await groupProvider.getPendingInvitations(
//       authProvider.userId ?? '',
//     );

//     setState(() {
//       _invitations = invitations;
//       _isLoading = false;
//     });
//   }

//   Future<void> _acceptInvitation(Map<String, dynamic> invitation) async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final groupProvider = Provider.of<GroupProvider>(context, listen: false);

//     final success = await groupProvider.acceptInvitation(
//       groupId: invitation['groupId'],
//       userId: authProvider.userId ?? '',
//     );

//     if (success && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Joined ${invitation['groupName']}'),
//           backgroundColor: kDeepForest,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//       );

//       // Navigate to active trail page
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (context) => ChangeNotifierProvider.value(
//             value: groupProvider,
//             child: const TrailGroupPage(),
//           ),
//         ),
//       );
//     }
//   }

//   Future<void> _declineInvitation(Map<String, dynamic> invitation) async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final groupProvider = Provider.of<GroupProvider>(context, listen: false);

//     final success = await groupProvider.declineInvitation(
//       groupId: invitation['groupId'],
//       userId: authProvider.userId ?? '',
//     );

//     if (success && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Declined invitation to ${invitation['groupName']}'),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//       );
//       _fetchInvitations(); // Refresh list
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(kDeepForest),
//             strokeWidth: 3,
//           ),
//         ),
//       );
//     }

//     if (_invitations.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: kSoftMint.withOpacity(0.5),
//             blurRadius: 15,
//             offset: const Offset(0, 6),
//             spreadRadius: 2,
//           ),
//         ],
//         border: Border.all(color: kSoftMint.withOpacity(0.3), width: 1),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Container(
//                 padding: const EdgeInsets.all(18),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [kDeepForest, kMediumSage],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: kDeepForest.withOpacity(0.2),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     // Icon container
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.mail_rounded,
//                         color: Colors.white,
//                         size: 22,
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     // Title
//                     const Expanded(
//                       child: Text(
//                         'Group Invitations',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: -0.3,
//                         ),
//                       ),
//                     ),
//                     // Count badge
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [kWarningDark, kWarningColor],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: [
//                           BoxShadow(
//                             color: kWarningDark.withOpacity(0.3),
//                             blurRadius: 6,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Text(
//                         '${_invitations.length}',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 13,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Invitation List
//               ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _invitations.length,
//                 separatorBuilder: (context, index) => Divider(
//                   height: 1,
//                   thickness: 1,
//                   color: kSoftMint.withOpacity(0.3),
//                   indent: 16,
//                   endIndent: 16,
//                 ),
//                 itemBuilder: (context, index) {
//                   return _buildInvitationCard(_invitations[index]);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInvitationCard(Map<String, dynamic> invitation) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               // Group icon with gradient background
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [kMediumSage, kDeepForest],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: [
//                     BoxShadow(
//                       color: kDeepForest.withOpacity(0.2),
//                       blurRadius: 8,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   Icons.group_rounded,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 14),
//               // Group and trail info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       invitation['groupName'] ?? 'Unnamed Group',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: kDeepForest,
//                         letterSpacing: -0.3,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.hiking_rounded,
//                           color: kMediumSage,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           invitation['trailName'] ?? 'No Trail',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: kDeepTeal,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               // Time ago with subtle background
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: kSoftMint.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   _getTimeAgo(invitation['createdAt']),
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: kDeepTeal,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           // Action buttons
//           Row(
//             children: [
//               // Accept button
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => _acceptInvitation(invitation),
//                   icon: const Icon(Icons.check_circle_rounded, size: 18),
//                   label: const Text('Accept'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kDeepForest,
//                     foregroundColor: Colors.white,
//                     elevation: 4,
//                     shadowColor: kDeepForest.withOpacity(0.4),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // Decline button
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => _declineInvitation(invitation),
//                   icon: const Icon(Icons.close_rounded, size: 18),
//                   label: const Text('Decline'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: kWarningColor,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     side: BorderSide(color: kWarningColor.withOpacity(0.7)),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   String _getTimeAgo(dynamic dateTime) {
//     if (dateTime == null) return 'Unknown';

//     DateTime date;
//     if (dateTime is String) {
//       date = DateTime.tryParse(dateTime) ?? DateTime.now();
//     } else if (dateTime is DateTime) {
//       date = dateTime;
//     } else {
//       return 'Unknown';
//     }

//     final difference = DateTime.now().difference(date);

//     if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays}d ago';
//     } else {
//       return '${(difference.inDays / 7).floor()}w ago';
//     }
//   }
// }
