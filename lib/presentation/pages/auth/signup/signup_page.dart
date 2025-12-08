import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/services/auth_services.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

// Ensure you have your StylishSelect widget available, or replace with DropdownButtonFormField
import 'package:hikingapp/presentation/widgets/stylish_select.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // --- Controllers ---
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  final _allergiesController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // New controller

  // --- State Variables ---
  String? _gender;
  String? _bloodType;
  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  final PageController _pageController = PageController();
  int _currentStep = 0;

  Future<void> _pickDob() async {
    final existing = DateTime.tryParse(_dobController.text);
    DateTime init = existing ?? DateTime(2000, 1, 1);
    if (init.isAfter(DateTime.now())) init = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  bool _isValidEmail(String v) {
    final s = v.trim();
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(s);
  }

  bool _isStepValid(int step) {
    if (step == 0) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final dob = _dobController.text.trim();
      final weight = _weightController.text.trim();
      final height = _heightController.text.trim();
      final g = _gender?.trim() ?? '';
      final dobOk =
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob) &&
          DateTime.tryParse(dob) != null;
      final weightOk = double.tryParse(weight) != null;
      final heightOk = double.tryParse(height) != null;
      return name.isNotEmpty &&
          phone.isNotEmpty &&
          dob.isNotEmpty &&
          g.isNotEmpty &&
          weight.isNotEmpty &&
          height.isNotEmpty &&
          dobOk &&
          weightOk &&
          heightOk;
    }
    if (step == 1) {
      final bt = _bloodType?.trim() ?? '';
      return bt.isNotEmpty;
    }
    final email = _emailController.text.trim();
    final pw = _passwordController.text;
    final cpw = _confirmPasswordController.text;
    final emailOk = email.isNotEmpty && _isValidEmail(email);
    return emailOk && pw.isNotEmpty && cpw.isNotEmpty && _passwordsMatch;
  }

  // --- Cleanup ---
  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Logic ---

  bool get _passwordsMatch {
    return _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _signup() async {
    if (!_passwordsMatch) {
      Get.snackbar("Error", "Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        dateOfBirth: _dobController.text.isNotEmpty
            ? DateTime.tryParse(_dobController.text)?.toIso8601String() ??
                  _dobController.text
            : null,
        gender: _gender,
        weightKg: double.tryParse(_weightController.text),
        heightCm: double.tryParse(_heightController.text),
        bloodType: _bloodType,
        allergies: _allergiesController.text.isNotEmpty
            ? _allergiesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      if (response["message"] == "User created") {
        Get.snackbar("Success", "Account created. Please log in.");
        Get.offNamed(AppRoutes.login);
      } else {
        Get.snackbar("Error", response["message"] ?? "Signup failed");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    final valid = _isStepValid(_currentStep);
    if (!valid) {
      Get.snackbar("Incomplete", "Please fill all fields correctly");
      return;
    }
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _signup();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Get.offNamed(AppRoutes.login);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [kDeepTeal, kDeepForest, kSoftMint],
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _prevPage,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color.fromARGB(255, 216, 240, 227),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Step ${_currentStep + 1} of 3",
                            style: TextStyle(
                              color: kSoftMint,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Create Account",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 215, 233, 223),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      _buildProgressIndicator(0),
                      const SizedBox(width: 8),
                      _buildProgressIndicator(1),
                      const SizedBox(width: 8),
                      _buildProgressIndicator(2),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics:
                                const NeverScrollableScrollPhysics(), // Prevent swiping, force buttons
                            children: [
                              _buildStep1Personal(),
                              _buildStep2Safety(),
                              _buildStep3Security(),
                            ],
                          ),
                        ),

                        // Bottom Action Button Area
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: _buildBottomButtons(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildProgressIndicator(int stepIndex) {
    bool isActive = _currentStep >= stepIndex;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? kMediumSage : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // --- STEP 1: PERSONAL INFO ---
  Widget _buildStep1Personal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle("Personal Info", "Tell us a bit about yourself."),
          const SizedBox(height: 20),

          _buildTextField(_nameController, "Full Name", Icons.person_outline),
          const SizedBox(height: 16),

          _buildTextField(
            _phoneController,
            "Phone Number",
            Icons.phone_outlined,
            type: TextInputType.phone,
            isInvalid: () => false,
          ),
          const SizedBox(height: 16),

          _buildDobField(),
          const SizedBox(height: 16),

          StylishSelect(
            label: "Gender",
            items: const ['Male', 'Female', 'Other'],
            value: _gender,
            prefixIcon: Icons.wc,
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _weightController,
                  "kg",
                  Icons.monitor_weight_outlined,
                  type: TextInputType.number,
                  isInvalid: () =>
                      _weightController.text.isNotEmpty &&
                      double.tryParse(_weightController.text) == null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  _heightController,
                  "cm",
                  Icons.height,
                  type: TextInputType.number,
                  isInvalid: () =>
                      _heightController.text.isNotEmpty &&
                      double.tryParse(_heightController.text) == null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 2: SAFETY INFO ---
  Widget _buildStep2Safety() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            "Safety Profile",
            "Crucial for emergency responders.",
          ),
          const SizedBox(height: 20),

          StylishSelect(
            label: "Blood Type",
            items: const ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
            value: _bloodType,
            prefixIcon: Icons.bloodtype_outlined,
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _allergiesController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "Allergies / Medical Conditions",
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.medical_services_outlined, color: kDeepTeal),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7F7),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _allergiesController.text.trim().isEmpty
                      ? Colors.transparent
                      : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _allergiesController.text.trim().isEmpty
                      ? Colors.transparent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Separate with commas (e.g., Peanuts, Penicillin, Asthma)",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: ACCOUNT SECURITY ---
  Widget _buildStep3Security() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            "Account Security",
            "Secure your Hiking App account.",
          ),
          const SizedBox(height: 20),

          _buildTextField(
            _emailController,
            "Email Address",
            Icons.email_outlined,
            type: TextInputType.emailAddress,
            isInvalid: () =>
                _emailController.text.isNotEmpty &&
                !_isValidEmail(_emailController.text),
          ),
          const SizedBox(height: 16),

          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: _isPasswordHidden,
            onChanged: (_) => setState(() {}), // Rebuild to check match
            decoration: InputDecoration(
              labelText: "Password",
              filled: true,
              fillColor: const Color(0xFFF5F7F7),
              prefixIcon: const Icon(Icons.lock_outline, color: kDeepTeal),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _isPasswordHidden = !_isPasswordHidden),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextField(
            controller: _confirmPasswordController,
            obscureText: _isConfirmPasswordHidden,
            onChanged: (_) => setState(() {}), // Rebuild to enable button
            decoration: InputDecoration(
              labelText: "Confirm Password",
              filled: true,
              fillColor: const Color(0xFFF5F7F7),
              prefixIcon: const Icon(Icons.lock_reset, color: kDeepTeal),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordHidden
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(
                  () => _isConfirmPasswordHidden = !_isConfirmPasswordHidden,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              // Visual cue for matching
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _passwordsMatch ? kMediumSage : Colors.redAccent,
                  width: 2,
                ),
              ),
            ),
          ),

          if (_passwordController.text.isNotEmpty &&
              _confirmPasswordController.text.isNotEmpty &&
              !_passwordsMatch)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 12),
              child: Text(
                "Passwords do not match",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 2;
    final canProceed = _isStepValid(_currentStep);

    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _prevPage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: kMediumSage.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Back",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kDeepForest,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: canProceed
                  ? const LinearGradient(colors: [kMediumSage, kDeepForest])
                  : const LinearGradient(colors: [Colors.grey, Colors.grey]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: canProceed
                  ? [
                      BoxShadow(
                        color: kMediumSage.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: (_isLoading || !canProceed) ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? "Register Account" : "Next Step",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper for Text Fields ---
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    bool Function()? isInvalid,
  }) {
    final invalid = (isInvalid?.call() ?? false);
    return TextField(
      controller: controller,
      keyboardType: type,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F7F7),
        prefixIcon: Icon(icon, color: kDeepTeal),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: invalid ? Colors.red : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: invalid ? Colors.red : Colors.transparent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kDeepForest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDobField() {
    return TextField(
      controller: _dobController,
      readOnly: true,
      onTap: _pickDob,
      decoration: InputDecoration(
        labelText: "Date of Birth",
        filled: true,
        fillColor: const Color(0xFFF5F7F7),
        prefixIcon: const Icon(Icons.calendar_today_outlined, color: kDeepTeal),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
