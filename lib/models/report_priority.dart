/// Priority values shared by AI drafts and confirmed reports.
enum ReportPriority {
  low,
  medium,
  high;

  static ReportPriority parse(Object? value) {
    if (value is! String) {
      throw FormatException('priority must be a string or null.');
    }

    return switch (value) {
      'low' => ReportPriority.low,
      'medium' => ReportPriority.medium,
      'high' => ReportPriority.high,
      _ => throw FormatException('Unsupported priority: $value.'),
    };
  }
}
