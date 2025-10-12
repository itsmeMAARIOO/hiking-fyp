import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:hikingapp/providers/group_provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'providers/map_provider.dart';
import 'presentation/widgets/minimized_trail_bubble.dart';
import 'presentation/pages/group/trail_group/trail_group_page.dart';

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
        theme: ThemeData(primarySwatch: Colors.green),
        initialRoute: AppRoutes.splash,
        getPages: AppRoutes.pages,
        builder: (context, child) {
          return Consumer<GroupProvider>(
            builder: (context, groupProvider, _) {
              final currentRoute = Get.currentRoute;
              final isDashboard = currentRoute == AppRoutes.dashboard;
              final bottomOffset = isDashboard ? 76.0 : 16.0; // raise above bottom nav on dashboard

              return Stack(
                children: [
                  if (child != null) child,
                  if (groupProvider.isTrailMinimized && groupProvider.activeGroup != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomOffset),
                        child: MinimizedTrailBubble(
                          groupName: groupProvider.activeGroup?['groupName'] ?? 'Trail Group',
                          onTap: () {
                            groupProvider.setTrailMinimized(false);
                            Get.to(() => const TrailGroupPage());
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
