import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/group/create_group/widgets/step_indicator_widgets.dart'
    as step;
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';

class SoloTrailNamePage extends StatefulWidget {
  const SoloTrailNamePage({super.key});

  @override
  State<SoloTrailNamePage> createState() => _SoloTrailNamePageState();
}

class _SoloTrailNamePageState extends State<SoloTrailNamePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onConfirm() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackbarHelper.showError(
        'Trail Name Required',
        'Please enter a trail name',
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isLoading = false);

    Get.toNamed(AppRoutes.soloTrail, arguments: {"trailName": name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C3F3F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: const [
                  Icon(Icons.edit_location_alt_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Solo Trail Setup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trail Name',
                        style: TextStyle(
                          color: Color(0xFF1C3F3F),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter a name for your trail',
                          filled: true,
                          fillColor: const Color(0xFFF8FAF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6BAF89),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6BAF89),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3E7B5B),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Confirm button styled similarly to group step indicator
                      step.NavigationButton(
                        currentStep: 2,
                        isLoading: _isLoading,
                        onNext: _onConfirm,
                        onBack: () => Get.back(),
                      ),
                      const SizedBox(height: 24),
                    ],
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
