// lib/config/api_config.dart
import 'dart:io';

class ApiConfig {
  static const int backendPort = 3000;

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.100.12:$backendPort/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:$backendPort/api';
    } else {
      return 'http://192.168.100.12:$backendPort/api'; // at home
      // return 'http://10.101.101.157:$backendPort/api'; // apu?
    }
  }
}
