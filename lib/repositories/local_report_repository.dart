import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/report.dart';
import 'report_repository.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

/// SQLite-backed Android repository with app-owned copies of report images.
///
/// [databaseFactory] and [supportDirectoryProvider] are injectable so tests
/// can use a real SQLite FFI database inside a temporary directory.
class LocalReportRepository implements ReportRepository {
  LocalReportRepository({
    sqflite.DatabaseFactory? databaseFactory,
    SupportDirectoryProvider? supportDirectoryProvider,
  }) : _databaseFactory = databaseFactory ?? sqflite.databaseFactory,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const int _schemaVersion = 1;
  static const String _databaseName = 'reports.db';
  static const String _reportsTable = 'reports';
  static final RegExp _photoPathPattern = RegExp(
    r'^report_photos/([A-Za-z0-9_-]{22})\.image$',
  );
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{22}$');

  final sqflite.DatabaseFactory _databaseFactory;
  final SupportDirectoryProvider _supportDirectoryProvider;
  Future<sqflite.Database>? _databaseFuture;
  Future<void> _operations = Future<void>.value();

  @override
  bool get isSupported => true;

  @override
  Future<Report> save(Report report, {Uint8List? imageBytes}) =>
      _serialize(() => _save(report, imageBytes: imageBytes));

