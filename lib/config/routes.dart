import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/auth/signup/signup_page.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/group/create_group/create_group_page.dart';
import 'package:hikingapp/presentation/pages/map/main_map/map_page.dart';
import 'package:hikingapp/presentation/pages/profile/edit_profile/edit_profile_page.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_page.dart';
import 'package:hikingapp/presentation/pages/trail/solo/solo_trail_name_page.dart';
import 'package:hikingapp/presentation/pages/trail/solo/solo_trail_page.dart';
import '../presentation/pages/auth/login/login_page.dart';
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
  static const editProfile = '/editProfile';
  static const soloTrailName = '/soloTrailName';
  static const soloTrail = '/soloTrail';

  static final pages = [
    GetPage(name: splash, page: () => SplashPage()),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: signup, page: () => const SignupPage()),
    GetPage(name: dashboard, page: () => const DashboardPage()),
    GetPage(name: map, page: () => const MapPage()),
    GetPage(name: emergency, page: () => const EmergencyPage()),
    GetPage(name: group, page: () => const GroupPage()),
    GetPage(name: profile, page: () => const ProfilePage()),
    GetPage(name: editProfile, page: () => const EditProfileScreen()),
    GetPage(name: soloTrailName, page: () => const SoloTrailNamePage()),
    GetPage(name: soloTrail, page: () => const SoloTrailPage()),
  ];
}
