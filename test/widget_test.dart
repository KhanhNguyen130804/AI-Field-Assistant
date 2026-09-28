import 'dart:async';
import 'dart:ui' as ui;

import 'package:ai_field_assistant/main.dart';
import 'package:ai_field_assistant/models/report.dart';
import 'package:ai_field_assistant/models/report_draft.dart';
import 'package:ai_field_assistant/repositories/report_repository.dart';
import 'package:ai_field_assistant/screens/create_report_screen.dart';
import 'package:ai_field_assistant/screens/report_draft_screen.dart';
import 'package:ai_field_assistant/services/gemini_report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('điều hướng hoạt động và form không tràn ở màn hình hẹp', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AiFieldAssistantApp(
        imagePicker: _FakeImagePicker(),
        reportService: _FakeReportService(),
        reportRepository: _FakeReportRepository(),
      ),
    );

    expect(find.byKey(const Key('incident-description-field')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Lịch sử chưa được tích hợp'), findsWidgets);

    await tester.tap(find.text('Tạo báo cáo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('incident-description-field')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.showKeyboard(
      find.byKey(const Key('incident-description-field')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('review-input-button')));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chặn đầu vào rỗng và xem lại mô tả mà không gửi đi', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(imagePicker: _FakeImagePicker()));

    await tester.tap(find.byKey(const Key('review-input-button')));
    await tester.pump();
    expect(
      find.text('Nhập mô tả hoặc chọn ảnh trước khi xem lại đầu vào.'),
      findsOneWidget,
    );

    const description = 'Điều hòa tại khu vực lễ tân không hoạt động.';
    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      description,
    );
    await tester.ensureVisible(find.byKey(const Key('review-input-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-input-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-description')), findsOneWidget);
    expect(
      find.text(
        'Đầu vào này chưa được gửi tới AI và chưa được lưu thành báo cáo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('chọn ảnh từ thư viện và xem lại preview cục bộ', (tester) async {
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(_testApp(imagePicker: picker));

    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    expect(picker.lastSource, ImageSource.gallery);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('review-input-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-input-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-image-preview')), findsOneWidget);
    expect(
      find.text(
        'Đầu vào này chưa được gửi tới AI và chưa được lưu thành báo cáo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('nút chụp ảnh gọi picker với camera source', (tester) async {
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(_testApp(imagePicker: picker));

    await tester.tap(find.byKey(const Key('take-photo-button')));
    await tester.pumpAndSettle();

    expect(picker.lastSource, ImageSource.camera);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
  });

  testWidgets('hủy picker giữ lại mô tả và ảnh đã chọn trước đó', (
    tester,
  ) async {
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(_testApp(imagePicker: picker));

    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Rò rỉ nước tại phòng kỹ thuật.',
    );

    picker.nextImage = null;
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Ảnh đã chọn. Chọn ảnh khác để thay thế.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
    expect(find.text('Rò rỉ nước tại phòng kỹ thuật.'), findsOneWidget);
    expect(find.byKey(const Key('input-error-message')), findsNothing);
  });

  testWidgets('permission error preserves text and shows a useful message', (
    tester,
  ) async {
    final picker = _FakeImagePicker(
      error: PlatformException(code: 'photo_access_denied'),
    );
    await tester.pumpWidget(_testApp(imagePicker: picker));
    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Mất điện tại tầng hai.',
    );

    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Quyền truy cập ảnh bị từ chối. Hãy kiểm tra Cài đặt ứng dụng hoặc tiếp tục với mô tả.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mất điện tại tầng hai.'), findsOneWidget);
  });

  testWidgets('từ chối ảnh quá lớn và giữ nguyên ảnh hiện tại', (tester) async {
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(_testApp(imagePicker: picker));
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    picker.nextImage = XFile.fromData(
      Uint8List(CreateReportScreen.maxImageBytes + 1),
      name: 'oversized.png',
      mimeType: 'image/png',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ảnh vượt quá giới hạn 10 MiB. Hãy chọn ảnh nhỏ hơn rồi thử lại.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
  });

  testWidgets('ảnh mới không đọc được thì giữ preview ảnh trước', (
    tester,
  ) async {
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(_testApp(imagePicker: picker));

    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);

    picker.nextImage = XFile.fromData(
      Uint8List.fromList(<int>[1, 2, 3, 4]),
      name: 'invalid.png',
      mimeType: 'image/png',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Ảnh mới không thể đọc được. Ảnh trước đó vẫn được giữ.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);

    picker.nextImage = XFile.fromData(
      Uint8List.fromList(_tinyPngBytes.take(8).toList()),
      name: 'truncated.png',
      mimeType: 'image/png',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Ảnh mới không thể đọc được. Ảnh trước đó vẫn được giữ.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chặn phân tích khi mô tả và ảnh đều trống', (tester) async {
    final service = _FakeReportService();
    await tester.pumpWidget(
      _testApp(imagePicker: _FakeImagePicker(), reportService: service),
    );

    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Nhập mô tả hoặc chọn ảnh trước khi phân tích.'),
      findsOneWidget,
    );
    expect(service.callCount, 0);
  });

  testWidgets('phân tích thành công: mở màn hình bản nháp AI', (tester) async {
    final service = _FakeReportService();
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(
      _testApp(imagePicker: picker, reportService: service),
    );

    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Điều hòa lễ tân không chạy.',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDraftScreen), findsOneWidget);
    expect(find.text('Bản nháp AI — cần kiểm tra, chưa lưu'), findsOneWidget);
    expect(find.text('Hỏng hóc thiết bị'), findsOneWidget);
    expect(find.text('Cao'), findsOneWidget);
    expect(find.byKey(const Key('needs-confirmation-list')), findsNothing);
    expect(find.byKey(const Key('draft-source-description')), findsOneWidget);
    expect(find.byKey(const Key('draft-source-image')), findsOneWidget);
    expect(find.byKey(const Key('input-error-message')), findsNothing);
  });

  testWidgets(
    'bản nháp thiếu trường: hiện needs_confirmation và badge từng trường',
    (tester) async {
      final service = _FakeReportService(_partialDraft());
      await tester.pumpWidget(
        _testApp(imagePicker: _FakeImagePicker(), reportService: service),
      );

      await tester.enterText(
        find.byKey(const Key('incident-description-field')),
        'Rò rỉ nước tại phòng kỹ thuật.',
      );
      await tester.ensureVisible(find.byKey(const Key('analyze-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('analyze-button')));
      await tester.pumpAndSettle();

      expect(find.byType(ReportDraftScreen), findsOneWidget);
      expect(find.byKey(const Key('needs-confirmation-list')), findsOneWidget);
      expect(find.text('• Sự cố'), findsOneWidget);
      expect(find.text('AI đề nghị kiểm tra'), findsWidgets);
      // Trường rỗng không được hiển thị như dữ kiện.
      expect(find.byKey(const Key('draft-field-Danh mục')), findsNothing);
      expect(find.byKey(const Key('draft-editor-field-issue')), findsOneWidget);
    },
  );

  testWidgets('suggested_action hiển thị như đề xuất, không phải việc đã làm', (
    tester,
  ) async {
    final service = _FakeReportService();
    await tester.pumpWidget(
      _testApp(imagePicker: _FakeImagePicker(), reportService: service),
    );

    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Điều hòa lễ tân không chạy.',
    );
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Đây là hành động đề xuất, chưa phải việc đã thực hiện.'),
      findsOneWidget,
    );
    expect(find.text('Cử nhân viên bảo trì kiểm tra.'), findsOneWidget);
  });

  testWidgets('trong lúc phân tích: hiện loading, khóa nút, giữ input', (
    tester,
  ) async {
    final service = _FakeReportService.hanging();
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(
      _testApp(imagePicker: picker, reportService: service),
    );

    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Điều hòa lễ tân không chạy.',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pump();

    expect(find.byKey(const Key('analyze-progress')), findsOneWidget);
    expect(find.text('Điều hòa lễ tân không chạy.'), findsOneWidget);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
    final analyzeButton = tester.widget<FilledButton>(
      find.byKey(const Key('analyze-button')),
    );
    expect(analyzeButton.onPressed, isNull);
    final reviewButton = tester.widget<FilledButton>(
      find.byKey(const Key('review-input-button')),
    );
    expect(reviewButton.onPressed, isNull);

    service.complete();
    await tester.pumpAndSettle();

    expect(find.byType(ReportDraftScreen), findsOneWidget);
  });

  testWidgets('lỗi service khi phân tích: hiện thông báo, giữ mô tả và ảnh', (
    tester,
  ) async {
    final service = _FakeReportService();
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(
      _testApp(imagePicker: picker, reportService: service),
    );

    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Mất điện tại tầng hai.',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    service.nextError = const ReportDraftServiceException();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDraftScreen), findsNothing);
    expect(
      find.text(
        'Không thể phân tích lúc này. Kiểm tra kết nối mạng rồi thử lại.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mất điện tại tầng hai.'), findsOneWidget);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);

    // Retry với service đã ổn định vẫn dùng lại nguyên input cũ.
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    expect(find.byType(ReportDraftScreen), findsOneWidget);
    expect(service.callCount, 2);
    // Form nguồn vẫn giữ mô tả khi quay lại từ bản nháp.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Mất điện tại tầng hai.'), findsOneWidget);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
  });

  testWidgets('lỗi timeout và quota: hiện thông báo tương ứng', (tester) async {
    final service = _FakeReportService();
    await tester.pumpWidget(
      _testApp(imagePicker: _FakeImagePicker(), reportService: service),
    );

    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Điều hòa hỏng.',
    );
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();

    service.nextError = const ReportDraftTimeoutException();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Phân tích mất quá nhiều thời gian. Bạn thử lại giúp mình nhé.',
      ),
      findsOneWidget,
    );
    expect(find.text('Điều hòa hỏng.'), findsOneWidget);

    service.nextError = const ReportDraftQuotaException();
    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Đã đạt giới hạn số lần phân tích'),
      findsOneWidget,
    );
    expect(find.text('Điều hòa hỏng.'), findsOneWidget);
  });

  testWidgets('chặn phân tích khi ảnh vượt 4 MiB trước khi gọi service', (
    tester,
  ) async {
    final service = _FakeReportService();
    final picker = _FakeImagePicker(nextImage: await _tinyPng());
    await tester.pumpWidget(
      _testApp(imagePicker: picker, reportService: service),
    );

    await tester.enterText(
      find.byKey(const Key('incident-description-field')),
      'Điều hòa hỏng.',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();

    // Thay ảnh bằng XFile ảo > 4 MiB (PNG header để form chấp nhận preview).
    picker.nextImage = XFile.fromData(
      Uint8List.fromList(<int>[
        ..._tinyPngBytes,
        ...Uint8List(maxImageBytesForAi + 1),
      ]),
      name: 'big.png',
      mimeType: 'image/png',
    );
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ảnh vượt quá giới hạn 4 MiB để gửi phân tích. '
        'Hãy chọn ảnh nhỏ hơn hoặc chụp lại.',
      ),
      findsOneWidget,
    );
    expect(service.callCount, 0);
    expect(find.byType(ReportDraftScreen), findsNothing);
    // Ảnh preview vẫn giữ, mô tả vẫn giữ.
    expect(find.text('Điều hòa hỏng.'), findsOneWidget);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
  });

  testWidgets('chỉ lưu sau khi người dùng xác nhận đủ sáu trường', (
    tester,
  ) async {
    final repository = _FakeReportRepository();
    await _openDraft(tester, repository: repository, image: await _tinyPng());

    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    expect(repository.saveCount, 0);
    expect(find.byKey(const Key('validation-error-issue')), findsOneWidget);

    await _confirmAllFields(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('confirm-field-summary')))
          .onPressed,
      isNotNull,
    );
    // The summary becomes reviewable after the other five fields.
    await _confirmField(tester, 'summary');
    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-save-button')));
    await tester.pumpAndSettle();

    expect(repository.saveCount, 1);
    expect(repository.lastRequested?.issue, 'Điều hòa không hoạt động');
    expect(repository.lastRequested?.sourceDescription, _sampleDescription);
    expect(repository.lastImageBytes, Uint8List.fromList(_tinyPngBytes));
    expect(repository.lastSaved?.photoPath, isNotNull);
    expect(find.byType(ReportDraftScreen), findsNothing);
    expect(find.textContaining('Đã lưu trên thiết bị.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('incident-description-field')),
          )
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('cho phép xác nhận trường tùy chọn không có thông tin', (
    tester,
  ) async {
    final repository = _FakeReportRepository();
    await _openDraft(tester, draft: _partialDraft(), repository: repository);

    for (final field in [
      'category',
      'location',
      'priority',
      'suggested_action',
    ]) {
      await _confirmField(tester, field, absent: true);
    }
    await _confirmField(tester, 'issue');
    await _confirmField(tester, 'summary', absent: true);

    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-save-button')));
    await tester.pumpAndSettle();

    expect(repository.lastSaved?.priority, isNull);
    expect(
      repository.lastSaved?.confirmedAbsentFields,
      containsAll([
        'category',
        'location',
        'priority',
        'suggested_action',
        'summary',
      ]),
    );
    expect(repository.lastSaved?.issue, 'Rò rỉ nước');
  });

  testWidgets('issue rỗng không thể xác nhận hoặc lưu', (tester) async {
    final repository = _FakeReportRepository();
    await _openDraft(tester, draft: _partialDraft(), repository: repository);

    await tester.enterText(
      find.byKey(const Key('draft-editor-field-issue')),
      '',
    );
    await tester.ensureVisible(find.byKey(const Key('confirm-field-issue')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('confirm-field-issue')))
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    expect(repository.saveCount, 0);
    expect(find.byKey(const Key('validation-error-issue')), findsOneWidget);
  });

  testWidgets('lỗi lưu giữ nội dung và retry dùng cùng ID', (tester) async {
    final repository = _FakeReportRepository()
      ..nextSaveError = const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể lưu báo cáo trên thiết bị.',
      );
    await _openDraft(tester, repository: repository);
    await _confirmAllFields(tester);
    await _confirmField(tester, 'summary');

    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-save-button')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDraftScreen), findsOneWidget);
    expect(find.text('Không thể lưu báo cáo trên thiết bị.'), findsOneWidget);
    expect(repository.saveCount, 1);
    final issueField = tester.widget<TextField>(
      find.byKey(const Key('draft-editor-field-issue')),
    );
    expect(issueField.controller!.text, 'Điều hòa không hoạt động');
    expect(issueField.enabled, isFalse);

    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();

    expect(repository.saveCount, 2);
    expect(repository.requestedIds.first, repository.requestedIds.last);
    expect(find.byType(ReportDraftScreen), findsNothing);
  });

  testWidgets('kiểm tra ID trước khi retry khi kết quả lưu chưa rõ', (
    tester,
  ) async {
    final repository = _FakeReportRepository()
      ..nextSaveError = const ReportStorageException(
        ReportStorageFailure.database,
        'Không xác định được kết quả lưu.',
      )
      ..commitBeforeNextSaveError = true;
    await _openDraft(tester, repository: repository);
    await _confirmAllFields(tester);
    await _confirmField(tester, 'summary');

    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-save-button')));
    await tester.pumpAndSettle();
    expect(repository.saveCount, 1);

    await tester.ensureVisible(find.byKey(const Key('resolve-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resolve-save-button')));
    await tester.pumpAndSettle();

    expect(repository.saveCount, 1);
    expect(find.byType(ReportDraftScreen), findsNothing);
    expect(find.textContaining('Đã lưu trên thiết bị.'), findsOneWidget);
  });

  testWidgets('Back hỏi trước khi bỏ review và giữ input nguồn', (
    tester,
  ) async {
    await _openDraft(tester, repository: _FakeReportRepository());
    await tester.enterText(
      find.byKey(const Key('draft-editor-field-location')),
      'Tầng 2',
    );

    await tester.tap(find.byKey(const Key('draft-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discard-review-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stay-in-editor-button')));
    await tester.pumpAndSettle();
    expect(find.byType(ReportDraftScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('draft-back-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discard-review-button')));
    await tester.pumpAndSettle();
    expect(find.byType(ReportDraftScreen), findsNothing);
    expect(find.text(_sampleDescription), findsOneWidget);
  });

  testWidgets('khóa thao tác lưu lặp khi repository còn đang lưu', (
    tester,
  ) async {
    final repository = _FakeReportRepository()..saveGate = Completer<void>();
    await _openDraft(tester, repository: repository);
    await _confirmAllFields(tester);
    await _confirmField(tester, 'summary');

    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-report-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-save-button')));
    await tester.pump();

    expect(repository.saveCount, 1);
    expect(find.byKey(const Key('save-progress')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('save-report-button')))
          .onPressed,
      isNull,
    );

    repository.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(repository.saveCount, 1);
    expect(find.byType(ReportDraftScreen), findsNothing);
  });

  testWidgets('editor cuộn được trên màn hình nhỏ khi bật bàn phím', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openDraft(tester, repository: _FakeReportRepository());
    await tester.showKeyboard(
      find.byKey(const Key('draft-editor-field-issue')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-report-button')));
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required ImagePicker imagePicker,
  GeminiReportService? reportService,
  ReportRepository? reportRepository,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CreateReportScreen(
        imagePicker: imagePicker,
        reportService: reportService,
        reportRepository: reportRepository ?? _FakeReportRepository(),
      ),
    ),
  );
}

