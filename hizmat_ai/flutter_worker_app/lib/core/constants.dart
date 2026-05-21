class AppConstants {
  AppConstants._();

  // On Android emulator use 10.0.2.2, on physical device use your LAN IP.
  // Override via --dart-define=BACKEND_URL=http://192.168.x.x:8000 at build time.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const int jobAcceptTimeoutSeconds = 60;
  static const int gpsActiveJobIntervalSeconds = 30;
  static const int gpsIdleIntervalSeconds = 300;
  static const int maxPhotoSizeKb = 500;
  static const double platformFeePKR = 99.0;
  static const double taxGstRate = 0.05;
  static const double spoofingMaxKmPerMinute = 5.0; // 300km/h max
  static const int noShowWaitMinutes = 15;
}
