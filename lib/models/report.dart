import 'dart:convert';
import 'dart:math';

import 'report_priority.dart';

enum ReportStatus { confirmed }

/// A report whose fields have all been reviewed by the user.
///
/// Empty optional values are only valid when explicitly listed in
/// [confirmedAbsentFields]. [suggestedAction] remains a proposal; this model
/// does not claim that the suggested work has been performed.
class Report {
  Report({
    required String id,
    required DateTime createdAt,
    required String category,
    required String location,
    required this.priority,
    required String issue,
    required String suggestedAction,
    required String summary,
    required this.sourceDescription,
    required Iterable<String> confirmedAbsentFields,
    this.photoPath,
  }) : id = _normalizeId(id),
       createdAt = _normalizeCreatedAt(createdAt),
       category = category.trim(),
       location = location.trim(),
       issue = issue.trim(),
       suggestedAction = suggestedAction.trim(),
       summary = summary.trim(),
       confirmedAbsentFields = _normalizeConfirmedAbsentFields(
         confirmedAbsentFields,
       ) {
    _validate();
  }

  static const fieldNames = <String>[
    'category',
    'location',
    'priority',
    'issue',
    'suggested_action',
    'summary',
  ];

  static const optionalFieldNames = <String>{
    'category',
    'location',
    'priority',
    'suggested_action',
    'summary',
  };

  final String id;
  final DateTime createdAt;
  final ReportStatus status = ReportStatus.confirmed;
  final String category;
  final String location;
  final ReportPriority? priority;
  final String issue;
  final String suggestedAction;
  final String summary;
  final String sourceDescription;
  final String? photoPath;
  final Set<String> confirmedAbsentFields;

  /// Creates an ID matching the Day 4 storage contract: 16 secure random
  /// bytes encoded as unpadded base64url (22 characters).
  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  factory Report.fromJson(Object? source) {
    if (source is! Map) {
      throw const FormatException('Report data must be a JSON object.');
    }

    final json = <String, Object?>{};
    for (final entry in source.entries) {
      if (entry.key is! String) {
        throw const FormatException('Report object keys must be strings.');
      }
      json[entry.key as String] = entry.value;
    }

    const expectedKeys = <String>{
      'id',
      'created_at',
      'status',
      'category',
      'location',
      'priority',
      'issue',
      'suggested_action',
      'summary',
      'source_description',
      'photo_path',
      'confirmed_absent_fields',
    };
    if (json.keys.toSet().difference(expectedKeys).isNotEmpty ||
        expectedKeys.difference(json.keys.toSet()).isNotEmpty) {
      throw const FormatException('Report data has missing or unknown fields.');
    }

    String readText(String field) {
      final value = json[field];
      if (value is! String) {
        throw FormatException('$field must be a string.');
      }
      return value;
    }

    final rawCreatedAt = json['created_at'];
    if (rawCreatedAt is! int) {
      throw const FormatException('created_at must be an integer timestamp.');
    }

    final rawStatus = json['status'];
    if (rawStatus != ReportStatus.confirmed.name) {
      throw const FormatException('status must be confirmed.');
    }

    final rawPriority = json['priority'];
    final parsedPriority = rawPriority == null
        ? null
        : ReportPriority.parse(rawPriority);

    final rawPhotoPath = json['photo_path'];
    if (rawPhotoPath != null && rawPhotoPath is! String) {
      throw const FormatException('photo_path must be a string or null.');
    }

    final rawAbsentFields = json['confirmed_absent_fields'];
    if (rawAbsentFields is! List ||
        rawAbsentFields.any((field) => field is! String)) {
      throw const FormatException(
        'confirmed_absent_fields must be an array of strings.',
      );
    }

    try {
      return Report(
        id: readText('id'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          rawCreatedAt,
          isUtc: true,
        ),
        category: readText('category'),
        location: readText('location'),
        priority: parsedPriority,
        issue: readText('issue'),
        suggestedAction: readText('suggested_action'),
        summary: readText('summary'),
        sourceDescription: readText('source_description'),
        photoPath: rawPhotoPath as String?,
        confirmedAbsentFields: rawAbsentFields.cast<String>(),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid report data: ${error.message}');
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'created_at': createdAt.millisecondsSinceEpoch,
    'status': status.name,
    'category': category,
    'location': location,
    'priority': priority?.name,
    'issue': issue,
    'suggested_action': suggestedAction,
    'summary': summary,
    'source_description': sourceDescription,
    'photo_path': photoPath,
    'confirmed_absent_fields': [
      for (final field in fieldNames)
        if (confirmedAbsentFields.contains(field)) field,
    ],
  };

  void _validate() {
    if (!_isValidId(id)) {
      throw ArgumentError.value(
        id,
        'id',
        'Must be a 22-character base64url ID.',
      );
    }
    if (issue.isEmpty) {
      throw ArgumentError.value(issue, 'issue', 'Issue must not be empty.');
    }
    if (!_isValidPhotoPath(photoPath)) {
      throw ArgumentError.value(
        photoPath,
        'photoPath',
        'Must be a relative path under report_photos/.',
      );
    }

    final expectedAbsent = <String>{
      if (category.isEmpty) 'category',
      if (location.isEmpty) 'location',
      if (priority == null) 'priority',
      if (suggestedAction.isEmpty) 'suggested_action',
      if (summary.isEmpty) 'summary',
    };
    if (confirmedAbsentFields.any(
      (field) => !optionalFieldNames.contains(field),
    )) {
      throw ArgumentError.value(
        confirmedAbsentFields,
        'confirmedAbsentFields',
        'Contains an unknown or non-optional field.',
      );
    }
    if (confirmedAbsentFields.length != expectedAbsent.length ||
        !confirmedAbsentFields.containsAll(expectedAbsent)) {
      throw ArgumentError.value(
        confirmedAbsentFields,
        'confirmedAbsentFields',
        'Must exactly match the empty optional fields.',
      );
    }
  }

  static String _normalizeId(String value) => value;

  static DateTime _normalizeCreatedAt(DateTime value) => value.toUtc();

  static Set<String> _normalizeConfirmedAbsentFields(Iterable<String> fields) {
    final result = <String>{};
    for (final field in fields) {
      if (!result.add(field)) {
        throw ArgumentError.value(
          fields,
          'confirmedAbsentFields',
          'Contains a duplicate field.',
        );
      }
    }
    return Set<String>.unmodifiable(result);
  }

  static bool _isValidId(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(value);

  static bool _isValidPhotoPath(String? value) {
    if (value == null) return true;
    if (!value.startsWith('report_photos/') || value.contains(r'\')) {
      return false;
    }
    final segments = value.split('/');
    return segments.length >= 2 &&
        segments.every(
          (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
        );
  }
}
