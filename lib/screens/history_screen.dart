import 'dart:async';

import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/report_priority.dart';
import '../repositories/report_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_notice.dart';

/// Displays reports returned by the shared local repository.
///
/// [refreshToken] changes when the history tab is opened or a report is saved.
/// The screen deliberately does not read repository data from [build].
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.repository,
    required this.isActive,
    required this.refreshToken,
    required this.onReportSelected,
  });

  final ReportRepository repository;
  final bool isActive;
  final int refreshToken;
  final ValueChanged<String> onReportSelected;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Report> _reports = const [];
  bool _isLoading = true;
  bool _hasSuccessfulLoad = false;
  String? _errorMessage;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive && widget.repository.isSupported) {
      unawaited(_loadReports());
    }
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReload =
        widget.refreshToken != oldWidget.refreshToken ||
        (widget.isActive && !oldWidget.isActive) ||
        (widget.isActive && widget.repository != oldWidget.repository);
    if (shouldReload && widget.repository.isSupported) {
      unawaited(_loadReports());
    }
  }

  Future<void> _loadReports() async {
    final generation = ++_loadGeneration;
    if (_hasSuccessfulLoad || !_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final reports = await widget.repository.listReports();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _reports = reports;
        _hasSuccessfulLoad = true;
        _isLoading = false;
        _errorMessage = null;
      });
    } on Object catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is ReportStorageException
            ? error.message
            : 'Không thể đọc lịch sử báo cáo trên thiết bị. Hãy thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.repository.isSupported) {
      return const _HistoryUnavailable();
    }
    if (!_hasSuccessfulLoad && _isLoading && !widget.isActive) {
      return const SizedBox.shrink();
    }
    if (!_hasSuccessfulLoad && _isLoading) {
      return const Center(
        key: Key('history-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (_errorMessage != null && _reports.isEmpty) {
      return _HistoryLoadError(message: _errorMessage!, onRetry: _loadReports);
    }
    if (_reports.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (_isLoading && widget.isActive)
          const LinearProgressIndicator(key: Key('history-refresh-progress')),
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
                    key: const Key('history-retry-button'),
                    onPressed: _loadReports,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Báo cáo đã lưu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${_reports.length} báo cáo đã được xác nhận',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadReports,
            child: ListView.separated(
              key: const Key('history-report-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: _reports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = _reports[index];
                return _ReportListTile(
                  key: ValueKey('history-item-${report.id}'),
                  report: report,
                  onTap: () => widget.onReportSelected(report.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        if (_isLoading && widget.isActive)
          const LinearProgressIndicator(key: Key('history-refresh-progress')),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadReports,
            child: ListView(
              key: const Key('history-empty-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 48,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: AppColors.paperFrost,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: AppColors.appleBlue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Chưa có báo cáo đã lưu',
                        key: const Key('history-empty-state'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Báo cáo bạn xác nhận và lưu trên thiết bị sẽ xuất hiện tại đây.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryUnavailable extends StatelessWidget {
  const _HistoryUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const StatusNotice(
            message: 'Lưu và xem lịch sử báo cáo chưa được hỗ trợ trên nền tảng này.',
          ),
        ),
      ),
    );
  }
}

class _HistoryLoadError extends StatelessWidget {
  const _HistoryLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
                  key: const Key('history-retry-button'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({super.key, required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('history-list-tile-${report.id}'),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          report.issue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report.location.isNotEmpty) ...[
                Text(
                  report.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_priorityLabel(report.priority)),
                  ),
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.verified_outlined, size: 18),
                    label: Text('Đã xác nhận'),
                  ),
                  Text(
                    _formatLocalDateTime(report.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _priorityLabel(ReportPriority? priority) => switch (priority) {
    ReportPriority.low => 'Ưu tiên thấp',
    ReportPriority.medium => 'Ưu tiên trung bình',
    ReportPriority.high => 'Ưu tiên cao',
    null => 'Chưa xác định',
  };

  String _formatLocalDateTime(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
