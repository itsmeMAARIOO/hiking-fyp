import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';

class EditProfileController extends ChangeNotifier {
  final BuildContext context;
  final String? userId;

  EditProfileController({required this.context, required this.userId});

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  File? selectedImage;
  String? currentImageUrl;
  bool isLoading = false;

  // Internal flag to prevent notifyListeners after dispose
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ✅ Fetch user data
  Future<void> fetchUserData() async {
    if (userId == null) {
      debugPrint("⚠️ No userId provided.");
      return;
    }

    try {
      isLoading = true;
      safeNotify();

      final url = Uri.parse("${ApiConfig.baseUrl}/users/$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emergencyNameController.text = data['emergencyContact']?['name'] ?? '';
        emergencyPhoneController.text =
            data['emergencyContact']?['phone'] ?? '';
        currentImageUrl =
            data['profileImage'] != null && data['profileImage'].isNotEmpty
            ? data['profileImage']
            : null;
      } else {
        debugPrint("❌ Failed to fetch user data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching user data: $e");
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  // ✅ Pick a new image
  Future<void> pickImage(ImagePicker picker) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage = File(pickedFile.path);
      currentImageUrl = null;
      safeNotify();
    }
  }

  // ✅ Save updated profile
  // Returns the API response as Map<String, dynamic> or null on error
  Future<Map<String, dynamic>?> saveProfile() async {
    if (!formKey.currentState!.validate()) return null;

    if (userId == null) {
      if (context.mounted) {
        SnackbarHelper.showError(
          "Error",
          "User ID not found. Please log in again.",
        );
      }
      return null;
    }

    isLoading = true;
    safeNotify();

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/update");
      final request = http.MultipartRequest("POST", url);

      request.fields['userId'] = userId!;
      request.fields['name'] = nameController.text;
      request.fields['email'] = emailController.text;
      request.fields['phone'] = phoneController.text;
      request.fields['emergencyContact'] = jsonEncode({
        'name': emergencyNameController.text,
        'phone': emergencyPhoneController.text,
      });

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage',
            selectedImage!.path,
          ),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final respData = jsonDecode(respStr);

      if (response.statusCode == 200 && context.mounted) {
        SnackbarHelper.showSuccess("Success", "Profile updated successfully");
      } else if (context.mounted) {
        SnackbarHelper.showError(
          "Error",
          "Error: ${response.reasonPhrase ?? 'Unknown'}",
        );
      }

      return respData;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError("Error", "Error: $e");
      }
      return null;
    } finally {
      isLoading = false;
      safeNotify();
    }
  }
}
