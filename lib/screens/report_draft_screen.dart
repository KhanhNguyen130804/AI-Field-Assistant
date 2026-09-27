import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/report_draft.dart';
import '../widgets/status_notice.dart';

/// Displays an unconfirmed AI draft for the user to review.
///
/// Nothing here persists or confirms anything: the user can only read the
/// proposal, see which fields need review and go back to edit the input.
/// Editing/saving belongs to a later milestone.
class ReportDraftScreen extends StatelessWidget {
  const ReportDraftScreen({
    super.key,
    required this.draft,
    required this.description,
    required this.imageBytes,
  });

  final ReportDraft draft;
  final String description;
  final List<int>? imageBytes;

  static const _fieldLabels = <String, String>{
    'category': 'Danh mục',
    'location': 'Địa điểm',
    'priority': 'Mức độ ưu tiên',
    'issue': 'Sự cố',
    'suggested_action': 'Hành động đề xuất',
    'summary': 'Tóm tắt',
  };

  static const _priorityLabels = <String, String>{
    'low': 'Thấp',
    'medium': 'Trung bình',
    'high': 'Cao',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bản nháp AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bản nháp AI — cần kiểm tra, chưa lưu',
                  key: const Key('draft-title'),
                  style: textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF17211F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nội dung dưới đây do AI đề xuất từ mô tả và ảnh của bạn. '
                  'Hãy kiểm tra từng trường trước khi tiếp tục.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF52615D),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                const StatusNotice(
                  message:
                      'Bản nháp chưa được lưu và chưa được xác nhận. '
                      'Tính năng chỉnh sửa và lưu sẽ có ở bước tiếp theo.',
                ),
                if (draft.needsConfirmation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _NeedsConfirmationList(
                    fields: draft.needsConfirmation
                        .map((field) => _fieldLabels[field] ?? field)
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 24),
                if (draft.issue.isNotEmpty)
                  _DraftField(
                    label: _fieldLabels['issue']!,
                    value: draft.issue,
                    needsConfirmation: draft.needsConfirmation.contains(
                      'issue',
                    ),
                  ),
                if (draft.category.isNotEmpty)
                  _DraftField(
                    label: _fieldLabels['category']!,
                    value: draft.category,
                    needsConfirmation: draft.needsConfirmation.contains(
                      'category',
                    ),
                  ),
                if (draft.location.isNotEmpty)
                  _DraftField(
                    label: _fieldLabels['location']!,
                    value: draft.location,
                    needsConfirmation: draft.needsConfirmation.contains(
                      'location',
                    ),
                  ),
                if (draft.priority != null)
                  _DraftField(
                    label: _fieldLabels['priority']!,
                    value:
                        _priorityLabels[draft.priority!.name] ??
                        draft.priority!.name,
                    needsConfirmation: draft.needsConfirmation.contains(
                      'priority',
                    ),
                  ),
                if (draft.suggestedAction.isNotEmpty) ...[
                  _DraftField(
                    label: _fieldLabels['suggested_action']!,
                    value: draft.suggestedAction,
                    needsConfirmation: draft.needsConfirmation.contains(
                      'suggested_action',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đây là hành động đề xuất, chưa phải việc đã thực hiện.',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (draft.summary.isNotEmpty)
                  _DraftField(
                    label: _fieldLabels['summary']!,
                    value: draft.summary,
                    needsConfirmation: draft.needsConfirmation.contains(
                      'summary',
                    ),
                  ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Mô tả bạn đã nhập',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    key: const Key('draft-source-description'),
                    style: textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ],
                if (imageBytes != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ảnh bạn đã chọn',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      Uint8List.fromList(imageBytes!),
                      key: const Key('draft-source-image'),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: const Color(0xFFEAF3F0),
                        alignment: Alignment.center,
                        child: const Text('Không hiển thị được ảnh này.'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedsConfirmationList extends StatelessWidget {
  const _NeedsConfirmationList({required this.fields});

  final List<String> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('needs-confirmation-list'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline_rounded, color: Color(0xFF684916)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Các trường AI chưa đủ căn cứ, cần bạn xem lại:',
                  style: TextStyle(
                    color: const Color(0xFF684916),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $field',
                      key: Key('needs-confirmation-$field'),
                      style: const TextStyle(color: Color(0xFF684916)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftField extends StatelessWidget {
  const _DraftField({
    required this.label,
    required this.value,
    required this.needsConfirmation,
  });

  final String label;
  final String value;
  final bool needsConfirmation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (needsConfirmation) const _NeedsConfirmationBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8E6)),
            ),
            child: Text(
              value,
              key: Key('draft-field-$label'),
              style: textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsConfirmationBadge extends StatelessWidget {
  const _NeedsConfirmationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Cần xác nhận',
        style: TextStyle(
          color: Color(0xFF684916),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
