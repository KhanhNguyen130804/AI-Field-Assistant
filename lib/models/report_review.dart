import 'report.dart';
import 'report_draft.dart';

enum ReportReviewStatus { pending, confirmedValue, confirmedAbsent }

/// User-edited values and per-field review state for an AI draft.
///
/// This is editor state only. It is never serialized as a saved [Report].
class ReportReview {
  ReportReview._({
    required this.category,
    required this.location,
    required this.priority,
    required this.issue,
    required this.suggestedAction,
    required this.summary,
    required List<String> aiNeedsReview,
    required Map<String, ReportReviewStatus> fieldStatuses,
  }) : aiNeedsReview = List<String>.unmodifiable(aiNeedsReview),
       fieldStatuses = Map<String, ReportReviewStatus>.unmodifiable(
         fieldStatuses,
       );

  factory ReportReview.fromDraft(ReportDraft draft) => ReportReview._(
    category: draft.category,
    location: draft.location,
    priority: draft.priority,
    issue: draft.issue,
    suggestedAction: draft.suggestedAction,
    summary: draft.summary,
    aiNeedsReview: draft.needsConfirmation,
    fieldStatuses: {
      for (final field in Report.fieldNames) field: ReportReviewStatus.pending,
    },
  );

  final String category;
  final String location;
  final ReportPriority? priority;
  final String issue;
  final String suggestedAction;
  final String summary;
  final List<String> aiNeedsReview;
  final Map<String, ReportReviewStatus> fieldStatuses;

  List<String> get pendingFields => [
    for (final field in Report.fieldNames)
      if (fieldStatuses[field] == ReportReviewStatus.pending) field,
  ];

  List<String> get validationErrors {
    final errors = <String>[];
    for (final field in Report.fieldNames) {
      final status = fieldStatuses[field];
      final value = _valueFor(field);

      if (status == null || status == ReportReviewStatus.pending) {
        errors.add(field);
        continue;
      }
      if (status == ReportReviewStatus.confirmedAbsent) {
        if (!Report.optionalFieldNames.contains(field) || !_isAbsent(value)) {
          errors.add(field);
        }
      } else if (_isAbsent(value)) {
        errors.add(field);
      }
    }

    if (issue.trim().isEmpty && !errors.contains('issue')) {
      errors.add('issue');
    }
    if (fieldStatuses['summary'] != ReportReviewStatus.pending &&
        Report.fieldNames
            .where((field) => field != 'summary')
            .any(
              (field) => fieldStatuses[field] == ReportReviewStatus.pending,
            )) {
      errors.add('summary');
    }
    return List<String>.unmodifiable(errors.toSet());
  }

  bool get canCreateReport => validationErrors.isEmpty;

  ReportReview updateField(String field, Object? value) {
    _requireKnownField(field);
    _validateValueType(field, value);
    if (_valueFor(field) == value) return this;

    final statuses = Map<String, ReportReviewStatus>.of(fieldStatuses)
      ..[field] = ReportReviewStatus.pending;
    if (field != 'summary') {
      statuses['summary'] = ReportReviewStatus.pending;
    }

    return _copyWithValue(field, value, statuses);
  }

  ReportReview confirmValue(String field) {
    _requireKnownField(field);
    _requireOtherFieldsReviewedForSummary(field);
    if (_isAbsent(_valueFor(field))) {
      throw ArgumentError.value(
        field,
        'field',
        'A confirmed value must not be empty or null.',
      );
    }

    return _copyWithStatus(field, ReportReviewStatus.confirmedValue);
  }

  ReportReview confirmAbsent(String field) {
    _requireKnownField(field);
    _requireOtherFieldsReviewedForSummary(field);
    if (!Report.optionalFieldNames.contains(field)) {
      throw ArgumentError.value(
        field,
        'field',
        'This field cannot be confirmed absent.',
      );
    }
    if (!_isAbsent(_valueFor(field))) {
      throw ArgumentError.value(
        field,
        'field',
        'Clear the value before confirming it absent.',
      );
    }

    return _copyWithStatus(field, ReportReviewStatus.confirmedAbsent);
  }

  Report toReport({
    required String id,
    required DateTime createdAt,
    required String sourceDescription,
    String? photoPath,
  }) {
    final errors = validationErrors;
    if (errors.isNotEmpty) throw ReportReviewValidationException(errors);

    return Report(
      id: id,
      createdAt: createdAt,
      category: category,
      location: location,
      priority: priority,
      issue: issue,
      suggestedAction: suggestedAction,
      summary: summary,
      sourceDescription: sourceDescription,
      photoPath: photoPath,
      confirmedAbsentFields: [
        for (final field in Report.optionalFieldNames)
          if (fieldStatuses[field] == ReportReviewStatus.confirmedAbsent) field,
      ],
    );
  }

  Object? _valueFor(String field) => switch (field) {
    'category' => category,
    'location' => location,
    'priority' => priority,
    'issue' => issue,
    'suggested_action' => suggestedAction,
    'summary' => summary,
    _ => throw ArgumentError.value(field, 'field', 'Unknown report field.'),
  };

  ReportReview _copyWithStatus(String field, ReportReviewStatus status) {
    final statuses = Map<String, ReportReviewStatus>.of(fieldStatuses)
      ..[field] = status;
    return ReportReview._(
      category: category,
      location: location,
      priority: priority,
      issue: issue,
      suggestedAction: suggestedAction,
      summary: summary,
      aiNeedsReview: aiNeedsReview,
      fieldStatuses: statuses,
    );
  }

  ReportReview _copyWithValue(
    String field,
    Object? value,
    Map<String, ReportReviewStatus> statuses,
  ) => ReportReview._(
    category: field == 'category' ? value! as String : category,
    location: field == 'location' ? value! as String : location,
    priority: field == 'priority' ? value as ReportPriority? : priority,
    issue: field == 'issue' ? value! as String : issue,
    suggestedAction: field == 'suggested_action'
        ? value! as String
        : suggestedAction,
    summary: field == 'summary' ? value! as String : summary,
    aiNeedsReview: aiNeedsReview,
    fieldStatuses: statuses,
  );

  void _requireKnownField(String field) {
    if (!Report.fieldNames.contains(field)) {
      throw ArgumentError.value(field, 'field', 'Unknown report field.');
    }
  }

  void _requireOtherFieldsReviewedForSummary(String field) {
    if (field == 'summary' &&
        Report.fieldNames
            .where((candidate) => candidate != 'summary')
            .any(
              (candidate) =>
                  fieldStatuses[candidate] == ReportReviewStatus.pending,
            )) {
      throw ReportReviewValidationException(
        Report.fieldNames
            .where(
              (candidate) =>
                  candidate != 'summary' &&
                  fieldStatuses[candidate] == ReportReviewStatus.pending,
            )
            .toList(),
      );
    }
  }

  void _validateValueType(String field, Object? value) {
    if (field == 'priority') {
      if (value != null && value is! ReportPriority) {
        throw ArgumentError.value(value, 'value', 'Invalid priority value.');
      }
    } else if (value is! String) {
      throw ArgumentError.value(value, 'value', 'Field value must be text.');
    }
  }

  bool _isAbsent(Object? value) =>
      value == null || value is String && value.trim().isEmpty;
}

class ReportReviewValidationException implements Exception {
  ReportReviewValidationException(Iterable<String> fields)
    : fields = List<String>.unmodifiable(fields);

  final List<String> fields;

  @override
  String toString() => 'Report review is incomplete: ${fields.join(', ')}';
}
