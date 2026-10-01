import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

// Public client configuration, not a server secret or an App Check debug token.
const androidAppCheckSiteKey = String.fromEnvironment(
  'APP_CHECK_ANDROID_SITE_KEY',
);

typedef AppCheckActivation = Future<void> Function({
  required AndroidAppCheckProvider providerAndroid,
  WebProvider? providerWeb,
});

/// Runs after Firebase initialization and before creating any AI service.
Future<void> initializeAppCheck({
  required bool isDebug,
  required bool isWeb,
  required TargetPlatform platform,
  required AppCheckActivation activate,
  String siteKey = androidAppCheckSiteKey,
}) async {
  if (isDebug) {
    await activate(
      providerAndroid: const AndroidDebugProvider(),
      providerWeb: WebDebugProvider(),
    );
    return;
  }

  // Production web/Apple configuration is outside this Android release task.
  if (isWeb || platform != TargetPlatform.android) return;

  final configuredKey = siteKey.trim();
  if (configuredKey.isEmpty) {
    throw StateError('Missing Android App Check site key configuration.');
  }
  // Profile and release never fall back to a debug provider on failure.
  await activate(providerAndroid: AndroidReCaptchaProvider(configuredKey));
}
