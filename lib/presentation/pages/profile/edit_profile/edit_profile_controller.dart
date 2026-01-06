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
  final dobController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final allergiesController = TextEditingController();
  String? gender;
  String? bloodType;
  // Emergency contacts managed separately on Profile page

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

  // Fetch user data
  Future<void> fetchUserData() async {
    if (userId == null) {
      debugPrint("No userId provided.");
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
        if (data['dateOfBirth'] != null) {
          try {
            final dobVal = data['dateOfBirth'];
            if (dobVal is String) {
              dobController.text = dobVal.split('T').first;
            } else {
              dobController.text = dobVal.toString();
            }
          } catch (_) {}
        }
        gender = (data['gender'] ?? null) as String?;
        bloodType = (data['bloodType'] ?? null) as String?;
        final w = data['weightKg'];
        final h = data['heightCm'];
        if (w != null) weightController.text = w.toString();
        if (h != null) heightController.text = h.toString();
        if (data['allergies'] is List) {
          final list = List<String>.from(data['allergies']);
          allergiesController.text = list.join(', ');
        } else if (data['allergies'] is String) {
          allergiesController.text = data['allergies'];
        }
        // Emergency contacts fetched separately
        currentImageUrl =
            data['profileImage'] != null && data['profileImage'].isNotEmpty
            ? data['profileImage']
            : null;
      } else {
        debugPrint("Failed to fetch user data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  // Pick a new image
  Future<void> pickImage(ImagePicker picker) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage = File(pickedFile.path);
      currentImageUrl = null;
      safeNotify();
    }
  }

  // Save updated profile
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
      if (dobController.text.isNotEmpty) {
        final iso =
            DateTime.tryParse(dobController.text)?.toIso8601String() ??
            dobController.text;
        request.fields['dateOfBirth'] = iso;
      }
      if (gender != null) request.fields['gender'] = gender!;
      if (bloodType != null) request.fields['bloodType'] = bloodType!;
      if (weightController.text.isNotEmpty)
        request.fields['weightKg'] = weightController.text;
      if (heightController.text.isNotEmpty)
        request.fields['heightCm'] = heightController.text;
      if (allergiesController.text.isNotEmpty)
        request.fields['allergies'] = allergiesController.text;
      // Emergency contacts are updated via dedicated APIs

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
