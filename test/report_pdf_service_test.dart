import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ai_field_assistant/models/report.dart';
import 'package:ai_field_assistant/models/report_priority.dart';
import 'package:ai_field_assistant/services/report_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = ReportPdfService();

  test(
    'generates a multipage-ready PDF with embedded Vietnamese text',
    () async {
      final report = _report(
        sourceDescription: List.filled(
          100,
          'Mô tả tiếng Việt có dấu.',
        ).join(' '),
      );

      final bytes = await service.generate(report: report);
      final output = latin1.decode(bytes, allowInvalid: true);

      expect(output, startsWith('%PDF-'));
      expect(output, contains('/Type/Page'));
      expect(bytes.length, greaterThan(1000));
    },
  );

  test('requires explicit confirmation before omitting a stored photo', () {
    expect(
      () => service.generate(report: _report(photoPath: _photoPath)),
      throwsA(isA<ReportPdfPhotoException>()),
    );
  });

  test('converts WebP photos into a PDF-supported image', () async {
    final image = img.Image(width: 2, height: 2)
      ..setPixelRgb(0, 0, 30, 120, 90);
    final webpBytes = Uint8List.fromList(img.encodeWebP(image));

    final bytes = await service.generate(
      report: _report(photoPath: _photoPath),
      photoBytes: webpBytes,
    );

    expect(latin1.decode(bytes, allowInvalid: true), contains('/Type/Page'));
  });

  test(
    'rejects malformed photo data instead of silently dropping it',
    () async {
      await expectLater(
        service.generate(
          report: _report(photoPath: _photoPath),
          photoBytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<ReportPdfPhotoException>()),
      );
    },
  );

  test(
    'allows photo omission only after an explicit caller confirmation',
    () async {
      final bytes = await service.generate(
        report: _report(photoPath: _photoPath),
        photoOmissionConfirmed: true,
      );

      expect(latin1.decode(bytes, allowInvalid: true), contains('/Type/Page'));
      expect(utf8.decode(bytes, allowMalformed: true), isNotEmpty);
    },
  );
}

const _photoPath = 'report_photos/AAAAAAAAAAAAAAAAAAAAAA.image';

Report _report({
  String sourceDescription = 'Mô tả sự cố.',
  String? photoPath,
}) => Report(
  id: 'AAAAAAAAAAAAAAAAAAAAAA',
  createdAt: DateTime.utc(2026, 9, 30, 12),
  category: 'Điện',
  location: 'Tầng 2',
  priority: ReportPriority.high,
  issue: 'Cầu dao bị nóng',
  suggestedAction: 'Kiểm tra thiết bị.',
  summary: 'Cầu dao có dấu hiệu quá nhiệt.',
  sourceDescription: sourceDescription,
  confirmedAbsentFields: const [],
  photoPath: photoPath,
);
