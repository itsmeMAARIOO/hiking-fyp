import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/auth/signup/signup_page.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/emergency/first_aid_page.dart';
import 'package:hikingapp/presentation/pages/profile/health_card/health_card_page.dart';
import 'package:hikingapp/presentation/pages/trail/create_trail/trail_page.dart';
import 'package:hikingapp/presentation/pages/map/map_page.dart';
import 'package:hikingapp/presentation/pages/profile/edit_profile/edit_profile_page.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_page.dart';
import 'package:hikingapp/presentation/pages/profile/history/hike_history_page.dart';
import 'package:hikingapp/presentation/pages/profile/history/group_trail_details_page.dart';
import 'package:hikingapp/presentation/pages/profile/history/solo_trail_details_page.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/active_trail.dart';
import 'package:hikingapp/presentation/pages/auth/forgot_password/forgot_password.dart';
import '../presentation/pages/auth/login/login_page.dart';
import '../presentation/pages/dashboard/dashboard_page.dart';
import '../presentation/pages/splash/splash_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgotPassword';
  static const dashboard = '/dashboard';
  static const signup = '/signup';
  static const bottomNav = '/bottom_nav';
  static const map = '/map';
  static const trail = '/trail';
  static const emergency = '/emergency';
  static const firstAid = '/firstAid';
  static const profile = '/profile';
  static const editProfile = '/editProfile';
  static const soloTrailName = '/soloTrailName';
  static const soloTrail = '/soloTrail';
  static const hikeHistory = '/hikeHistory';
  static const groupTrailDetails = '/groupTrailDetails';
  static const soloTrailDetails = '/soloTrailDetails';
  static const healthCard = '/healthCard';

  static final pages = [
    GetPage(name: splash, page: () => SplashPage()),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordPage()),
    GetPage(name: signup, page: () => const SignupPage()),
    GetPage(name: dashboard, page: () => const DashboardPage()),
    GetPage(name: map, page: () => const MapPage()),
    GetPage(name: emergency, page: () => const EmergencyPage()),
    GetPage(name: firstAid, page: () => const FirstAidPage()),
    GetPage(name: trail, page: () => const TrailPage()),
    GetPage(name: profile, page: () => const ProfilePage()),
    GetPage(name: editProfile, page: () => const EditProfileScreen()),
    GetPage(name: hikeHistory, page: () => const HikeHistoryPage()),
    GetPage(name: groupTrailDetails, page: () => const GroupTrailDetailsPage()),
    GetPage(name: soloTrailDetails, page: () => const SoloTrailDetailsPage()),
    GetPage(name: soloTrail, page: () => const ActiveTrailPage()),
    GetPage(name: healthCard, page: () => const HealthCardPage()),
  ];
}
