import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ai_field_assistant/main.dart';
import 'package:ai_field_assistant/models/report.dart';
import 'package:ai_field_assistant/models/report_priority.dart';
import 'package:ai_field_assistant/repositories/report_repository.dart';
import 'package:ai_field_assistant/screens/report_detail_screen.dart';

void main() {
  testWidgets('loads the selected report and shows confirmed details', (
    tester,
  ) async {
    final report = _report();
    final repository = _FakeReportRepository(reports: [report]);

    await tester.pumpWidget(_detailApp(repository, report.id));
    await tester.pumpAndSettle();

    expect(repository.lastRequestedId, report.id);
    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
    expect(find.text('Điện'), findsOneWidget);
    expect(find.text('Tầng 2'), findsOneWidget);
    expect(find.text('Cao'), findsOneWidget);
    expect(
      find.text('Kiểm tra cầu dao và ngắt nguồn nếu thấy tia lửa.'),
      findsOneWidget,
    );
    expect(
      find.text('Đây là hành động đề xuất, chưa phải việc đã thực hiện.'),
      findsOneWidget,
    );
    expect(find.text('Đã xác nhận'), findsOneWidget);
    await _scrollTo(
      tester,
      find.byKey(const Key('report-detail-source-description')),
    );
    expect(find.text('Mô tả tổng hợp do người dùng cung cấp.'), findsOneWidget);
    expect(find.byKey(const Key('report-detail-content')), findsOneWidget);
  });

  testWidgets('shows loading until the report read completes', (tester) async {
    final report = _report();
    final response = Completer<Report?>();
    final repository = _FakeReportRepository(reports: [report])
      ..nextFindResult = response;

    await tester.pumpWidget(_detailApp(repository, report.id));
    expect(find.byKey(const Key('report-detail-loading')), findsOneWidget);

    response.complete(report);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-detail-loading')), findsNothing);
    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
  });

  testWidgets('shows confirmed absent values and the no-photo state', (
    tester,
  ) async {
    final report = _report(
      category: '',
      location: '',
      priority: null,
      suggestedAction: '',
      summary: '',
      confirmedAbsentFields: const [
        'category',
        'location',
        'priority',
        'suggested_action',
        'summary',
      ],
    );
    final repository = _FakeReportRepository(reports: [report]);

    await tester.pumpWidget(_detailApp(repository, report.id));
    await tester.pumpAndSettle();

    for (final field in [
      'category',
      'location',
      'suggested_action',
      'summary',
    ]) {
      await _scrollTo(tester, find.byKey(Key('report-detail-field-$field')));
      expect(
        tester.widget<Text>(find.byKey(Key('report-detail-value-$field'))).data,
        'Đã xác nhận không có thông tin',
      );
    }
    await _scrollTo(
      tester,
      find.byKey(const Key('report-detail-field-priority')),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('report-detail-value-priority')))
          .data,
      'Đã xác nhận chưa xác định',
    );
    await _scrollTo(
      tester,
      find.byKey(const Key('report-detail-photo-section')),
    );
    expect(find.text('Không có ảnh được lưu cùng báo cáo.'), findsOneWidget);
    expect(repository.photoReadCallCount, 0);
  });

  testWidgets('shows a distinct not-found state for an unknown report ID', (
    tester,
  ) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(_detailApp(repository, 'BBBBBBBBBBBBBBBBBBBBBB'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-detail-not-found')), findsOneWidget);
    expect(
      find.text('Không tìm thấy báo cáo này trong lịch sử đã lưu.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-detail-content')), findsNothing);
  });

  testWidgets('retries report load after a storage error', (tester) async {
    final repository = _FakeReportRepository(reports: [_report()])
      ..nextFindError = const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể đọc báo cáo trên thiết bị.',
      );

    await tester.pumpWidget(_detailApp(repository, _reportId));
    await tester.pumpAndSettle();

    expect(find.text('Không thể đọc báo cáo trên thiết bị.'), findsOneWidget);
    expect(find.byKey(const Key('report-detail-retry-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('report-detail-retry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
    expect(repository.findByIdCallCount, 2);
  });

  testWidgets('photo read failure keeps report text and supports photo retry', (
    tester,
  ) async {
    final repository =
        _FakeReportRepository(reports: [_report(photoPath: _photoPath)])
          ..nextPhotoError = const ReportStorageException(
            ReportStorageFailure.photo,
            'Không thể đọc ảnh đã lưu. Nội dung báo cáo vẫn được giữ.',
          );

    await tester.pumpWidget(_detailApp(repository, _reportId));
    await tester.pumpAndSettle();

    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
    await _scrollTo(
      tester,
      find.byKey(const Key('report-detail-photo-section')),
    );
    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
    expect(
      find.text('Không thể đọc ảnh đã lưu. Nội dung báo cáo vẫn được giữ.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('report-photo-retry-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-detail-photo')), findsOneWidget);
    expect(repository.photoReadCallCount, 2);
    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
  });

  testWidgets('renders a stored photo from repository bytes', (tester) async {
    final repository = _FakeReportRepository(
      reports: [_report(photoPath: _photoPath)],
    );

    await tester.pumpWidget(_detailApp(repository, _reportId));
    await tester.pumpAndSettle();

    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
    await _scrollTo(
      tester,
      find.byKey(const Key('report-detail-photo-section')),
    );
    expect(repository.lastRequestedPhotoPath, _photoPath);
    expect(find.byKey(const Key('report-detail-photo')), findsOneWidget);
  });

  testWidgets('unreadable image bytes show fallback and can be retried', (
    tester,
  ) async {
    final repository = _FakeReportRepository(
      reports: [_report(photoPath: _photoPath)],
      photoBytes: const [0x00, 0x01, 0x02],
    );

    await tester.pumpWidget(_detailApp(repository, _reportId));
    await tester.pumpAndSettle();

    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);
    await _scrollTo(
      tester,
      find.byKey(const Key('report-detail-photo-section')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('report-detail-photo-decode-error')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Ảnh đã lưu không thể hiển thị. Nội dung báo cáo vẫn được giữ.',
      ),
      findsOneWidget,
    );

    repository.photoBytes = _tinyPngBytes;
    await tester.tap(find.byKey(const Key('report-photo-retry-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('report-detail-photo')), findsOneWidget);
    expect(repository.photoReadCallCount, 2);
  });

  testWidgets('history selection opens the matching detail and Back returns', (
    tester,
  ) async {
    final report = _report();
    final repository = _FakeReportRepository(reports: [report]);

    await tester.pumpWidget(
      AiFieldAssistantApp(
        imagePicker: _UnusedImagePicker(),
        reportRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('history-item-${report.id}')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDetailScreen), findsOneWidget);
    expect(repository.lastRequestedId, report.id);
    expect(find.text('Cầu dao tầng 2 bị nóng'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ReportDetailScreen), findsNothing);
    expect(find.byKey(ValueKey('history-item-${report.id}')), findsOneWidget);
  });
}

Widget _detailApp(_FakeReportRepository repository, String reportId) =>
    MaterialApp(
      home: ReportDetailScreen(repository: repository, reportId: reportId),
    );

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final scrollable = find.byKey(const Key('report-detail-content'));
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

const _reportId = 'AAAAAAAAAAAAAAAAAAAAAA';
const _photoPath = 'report_photos/AAAAAAAAAAAAAAAAAAAAAA.image';

Report _report({
  String category = 'Điện',
  String location = 'Tầng 2',
  ReportPriority? priority = ReportPriority.high,
  String issue = 'Cầu dao tầng 2 bị nóng',
  String suggestedAction = 'Kiểm tra cầu dao và ngắt nguồn nếu thấy tia lửa.',
  String summary = 'Cầu dao tầng 2 có dấu hiệu quá nhiệt.',
  String sourceDescription = 'Mô tả tổng hợp do người dùng cung cấp.',
  String? photoPath,
  Iterable<String> confirmedAbsentFields = const [],
}) => Report(
  id: _reportId,
  createdAt: DateTime.utc(2026, 9, 29, 8, 5),
  category: category,
  location: location,
  priority: priority,
  issue: issue,
  suggestedAction: suggestedAction,
  summary: summary,
  sourceDescription: sourceDescription,
  photoPath: photoPath,
  confirmedAbsentFields: confirmedAbsentFields,
);

class _FakeReportRepository implements ReportRepository {
  _FakeReportRepository({
    this.reports = const [],
    this.photoBytes = _tinyPngBytes,
  });

  @override
  bool get isSupported => true;

  List<Report> reports;
  Completer<Report?>? nextFindResult;
  List<int> photoBytes = _tinyPngBytes;
  Object? nextFindError;
  Object? nextPhotoError;
  String? lastRequestedId;
  String? lastRequestedPhotoPath;
  int findByIdCallCount = 0;
  int photoReadCallCount = 0;

  @override
  Future<Report> save(Report report, {Uint8List? imageBytes}) async {
    reports = [...reports, report];
    return report;
  }

  @override
  Future<List<Report>> listReports() async => List.unmodifiable(reports);

  @override
  Future<Report?> findById(String id) async {
    findByIdCallCount++;
    lastRequestedId = id;
    final response = nextFindResult;
    nextFindResult = null;
    if (response != null) return response.future;
    final error = nextFindError;
    nextFindError = null;
    if (error != null) throw error;
    for (final report in reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  @override
  Future<Uint8List> readPhotoBytes(String relativePath) async {
    photoReadCallCount++;
    lastRequestedPhotoPath = relativePath;
    final error = nextPhotoError;
    nextPhotoError = null;
    if (error != null) throw error;
    return Uint8List.fromList(photoBytes);
  }

  @override
  Future<void> close() async {}
}

class _UnusedImagePicker extends ImagePicker {
  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
}

const _tinyPngBytes = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0b,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0xa5,
  0xf6,
  0x45,
  0x40,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];
