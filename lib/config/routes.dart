import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/auth/signup_page.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/group/group_page.dart';
import 'package:hikingapp/presentation/pages/map/map_page.dart';
import 'package:hikingapp/presentation/pages/profile/profile_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/dashboard/dashboard_page.dart';
import '../presentation/pages/splash/splash_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const signup = '/signup';
  static const bottomNav = '/bottom_nav';
  static const map = '/map';
  static const group = '/group';
  static const emergency = '/emergency';
  static const profile = '/profile';

  static final pages = [
    GetPage(name: splash, page: () => SplashPage()),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: signup, page: () => const SignupPage()),
    GetPage(name: dashboard, page: () => const DashboardPage()),
    GetPage(name: map, page: () => const MapPage()),
    GetPage(name: emergency, page: () => const EmergencyPage()),
    GetPage(name: group, page: () => const GroupPage()),
    GetPage(name: profile, page: () => const ProfilePage()),
  ];
}
