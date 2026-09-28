import 'package:flutter/foundation.dart';

import 'local_report_repository.dart';
import 'report_repository.dart';

ReportRepository createPlatformReportRepository() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return LocalReportRepository();
  }
  return const UnsupportedReportRepository();
}
