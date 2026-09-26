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

/// An unconfirmed AI proposal. Empty or uncertain values are kept explicit
/// and listed in [needsConfirmation] for the user to review.
class ReportDraft {
  ReportDraft({
    required String category,
    required String location,
    required this.priority,
    required String issue,
    required String suggestedAction,
    required String summary,
    Iterable<String> needsConfirmation = const [],
  }) {
    final confirmations = <String>[];

    void addConfirmation(String field) {
      if (!confirmableFields.contains(field)) {
        throw ArgumentError.value(
          field,
          'needsConfirmation',
          'Unknown report field.',
        );
      }
      if (!confirmations.contains(field)) confirmations.add(field);
    }

    for (final field in needsConfirmation) {
      addConfirmation(field);
    }

    this.category = category.trim();
    this.location = location.trim();
    this.issue = issue.trim();
    this.suggestedAction = suggestedAction.trim();
    this.summary = summary.trim();

    if (this.category.isEmpty) addConfirmation('category');
    if (this.location.isEmpty) addConfirmation('location');
    if (priority == null) addConfirmation('priority');
    if (this.issue.isEmpty) addConfirmation('issue');
    if (this.suggestedAction.isEmpty) addConfirmation('suggested_action');
    if (this.summary.isEmpty) addConfirmation('summary');

    this.needsConfirmation = List<String>.unmodifiable(confirmations);
  }

  static const confirmableFields = <String>[
    'category',
    'location',
    'priority',
    'issue',
    'suggested_action',
    'summary',
  ];

  late final String category;
  late final String location;
  final ReportPriority? priority;
  late final String issue;
  late final String suggestedAction;
  late final String summary;
  late final List<String> needsConfirmation;

  factory ReportDraft.fromJson(Object? source) {
    if (source is! Map) {
      throw FormatException('Report draft response must be a JSON object.');
    }

    final json = <String, Object?>{};
    for (final entry in source.entries) {
      if (entry.key is! String) {
        throw FormatException('Report draft object keys must be strings.');
      }
      json[entry.key as String] = entry.value;
    }

    String readText(String field) {
      if (!json.containsKey(field)) return '';

      final value = json[field];
      if (value is! String) {
        throw FormatException('$field must be a string.');
      }
      return value;
    }

    final confirmations = <String>[];
    if (!json.containsKey('needs_confirmation')) {
      // A response without the confirmation list is ambiguous: ask the user
      // to review every field instead of treating it as verified.
      confirmations.addAll(confirmableFields);
    } else {
      final rawConfirmations = json['needs_confirmation'];
      if (rawConfirmations is! List) {
        throw FormatException('needs_confirmation must be an array.');
      }

      for (final value in rawConfirmations) {
        if (value is! String || !confirmableFields.contains(value)) {
          throw FormatException(
            'needs_confirmation contains an unsupported field.',
          );
        }
        if (!confirmations.contains(value)) confirmations.add(value);
      }
    }

    final rawPriority = json['priority'];
    final priority = !json.containsKey('priority') || rawPriority == null
        ? null
        : ReportPriority.parse(rawPriority);

    return ReportDraft(
      category: readText('category'),
      location: readText('location'),
      priority: priority,
      issue: readText('issue'),
      suggestedAction: readText('suggested_action'),
      summary: readText('summary'),
      needsConfirmation: confirmations,
    );
  }

  Map<String, Object?> toJson() => {
    'category': category,
    'location': location,
    'priority': priority?.name,
    'issue': issue,
    'suggested_action': suggestedAction,
    'summary': summary,
    'needs_confirmation': needsConfirmation,
  };
}
