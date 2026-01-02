import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class Step1GroupDetails extends StatefulWidget {
  final TextEditingController groupNameController;
  final TextEditingController trailNameController;
  final TextEditingController trailDescriptionController;

  const Step1GroupDetails({
    super.key,
    required this.groupNameController,
    required this.trailNameController,
    required this.trailDescriptionController,
  });

  @override
  State<Step1GroupDetails> createState() => _Step1GroupDetailsState();
}

class _Step1GroupDetailsState extends State<Step1GroupDetails> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kDeepForest.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: widget.groupNameController,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kDeepForest,
              ),
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: TextStyle(
                  color: kDeepForest.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'e.g. Summit Squad',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.groups_rounded,
                    color: kMediumSage,
                    size: 22,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kDeepForest.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: widget.trailNameController,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kDeepForest,
              ),
              decoration: InputDecoration(
                labelText: 'Trail Name (Optional)',
                labelStyle: TextStyle(
                  color: kDeepForest.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'e.g. Mount Kinabalu Route',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.landscape_rounded,
                    color: kMediumSage,
                    size: 22,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kDeepForest.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: widget.trailDescriptionController,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kDeepForest,
              ),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(
                  color: kDeepForest.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'Notes about this route',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.description_rounded,
                    color: kMediumSage,
                    size: 22,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