const _sampleDescription = 'Máy điều hòa khu vực lễ tân không hoạt động.';

Future<void> _openDraft(
  WidgetTester tester, {
  ReportDraft? draft,
  ReportRepository? repository,
  XFile? image,
}) async {
  final picker = _FakeImagePicker(nextImage: image);
  await tester.pumpWidget(
    _testApp(
      imagePicker: picker,
      reportService: _FakeReportService(draft),
      reportRepository: repository,
    ),
  );
  await tester.enterText(
    find.byKey(const Key('incident-description-field')),
    _sampleDescription,
  );
  if (image != null) {
    await tester.tap(find.byKey(const Key('choose-photo-button')));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.byKey(const Key('analyze-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('analyze-button')));
  await tester.pumpAndSettle();
  expect(find.byType(ReportDraftScreen), findsOneWidget);
}

Future<void> _confirmAllFields(WidgetTester tester) async {
  for (final field in [
    'category',
    'location',
    'priority',
    'issue',
    'suggested_action',
  ]) {
    await _confirmField(tester, field);
  }
}

Future<void> _confirmField(
  WidgetTester tester,
  String field, {
  bool absent = false,
}) async {
  final key = field == 'issue'
      ? 'confirm-field-issue'
      : absent
      ? 'confirm-absent-$field'
      : 'confirm-field-$field';
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

ReportDraft _fullDraft() {
  return ReportDraft(
    category: 'Hỏng hóc thiết bị',
    location: 'Khu vực lễ tân',
    priority: ReportPriority.high,
    issue: 'Điều hòa không hoạt động',
    suggestedAction: 'Cử nhân viên bảo trì kiểm tra.',
    summary: 'Điều hòa lễ tân không hoạt động, khách phàn nàn.',
  );
}

ReportDraft _partialDraft() {
  // issue has content but the AI still flagged it: the badge must show while
  // empty fields stay hidden instead of being presented as facts.
  return ReportDraft(
    category: '',
    location: '',
    priority: null,
    issue: 'Rò rỉ nước',
    suggestedAction: '',
    summary: '',
    needsConfirmation: ['issue'],
  );
}

Future<XFile> _tinyPng() async {
  return XFile.fromData(
    Uint8List.fromList(_tinyPngBytes),
    name: 'test.png',
    mimeType: 'image/png',
  );
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

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.nextImage, this.error});

  XFile? nextImage;
  final Object? error;
  ImageSource? lastSource;

  @override
  bool supportsImageSource(ImageSource source) => true;

  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    if (error != null) throw error!;
    return nextImage;
  }
}

class _FakeReportService extends GeminiReportService {
  _FakeReportService([ReportDraft? draft])
    : _isHanging = false,
      draft = draft ?? _fullDraft();

  _FakeReportService.hanging() : _isHanging = true, draft = _fullDraft();

  ReportDraft draft;
  Object? nextError;
  int callCount = 0;
  final bool _isHanging;
  Completer<ReportDraft>? _completer;

  void complete() {
    _completer?.complete(draft);
  }

  @override
  Future<ReportDraft> createReportDraft({String? description, XFile? image}) {
    callCount++;
    final error = nextError;
    if (error != null) {
      nextError = null;
      return Future.error(error);
    }
    if (_isHanging) {
      _completer = Completer<ReportDraft>();
      return _completer!.future;
    }
    return Future.value(draft);
  }
}

class _FakeReportRepository implements ReportRepository {
  bool supported = true;
  int saveCount = 0;
  ReportStorageException? nextSaveError;
  bool commitBeforeNextSaveError = false;
  Completer<void>? saveGate;
  Report? lastRequested;
  Report? lastSaved;
  Uint8List? lastImageBytes;
  final requestedIds = <String>[];
  final _reports = <String, Report>{};

  @override
  bool get isSupported => supported;

  @override
  Future<Report> save(Report report, {Uint8List? imageBytes}) async {
    saveCount++;
    lastRequested = report;
    requestedIds.add(report.id);
    lastImageBytes = imageBytes == null ? null : Uint8List.fromList(imageBytes);
    await saveGate?.future;

    final error = nextSaveError;
    nextSaveError = null;
    if (error != null && !commitBeforeNextSaveError) throw error;
    commitBeforeNextSaveError = false;

    final json = report.toJson();
    if (imageBytes != null) {
      json['photo_path'] = 'report_photos/${report.id}.image';
    }
    final saved = Report.fromJson(json);
    _reports[saved.id] = saved;
    lastSaved = saved;
    if (error != null) throw error;
    return saved;
  }

  @override
  Future<List<Report>> listReports() async =>
      List.unmodifiable(_reports.values);

  @override
  Future<Report?> findById(String id) async => _reports[id];

  @override
  Future<Uint8List> readPhotoBytes(String relativePath) async =>
      Uint8List.fromList(_tinyPngBytes);

  @override
  Future<void> close() async {}
}
