// // lib/config/api_config.dart
// import 'dart:io';

// class ApiConfig {
//   static const int backendPort = 3000;

//   static String get baseUrl {
//     if (Platform.isAndroid) {
//       return 'http://192.168.100.12:$backendPort/api';
//     } else if (Platform.isIOS) {
//       return 'http://localhost:$backendPort/api';
//     } else {
//       return 'http://192.168.100.12:$backendPort/api'; // at home
//       // return 'http://10.101.101.157:$backendPort/api'; // apu?
//     }
//   }
// }

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const int backendPort = 3000;

  // force use ngrok
  // static String baseUrl = 'https://systemizable-sheena-unchloridized.ngrok-free.dev/api';

  static String get baseUrl {
    const ngrokUrl =
        'https://systemizable-sheena-unchloridized.ngrok-free.dev/api';
    // const localIp = 'http://192.168.100.12:$backendPort/api';

    // Use ngrok for web to avoid unsupported Platform calls
    // if (kIsWeb) {
    //   return ngrokUrl;
    // }

    // if (Platform.isAndroid || Platform.isIOS) {
    //   return ngrokUrl; // change to ngrok when using remotely
    // }

    return ngrokUrl;
  }
}
