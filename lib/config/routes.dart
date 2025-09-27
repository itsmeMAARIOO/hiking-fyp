import 'package:get/get.dart';
import '../presentation/pages/auth/login_page.dart';
// import '../presentation/pages/dashboard/dashboard_page.dart';
import '../presentation/pages/splash/splash_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const signup = '/signup';

  static final pages = [
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: login, page: () => const LoginPage()),
    // GetPage(name: home, page: () => const DashboardPage()),
    // Add SignupPage later
  ];
}