  @override
  Future<List<Report>> listReports() => _serialize(() async {
    final database = await _database();
    try {
      final rows = await database.query(
        _reportsTable,
        orderBy: 'created_at DESC, id DESC',
      );
      return List<Report>.unmodifiable(rows.map((row) => _reportFromRow(row)));
    } on ReportStorageException {
      rethrow;
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể đọc danh sách báo cáo trên thiết bị.',
      );
    }
  });

  @override
  Future<Report?> findById(String id) => _serialize(() async {
    _validateId(id);
    final database = await _database();
    try {
      return await _findById(database, id);
    } on ReportStorageException {
      rethrow;
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể đọc báo cáo trên thiết bị.',
      );
    }
  });

  @override
  Future<Uint8List> readPhotoBytes(String relativePath) => _serialize(() async {
    final match = _photoPathPattern.firstMatch(relativePath);
    if (match == null) {
      throw const ReportStorageException(
        ReportStorageFailure.invalidReport,
        'Đường dẫn ảnh báo cáo không hợp lệ.',
      );
    }

    try {
      final supportDirectory = await _supportDirectoryProvider();
      final file = File(p.join(supportDirectory.path, relativePath));
      return await file.readAsBytes();
    } on FileSystemException {
      throw const ReportStorageException(
        ReportStorageFailure.photo,
        'Không thể đọc ảnh đã lưu. Nội dung báo cáo vẫn được giữ.',
      );
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.photo,
        'Không thể đọc ảnh đã lưu. Nội dung báo cáo vẫn được giữ.',
      );
    }
  });

  @override
  Future<void> close() => _serialize(() async {
    final databaseFuture = _databaseFuture;
    _databaseFuture = null;
    if (databaseFuture == null) return;
    try {
      final database = await databaseFuture;
      await database.close();
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể đóng kho báo cáo trên thiết bị.',
      );
    }
  });

  Future<Report> _save(Report report, {required Uint8List? imageBytes}) async {
    if (report.photoPath != null) {
      throw const ReportStorageException(
        ReportStorageFailure.invalidReport,
        'Báo cáo mới không được chỉ định sẵn đường dẫn ảnh.',
      );
    }
    if (imageBytes != null && imageBytes.isEmpty) {
      throw const ReportStorageException(
        ReportStorageFailure.photo,
        'Ảnh báo cáo không có dữ liệu.',
      );
    }

    final database = await _database();
    final Report? existing;
    try {
      existing = await _findById(database, report.id);
    } on ReportStorageException {
      rethrow;
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể kiểm tra báo cáo đã tồn tại trên thiết bị.',
      );
    }
    if (existing != null) {
      return _verifyRetry(existing, report, imageBytes);
    }

    File? createdPhotoFile;
    File? stagingFile;
    var stagingCreated = false;
    var insertStarted = false;
    var insertCommitted = false;
    Report savedReport = report;

    try {
      if (imageBytes != null) {
        final supportDirectory = await _supportDirectoryProvider();
        final photoDirectory = Directory(
          p.join(supportDirectory.path, 'report_photos'),
        );
        await photoDirectory.create(recursive: true);

        final relativePath = _photoPathFor(report.id);
        final targetFile = File(p.join(supportDirectory.path, relativePath));
        if (await targetFile.exists()) {
          final priorBytes = await targetFile.readAsBytes();
          if (!_bytesEqual(priorBytes, imageBytes)) {
            throw const ReportStorageException(
              ReportStorageFailure.conflict,
              'Đã tồn tại ảnh khác cho ID báo cáo này.',
            );
          }
          // A matching file may be an orphan left after a process crash. Keep
          // it on failure because this attempt did not create it.
        } else {
          stagingFile = File(
            p.join(photoDirectory.path, _stagingFileName(report.id)),
          );
          await stagingFile.create(exclusive: true);
          stagingCreated = true;
          await stagingFile.writeAsBytes(imageBytes, flush: true);
          await stagingFile.rename(targetFile.path);
          stagingFile = null;
          stagingCreated = false;
          createdPhotoFile = targetFile;
        }

        savedReport = _copyWithPhotoPath(report, relativePath);
      }

      final row = _rowForReport(savedReport);
      insertStarted = true;
      await database.transaction((transaction) async {
        await transaction.insert(
          _reportsTable,
          row,
          conflictAlgorithm: sqflite.ConflictAlgorithm.abort,
        );
      });
      insertCommitted = true;
      return savedReport;
    } on Object catch (error) {
      if (insertCommitted) rethrow;

      if (insertStarted) {
        // A commit error can leave its outcome unclear. Read by ID before
        // cleaning up any file that could now belong to a committed report.
        try {
          final recovered = await _findById(database, report.id);
          if (recovered != null) {
            return await _verifyRetry(recovered, report, imageBytes);
          }
          await _deleteIfCreated(createdPhotoFile);
        } on ReportStorageException catch (recoveryError) {
          if (recoveryError.failure == ReportStorageFailure.conflict) {
            rethrow;
          }
          throw const ReportStorageException(
            ReportStorageFailure.database,
            'Không xác định được kết quả lưu. Ảnh tạm được giữ để tránh mất dữ liệu; hãy thử đọc lại báo cáo.',
          );
        } on Object {
          throw const ReportStorageException(
            ReportStorageFailure.database,
            'Không xác định được kết quả lưu. Ảnh tạm được giữ để tránh mất dữ liệu; hãy thử đọc lại báo cáo.',
          );
        }
      } else {
        await _deleteIfCreated(createdPhotoFile);
      }

      if (error is ReportStorageException) rethrow;
      if (stagingCreated) await _deleteIfCreated(stagingFile);
      if (error is FileSystemException) {
        throw const ReportStorageException(
          ReportStorageFailure.photo,
          'Không thể lưu ảnh báo cáo trên thiết bị.',
        );
      }
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể lưu báo cáo trên thiết bị.',
      );
    } finally {
      if (stagingCreated) await _deleteIfCreated(stagingFile);
    }
  }

  Future<Report> _verifyRetry(
    Report existing,
    Report requested,
    Uint8List? imageBytes,
  ) async {
    if (!_sameReportSnapshot(existing, requested)) {
      throw const ReportStorageException(
        ReportStorageFailure.conflict,
        'ID báo cáo này đã được dùng cho nội dung khác.',
      );
    }

    if (existing.photoPath == null) {
      if (imageBytes != null) {
        throw const ReportStorageException(
          ReportStorageFailure.conflict,
          'Báo cáo đã lưu không có ảnh nhưng lần thử lại có ảnh.',
        );
      }
      return existing;
    }

    if (imageBytes == null) {
      throw const ReportStorageException(
        ReportStorageFailure.photo,
        'Không thể xác minh ảnh của lần lưu trước khi thử lại.',
      );
    }

    final storedBytes = await _readStoredPhoto(existing.photoPath!);
    if (!_bytesEqual(storedBytes, imageBytes)) {
      throw const ReportStorageException(
        ReportStorageFailure.conflict,
        'ID báo cáo này đã được dùng cho ảnh khác.',
      );
    }
    return existing;
  }

  Future<Uint8List> _readStoredPhoto(String relativePath) async {
    final match = _photoPathPattern.firstMatch(relativePath);
    if (match == null) {
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Bản ghi có đường dẫn ảnh không hợp lệ.',
      );
    }
    try {
      final supportDirectory = await _supportDirectoryProvider();
      return await File(p.join(supportDirectory.path, relativePath))
          .readAsBytes();
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.photo,
        'Không thể xác minh ảnh đã lưu. Báo cáo vẫn được giữ.',
      );
    }
  }

  Future<sqflite.Database> _database() async {
    final current = _databaseFuture;
    if (current != null) return current;

    final opening = _openDatabase();
    _databaseFuture = opening;
    try {
      return await opening;
    } on Object {
      if (identical(_databaseFuture, opening)) _databaseFuture = null;
      rethrow;
    }
  }

  Future<sqflite.Database> _openDatabase() async {
    try {
      final supportDirectory = await _supportDirectoryProvider();
      await supportDirectory.create(recursive: true);
      final databasePath = p.join(supportDirectory.path, _databaseName);
      return await _databaseFactory.openDatabase(
        databasePath,
        options: sqflite.OpenDatabaseOptions(
          version: _schemaVersion,
          onCreate: (database, version) async {
            await database.execute('''
              CREATE TABLE $_reportsTable (
                id TEXT NOT NULL PRIMARY KEY,
                category TEXT NOT NULL,
                location TEXT NOT NULL,
                priority TEXT CHECK (
                  priority IS NULL OR priority IN ('low', 'medium', 'high')
                ),
                issue TEXT NOT NULL CHECK (length(trim(issue)) > 0),
                suggested_action TEXT NOT NULL,
                summary TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                status TEXT NOT NULL CHECK (status = 'confirmed'),
                source_description TEXT NOT NULL,
                photo_path TEXT,
                confirmed_absent_fields TEXT NOT NULL
              )
            ''');
            await database.execute('''
              CREATE INDEX reports_created_at_id
              ON $_reportsTable(created_at DESC, id DESC)
            ''');
          },
        ),
      );
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Không thể mở kho báo cáo trên thiết bị.',
      );
    }
  }

  Future<Report?> _findById(
    sqflite.DatabaseExecutor database,
    String id,
  ) async {
    final rows = await database.query(
      _reportsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _reportFromRow(rows.single);
  }

  Report _reportFromRow(Map<String, Object?> source) {
    try {
      final row = Map<String, Object?>.from(source);
      final rawAbsentFields = row['confirmed_absent_fields'];
      if (rawAbsentFields is! String) {
        throw const FormatException('Invalid absent-field storage value.');
      }
      row['confirmed_absent_fields'] = jsonDecode(rawAbsentFields);
      final report = Report.fromJson(row);
      if (report.photoPath != null &&
          !_photoPathPattern.hasMatch(report.photoPath!)) {
        throw const FormatException('Invalid stored photo path.');
      }
      return report;
    } on Object {
      throw const ReportStorageException(
        ReportStorageFailure.database,
        'Dữ liệu báo cáo trong kho không hợp lệ.',
      );
    }
  }

  Map<String, Object?> _rowForReport(Report report) {
    final json = report.toJson();
    json['confirmed_absent_fields'] = jsonEncode(
      json['confirmed_absent_fields'],
    );
    return json;
  }

  Report _copyWithPhotoPath(Report report, String photoPath) => Report(
    id: report.id,
    createdAt: report.createdAt,
    category: report.category,
    location: report.location,
    priority: report.priority,
    issue: report.issue,
    suggestedAction: report.suggestedAction,
    summary: report.summary,
    sourceDescription: report.sourceDescription,
    confirmedAbsentFields: report.confirmedAbsentFields,
    photoPath: photoPath,
  );

  bool _sameReportSnapshot(Report existing, Report requested) {
    if (existing.id != requested.id ||
        existing.createdAt.millisecondsSinceEpoch !=
            requested.createdAt.millisecondsSinceEpoch ||
        existing.category != requested.category ||
        existing.location != requested.location ||
        existing.priority != requested.priority ||
        existing.issue != requested.issue ||
        existing.suggestedAction != requested.suggestedAction ||
        existing.summary != requested.summary ||
        existing.sourceDescription != requested.sourceDescription ||
        existing.confirmedAbsentFields.length !=
            requested.confirmedAbsentFields.length) {
      return false;
    }
    return existing.confirmedAbsentFields.containsAll(
      requested.confirmedAbsentFields,
    );
  }

  String _photoPathFor(String id) => 'report_photos/$id.image';

  String _stagingFileName(String id) {
    final suffix = List<int>.generate(8, (_) => Random.secure().nextInt(256));
    return '.$id.${base64Url.encode(suffix).replaceAll('=', '')}.tmp';
  }

  void _validateId(String id) {
    if (!_idPattern.hasMatch(id)) {
      throw const ReportStorageException(
        ReportStorageFailure.invalidReport,
        'Mã báo cáo không hợp lệ.',
      );
    }
  }

  bool _bytesEqual(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  Future<void> _deleteIfCreated(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } on Object {
      // Cleanup is best-effort and must never hide the original storage error.
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operations = _operations.then((_) async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
