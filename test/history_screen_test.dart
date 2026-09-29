import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ai_field_assistant/main.dart';
import 'package:ai_field_assistant/models/report.dart';
import 'package:ai_field_assistant/models/report_draft.dart';
import 'package:ai_field_assistant/repositories/report_repository.dart';
import 'package:ai_field_assistant/screens/history_screen.dart';
import 'package:ai_field_assistant/services/gemini_report_service.dart';

void main() {
  testWidgets('history loads on tab entry and only shows empty after success', (
    tester,
  ) async {
    final repository = _FakeReportRepository();
    final response = Completer<List<Report>>();
    repository.nextRead = response;
    var isActive = false;
    var refreshToken = 0;

    Widget buildApp() => MaterialApp(
      home: Scaffold(
        body: HistoryScreen(
          repository: repository,
          isActive: isActive,
          refreshToken: refreshToken,
          onReportSelected: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(buildApp());
    expect(repository.listCallCount, 0);

    isActive = true;
    refreshToken++;
    await tester.pumpWidget(buildApp());
    expect(repository.listCallCount, 1);
    expect(find.byKey(const Key('history-loading')), findsOneWidget);

    response.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-empty-state')), findsOneWidget);

    await tester.pumpWidget(buildApp());
    expect(repository.listCallCount, 1);
  });

  testWidgets('history shows a read error and retry recovers to a report', (
    tester,
  ) async {
    final repository = _FakeReportRepository()
      ..nextError = const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể đọc danh sách báo cáo trên thiết bị.',
      )
      ..reports = [
        _report(id: 'AAAAAAAAAAAAAAAAAAAAAA', issue: 'Sự cố đã lưu'),
      ];

    await tester.pumpWidget(_historyApp(repository, refreshToken: 1));
    await tester.pumpAndSettle();

    expect(
      find.text('Không thể đọc danh sách báo cáo trên thiết bị.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('history-empty-state')), findsNothing);
    expect(find.byKey(const Key('history-retry-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-retry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Sự cố đã lưu'), findsOneWidget);
    expect(repository.listCallCount, 2);
  });

  testWidgets('history refreshes on token changes and emits the selected ID', (
    tester,
  ) async {
    final oldReport = _report(
      id: 'BBBBBBBBBBBBBBBBBBBBBB',
      issue: 'Báo cáo cũ',
      createdAt: DateTime(2026, 9, 28, 10),
    );
    final newReport = _report(
      id: 'CCCCCCCCCCCCCCCCCCCCCC',
      issue: 'Báo cáo mới',
      createdAt: DateTime(2026, 9, 29, 8, 5),
      priority: null,
    );
    final repository = _FakeReportRepository()..reports = [oldReport];
    String? selectedId;
    var refreshToken = 0;

    Widget buildApp() => _historyApp(
      repository,
      refreshToken: refreshToken,
      onReportSelected: (id) => selectedId = id,
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(repository.listCallCount, 1);

    repository.reports = [newReport, oldReport];
    refreshToken++;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(repository.listCallCount, 2);
    expect(find.text('Chưa xác định'), findsOneWidget);
    expect(find.text('Đã xác nhận'), findsNWidgets(2));
    expect(find.text('29/09/2026 08:05'), findsOneWidget);
    expect(repository.readPhotoCallCount, 0);
    expect(
      tester
          .getTopLeft(find.byKey(ValueKey('history-item-${newReport.id}')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(ValueKey('history-item-${oldReport.id}')))
            .dy,
      ),
    );

    await tester.tap(find.byKey(ValueKey('history-item-${newReport.id}')));
    expect(selectedId, newReport.id);

    await tester.pumpWidget(buildApp());
    expect(repository.listCallCount, 2);
  });

  testWidgets('unsupported platforms get a clear state without a fake read', (
    tester,
  ) async {
    final repository = _FakeReportRepository(isSupported: false);

    await tester.pumpWidget(_historyApp(repository, refreshToken: 1));

    expect(
      find.text(
        'Lưu và xem lịch sử báo cáo chưa được hỗ trợ trên nền tảng này.',
      ),
      findsOneWidget,
    );
    expect(repository.listCallCount, 0);
  });

  testWidgets(
    'successful save refreshes history and tab changes preserve the form',
    (tester) async {
      final repository = _FakeReportRepository();
      await tester.pumpWidget(
        AiFieldAssistantApp(
          imagePicker: _UnusedImagePicker(),
          reportService: _SuccessfulReportService(),
          reportRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      const description = 'Tủ điện tầng 2 phát ra tiếng lạ.';
      await tester.enterText(
        find.byKey(const Key('incident-description-field')),
        description,
      );
      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();
      expect(repository.listCallCount, 1);
      expect(find.byKey(const Key('history-empty-state')), findsOneWidget);

      await tester.tap(find.text('Tạo báo cáo'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('incident-description-field')),
            )
            .controller!
            .text,
        description,
      );

      await tester.ensureVisible(find.byKey(const Key('analyze-button')));
      await tester.tap(find.byKey(const Key('analyze-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('draft-title')), findsOneWidget);

      for (final field in Report.fieldNames) {
        final confirmButton = find.byKey(Key('confirm-field-$field'));
        await tester.ensureVisible(confirmButton);
        await tester.pumpAndSettle();
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();
      }

      final saveButton = find.byKey(const Key('save-report-button'));
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-save-button')));
      await tester.pumpAndSettle();

      expect(repository.saveCallCount, 1);
      expect(repository.listCallCount, 2);

      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();
      expect(repository.listCallCount, 3);
      expect(find.text('Cầu dao bị nóng bất thường'), findsOneWidget);
    },
  );
}

Widget _historyApp(
  _FakeReportRepository repository, {
  required int refreshToken,
  ValueChanged<String>? onReportSelected,
}) => MaterialApp(
  home: Scaffold(
    body: HistoryScreen(
      repository: repository,
      isActive: true,
      refreshToken: refreshToken,
      onReportSelected: onReportSelected ?? (_) {},
    ),
  ),
);

Report _report({
  required String id,
  required String issue,
  DateTime? createdAt,
  ReportPriority? priority = ReportPriority.high,
}) => Report(
  id: id,
  createdAt: createdAt ?? DateTime(2026, 9, 29, 8),
  category: 'Điện',
  location: 'Tầng 2',
  priority: priority,
  issue: issue,
  suggestedAction: 'Kiểm tra thiết bị.',
  summary: 'Sự cố được ghi nhận.',
  sourceDescription: 'Mô tả tổng hợp.',
  confirmedAbsentFields: priority == null ? const ['priority'] : const [],
);

class _FakeReportRepository implements ReportRepository {
  _FakeReportRepository({this.isSupported = true});

  @override
  final bool isSupported;

  List<Report> reports = const [];
  Completer<List<Report>>? nextRead;
  Object? nextError;
  int listCallCount = 0;
  int saveCallCount = 0;
  int readPhotoCallCount = 0;

  @override
  Future<Report> save(Report report, {Uint8List? imageBytes}) async {
    saveCallCount++;
    reports = [...reports, report]
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return report;
  }

  @override
  Future<List<Report>> listReports() {
    listCallCount++;
    final delayedRead = nextRead;
    if (delayedRead != null) {
      nextRead = null;
      return delayedRead.future;
    }
    final error = nextError;
    if (error != null) {
      nextError = null;
      return Future.error(error);
    }
    return Future.value(List<Report>.unmodifiable(reports));
  }

  @override
  Future<Report?> findById(String id) async {
    for (final report in reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  @override
  Future<Uint8List> readPhotoBytes(String relativePath) async {
    readPhotoCallCount++;
    return Uint8List(0);
  }

  @override
  Future<void> close() async {}
}

class _UnusedImagePicker extends ImagePicker {}

class _SuccessfulReportService extends GeminiReportService {
  @override
  Future<ReportDraft> createReportDraft({
    String? description,
    XFile? image,
  }) async => ReportDraft(
    category: 'Điện',
    location: 'Tầng 2',
    priority: ReportPriority.high,
    issue: 'Cầu dao bị nóng bất thường',
    suggestedAction: 'Kiểm tra cầu dao.',
    summary: 'Cầu dao tầng 2 bị nóng.',
  );
}
