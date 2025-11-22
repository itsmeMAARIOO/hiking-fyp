import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'providers/map_provider.dart';
import 'presentation/widgets/minimized_trail_bubble.dart';
import 'presentation/pages/trail/active_trail/active_trail.dart';
import 'package:google_fonts/google_fonts.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: "TrailGuard",
        theme: ThemeData(
          fontFamily: GoogleFonts.inter().fontFamily,
          primaryColor: kDeepTeal,
          scaffoldBackgroundColor: kLightCream,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kDeepTeal,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: kDeepTeal,
            elevation: 0,
            centerTitle: true,
            foregroundColor: kLightCream,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDeepForest,
              foregroundColor: kLightCream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kWarmWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kSoftMint.withOpacity(0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kSoftMint.withOpacity(0.4)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: kMediumSage, width: 2),
            ),
            hintStyle: TextStyle(color: kDeepTeal.withOpacity(0.5)),
          ),
        ),
        initialRoute: AppRoutes.splash,
        getPages: AppRoutes.pages,
        builder: (context, child) {
          // Sync fall detection toggle with Profile settings and ensure listener
          final emergencyProvider = Provider.of<EmergencyProvider>(
            context,
            listen: false,
          );
          final profileProvider = Provider.of<ProfileProvider>(context);
          final desiredFall =
              profileProvider.settings['fallDetection'] ?? false;
          if (desiredFall != emergencyProvider.fallDetectionEnabled) {
            emergencyProvider.toggleFallDetection(desiredFall);
          }

          return Consumer<GroupProvider>(
            builder: (context, groupProvider, _) {
              final mapProvider = Provider.of<MapProvider>(context);
              final currentRoute = Get.currentRoute;
              final isDashboard = currentRoute == AppRoutes.dashboard;
              final bottomOffset = isDashboard
                  ? 76.0
                  : 16.0; // raise above bottom nav on dashboard

              return Stack(
                children: [
                  if (child != null) child,
                  if (groupProvider.isTrailMinimized &&
                      groupProvider.activeGroup != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomOffset),
                        child: MinimizedTrailBubble(
                          groupName:
                              groupProvider.activeGroup?['groupName'] ??
                              'Trail Group',
                          onTap: () {
                            groupProvider.setTrailMinimized(false);
                            Get.to(() => const TrailGroupPage());
                          },
                        ),
                      ),
                    ),
                  if (mapProvider.isSoloTrailMinimized)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomOffset),
                        child: MinimizedTrailBubble(
                          groupName: 'Solo Trail',
                          onTap: () {
                            mapProvider.setSoloTrailMinimized(false);
                            Get.toNamed(AppRoutes.soloTrail);
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
