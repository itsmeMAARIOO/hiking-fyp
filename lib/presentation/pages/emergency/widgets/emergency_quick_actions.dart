import 'package:flutter/material.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:hikingapp/presentation/styles/colors.dart';

class QuickActionsButtons extends StatelessWidget {
  const QuickActionsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);
    final isSending = emergencyProvider.isSendingLocation;
    final sosActive = emergencyProvider.sosActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Emergency Call Button
            Expanded(
              child: _NatureActionButton(
                onPressed: () => emergencyProvider.callEmergency(context),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.shade600, Colors.red.shade800],
                ),
                icon: Icons.emergency_rounded,
                title: "Emergency",
                subtitle: "Call",
                accentColor: Colors.red.shade300,
              ),
            ),
            const SizedBox(width: 12),

            // First Aid Button
            Expanded(
              child: _NatureActionButton(
                onPressed: () => emergencyProvider.showFirstAid(context),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kMediumSage, kDeepForest],
                ),
                icon: Icons.medical_services_rounded,
                title: "First Aid",
                subtitle: "Guide",
                accentColor: kSoftMint,
              ),
            ),
            const SizedBox(width: 12),

            // Share Location Button
            Expanded(
              child: _NatureActionButton(
                onPressed: () => sosActive
                    ? emergencyProvider.shareEmergencyLocation(context)
                    : emergencyProvider.shareLocation(context),
                gradient: sosActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.red.shade600, Colors.red.shade800],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kDeepTeal, const Color(0xFF1a2f2f)],
                      ),
                icon: Icons.share_location_rounded,
                title: sosActive ? "Emergency" : "Share",
                subtitle: sosActive ? "Location" : "Location",
                accentColor:
                    sosActive ? Colors.red.shade300 : kSoftMint,
                isLoading: isSending,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NatureActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isLoading;

  const _NatureActionButton({
    required this.onPressed,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.isLoading = false,
  });

  @override
  State<_NatureActionButton> createState() => _NatureActionButtonState();
}

class _NatureActionButtonState extends State<_NatureActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.isLoading ? null : _handleTapDown,
            onTapUp: widget.isLoading ? null : _handleTapUp,
            onTapCancel: widget.isLoading ? null : _handleTapCancel,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon container with glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.accentColor.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: widget.isLoading
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        widget.icon,
                                        size: 26,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 2),

                        // Subtitle
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Decorative indicator
                        Container(
                          width: 24,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
