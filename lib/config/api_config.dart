class ApiConfig {
  static const int backendPort = 3000;
  static String get baseUrl {
    const ngrokUrl =
        'https://systemizable-sheena-unchloridized.ngrok-free.dev/api';
    return ngrokUrl;

    // const baseurl = 'http://3.105.36.67:3000/api';
    // return baseurl;
  }
}
