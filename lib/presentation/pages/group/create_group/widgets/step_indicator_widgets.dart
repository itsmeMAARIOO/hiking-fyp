// lib/presentation/pages/group/create_group/widgets/step_indicator_widgets.dart
import 'package:flutter/material.dart';

// --- Color Palette & Constants ---

const Color kBackgroundColor = Color(0xFFA0D5B9);
const Color kPrimaryColor = Color(0xFF6BAF89);
const Color kDarkPrimaryColor = Color(0xFF3E7B5B);
const Color kTextColor = Color(0xFF1C3F3F);
const Duration kAnimationDuration = Duration(milliseconds: 500);

// --- 1. Floating Navigation Button (Circular) ---

class NavigationButton extends StatelessWidget {
  final int currentStep;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const NavigationButton({
    super.key,
    required this.currentStep,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLastStep = currentStep == 2;
    final IconData icon = isLastStep
        ? Icons.check_rounded
        : Icons.arrow_forward_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Back Button
        if (currentStep > 0)
          FloatingActionButton(
            heroTag: 'backButton',
            onPressed: isLoading ? null : onBack,
            mini: true,
            backgroundColor: Colors.white.withOpacity(0.9),
            elevation: 8,
            shape: const CircleBorder(
              side: BorderSide(color: kDarkPrimaryColor, width: 1),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isLoading ? Colors.grey : kDarkPrimaryColor,
              size: 20,
            ),
          ),

        if (currentStep > 0) const SizedBox(width: 24),

        // Main Action Button
        AnimatedContainer(
          duration: kAnimationDuration,
          curve: Curves.easeOutBack,
          height: 72,
          width: isLastStep ? 120 : 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLastStep ? 36 : 72),
            gradient: isLoading
                ? null
                : const LinearGradient(
                    colors: [kPrimaryColor, kDarkPrimaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isLoading ? Colors.grey[400] : null,
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onNext,
              borderRadius: BorderRadius.circular(isLastStep ? 36 : 72),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: isLastStep ? 12 : 0,
                              left: isLastStep ? 8 : 0,
                            ),
                            child: Icon(icon, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 2. Enhanced Step Progress Indicator (Organic/Animated) ---

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;

  const StepProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepOrb(
            stepNumber: 1,
            label: 'Details',
            isActive: currentStep == 0,
            isCompleted: currentStep > 0,
          ),
          _StepLine(isActive: currentStep >= 1),

          _StepOrb(
            stepNumber: 2,
            label: 'Invite',
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
          ),
          _StepLine(isActive: currentStep >= 2),

          _StepOrb(
            stepNumber: 3,
            label: 'Confirm',
            isActive: currentStep == 2,
            isCompleted: currentStep > 2,
          ),
        ],
      ),
    );
  }
}

// --- 3. Step Orb (Organic Shape with Animation) ---

class _StepOrb extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepOrb({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isCompleted || isActive
        ? Colors.white
        : kTextColor.withOpacity(0.7);

    // FIX 1: Define gradients for both active and inactive states to allow smooth interpolation.
    final Gradient activeGradient = const LinearGradient(
      colors: [kPrimaryColor, kDarkPrimaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    // Inactive gradient is just a flat color from the palette
    final Gradient inactiveGradient = LinearGradient(
      colors: [
        kBackgroundColor.withOpacity(0.6),
        kBackgroundColor.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // FIX 2: Ensure the shadow list always has the same length (1) and valid blur properties.
    final List<BoxShadow> orbShadows = isActive || isCompleted
        ? [
            // Active shadow
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ]
        : [
            // Inactive shadow for smooth lerping
            BoxShadow(
              color: kTextColor.withOpacity(
                0.1,
              ), // Subtle color for neumorphic lift
              blurRadius: 5.0, // Non-negative blur radius
              offset: const Offset(2, 2),
            ),
          ];

    return Column(
      children: [
        AnimatedContainer(
          duration: kAnimationDuration,
          curve: Curves.elasticOut,
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Removed 'color' property since 'gradient' is now always set
            boxShadow: orbShadows,
            gradient: isActive || isCompleted
                ? activeGradient
                : inactiveGradient, // Always use a gradient
          ),
          child: ClipPath(
            clipper: _CustomPathClipper(isActive: isActive),
            child: Center(
              child: AnimatedSwitcher(
                duration: kAnimationDuration,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation.drive(
                      Tween<double>(
                        begin: 0.2,
                        end: 1.0,
                      ).chain(CurveTween(curve: Curves.easeInOutBack)),
                    ),
                    child: child,
                  );
                },
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        color: foregroundColor,
                        size: 30,
                        key: const ValueKey('check'),
                      )
                    : Text(
                        '$stepNumber',
                        key: ValueKey('step$stepNumber'),
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          shadows:
                              const [], // Explicitly set empty shadows to prevent animation issues
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? kDarkPrimaryColor : kTextColor.withOpacity(0.7),
            fontWeight: isActive || isCompleted
                ? FontWeight.bold
                : FontWeight.w600,
            shadows:
                const [], // Explicitly set empty shadows to prevent animation issues
          ),
        ),
      ],
    );
  }
}

// --- 4. Custom Clipper for Organic Shape ---

class _CustomPathClipper extends CustomClipper<Path> {
  final bool isActive;

  _CustomPathClipper({required this.isActive});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    if (isActive) {
      path.moveTo(w * 0.5, 0);
      path.cubicTo(w * 0.9, h * 0.1, w, h * 0.4, w * 0.9, h * 0.7);
      path.cubicTo(w * 0.8, h * 0.9, w * 0.6, h, w * 0.4, h * 0.9);
      path.cubicTo(w * 0.2, h * 0.8, w * 0.1, h * 0.6, w * 0.1, h * 0.3);
      path.cubicTo(w * 0.1, h * 0.1, w * 0.4, 0, w * 0.5, 0);
    } else {
      path.addOval(Rect.fromLTWH(0, 0, w, h));
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _CustomPathClipper oldClipper) {
    return oldClipper.isActive != isActive;
  }
}

// --- 5. Step Line (Animated) ---

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: kAnimationDuration,
        curve: Curves.easeInOut,
        height: 4,
        margin: const EdgeInsets.only(bottom: 40, left: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: isActive
              ? const LinearGradient(
                  colors: [kPrimaryColor, kDarkPrimaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isActive ? null : kBackgroundColor.withOpacity(0.7),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
          ],
        ),
      ),
    );
  }
}
