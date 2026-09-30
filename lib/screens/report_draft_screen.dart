import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/report_draft.dart';
import '../models/report_review.dart';
import '../repositories/report_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_notice.dart';

/// Lets the user review and edit an AI proposal before saving it locally.
///
/// AI confirmation flags remain advisory. Every field must be explicitly
/// reviewed through [ReportReview] before a [Report] can be persisted.
class ReportDraftScreen extends StatefulWidget {
  const ReportDraftScreen({
    super.key,
    required this.draft,
    required this.description,
    required this.imageBytes,
    required this.repository,
  });

  final ReportDraft draft;
  final String description;
  final List<int>? imageBytes;
  final ReportRepository repository;

  static const fieldLabels = <String, String>{
    'category': 'Danh mục',
    'location': 'Địa điểm',
    'priority': 'Mức độ ưu tiên',
    'issue': 'Sự cố',
    'suggested_action': 'Hành động đề xuất',
    'summary': 'Tóm tắt',
  };

  static const priorityLabels = <ReportPriority, String>{
    ReportPriority.low: 'Thấp',
    ReportPriority.medium: 'Trung bình',
    ReportPriority.high: 'Cao',
  };

  @override
  State<ReportDraftScreen> createState() => _ReportDraftScreenState();
}

class _ReportDraftScreenState extends State<ReportDraftScreen> {
  late ReportReview _review;
  late final Map<String, TextEditingController> _controllers;
  bool _showValidation = false;
  bool _isSaving = false;
  bool _isResolvingSave = false;
  String? _saveMessage;
  bool _saveMessageIsError = false;
  _PendingSave? _pendingSave;

  bool get _fieldsLocked =>
      _isSaving || _isResolvingSave || _pendingSave != null;

  bool get _hasUnsavedChanges {
    final draft = widget.draft;
    return _pendingSave != null ||
        _review.category != draft.category ||
        _review.location != draft.location ||
        _review.priority != draft.priority ||
        _review.issue != draft.issue ||
        _review.suggestedAction != draft.suggestedAction ||
        _review.summary != draft.summary ||
        _review.fieldStatuses.values.any(
          (status) => status != ReportReviewStatus.pending,
        );
  }

  int get _reviewedFieldCount => _review.fieldStatuses.values
      .where((status) => status != ReportReviewStatus.pending)
      .length;

  bool get _canReviewSummary =>
      _review.pendingFields.where((field) => field != 'summary').isEmpty;

  @override
  void initState() {
    super.initState();
    _review = ReportReview.fromDraft(widget.draft);
    _controllers = {
      'category': TextEditingController(text: _review.category),
      'location': TextEditingController(text: _review.location),
      'issue': TextEditingController(text: _review.issue),
      'suggested_action': TextEditingController(text: _review.suggestedAction),
      'summary': TextEditingController(text: _review.summary),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateText(String field, String value) {
    setState(() {
      _review = _review.updateField(field, value);
      _showValidation = false;
      _saveMessage = null;
    });
  }

  void _updatePriority(ReportPriority? value) {
    setState(() {
      _review = _review.updateField('priority', value);
      _showValidation = false;
      _saveMessage = null;
    });
  }

  bool _isEmpty(String field) => switch (field) {
    'priority' => _review.priority == null,
    'category' => _review.category.trim().isEmpty,
    'location' => _review.location.trim().isEmpty,
    'issue' => _review.issue.trim().isEmpty,
    'suggested_action' => _review.suggestedAction.trim().isEmpty,
    'summary' => _review.summary.trim().isEmpty,
    _ => true,
  };

  void _confirmField(String field, {required bool absent}) {
    try {
      setState(() {
        _review = absent
            ? _review.confirmAbsent(field)
            : _review.confirmValue(field);
        _showValidation = false;
        _saveMessage = null;
      });
    } on ArgumentError {
      setState(() => _showValidation = true);
    } on ReportReviewValidationException {
      setState(() => _showValidation = true);
    }
  }

  String? _validationMessage(String field) {
    if (!_showValidation || !_review.validationErrors.contains(field)) {
      return null;
    }
    if (field == 'issue' && _review.issue.trim().isEmpty) {
      return 'Nhập nội dung sự cố trước khi xác nhận.';
    }
    if (field == 'summary' && !_canReviewSummary) {
      return 'Xem và xác nhận các trường còn lại trước.';
    }
    return 'Hãy xem lại và xác nhận trường này.';
  }

  Future<void> _saveReport() async {
    if (_isSaving || _isResolvingSave) return;
    if (_pendingSave != null) {
      await _savePendingSnapshot();
      return;
    }
    if (!widget.repository.isSupported) {
      setState(() {
        _saveMessage = 'Lưu báo cáo chưa được hỗ trợ trên nền tảng này.';
        _saveMessageIsError = true;
      });
      return;
    }
    if (!_review.canCreateReport) {
      setState(() => _showValidation = true);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận và lưu báo cáo?'),
        content: const Text(
          'Báo cáo đã được bạn xem lại và sẽ được lưu trên thiết bị này.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-save-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            key: const Key('confirm-save-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận lưu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final report = _review.toReport(
        id: Report.generateId(),
        createdAt: DateTime.now().toUtc(),
        sourceDescription: widget.description,
      );
      final bytes = widget.imageBytes;
      setState(() {
        _pendingSave = _PendingSave(
          report,
          bytes == null ? null : Uint8List.fromList(bytes),
        );
        _saveMessage = null;
        _saveMessageIsError = false;
      });
      await _savePendingSnapshot();
    } on ReportReviewValidationException {
      setState(() => _showValidation = true);
    } on ArgumentError {
      setState(() => _showValidation = true);
    }
  }

  Future<void> _savePendingSnapshot() async {
    final pending = _pendingSave;
    if (pending == null || _isSaving || _isResolvingSave) return;

    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });
    try {
      final saved = await widget.repository.save(
        pending.report,
        imageBytes: pending.imageBytes,
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveMessage = error is ReportStorageException ? error.message : 'Không thể lưu báo cáo trên thiết bị. Nội dung vẫn được giữ; bạn có thể thử lại.';
        _saveMessageIsError = true;
      });
    }
  }

