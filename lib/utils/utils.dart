import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

// const String baseUrl = "http://194.238.23.250:3000";
// const String oldUrl = "http://51.20.189.225";

//New_backend_url

// const String tempUrl = "https://ghj5w9n1-3003.inc1.devtunnels.ms";

const String cloudBaseUrl = "https://smartschoolserver.ramchintech.com";
// const String cloudBaseUrl = "https://ghj5w9n1-3003.inc1.devtunnels.ms";

String get baseUrl {
  return cloudBaseUrl;
}

///Demo_url
// const String tempUrl = "https://ghj5w9n1-3000.inc1.devtunnels.ms";
// const String baseUrl = "https://schoolattendance.ramchintech.com";

bool get isDesktopPlatform {
  if (kIsWeb) {
    // Heuristic for web desktop: check if not mobile/tablet
    // Note: This is an approximation for Web without extra packages
    return true;
  }
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
  if (kIsWeb) {
    // Very basic check for web mobile
    return false; // Default to Desktop for Web unless we perform more complex UA checks
  }
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

int getResponsiveColumnCount(double width) {
  if (width < 600) {
    return 2; // Mobile
  } else if (width < 900) {
    return 3; // Tablet portrait
  } else if (width < 1200) {
    return 4; // Tablet landscape / Small laptop
  } else {
    return 6; // Desktop / Large laptop
  }
}
