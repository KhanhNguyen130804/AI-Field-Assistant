import 'package:flutter/material.dart';

/// Inline notice used across screens for neutral info and error feedback.
class StatusNotice extends StatelessWidget {
  const StatusNotice({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isError
        ? const Color(0xFFFFF0ED)
        : const Color(0xFFFFF7E8);
    final foregroundColor = isError
        ? const Color(0xFF8B2D1B)
        : const Color(0xFF684916);

    return Container(
      key: isError ? const Key('input-error-message') : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: foregroundColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foregroundColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
