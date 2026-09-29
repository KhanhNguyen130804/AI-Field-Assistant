import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/report_priority.dart';
import '../repositories/report_repository.dart';
import '../widgets/status_notice.dart';

/// Reads and displays a previously saved, user-confirmed report.
class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.repository,
    required this.reportId,
  });

  final ReportRepository repository;
  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Report? _report;
  Uint8List? _photoBytes;
  bool _isLoading = true;
  bool _isPhotoLoading = false;
  String? _errorMessage;
  String? _photoErrorMessage;
  int _loadGeneration = 0;
  int _photoGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReport());
  }

  @override
  void didUpdateWidget(covariant ReportDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reportId != oldWidget.reportId ||
        widget.repository != oldWidget.repository) {
      _report = null;
      _photoBytes = null;
      _photoErrorMessage = null;
      _isPhotoLoading = false;
      unawaited(_loadReport());
    }
  }

  Future<void> _loadReport() async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!widget.repository.isSupported) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chi tiết báo cáo chưa được hỗ trợ trên nền tảng này.';
      });
      return;
    }

    try {
      final report = await widget.repository.findById(widget.reportId);
      if (!mounted || generation != _loadGeneration) return;

      // A successful report read replaces the current report and its photo.
      // An errored retry leaves the existing content and an in-flight photo
      // read untouched.
      _photoGeneration++;
      setState(() {
        _report = report;
        _photoBytes = null;
        _photoErrorMessage = null;
        _isPhotoLoading = report?.photoPath != null;
        _isLoading = false;
        _errorMessage = null;
      });

      if (report != null) {
        final photoPath = report.photoPath;
        if (photoPath != null) {
          unawaited(_loadPhoto(report, photoPath));
        }
      }
    } on Object catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is ReportStorageException
            ? error.message
            : 'Không thể đọc báo cáo trên thiết bị. Hãy thử lại.';
      });
    }
  }

  Future<void> _loadPhoto(Report report, String photoPath) async {
    final photoGeneration = ++_photoGeneration;
    setState(() {
      _isPhotoLoading = true;
      _photoErrorMessage = null;
      _photoBytes = null;
    });

    try {
      final bytes = await widget.repository.readPhotoBytes(photoPath);
      if (!_isCurrentPhotoRequest(report, photoGeneration)) return;
      if (bytes.isEmpty) {
        throw const ReportStorageException(
          ReportStorageFailure.photo,
          'Ảnh đã lưu không có dữ liệu. Nội dung báo cáo vẫn được giữ.',
        );
      }
      setState(() {
        _photoBytes = bytes;
        _isPhotoLoading = false;
        _photoErrorMessage = null;
      });
    } on Object catch (error) {
      if (!_isCurrentPhotoRequest(report, photoGeneration)) return;
      setState(() {
        _isPhotoLoading = false;
        _photoErrorMessage = error is ReportStorageException
            ? error.message
            : 'Không thể tải ảnh đã lưu. Nội dung báo cáo vẫn được giữ.';
      });
    }
  }

  bool _isCurrentPhotoRequest(Report report, int photoGeneration) =>
      mounted &&
      photoGeneration == _photoGeneration &&
      _report?.id == report.id &&
      _report?.photoPath == report.photoPath;

  void _retryPhoto() {
    final report = _report;
    final photoPath = report?.photoPath;
    if (report == null || photoPath == null) return;
    unawaited(_loadPhoto(report, photoPath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết báo cáo')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final report = _report;
    if (report == null) {
      if (_isLoading) {
        return const Center(
          key: Key('report-detail-loading'),
          child: CircularProgressIndicator(),
        );
      }
      if (_errorMessage != null) {
        return _buildLoadError(_errorMessage!);
      }
      return _buildNotFound();
    }

    return Column(
      children: [
        if (_isLoading)
          const LinearProgressIndicator(
            key: Key('report-detail-refresh-progress'),
          ),
        if (_errorMessage case final message?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusNotice(message: message, isError: true),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('report-detail-retry-button'),
                    onPressed: _loadReport,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            key: const Key('report-detail-content'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _buildReportHeader(report),
              const SizedBox(height: 14),
              _buildDetailField(
                report,
                field: 'category',
                label: 'Danh mục',
                value: report.category,
              ),
              _buildDetailField(
                report,
                field: 'location',
                label: 'Địa điểm',
                value: report.location,
              ),
              _buildDetailField(
                report,
                field: 'priority',
                label: 'Mức độ ưu tiên',
                value: _priorityLabel(report.priority),
              ),
              _buildDetailField(
                report,
                field: 'issue',
                label: 'Sự cố',
                value: report.issue,
              ),
              _buildDetailField(
                report,
                field: 'suggested_action',
                label: 'Hành động đề xuất',
                value: report.suggestedAction,
                helperText:
                    'Đây là hành động đề xuất, chưa phải việc đã thực hiện.',
              ),
              _buildDetailField(
                report,
                field: 'summary',
                label: 'Tóm tắt',
                value: report.summary,
              ),
              const SizedBox(height: 6),
              _buildSourceDescription(report),
              const SizedBox(height: 10),
              _buildPhotoSection(report),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportHeader(Report report) {
    return Card(
      key: const Key('report-detail-header'),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Chip(
                  key: Key('report-detail-confirmed-status'),
                  avatar: Icon(Icons.verified_outlined, size: 18),
                  label: Text('Đã xác nhận'),
                ),
                Text(
                  _formatLocalDateTime(report.createdAt),
                  key: const Key('report-detail-created-at'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(
    Report report, {
    required String field,
    required String label,
    required String value,
    String? helperText,
  }) {
    final isConfirmedAbsent = report.confirmedAbsentFields.contains(field);
    final displayValue = isConfirmedAbsent
        ? field == 'priority'
              ? 'Đã xác nhận chưa xác định'
              : 'Đã xác nhận không có thông tin'
        : value.isEmpty
        ? 'Không có dữ liệu'
        : value;

    return Card(
      key: Key('report-detail-field-$field'),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(displayValue, key: Key('report-detail-value-$field')),
            if (helperText != null) ...[
              const SizedBox(height: 8),
              Text(
                helperText,
                key: const Key('report-detail-suggested-action-note'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceDescription(Report report) => Card(
    key: const Key('report-detail-source-description'),
    color: Colors.white,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả gốc',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            report.sourceDescription.isEmpty
                ? 'Không có mô tả gốc.'
                : report.sourceDescription,
            key: const Key('report-detail-source-description-value'),
          ),
        ],
      ),
    ),
  );

  Widget _buildPhotoSection(Report report) {
    final photoPath = report.photoPath;
    return Card(
      key: const Key('report-detail-photo-section'),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ảnh báo cáo',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (photoPath == null)
              const StatusNotice(
                key: Key('report-detail-no-photo'),
                message: 'Không có ảnh được lưu cùng báo cáo.',
              )
            else if (_isPhotoLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Đang tải ảnh…'),
                    ],
                  ),
                ),
              )
            else if (_photoErrorMessage case final message?)
              _buildPhotoError(message)
            else if (_photoBytes case final bytes?)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  key: const Key('report-detail-photo'),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPhotoError(
                        'Ảnh đã lưu không thể hiển thị. Nội dung báo cáo vẫn được giữ.',
                        key: const Key('report-detail-photo-decode-error'),
                      ),
                ),
              )
            else
              _buildPhotoError(
                'Không thể tải ảnh đã lưu. Nội dung báo cáo vẫn được giữ.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoError(String message, {Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StatusNotice(message: message, isError: true),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('report-photo-retry-button'),
          onPressed: _isPhotoLoading ? null : _retryPhoto,
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại ảnh'),
        ),
      ),
    ],
  );

  Widget _buildLoadError(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusNotice(message: message, isError: true),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: const Key('report-detail-retry-button'),
                onPressed: _loadReport,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildNotFound() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: const StatusNotice(
          key: Key('report-detail-not-found'),
          message: 'Không tìm thấy báo cáo này trong lịch sử đã lưu.',
        ),
      ),
    ),
  );

  String _priorityLabel(ReportPriority? priority) => switch (priority) {
    ReportPriority.low => 'Thấp',
    ReportPriority.medium => 'Trung bình',
    ReportPriority.high => 'Cao',
    null => 'Chưa xác định',
  };

  String _formatLocalDateTime(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
