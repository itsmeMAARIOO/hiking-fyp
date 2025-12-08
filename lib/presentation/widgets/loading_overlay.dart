import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/config/images/image_locations.dart';

class LoadingOverlay extends StatelessWidget {
  final bool visible;
  final String message;
  final Color shadeColor;
  final Color spinnerColor;
  final Color spinnerBackgroundColor;
  final String? logoAsset;
  final double size;

  const LoadingOverlay({
    super.key,
    required this.visible,
    this.message = 'Loading...',
    this.shadeColor = const Color(0x14000000),
    this.spinnerColor = kMediumSage,
    this.spinnerBackgroundColor = const Color(0x336BAF89),
    this.logoAsset = ImageLocation.appLogo,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final double circleSize = size * 0.65;
    final double logoSize = size * 0.44;
    return Positioned.fill(
      child: Container(
        color: shadeColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation(spinnerColor),
                        backgroundColor: spinnerBackgroundColor,
                      ),
                    ),
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: logoAsset == null
                          ? const SizedBox.shrink()
                          : Image.asset(
                              logoAsset!,
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kDeepTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
