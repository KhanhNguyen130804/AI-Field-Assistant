import 'package:ai_field_assistant/models/report.dart';
import 'package:ai_field_assistant/models/report_draft.dart';
import 'package:ai_field_assistant/models/report_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportReview.fromDraft', () {
    test('starts every field pending even when AI requested no review', () {
      final review = ReportReview.fromDraft(
        _draft(needsConfirmation: const []),
      );

      expect(review.pendingFields, Report.fieldNames);
      expect(review.aiNeedsReview, isEmpty);
      expect(review.canCreateReport, isFalse);
    });

    test('keeps the original AI review flags separate from user status', () {
      final review = ReportReview.fromDraft(
        _draft(needsConfirmation: const ['location', 'priority']),
      );

      expect(review.aiNeedsReview, ['location', 'priority']);
      expect(review.fieldStatuses['location'], ReportReviewStatus.pending);
      expect(review.fieldStatuses['priority'], ReportReviewStatus.pending);
    });
  });

  group('ReportReview state transitions', () {
    test('confirms values and rejects blank or invalid values', () {
      var review = ReportReview.fromDraft(_draft(category: ''));
      expect(() => review.confirmValue('category'), throwsArgumentError);
      expect(
        () => review.updateField('priority', 'urgent'),
        throwsArgumentError,
      );
      expect(() => review.updateField('issue', null), throwsArgumentError);

      review = review.updateField('category', 'Điện');
      review = review.confirmValue('category');
      review = review.updateField('priority', ReportPriority.medium);
      review = review.confirmValue('priority');

      expect(
        review.fieldStatuses['category'],
        ReportReviewStatus.confirmedValue,
      );
      expect(
        review.fieldStatuses['priority'],
        ReportReviewStatus.confirmedValue,
      );
    });

    test('confirms optional absence only when its value is empty or null', () {
      var review = ReportReview.fromDraft(_draft());

      expect(() => review.confirmAbsent('issue'), throwsArgumentError);
      expect(() => review.confirmAbsent('category'), throwsArgumentError);

      review = review.updateField('category', '');
      review = review.confirmAbsent('category');
      review = review.updateField('priority', null);
      review = review.confirmAbsent('priority');

      expect(
        review.fieldStatuses['category'],
        ReportReviewStatus.confirmedAbsent,
      );
      expect(
        review.fieldStatuses['priority'],
        ReportReviewStatus.confirmedAbsent,
      );
    });

    test('editing a confirmed field resets it and summary review', () {
      var review = _completeReview();
      expect(review.canCreateReport, isTrue);

      review = review.updateField('location', 'Tầng 3');

      expect(review.fieldStatuses['location'], ReportReviewStatus.pending);
      expect(review.fieldStatuses['summary'], ReportReviewStatus.pending);
      expect(review.pendingFields, containsAll(['location', 'summary']));
      expect(review.canCreateReport, isFalse);
    });

    test('changing to the same value keeps its existing confirmation', () {
      final review = _completeReview();

      final unchanged = review.updateField('category', review.category);

      expect(identical(unchanged, review), isTrue);
      expect(
        unchanged.fieldStatuses['category'],
        ReportReviewStatus.confirmedValue,
      );
    });

    test(
      'summary cannot be confirmed before the other fields are reviewed',
      () {
        final review = ReportReview.fromDraft(_draft());

        expect(
          () => review.confirmValue('summary'),
          throwsA(isA<ReportReviewValidationException>()),
        );
        expect(
          () => review.confirmAbsent('summary'),
          throwsA(isA<ReportReviewValidationException>()),
        );
      },
    );

    test(
      'confirming an absent field then entering a value requires review',
      () {
        var review = _completeReview(summaryConfirmed: false);
        review = review.updateField('location', '');
        review = review.confirmAbsent('location');

        review = review.updateField('location', 'Tầng 4');

        expect(review.location, 'Tầng 4');
        expect(review.fieldStatuses['location'], ReportReviewStatus.pending);
        expect(review.fieldStatuses['summary'], ReportReviewStatus.pending);
      },
    );

    test('rejects confirmation of a blank issue', () {
      final review = ReportReview.fromDraft(_draft(issue: '  '));

      expect(() => review.confirmValue('issue'), throwsArgumentError);
      expect(() => review.confirmAbsent('issue'), throwsArgumentError);
      expect(review.validationErrors, contains('issue'));
    });

    test('creates a trimmed Report only after every field is reviewed', () {
      var review = _completeReview(summaryConfirmed: false);
      review = review
          .updateField('category', '  Điện  ')
          .confirmValue('category');
      review = review
          .updateField('summary', '  Ổ cắm bị nóng.  ')
          .confirmValue('summary');
      final report = review.toReport(
        id: _id,
        createdAt: DateTime.utc(2026, 9, 27, 8),
        sourceDescription: 'Ổ cắm trong phòng bị nóng.',
      );

      expect(report.category, 'Điện');
      expect(report.summary, 'Ổ cắm bị nóng.');
      expect(report.confirmedAbsentFields, contains('priority'));
      expect(report.issue, isNotEmpty);
    });

    test('does not allow conversion while a field is pending', () {
      final review = ReportReview.fromDraft(_draft());

      expect(
        () => review.toReport(
          id: _id,
          createdAt: DateTime.utc(2026),
          sourceDescription: '',
        ),
        throwsA(isA<ReportReviewValidationException>()),
      );
    });

    test('summary must be reviewed again after other values change', () {
      var review = _completeReview();
      review = review.updateField('issue', 'Sự cố mới');
      review = review.confirmValue('issue');

      expect(review.fieldStatuses['summary'], ReportReviewStatus.pending);
      expect(
        () => review.toReport(
          id: _id,
          createdAt: DateTime.utc(2026),
          sourceDescription: '',
        ),
        throwsA(isA<ReportReviewValidationException>()),
      );
    });
  });
}

const _id = 'abcdefghijklmnopqrstuv';

ReportDraft _draft({
  String category = 'Thiết bị',
  String location = 'Tầng 2',
  ReportPriority? priority = ReportPriority.high,
  String issue = 'Thiết bị không hoạt động',
  String suggestedAction = 'Kiểm tra nguồn điện',
  String summary = 'Thiết bị tại tầng 2 không hoạt động.',
  Iterable<String> needsConfirmation = const ['priority'],
}) => ReportDraft(
  category: category,
  location: location,
  priority: priority,
  issue: issue,
  suggestedAction: suggestedAction,
  summary: summary,
  needsConfirmation: needsConfirmation,
);

ReportReview _completeReview({
  String category = 'Thiết bị',
  String summary = 'Thiết bị tại tầng 2 không hoạt động.',
  bool summaryConfirmed = true,
}) {
  var review = ReportReview.fromDraft(_draft(category: category));
  for (final field in Report.fieldNames.where((field) => field != 'summary')) {
    if (field == 'priority') {
      review = review.updateField(field, null).confirmAbsent(field);
    } else {
      review = review.confirmValue(field);
    }
  }
  review = review.updateField('summary', summary);
  if (summaryConfirmed) review = review.confirmValue('summary');
  return review;
}
