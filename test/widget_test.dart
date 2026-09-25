import 'dart:ui' as ui;

import 'package:ai_field_assistant/main.dart';
import 'package:ai_field_assistant/screens/create_report_screen.dart';
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
      AiFieldAssistantApp(imagePicker: _FakeImagePicker()),
    );

    expect(find.byKey(const Key('incident-description-field')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có báo cáo'), findsOneWidget);

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
}

Widget _testApp({required ImagePicker imagePicker}) {
  return MaterialApp(
    home: Scaffold(body: CreateReportScreen(imagePicker: imagePicker)),
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
