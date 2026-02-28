import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

// const String baseUrl = "http://194.238.23.250:3000";
// const String oldUrl = "http://51.20.189.225";

//New_backend_url

// const String tempUrl = "https://ghj5w9n1-3003.inc1.devtunnels.ms";

// const String baseUrl = "https://smartschoolserver.ramchintech.com";
// const String baseUrl = "https://ghj5w9n1-3003.inc1.devtunnels.ms";

// Local development server - use localhost (works better than 127.0.0.1)
// Environment-based Base URL
String get baseUrl {
  if (kIsWeb) {
    // For web, check if it's a mobile browser or desktop
    // Simple check: if it's NOT desktop platform, assume mobile-like environment
    return "https://smartschoolserver.ramchintech.com";
  } else if (isMobilePlatform) {
    // Android/iOS Native
    return "https://smartschoolserver.ramchintech.com";
  } else {
    // Desktop (Windows/Mac/Linux)
    return "http://localhost:3003";
  }
}


///Demo_url
// const String tempUrl = "https://ghj5w9n1-3000.inc1.devtunnels.ms";
// const String baseUrl = "https://schoolattendance.ramchintech.com";

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  } catch (e) {
    return false;
  }
}

bool get isAndroidPlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid;
  } catch (e) {
    return false;
  }
}

bool get isIOSPlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isIOS;
  } catch (e) {
    return false;
  }
}

bool get isMobilePlatform {
  return isAndroidPlatform || isIOSPlatform;
}

Map<String, String> getApiHeaders() {
  Map<String, String> headers = {"Content-Type": "application/json"};

  if (isDesktopPlatform) {
    headers['x-platform'] = 'desktop';
  }

  return headers;
}

void safeExit() {
  if (isDesktopPlatform) {
    exit(0);
  }
}
