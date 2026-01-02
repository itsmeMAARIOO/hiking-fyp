import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class CreateSoloStep1 extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController descriptionController;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int? durationMinutes;
  final ValueChanged<int?>? onDurationChanged;

  const CreateSoloStep1({
    super.key,
    required this.controller,
    required this.descriptionController,
    required this.isLoading,
    required this.onNext,
    this.onBack,
    this.durationMinutes,
    this.onDurationChanged,
  });

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

          // Trail name
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
              controller: controller,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kDeepForest,
              ),
              decoration: InputDecoration(
                labelText: 'Trail Name',
                labelStyle: TextStyle(
                  color: kDeepForest.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'e.g. Glimspe of Dusk',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.edit_location_alt_rounded,
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

          const SizedBox(height: 24),

          // Description
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
              controller: descriptionController,
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
                  vertical: 14,
                  horizontal: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // expected duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.access_time_rounded, color: kMediumSage),
                    SizedBox(width: 10),
                    Text(
                      'Expected Duration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kDeepForest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final minutes = durationMinutes ?? 0;
                    final h = minutes ~/ 60;
                    final m = minutes % 60;
                    final label = minutes > 0
                        ? (h > 0 ? (m > 0 ? '${h}h ${m}m' : '${h}h') : '${m}m')
                        : 'Select';
                    return Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDeepForest.withOpacity(0.6),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                    activeTrackColor: kMediumSage,
                    inactiveTrackColor: kMediumSage.withOpacity(0.2),
                    thumbColor: kMediumSage,
                  ),
                  child: Slider(
                    min: 1,
                    max: 720,
                    divisions: 719,
                    value: ((durationMinutes ?? 30)).toDouble().clamp(
                      1.0,
                      720.0,
                    ),
                    onChanged: (v) {
                      int minutes = v.round();
                      if (minutes < 30) {
                        onDurationChanged?.call(1);
                      } else {
                        final snapped = ((minutes / 30).round()) * 30;
                        onDurationChanged?.call(snapped);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
