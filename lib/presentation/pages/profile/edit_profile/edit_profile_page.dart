import 'dart:io';
import 'package:flutter/material.dart';
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
      if (profileProvider.emergencyContact != null) {
        final split = profileProvider.emergencyContact!.split(' - ');
        _controller.emergencyNameController.text = split.first;
        _controller.emergencyPhoneController.text = split.last;
      }
      _controller.currentImageUrl = profileProvider.profileImage;
      _controller.fetchUserData();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF16A085).withOpacity(0.9),
                        const Color(0xFF8B4513).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Profile Image
                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          await _controller.pickImage(picker);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                const Color(0xFF16A085).withOpacity(0.3),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: const Color(0xFFE8F8F5),
                                backgroundImage:
                                    _controller.selectedImage != null
                                    ? FileImage(_controller.selectedImage!)
                                    : (_controller.currentImageUrl != null &&
                                          _controller
                                              .currentImageUrl!
                                              .isNotEmpty)
                                    ? _controller.currentImageUrl!.startsWith(
                                            'http',
                                          )
                                          ? NetworkImage(
                                              _controller.currentImageUrl!,
                                            )
                                          : FileImage(
                                              File(
                                                _controller.currentImageUrl!,
                                              ),
                                            )
                                    : AssetImage(ImageLocation.climber)
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
                      const SizedBox(height: 5),
                      const Text(
                        "Edit Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Form Card
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
                          _buildTextField(
                            label: "Emergency Contact Name",
                            controller: _controller.emergencyNameController,
                            icon: Icons.person_pin_circle_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Emergency Contact Phone",
                            controller: _controller.emergencyPhoneController,
                            icon: Icons.call_outlined,
                            inputType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Save Button (same style as logout)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () async {
                        if (_controller.formKey.currentState!.validate()) {
                          await _controller.saveProfile();

                          if (!mounted) return;
                          final profileProvider = Provider.of<ProfileProvider>(
                            context,
                            listen: false,
                          );

                          profileProvider.setProfile({
                            'id': profileProvider.userId,
                            'name': _controller.nameController.text,
                            'email': _controller.emailController.text,
                            'phone': _controller.phoneController.text,
                            'profileImage': _controller.selectedImage != null
                                ? _controller.selectedImage!.path
                                : _controller.currentImageUrl,
                            'emergencyContact':
                                '${_controller.emergencyNameController.text} - ${_controller.emergencyPhoneController.text}',
                            'totalHikes': profileProvider.totalSoloHikes,
                            'totalDistance': profileProvider.totalGroupHikes,
                          });

                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A085),
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
}
