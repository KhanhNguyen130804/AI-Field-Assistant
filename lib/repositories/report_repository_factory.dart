import 'report_repository.dart';
import 'report_repository_factory_stub.dart'
    if (dart.library.io) 'report_repository_factory_io.dart'
    as platform;

/// Creates the repository supported by the current app platform.
///
/// The web implementation is deliberately unsupported; it does not pretend
/// to persist reports in memory.
ReportRepository createReportRepository() =>
    platform.createPlatformReportRepository();
