import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Inline notice used across screens for neutral info and error feedback.
class StatusNotice extends StatelessWidget {
  const StatusNotice({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isError
        ? AppColors.errorContainer
        : AppColors.paperFrost;
    final foregroundColor = isError
        ? AppColors.onErrorContainer
        : AppColors.appleBlue;

    return Container(
      key: isError ? const Key('input-error-message') : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isError ? AppColors.errorContainer : AppColors.hairlineSilver,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: foregroundColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: foregroundColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
