import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const envUrl = String.fromEnvironment("API_BASE_URL", defaultValue: "");
    if (envUrl.isNotEmpty) return envUrl;

    // Android emulator cannot access host machine via localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:3000";
    }

    // Web, iOS simulator and desktop local runs.
    return "http://localhost:3000";
  }
}