  Future<void> _resolvePendingSave() async {
    final pending = _pendingSave;
    if (pending == null || _isSaving || _isResolvingSave) return;

    setState(() {
      _isResolvingSave = true;
      _saveMessage = null;
    });
    try {
      final existing = await widget.repository.findById(pending.report.id);
      if (!mounted) return;
      if (existing == null) {
        setState(() {
          _pendingSave = null;
          _isResolvingSave = false;
          _saveMessage =
              'Chưa tìm thấy báo cáo đã lưu. Bạn có thể chỉnh sửa rồi thử lại.';
          _saveMessageIsError = false;
        });
      } else if (_matchesPendingReport(existing, pending.report)) {
        setState(() => _isResolvingSave = false);
        Navigator.of(context).pop(existing);
      } else {
        setState(() {
          _isResolvingSave = false;
          _saveMessage = 'Không thể xác nhận kết quả lưu vì mã báo cáo đã gắn với nội dung khác. Hãy giữ nguyên màn hình và thử lại.';
          _saveMessageIsError = true;
        });
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isResolvingSave = false;
        _saveMessage = error is ReportStorageException
            ? error.message
            : 'Không thể kiểm tra kết quả lưu. Hãy thử lại.';
        _saveMessageIsError = true;
      });
    }
  }

  bool _matchesPendingReport(Report existing, Report expected) {
    return existing.id == expected.id &&
        existing.createdAt.millisecondsSinceEpoch ==
            expected.createdAt.millisecondsSinceEpoch &&
        existing.category == expected.category &&
        existing.location == expected.location &&
        existing.priority == expected.priority &&
        existing.issue == expected.issue &&
        existing.suggestedAction == expected.suggestedAction &&
        existing.summary == expected.summary &&
        existing.sourceDescription == expected.sourceDescription &&
        existing.confirmedAbsentFields.length ==
            expected.confirmedAbsentFields.length &&
        existing.confirmedAbsentFields.containsAll(
          expected.confirmedAbsentFields,
        );
  }

  Future<void> _confirmDiscard() async {
    if (_isSaving || _isResolvingSave) return;
    if (_pendingSave != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy thử lưu lại hoặc kiểm tra kết quả lưu trước khi rời màn hình.',
          ),
        ),
      );
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ phần đã xem lại?'),
        content: const Text(
          'Các chỉnh sửa và xác nhận trên bản nháp này sẽ bị bỏ. '
          'Mô tả và ảnh gốc vẫn còn ở màn hình trước.',
        ),
        actions: [
          TextButton(
            key: const Key('stay-in-editor-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục sửa'),
          ),
          FilledButton(
            key: const Key('discard-review-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _handleBack() async {
    if (_isSaving || _isResolvingSave) return;
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    await _confirmDiscard();
  }

  Widget _fieldCard(String field, ThemeData theme) {
    final label = ReportDraftScreen.fieldLabels[field]!;
    final status = _review.fieldStatuses[field] ?? ReportReviewStatus.pending;
    final isEmpty = _isEmpty(field);
    final validationMessage = _validationMessage(field);
    final isSummaryBlocked = field == 'summary' && !_canReviewSummary;

    return Card(
      key: Key('review-card-$field'),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_review.aiNeedsReview.contains(field))
                  const Chip(
                    key: Key('ai-needs-review-chip'),
                    visualDensity: VisualDensity.compact,
                    label: Text('AI đề nghị kiểm tra'),
                  ),
                Chip(
                  key: Key('review-status-$field'),
                  visualDensity: VisualDensity.compact,
                  label: Text(_reviewStatusLabel(status)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (field == 'priority')
              DropdownButtonFormField<ReportPriority?>(
                key: const Key('draft-editor-field-priority'),
                initialValue: _review.priority,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                items: [
                  const DropdownMenuItem<ReportPriority?>(
                    value: null,
                    child: Text('Chưa xác định'),
                  ),
                  for (final entry in ReportDraftScreen.priorityLabels.entries)
                    DropdownMenuItem<ReportPriority?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: _fieldsLocked ? null : _updatePriority,
              )
            else
              TextField(
                key: Key('draft-editor-field-$field'),
                controller: _controllers[field],
                enabled: !_fieldsLocked,
                minLines:
                    field == 'issue' ||
                        field == 'suggested_action' ||
                        field == 'summary'
                    ? 2
                    : 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: label,
                  alignLabelWithHint: true,
                ),
                onChanged: (value) => _updateText(field, value),
              ),
            if (field == 'suggested_action') ...[
              const SizedBox(height: 8),
              Text(
                'Đây là hành động đề xuất, chưa phải việc đã thực hiện.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (field == 'summary' && isSummaryBlocked) ...[
              const SizedBox(height: 8),
              Text(
                'Xem và xác nhận các trường còn lại trước khi xác nhận tóm tắt.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (validationMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                validationMessage,
                key: Key('validation-error-$field'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            _reviewButton(field, status, isEmpty, isSummaryBlocked),
          ],
        ),
      ),
    );
  }

  Widget _reviewButton(
    String field,
    ReportReviewStatus status,
    bool isEmpty,
    bool isSummaryBlocked,
  ) {
    if (status != ReportReviewStatus.pending) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(_reviewStatusLabel(status)),
        ),
      );
    }

    final enabled = !_fieldsLocked && !isSummaryBlocked;
    if (field == 'issue') {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonal(
          key: const Key('confirm-field-issue'),
          onPressed: enabled && !isEmpty
              ? () => _confirmField(field, absent: false)
              : null,
          child: Text(isEmpty ? 'Nhập sự cố để xác nhận' : 'Xác nhận sự cố'),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonal(
        key: Key(isEmpty ? 'confirm-absent-$field' : 'confirm-field-$field'),
        onPressed: enabled ? () => _confirmField(field, absent: isEmpty) : null,
        child: Text(
          isEmpty ? 'Xác nhận chưa có thông tin' : 'Xác nhận trường này',
        ),
      ),
    );
  }

  String _reviewStatusLabel(ReportReviewStatus status) => switch (status) {
    ReportReviewStatus.pending => 'Chờ bạn xác nhận',
    ReportReviewStatus.confirmedValue => 'Đã xác nhận',
    ReportReviewStatus.confirmedAbsent => 'Đã xác nhận chưa có thông tin',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<Report>(
      canPop: !_hasUnsavedChanges && !_isSaving && !_isResolvingSave,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmDiscard());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('draft-back-button'),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          title: const Text('Bản nháp AI'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bản nháp AI — cần kiểm tra, chưa lưu',
                    key: const Key('draft-title'),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI chỉ đề xuất nội dung. Hãy kiểm tra từng trường, '
                    'chỉnh sửa nếu cần rồi xác nhận trước khi lưu.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const StatusNotice(
                    message: 'Bản nháp chưa được lưu. Mỗi trường cần được bạn xem lại và xác nhận.',
                  ),
                  if (widget.draft.needsConfirmation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _NeedsConfirmationList(
                      fields: widget.draft.needsConfirmation
                          .map(
                            (field) =>
                                ReportDraftScreen.fieldLabels[field] ?? field,
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiến độ xác nhận',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đã xác nhận $_reviewedFieldCount/${Report.fieldNames.length} trường',
                            key: const Key('review-progress'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value:
                                  _reviewedFieldCount /
                                  Report.fieldNames.length,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final field in Report.fieldNames) ...[
                    _fieldCard(field, theme),
                    const SizedBox(height: 12),
                  ],
                  if (widget.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mô tả bạn đã nhập',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      key: const Key('draft-source-description'),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                  if (widget.imageBytes != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Ảnh bạn đã chọn',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.memory(
                        Uint8List.fromList(widget.imageBytes!),
                        key: const Key('draft-source-image'),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: AppColors.paperFrost,
                          alignment: Alignment.center,
                          child: const Text('Không hiển thị được ảnh này.'),
                        ),
                      ),
                    ),
                  ],
                  if (_saveMessage case final message?) ...[
                    const SizedBox(height: 16),
                    StatusNotice(
                      message: message,
                      isError: _saveMessageIsError,
                    ),
                  ],
                  if (_pendingSave != null && !_isSaving) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('resolve-save-button'),
                      onPressed: _isResolvingSave ? null : _resolvePendingSave,
                      icon: const Icon(Icons.manage_search),
                      label: const Text('Kiểm tra kết quả lưu'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('save-report-button'),
                    onPressed: _isSaving || _isResolvingSave
                        ? null
                        : _saveReport,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving
                          ? 'Đang lưu…'
                          : _pendingSave != null
                          ? 'Thử lưu lại'
                          : 'Xác nhận và lưu báo cáo',
                    ),
                  ),
                  if (_isSaving || _isResolvingSave) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(key: Key('save-progress')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingSave {
  const _PendingSave(this.report, this.imageBytes);

  final Report report;
  final Uint8List? imageBytes;
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
                  style: const TextStyle(
                    color: Color(0xFF684916),
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
                    child: Text('• $field'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
