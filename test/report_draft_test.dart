import 'package:ai_field_assistant/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportDraft.fromJson', () {
    test('parses valid fields and serializes the same schema', () {
      final draft = ReportDraft.fromJson(_validJson());

      expect(draft.category, 'Equipment failure');
      expect(draft.location, 'Reception');
      expect(draft.priority, ReportPriority.high);
      expect(draft.issue, 'The air conditioner is not working.');
      expect(draft.suggestedAction, 'Inspect the unit.');
      expect(draft.summary, 'The reception air conditioner is not working.');
      expect(draft.needsConfirmation, isEmpty);
      expect(draft.toJson(), _validJson());
    });

    test(
      'keeps missing and empty fields explicit and requiring confirmation',
      () {
        final draft = ReportDraft.fromJson({
          'category': 'Water leak',
          'issue': '',
          'priority': null,
          'needs_confirmation': ['location'],
        });

        expect(draft.category, 'Water leak');
        expect(draft.location, '');
        expect(draft.suggestedAction, '');
        expect(draft.summary, '');
        expect(
          draft.needsConfirmation,
          containsAll([
            'location',
            'priority',
            'issue',
            'suggested_action',
            'summary',
          ]),
        );
        expect(
          draft.needsConfirmation.toSet().length,
          draft.needsConfirmation.length,
        );
      },
    );

    test('requires review of all fields if needs_confirmation is missing', () {
      final draft = ReportDraft.fromJson({
        'category': 'Equipment failure',
        'location': 'Reception',
        'priority': 'high',
        'issue': 'The unit is not working.',
        'suggested_action': 'Inspect the unit.',
        'summary': 'The unit is not working.',
      });

      expect(draft.needsConfirmation, ReportDraft.confirmableFields);
    });

    test('rejects a non-object JSON response', () {
      expect(
        () => ReportDraft.fromJson(['not', 'an', 'object']),
        throwsFormatException,
      );
    });

    test('rejects incorrect field types and unsupported priorities', () {
      final wrongTextType = _validJson()..['location'] = 42;
      final wrongPriority = _validJson()..['priority'] = 'urgent';
      final wrongConfirmationType = _validJson()
        ..['needs_confirmation'] = 'issue';
      final unknownConfirmationField = _validJson()
        ..['needs_confirmation'] = ['cause'];

      expect(() => ReportDraft.fromJson(wrongTextType), throwsFormatException);
      expect(() => ReportDraft.fromJson(wrongPriority), throwsFormatException);
      expect(
        () => ReportDraft.fromJson(wrongConfirmationType),
        throwsFormatException,
      );
      expect(
        () => ReportDraft.fromJson(unknownConfirmationField),
        throwsFormatException,
      );
    });
  });
}

Map<String, Object?> _validJson() => {
  'category': 'Equipment failure',
  'location': 'Reception',
  'priority': 'high',
  'issue': 'The air conditioner is not working.',
  'suggested_action': 'Inspect the unit.',
  'summary': 'The reception air conditioner is not working.',
  'needs_confirmation': <String>[],
};
