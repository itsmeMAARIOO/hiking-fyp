import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/presentation/widgets/stylish_select.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import '../../../../providers/profile_provider.dart';
import 'edit_profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  final String? userId;
  const EditProfileScreen({super.key, this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late EditProfileController _controller;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _controller = EditProfileController(
      userId: authProvider.userId ?? profileProvider.userId,
      context: context,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.nameController.text = profileProvider.userName ?? '';
      _controller.emailController.text = profileProvider.userEmail ?? '';
      _controller.phoneController.text = profileProvider.phone ?? '';
      _controller.currentImageUrl = profileProvider.profileImage;
      _controller.fetchUserData();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      CommonHeader(
                        title: 'Edit Profile',
                        showBack: true,
                        onBack: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _controller.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: InkWell(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      await _controller.pickImage(picker);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kDeepTeal,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 45,
                                            backgroundColor: const Color(
                                              0xFFE8F8F5,
                                            ),
                                            backgroundImage:
                                                _controller.selectedImage !=
                                                    null
                                                ? FileImage(
                                                    _controller.selectedImage!,
                                                  )
                                                : (_controller.currentImageUrl !=
                                                          null &&
                                                      _controller
                                                          .currentImageUrl!
                                                          .isNotEmpty)
                                                ? _controller.currentImageUrl!
                                                          .startsWith('http')
                                                      ? NetworkImage(
                                                          _controller
                                                              .currentImageUrl!,
                                                        )
                                                      : FileImage(
                                                          File(
                                                            _controller
                                                                .currentImageUrl!,
                                                          ),
                                                        )
                                                : AssetImage(
                                                        ImageLocation.climber,
                                                      )
                                                      as ImageProvider,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: CircleAvatar(
                                              backgroundColor: Colors.white,
                                              radius: 16,
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.black87,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: "Full Name",
                                  controller: _controller.nameController,
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: "Email",
                                  controller: _controller.emailController,
                                  icon: Icons.email_outlined,
                                  inputType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: "Phone Number",
                                  controller: _controller.phoneController,
                                  icon: Icons.phone_outlined,
                                  inputType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildDateField(
                                  label: "Date of Birth",
                                  controller: _controller.dobController,
                                  icon: Icons.calendar_month_outlined,
                                ),
                                const SizedBox(height: 16),
                                StylishSelect(
                                  label: "Gender",
                                  items: const ['Male', 'Female', 'Other'],
                                  value: _controller.gender,
                                  onChanged: (v) {
                                    setState(() {
                                      _controller.gender = v;
                                    });
                                  },
                                  prefixIcon: Icons.transgender,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: "Weight (kg)",
                                  controller: _controller.weightController,
                                  icon: Icons.fitness_center_outlined,
                                  inputType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: "Height (cm)",
                                  controller: _controller.heightController,
                                  icon: Icons.height,
                                  inputType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                StylishSelect(
                                  label: "Blood Type",
                                  items: const [
                                    'A+',
                                    'A-',
                                    'B+',
                                    'B-',
                                    'O+',
                                    'O-',
                                    'AB+',
                                    'AB-',
                                  ],
                                  value: _controller.bloodType,
                                  onChanged: (v) {
                                    setState(() {
                                      _controller.bloodType = v;
                                    });
                                  },
                                  prefixIcon: Icons.bloodtype_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: "Allergies",
                                  controller: _controller.allergiesController,
                                  icon: Icons.sick_outlined,
                                ),
                                const SizedBox(height: 0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              if (_controller.formKey.currentState!
                                  .validate()) {
                                await _controller.saveProfile();

                                if (!mounted) return;
                                final profileProvider =
                                    Provider.of<ProfileProvider>(
                                      context,
                                      listen: false,
                                    );

                                profileProvider.setProfile({
                                  'id': profileProvider.userId,
                                  'name': _controller.nameController.text,
                                  'email': _controller.emailController.text,
                                  'phone': _controller.phoneController.text,
                                  'profileImage':
                                      _controller.selectedImage != null
                                      ? _controller.selectedImage!.path
                                      : _controller.currentImageUrl,
                                  'totalHikes': profileProvider.totalSoloHikes,
                                  'totalDistance':
                                      profileProvider.totalGroupHikes,
                                });

                                if (mounted) Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDeepForest,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: (val) => val!.isEmpty ? "$label cannot be empty" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF16A085)),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF16A085), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: (val) => val!.isEmpty ? "$label cannot be empty" : null,
      onTap: _openDobPicker,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF16A085)),
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF16A085), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        suffixIcon: const Icon(
          Icons.calendar_today_rounded,
          color: Color(0xFF16A085),
        ),
      ),
    );
  }

  void _openDobPicker() {
    final initial =
        _tryParseDate(_controller.dobController.text) ??
        DateTime(DateTime.now().year - 18, 1, 1);

    DateTime selected = initial;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: Color(0xFFE8F8F5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF16A085),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Select Date of Birth',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A085),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _controller.dobController.text = _formatStorageDate(
                            selected,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 260,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initial,
                    minimumDate: DateTime(1900, 1, 1),
                    maximumDate: DateTime(DateTime.now().year, 12, 31),
                    minimumYear: 1900,
                    maximumYear: DateTime.now().year,
                    onDateTimeChanged: (DateTime value) {
                      selected = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime? _tryParseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatStorageDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
