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
