import 'dart:ui';

import 'package:ai_field_assistant/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('điều hướng giữa Tạo báo cáo và Lịch sử', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AiFieldAssistantApp());

    expect(find.text('Quy trình dự kiến'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có báo cáo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tạo báo cáo'));
    await tester.pumpAndSettle();

    expect(find.text('Quy trình dự kiến'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
