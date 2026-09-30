import 'package:ai_field_assistant/models/report.dart';
import 'package:ai_field_assistant/models/report_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Report', () {
    test('serializes and restores confirmed report data', () {
      final report = Report(
        id: _id,
        createdAt: DateTime.utc(2026, 9, 27, 7, 30),
        category: 'Điện',
        location: '',
        priority: null,
        issue: 'Ổ cắm bị nóng',
        suggestedAction: 'Kiểm tra tải và đầu nối',
        summary: 'Nhân viên ghi nhận ổ cắm bị nóng.',
        sourceDescription: 'Ổ cắm ở phòng A bị nóng.',
        photoPath: 'report_photos/$_id.jpg',
        confirmedAbsentFields: const {'location', 'priority'},
      );

      final restored = Report.fromJson(report.toJson());

      expect(restored.toJson(), report.toJson());
      expect(restored.createdAt.isUtc, isTrue);
      expect(restored.status, ReportStatus.confirmed);
      expect(restored.confirmedAbsentFields, {'location', 'priority'});
      expect(restored.category, 'Điện');
    });

    test('round-trips an empty confirmed-absence list', () {
      final report = _validReport();

      final restored = Report.fromJson(report.toJson());

      expect(report.toJson()['confirmed_absent_fields'], isEmpty);
      expect(restored.confirmedAbsentFields, isEmpty);
      expect(restored.toJson(), report.toJson());
    });

    test('stores timestamps as UTC epoch milliseconds', () {
      final localTime = DateTime(2026, 9, 27, 12);
      final report = _validReport(createdAt: localTime);

      expect(report.createdAt.isUtc, isTrue);
      expect(
        report.toJson()['created_at'],
        localTime.toUtc().millisecondsSinceEpoch,
      );
      expect(Report.fromJson(report.toJson()).createdAt, localTime.toUtc());
    });

    test('generates a 22-character base64url ID', () {
      final id = Report.generateId();

      expect(id, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
    });

    test('trims report field values only at report creation', () {
      final report = _validReport(
        category: '  Nước  ',
        issue: '  Rò rỉ  ',
        suggestedAction: '  Khóa van  ',
        summary: '  Rò rỉ nước  ',
      );

      expect(report.category, 'Nước');
      expect(report.issue, 'Rò rỉ');
      expect(report.suggestedAction, 'Khóa van');
      expect(report.summary, 'Rò rỉ nước');
    });

    test('rejects an empty issue even when other fields are confirmed', () {
      expect(() => _validReport(issue: ' \n '), throwsArgumentError);
    });

    test('requires confirmed absence for every empty optional field', () {
      expect(
        () => _validReport(category: '', confirmedAbsentFields: const {}),
        throwsArgumentError,
      );
    });

    test('rejects absence markers that do not match field values', () {
      expect(
        () => _validReport(confirmedAbsentFields: const {'category'}),
        throwsArgumentError,
      );
      expect(
        () => _validReport(confirmedAbsentFields: const {'issue'}),
        throwsArgumentError,
      );
      expect(
        () => _validReport(confirmedAbsentFields: const {'unknown'}),
        throwsArgumentError,
      );
      expect(
        () =>
            _validReport(confirmedAbsentFields: const ['location', 'location']),
        throwsArgumentError,
      );
    });

    test('rejects invalid IDs and unsafe photo paths', () {
      expect(() => _validReport(id: 'not-an-id'), throwsArgumentError);
      expect(
        () => _validReport(photoPath: r'report_photos\..outside.jpg'),
        throwsArgumentError,
      );
      expect(
        () => _validReport(photoPath: 'report_photos/../outside.jpg'),
        throwsArgumentError,
      );
      expect(
        () => _validReport(photoPath: '/report_photos/outside.jpg'),
        throwsArgumentError,
      );
    });

    test('rejects malformed serialized reports with FormatException', () {
      final missing = _validReport().toJson()..remove('issue');
      final invalidPriority = _validReport().toJson()..['priority'] = 'urgent';
      final invalidTimestamp = _validReport().toJson()
        ..['created_at'] = 'today';
      final invalidStatus = _validReport().toJson()..['status'] = 'draft';
      final unknownField = _validReport().toJson()..['debug'] = true;
      final invalidAbsent = _validReport().toJson()
        ..['confirmed_absent_fields'] = ['issue'];

      for (final json in [
        null,
        ['not', 'a', 'map'],
        missing,
        invalidPriority,
        invalidTimestamp,
        invalidStatus,
        unknownField,
        invalidAbsent,
      ]) {
        expect(() => Report.fromJson(json), throwsFormatException);
      }
    });
  });
}

const _id = 'abcdefghijklmnopqrstuv';

Report _validReport({
  String id = _id,
  DateTime? createdAt,
  String category = 'Thiết bị',
  String location = 'Tầng 2',
  ReportPriority? priority = ReportPriority.high,
  String issue = 'Thiết bị không hoạt động',
  String suggestedAction = 'Kiểm tra nguồn điện',
  String summary = 'Thiết bị tại tầng 2 không hoạt động.',
  String? photoPath,
  Iterable<String> confirmedAbsentFields = const [],
}) => Report(
  id: id,
  createdAt: createdAt ?? DateTime.utc(2026, 9, 27),
  category: category,
  location: location,
  priority: priority,
  issue: issue,
  suggestedAction: suggestedAction,
  summary: summary,
  sourceDescription: 'Mô tả nguồn ban đầu.',
  photoPath: photoPath,
  confirmedAbsentFields: confirmedAbsentFields,
);
