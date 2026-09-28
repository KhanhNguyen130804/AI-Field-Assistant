import 'dart:typed_data';

import '../models/report.dart';

enum ReportStorageFailure {
  unsupportedPlatform,
  invalidReport,
  database,
  photo,
  conflict,
}

/// A storage failure safe to surface in the UI.
///
/// Raw plugin errors and local file paths are deliberately not included in
/// [message].
class ReportStorageException implements Exception {
  const ReportStorageException(this.failure, this.message);

  final ReportStorageFailure failure;
  final String message;

  @override
  String toString() => message;
}

/// Persists only reports the user has reviewed and confirmed.
abstract interface class ReportRepository {
  /// Whether this implementation can persist reports on the current target.
  bool get isSupported;

  Future<Report> save(Report report, {Uint8List? imageBytes});

  Future<List<Report>> listReports();

  Future<Report?> findById(String id);

  /// Reads a stored image by its app-generated relative path.
  Future<Uint8List> readPhotoBytes(String relativePath);

  Future<void> close();
}

/// Repository implementation used where local SQLite storage is unavailable.
class UnsupportedReportRepository implements ReportRepository {
  const UnsupportedReportRepository();

  @override
  bool get isSupported => false;

  ReportStorageException get _error => const ReportStorageException(
    ReportStorageFailure.unsupportedPlatform,
    'Lưu báo cáo cục bộ chưa được hỗ trợ trên nền tảng này.',
  );

  @override
  Future<Report> save(Report report, {Uint8List? imageBytes}) async =>
      throw _error;

  @override
  Future<List<Report>> listReports() async => throw _error;

  @override
  Future<Report?> findById(String id) async => throw _error;

  @override
  Future<Uint8List> readPhotoBytes(String relativePath) async => throw _error;

  @override
  Future<void> close() async {}
}
