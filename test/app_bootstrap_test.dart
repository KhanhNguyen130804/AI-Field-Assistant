import 'dart:async';

import 'package:ai_field_assistant/widgets/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'does not build the app or services before initialization completes',
    (tester) async {
      final ready = Completer<void>();
      var appBuilt = false;
      await tester.pumpWidget(
        AppBootstrap(
          initialize: () => ready.future,
          appBuilder: (_) {
            appBuilt = true;
            return const MaterialApp(home: Text('Ready'));
          },
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(appBuilt, isFalse);
      ready.complete();
      await tester.pumpAndSettle();
      expect(appBuilt, isTrue);
      expect(find.text('Ready'), findsOneWidget);
    },
  );

  testWidgets(
    'failed startup hides raw errors and retry cannot run concurrently',
    (tester) async {
      var attempts = 0;
      var appBuilt = false;
      final retry = Completer<void>();
      await tester.pumpWidget(
        AppBootstrap(
          initialize: () async {
            attempts++;
            if (attempts == 1) throw Exception('synthetic-private-error');
            await retry.future;
          },
          appBuilder: (_) {
            appBuilt = true;
            return const MaterialApp(home: Text('Ready'));
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(appBuilt, isFalse);
      expect(find.textContaining('Không thể khởi động'), findsOneWidget);
      expect(find.textContaining('synthetic-private-error'), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(attempts, 2);
      expect(find.text('Thử lại'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(appBuilt, isFalse);
      retry.complete();
      await tester.pumpAndSettle();
      expect(appBuilt, isTrue);
      expect(find.text('Ready'), findsOneWidget);
    },
  );

  testWidgets('synchronous initialization failure also shows recovery UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppBootstrap(
        initialize: () => throw StateError('synthetic missing configuration'),
        appBuilder: (_) => const MaterialApp(home: Text('Ready')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Ready'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
