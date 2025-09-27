import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Hiker Safety App",
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: AppRoutes.splash, // Start with splash
      getPages: AppRoutes.pages,
    );
  }
}
