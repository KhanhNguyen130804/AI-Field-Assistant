import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ai_field_assistant/models/report.dart';
import 'package:ai_field_assistant/models/report_priority.dart';
import 'package:ai_field_assistant/repositories/local_report_repository.dart';
import 'package:ai_field_assistant/repositories/report_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Directory supportDirectory;
  late LocalReportRepository repository;

  LocalReportRepository createRepository(Directory root) =>
      LocalReportRepository(
        databaseFactory: databaseFactoryFfi,
        supportDirectoryProvider: () async => root,
      );

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'field-assistant-repository-test-',
    );
    repository = createRepository(supportDirectory);
  });

  tearDown(() async {
    await repository.close();
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  group('LocalReportRepository', () {
    test(
      'round-trips confirmed report values and explicit absent fields',
      () async {
        final report = _report(
          id: 'aaaaaaaaaaaaaaaaaaaaaa',
          category: '',
          priority: null,
          suggestedAction: '',
          summary: '',
          confirmedAbsentFields: const {
            'category',
            'priority',
            'suggested_action',
            'summary',
          },
        );

        final saved = await repository.save(report);
        final read = await repository.findById(report.id);
        final listed = await repository.listReports();

        expect(saved.photoPath, isNull);
        expect(read?.toJson(), report.toJson());
        expect(listed, hasLength(1));
        expect(listed.single.toJson(), report.toJson());
      },
    );

    test('keeps a copied image across repository close and reopen', () async {
      final report = _report(id: 'bbbbbbbbbbbbbbbbbbbbbb');
      final imageBytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1, 2, 3]);

      final saved = await repository.save(report, imageBytes: imageBytes);
      final photoPath = saved.photoPath!;
      final storedFile = File(p.join(supportDirectory.path, photoPath));
      expect(await storedFile.exists(), isTrue);
      expect(await repository.readPhotoBytes(photoPath), imageBytes);

      await repository.close();
      repository = createRepository(supportDirectory);
      final reopened = await repository.findById(report.id);

      expect(reopened?.toJson(), saved.toJson());
      expect(await repository.readPhotoBytes(photoPath), imageBytes);
    });

    test(
      'orders newest first and breaks equal timestamps by descending ID',
      () async {
        final timestamp = DateTime.utc(2026, 9, 27, 8);
        await repository.save(
          _report(id: 'aaaaaaaaaaaaaaaaaaaaaa', createdAt: timestamp),
        );
        await repository.save(
          _report(id: 'cccccccccccccccccccccc', createdAt: timestamp),
        );
        await repository.save(
          _report(
            id: 'bbbbbbbbbbbbbbbbbbbbbb',
            createdAt: timestamp.add(const Duration(seconds: 1)),
          ),
        );

        final reports = await repository.listReports();

        expect(reports.map((report) => report.id), [
          'bbbbbbbbbbbbbbbbbbbbbb',
          'cccccccccccccccccccccc',
          'aaaaaaaaaaaaaaaaaaaaaa',
        ]);
      },
    );

    test(
      'returns an identical retry and rejects an ID reused for other data',
      () async {
        final report = _report(id: 'dddddddddddddddddddddd');
        await repository.save(report);

        final retry = await repository.save(report);
        expect(retry.toJson(), report.toJson());
        expect(await repository.listReports(), hasLength(1));

        await expectLater(
          repository.save(_report(id: report.id, summary: 'Nội dung khác')),
          throwsA(
            isA<ReportStorageException>().having(
              (error) => error.failure,
              'failure',
              ReportStorageFailure.conflict,
            ),
          ),
        );
        expect(await repository.listReports(), hasLength(1));
      },
    );

    test(
      'verifies image bytes on retry and refuses an unverifiable retry',
      () async {
        final report = _report(id: 'eeeeeeeeeeeeeeeeeeeeee');
        final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
        final saved = await repository.save(report, imageBytes: imageBytes);

        expect(
          (await repository.save(report, imageBytes: imageBytes)).photoPath,
          saved.photoPath,
        );
        await expectLater(
          repository.save(report),
          throwsA(
            isA<ReportStorageException>().having(
              (error) => error.failure,
              'failure',
              ReportStorageFailure.photo,
            ),
          ),
        );
        await expectLater(
          repository.save(report, imageBytes: Uint8List.fromList([4, 3, 2, 1])),
          throwsA(isA<ReportStorageException>()),
        );
        expect(await repository.listReports(), hasLength(1));
      },
    );

    test('reports a missing image without deleting its report', () async {
      final report = _report(id: 'ffffffffffffffffffffff');
      final saved = await repository.save(
        report,
        imageBytes: Uint8List.fromList([5, 6, 7]),
      );
      await File(p.join(supportDirectory.path, saved.photoPath!)).delete();

      await expectLater(
        repository.readPhotoBytes(saved.photoPath!),
        throwsA(
          isA<ReportStorageException>().having(
            (error) => error.failure,
            'failure',
            ReportStorageFailure.photo,
          ),
        ),
      );
      expect((await repository.findById(report.id))?.issue, report.issue);
    });

    test('rejects unsafe image paths without touching files', () async {
      await expectLater(
        repository.readPhotoBytes('../outside.image'),
        throwsA(
          isA<ReportStorageException>().having(
            (error) => error.failure,
            'failure',
            ReportStorageFailure.invalidReport,
          ),
        ),
      );
      expect(await supportDirectory.list().isEmpty, isTrue);
    });

    test(
      'maps image directory write failures and does not insert a report',
      () async {
        await File(p.join(supportDirectory.path, 'report_photos'))
            .writeAsString('blocker');
        final report = _report(id: 'gggggggggggggggggggggg');

        await expectLater(
          repository.save(report, imageBytes: Uint8List.fromList([8, 9])),
          throwsA(
            isA<ReportStorageException>().having(
              (error) => error.failure,
              'failure',
              ReportStorageFailure.photo,
            ),
          ),
        );
        expect(await repository.listReports(), isEmpty);
      },
    );

    test(
      'maps database write failures and cleans up its uncommitted image',
      () async {
        await repository.listReports();
        await repository.close();
        final database = await databaseFactoryFfi.openDatabase(
          p.join(supportDirectory.path, 'reports.db'),
        );
        await database.execute('''
          CREATE TRIGGER fail_report_insert
          BEFORE INSERT ON reports
          BEGIN
            SELECT RAISE(ABORT, 'test write failure');
          END
        ''');
        await database.close();
        repository = createRepository(supportDirectory);

        final report = _report(id: 'iiiiiiiiiiiiiiiiiiiiii');
        await expectLater(
          repository.save(report, imageBytes: Uint8List.fromList([10, 11, 12])),
          throwsA(
            isA<ReportStorageException>().having(
              (error) => error.failure,
              'failure',
              ReportStorageFailure.database,
            ),
          ),
        );

        expect(await repository.findById(report.id), isNull);
        final photoDirectory = Directory(
          p.join(supportDirectory.path, 'report_photos'),
        );
        if (await photoDirectory.exists()) {
          expect(await photoDirectory.list().isEmpty, isTrue);
        }
      },
    );

    test('maps corrupt stored JSON to a database error', () async {
      final report = _report(id: 'hhhhhhhhhhhhhhhhhhhhhh');
      await repository.save(report);
      await repository.close();
      final database = await databaseFactoryFfi.openDatabase(
        p.join(supportDirectory.path, 'reports.db'),
      );
      await database.update(
        'reports',
        {'confirmed_absent_fields': '{bad json'},
        where: 'id = ?',
        whereArgs: [report.id],
      );
      await database.close();
      repository = createRepository(supportDirectory);

      await expectLater(
        repository.findById(report.id),
        throwsA(
          isA<ReportStorageException>().having(
            (error) => error.failure,
            'failure',
            ReportStorageFailure.database,
          ),
        ),
      );
    });
  });
}

Report _report({
  required String id,
  DateTime? createdAt,
  String category = 'Điện',
  String location = 'Tầng 2',
  ReportPriority? priority = ReportPriority.high,
  String issue = 'Ổ cắm bị nóng',
  String suggestedAction = 'Kiểm tra ổ cắm',
  String summary = 'Ổ cắm tại tầng 2 bị nóng.',
  Set<String> confirmedAbsentFields = const {},
}) => Report(
  id: id,
  createdAt: createdAt ?? DateTime.utc(2026, 9, 27, 8),
  category: category,
  location: location,
  priority: priority,
  issue: issue,
  suggestedAction: suggestedAction,
  summary: summary,
  sourceDescription: 'Ổ cắm tại tầng 2 có dấu hiệu nóng.',
  confirmedAbsentFields: confirmedAbsentFields,
);
