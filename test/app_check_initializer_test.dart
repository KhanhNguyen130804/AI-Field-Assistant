import 'package:ai_field_assistant/services/app_check_initializer.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'debug works without release configuration and never embeds a token',
    () async {
      AndroidAppCheckProvider? android;
      WebProvider? web;
      await initializeAppCheck(
        isDebug: true,
        isWeb: false,
        platform: TargetPlatform.android,
        siteKey: '',
        activate: ({required providerAndroid, providerWeb}) async {
          android = providerAndroid;
          web = providerWeb;
        },
      );
      expect(android, isA<AndroidDebugProvider>());
      expect((android as AndroidDebugProvider).debugToken, isNull);
      expect(web, isA<WebDebugProvider>());
    },
  );

  test(
    'Android non-debug forwards the public key without a web provider',
    () async {
      AndroidAppCheckProvider? android;
      WebProvider? web;
      await initializeAppCheck(
        isDebug: false,
        isWeb: false,
        platform: TargetPlatform.android,
        siteKey: ' test-public-site-key ',
        activate: ({required providerAndroid, providerWeb}) async {
          android = providerAndroid;
          web = providerWeb;
        },
      );
      expect(android, isA<AndroidReCaptchaProvider>());
      expect(
        (android as AndroidReCaptchaProvider).siteKey,
        'test-public-site-key',
      );
      expect(web, isNull);
    },
  );

  test('missing release key blocks activation before any SDK call', () async {
    var calls = 0;
    await expectLater(
      initializeAppCheck(
        isDebug: false,
        isWeb: false,
        platform: TargetPlatform.android,
        siteKey: '  ',
        activate: ({required providerAndroid, providerWeb}) async => calls++,
      ),
      throwsStateError,
    );
    expect(calls, 0);
  });

  test(
    'activation failure propagates without trying a debug fallback',
    () async {
      final attemptedProviders = <AndroidAppCheckProvider>[];
      final failure = Exception('synthetic activation failure');
      await expectLater(
        initializeAppCheck(
          isDebug: false,
          isWeb: false,
          platform: TargetPlatform.android,
          siteKey: 'test-public-site-key',
          activate: ({required providerAndroid, providerWeb}) async {
            attemptedProviders.add(providerAndroid);
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(attemptedProviders, hasLength(1));
      expect(attemptedProviders.single, isA<AndroidReCaptchaProvider>());
    },
  );

  test(
    'production web never uses the Android key or changes web policy',
    () async {
      var calls = 0;
      await initializeAppCheck(
        isDebug: false,
        isWeb: true,
        platform: TargetPlatform.android,
        siteKey: '',
        activate: ({required providerAndroid, providerWeb}) async => calls++,
      );
      expect(calls, 0);
    },
  );

  test(
    'production non-Android does not install the Android provider',
    () async {
      var calls = 0;
      await initializeAppCheck(
        isDebug: false,
        isWeb: false,
        platform: TargetPlatform.iOS,
        siteKey: '',
        activate: ({required providerAndroid, providerWeb}) async => calls++,
      );
      expect(calls, 0);
    },
  );
}
