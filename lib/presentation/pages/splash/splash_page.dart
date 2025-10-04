import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/utils/loading_helper.dart';
import 'splash_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;

  final List<String> backgroundGifs = [
    ImageLocation.climber,
    ImageLocation.icemount,
    ImageLocation.mountain,
    ImageLocation.mountains,
    ImageLocation.rocky,
    ImageLocation.route,
    ImageLocation.summit,
    ImageLocation.volcano,
    ImageLocation.winter,
  ];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(
      const Duration(milliseconds: 400),
      () => _textController.forward(),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SplashController controller = Get.put(SplashController());
    final size = MediaQuery.of(context).size;
    final rows = (size.height / 50).ceil();
    final cols = (size.width / 50).ceil();

    return Scaffold(
      body: Stack(
        children: [
          // Background GIFs
          for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
              Positioned(
                top: r * 50 + _random.nextDouble() * 25,
                left: c * 50 + _random.nextDouble() * 25,
                child: Opacity(
                  opacity: 0.1 + _random.nextDouble() * 0.15,
                  child: Transform.rotate(
                    angle: _random.nextDouble() * 0.5 - 0.25,
                    child: Image.asset(
                      backgroundGifs[_random.nextInt(backgroundGifs.length)],
                      width: 25 + _random.nextDouble() * 25,
                      height: 25 + _random.nextDouble() * 25,
                    ),
                  ),
                ),
              ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.3, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _logoController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      ImageLocation.appLogo,
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _textController,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _textController,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: Column(
                      children: const [
                        Text(
                          "TrailGuard",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "YOUR ADVENTURE COMPANION",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Color.fromARGB(255, 21, 78, 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                LoadingHelper(imagePath: ImageLocation.loading, size: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
