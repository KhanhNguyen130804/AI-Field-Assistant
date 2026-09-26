import 'dart:async';
import 'dart:typed_data';

import 'package:ai_field_assistant/models/report_draft.dart';
import 'package:ai_field_assistant/services/gemini_report_service.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

const _validDraftJson = '''
{
  "category": "Hỏng hóc thiết bị",
  "location": "Khu vực lễ tân",
  "priority": "high",
  "issue": "Điều hòa không hoạt động",
  "suggested_action": "Cử nhân viên bảo trì kiểm tra.",
  "summary": "Điều hòa lễ tân không hoạt động, khách phàn nàn.",
  "needs_confirmation": []
}
''';

// Minimal PNG header so the service can sniff the MIME type when XFile
// carries none.
const _pngHeaderBytes = <int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
];

void main() {
  GeminiReportService buildService(
    ReportDraftRequestSender sender, {
    Duration? timeout,
  }) {
    return GeminiReportService(
      requestSender: sender,
      requestTimeout: timeout ?? const Duration(seconds: 5),
    );
  }

  test('mô tả không kèm ảnh: gửi một TextPart và parse draft', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    final draft = await service.createReportDraft(
      description: '  Điều hòa lễ tân không chạy.  ',
    );

    expect(draft.category, 'Hỏng hóc thiết bị');
    expect(draft.priority, ReportPriority.high);
    expect(draft.needsConfirmation, isEmpty);
    expect(sender.callCount, 1);
    final prompt = sender.lastPrompt;
    expect(prompt.parts.whereType<TextPart>(), hasLength(1));
    expect(
      prompt.parts.whereType<TextPart>().single.text,
      'Điều hòa lễ tân không chạy.',
    );
    expect(prompt.parts.whereType<InlineDataPart>(), isEmpty);
  });

  test('chỉ có ảnh: gửi InlineDataPart không kèm TextPart', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    final draft = await service.createReportDraft(
      image: XFile.fromData(
        Uint8List.fromList(_pngHeaderBytes),
        name: 'photo.png',
        mimeType: 'image/png',
      ),
    );

    expect(draft.issue, 'Điều hòa không hoạt động');
    expect(sender.callCount, 1);
    final prompt = sender.lastPrompt;
    expect(prompt.parts.whereType<InlineDataPart>(), hasLength(1));
    expect(
      prompt.parts.whereType<InlineDataPart>().single.mimeType,
      'image/png',
    );
    expect(prompt.parts.whereType<TextPart>(), isEmpty);
  });

  test('có cả mô tả và ảnh: thứ tự TextPart trước InlineDataPart', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    await service.createReportDraft(
      description: 'Điều hòa lễ tân không chạy.',
      image: XFile.fromData(
        Uint8List.fromList(_pngHeaderBytes),
        name: 'photo.png',
        mimeType: 'image/png',
      ),
    );

    final parts = sender.lastPrompt.parts;
    expect(
      parts.whereType<TextPart>().single.text,
      'Điều hòa lễ tân không chạy.',
    );
    expect(
      parts.whereType<InlineDataPart>().single.bytes,
      Uint8List.fromList(_pngHeaderBytes),
    );
    expect(
      parts.indexOf(parts.whereType<TextPart>().single),
      lessThan(parts.indexOf(parts.whereType<InlineDataPart>().single)),
    );
  });

  test('ảnh không khai báo MIME: nhận diện từ signature PNG', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    await service.createReportDraft(
      image: XFile.fromData(Uint8List.fromList(_pngHeaderBytes), name: 'photo'),
    );

    expect(
      sender.lastPrompt.parts.whereType<InlineDataPart>().single.mimeType,
      'image/png',
    );
  });

  test('cả mô tả và ảnh đều trống: chặn trước khi gửi', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: '   '),
      throwsA(isA<InvalidReportDraftInputException>()),
    );
    expect(sender.callCount, 0);
  });

  test('ảnh vượt 4 MiB: chặn trước khi gửi', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(
        image: XFile.fromData(
          Uint8List(4 * 1024 * 1024 + 1),
          name: 'big.png',
          mimeType: 'image/png',
        ),
      ),
      throwsA(
        isA<InvalidReportDraftInputException>().having(
          (error) => error.userMessage,
          'userMessage',
          contains('4 MiB'),
        ),
      ),
    );
    expect(sender.callCount, 0);
  });

  test('ảnh rỗng: chặn với thông báo ảnh không đọc được', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(
        image: XFile.fromData(Uint8List(0), name: 'empty.png'),
      ),
      throwsA(isA<InvalidReportDraftInputException>()),
    );
    expect(sender.callCount, 0);
  });

  test('bytes không phải ảnh: chặn với thông báo loại ảnh', () async {
    final sender = _FakeSender(responseText: _validDraftJson);
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(
        image: XFile.fromData(Uint8List.fromList([1, 2, 3, 4]), name: 'x'),
      ),
      throwsA(isA<InvalidReportDraftInputException>()),
    );
    expect(sender.callCount, 0);
  });

  test('response rỗng: báo lỗi phản hồi AI', () async {
    final sender = _FakeSender(responseText: '   ');
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftResponseException>()),
    );
  });

  test('response không phải JSON: báo lỗi phản hồi AI', () async {
    final sender = _FakeSender(responseText: 'Xin chào, tôi không thể giúp.');
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftResponseException>()),
    );
  });

  test('JSON root không phải object: báo lỗi phản hồi AI', () async {
    final sender = _FakeSender(responseText: '["category"]');
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftResponseException>()),
    );
  });

  test(
    'thiếu needs_confirmation: mọi field được đánh dấu cần xem lại',
    () async {
      final sender = _FakeSender(
        responseText:
            '{"category":"","location":"","priority":null,"issue":"Rò rỉ nước",'
            '"suggested_action":"","summary":"","priority2":null}',
      );
      final service = buildService(sender);

      final draft = await service.createReportDraft(description: 'Rò rỉ nước.');

      expect(draft.issue, 'Rò rỉ nước');
      expect(draft.needsConfirmation, ReportDraft.confirmableFields);
    },
  );

  test('priority null: draft giữ null và đưa vào needs_confirmation', () async {
    final sender = _FakeSender(
      responseText:
          '{"category":"","location":"","priority":null,"issue":"Rò rỉ nước",'
          '"suggested_action":"","summary":"","needs_confirmation":["priority"]}',
    );
    final service = buildService(sender);

    final draft = await service.createReportDraft(description: 'Rò rỉ nước.');

    expect(draft.priority, isNull);
    expect(draft.needsConfirmation, contains('priority'));
  });

  test('QuotaExceeded: ánh xạ thành lỗi quota', () async {
    final sender = _FakeSender(error: QuotaExceeded('resource exhausted'));
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftQuotaException>()),
    );
  });

  test('TimeoutException từ sender: ánh xạ thành lỗi timeout', () async {
    final sender = _FakeSender(error: TimeoutException('deadline', null));
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftTimeoutException>()),
    );
  });

  test('sender treo quá thời hạn: timeout của service', () async {
    final sender = _HangingSender();
    final service = buildService(
      sender,
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftTimeoutException>()),
    );
  });

  test('ServiceApiNotEnabled: ánh xạ thành lỗi cấu hình', () async {
    final sender = _FakeSender(error: ServiceApiNotEnabled('project'));
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftConfigException>()),
    );
  });

  test('lỗi App Check: ánh xạ thành lỗi App Check', () async {
    final sender = _FakeSender(
      error: FirebaseAIException('App Check token was rejected.'),
    );
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftAppCheckException>()),
    );
  });

  test('response bị block: ánh xạ thành lỗi phản hồi AI', () async {
    final sender = _FakeSender(
      error: FirebaseAIException('Response was blocked due to SAFETY'),
    );
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftResponseException>()),
    );
  });

  test('lỗi server chung: ánh xạ thành lỗi dịch vụ/mạng', () async {
    final sender = _FakeSender(error: ServerException('503'));
    final service = buildService(sender);

    await expectLater(
      service.createReportDraft(description: 'Điều hòa hỏng.'),
      throwsA(isA<ReportDraftServiceException>()),
    );
  });
}

class _FakeSender implements ReportDraftRequestSender {
  _FakeSender({this.responseText, this.error});

  final String? responseText;
  final Object? error;
  Content lastPrompt = Content.text('');
  int callCount = 0;

  @override
  Future<String?> send(Content prompt) async {
    callCount++;
    lastPrompt = prompt;
    if (error != null) throw error!;
    return responseText;
  }
}

class _HangingSender implements ReportDraftRequestSender {
  final Completer<String?> _never = Completer<String?>();

  @override
  Future<String?> send(Content prompt) => _never.future;
}
