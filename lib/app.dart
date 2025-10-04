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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
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
      ),
    );
  }
}
