import 'package:flutter/material.dart';

class Step1GroupDetails extends StatefulWidget {
  final TextEditingController groupNameController;
  final TextEditingController trailNameController;

  const Step1GroupDetails({
    super.key,
    required this.groupNameController,
    required this.trailNameController,
  });

  @override
  State<Step1GroupDetails> createState() => _Step1GroupDetailsState();
}

class _Step1GroupDetailsState extends State<Step1GroupDetails>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _groupNameFocused = false;
  bool _trailNameFocused = false;

  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent background (no color blocking the main background)
        Positioned.fill(child: Container(color: Colors.transparent)),

        // Main content (centered form card)
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
            child: _buildFormCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3E7B5B).withOpacity(0.1),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomTextField(
                controller: widget.groupNameController,
                label: 'Group Name',
                hint: 'Summit Squad',
                icon: Icons.groups_rounded,
                isRequired: true,
                isFocused: _groupNameFocused,
                onFocusChange: (focused) {
                  setState(() => _groupNameFocused = focused);
                },
              ),
              const SizedBox(height: 20),
              _buildCustomTextField(
                controller: widget.trailNameController,
                label: 'Trail Name',
                hint: 'Mount Kinabalu Route',
                icon: Icons.landscape_rounded,
                isRequired: false,
                isFocused: _trailNameFocused,
                onFocusChange: (focused) {
                  setState(() => _trailNameFocused = focused);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isRequired,
    required bool isFocused,
    required Function(bool) onFocusChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C3F3F),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF6BAF89).withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C3F3F),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF1C3F3F).withOpacity(0.4),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFocused
                      ? const Color(0xFF3E7B5B).withOpacity(0.1)
                      : const Color(0xFF6BAF89).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isFocused
                      ? const Color(0xFF3E7B5B)
                      : const Color(0xFF6BAF89),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE8F4EE),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE8F4EE),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF3E7B5B),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
