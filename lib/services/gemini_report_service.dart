import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_draft.dart';
import 'report_draft_prompt.dart';

/// Primary model: strongest free-tier quality for vision + structured JSON.
/// Its free-tier cap is low (20 requests/day per project on 27/09/2026).
const _primaryModelName = 'gemini-3.8-flash';

/// Fallback model: lower quality but a much larger free-tier daily bucket
/// (500 requests/day). Used only when the primary model is quota-exhausted
/// so the app keeps working instead of blocking the user.
const _fallbackModelName = 'gemini-3.5-flash-lite';

const _defaultRequestTimeout = Duration(seconds: 60);

const _supportedInlineImageMimeTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

/// Maximum original image bytes accepted for an AI request: 4 MiB leaves
/// room for the base64 overhead under the Firebase AI Logic 7 MB inline limit.
const maxImageBytesForAi = 4 * 1024 * 1024;

const _defaultMaxImageBytes = maxImageBytesForAi;

final _reportDraftResponseSchema = Schema.object(
  properties: {
    'category': Schema.string(
      description: 'Danh mục sự cố; chuỗi rỗng nếu không đủ căn cứ phân loại.',
    ),
    'location': Schema.string(
      description: 'Địa điểm nêu rõ trong mô tả; chuỗi rỗng nếu không được nêu, không suy đoán.',
    ),
    'priority': Schema.enumString(
      enumValues: ['low', 'medium', 'high'],
      nullable: true,
      description: 'Mức độ ưu tiên; null nếu mô tả/ảnh không đủ căn cứ, không tự mặc định.',
    ),
    'issue': Schema.string(
      description: 'Mô tả ngắn sự cố; chuỗi rỗng nếu chưa rõ.',
    ),
    'suggested_action': Schema.string(
      description: 'Hành động đề xuất, không mô tả việc đã thực hiện; chuỗi rỗng nếu không đề xuất được an toàn.',
    ),
    'summary': Schema.string(
      description: 'Chỉ tóm tắt dữ kiện người dùng nêu rõ trong mô tả; chuỗi rỗng nếu không có.',
    ),
    'needs_confirmation': Schema.array(
      items: Schema.enumString(enumValues: ReportDraft.confirmableFields),
      description: 'Tên các trường còn thiếu, rỗng hoặc không chắc chắn cần người dùng xem lại.',
    ),
  },
);

/// A thin seam over the Firebase AI Logic SDK so unit tests can inject a fake
/// without initializing Firebase or reaching the network.
abstract interface class ReportDraftRequestSender {
  /// Sends one request and returns the text of the model response.
  Future<String?> send(Content prompt);
}

/// Errors from creating a report draft, carrying a user-facing message.
///
/// Messages stay structural on purpose: they never include the prompt, image
/// bytes or raw model response.
sealed class ReportDraftException implements Exception {
  const ReportDraftException(this.userMessage);

  final String userMessage;
}

class InvalidReportDraftInputException extends ReportDraftException {
  const InvalidReportDraftInputException(super.userMessage);
}

class ReportDraftTimeoutException extends ReportDraftException {
  const ReportDraftTimeoutException()
    : super('Phân tích mất quá nhiều thời gian. Bạn thử lại giúp mình nhé.');
}

class ReportDraftQuotaException extends ReportDraftException {
  const ReportDraftQuotaException()
    : super(
        'Đã đạt giới hạn số lần phân tích trong lúc này. '
        'Bạn thử lại sau ít phút.',
      );
}

class ReportDraftConfigException extends ReportDraftException {
  const ReportDraftConfigException()
    : super(
        'Dịch vụ AI chưa được cấu hình đúng cho ứng dụng. '
        'Bạn báo lại cho người quản trị ứng dụng.',
      );
}

class ReportDraftAppCheckException extends ReportDraftException {
  const ReportDraftAppCheckException()
    : super(
        'Ứng dụng chưa được xác minh với dịch vụ AI (App Check). '
        'Bạn báo lại cho người quản trị ứng dụng.',
      );
}

class ReportDraftServiceException extends ReportDraftException {
  const ReportDraftServiceException()
    : super('Không thể phân tích lúc này. Kiểm tra kết nối mạng rồi thử lại.');
}

class ReportDraftResponseException extends ReportDraftException {
  const ReportDraftResponseException()
    : super('AI không trả về kết quả dùng được. Bạn thử lại hoặc chỉnh mô tả.');
}

/// Creates an unconfirmed [ReportDraft] from a description and/or an image
/// using Firebase AI Logic (`gemini-3.8-flash`, falling back to
/// `gemini-3.5-flash-lite` when the primary model's daily quota is used up)
/// with JSON structured output.
///
/// The service never persists or edits the draft: the result is a proposal
/// for the user to review. Retry is manual — callers surface
/// [ReportDraftException.userMessage] and let the user trigger a new call.
class GeminiReportService {
  GeminiReportService({
    this.requestSender,
    this.senderFactory,
    this.requestTimeout = _defaultRequestTimeout,
    this.maxImageBytes = _defaultMaxImageBytes,
  });

  final ReportDraftRequestSender? requestSender;

  /// Builds a sender for a named model. The service uses the primary model
  /// first and only builds the fallback sender when its quota is exhausted,
  /// so tests can assert which models were actually instantiated.
  final ReportDraftRequestSender Function(String modelName)? senderFactory;

  final Duration requestTimeout;
  final int maxImageBytes;

  final Map<String, ReportDraftRequestSender> _senders = {};

  ReportDraftRequestSender _senderFor(String modelName) {
    if (requestSender != null) return requestSender!;
    return _senders.putIfAbsent(
      modelName,
      () => senderFactory?.call(modelName) ?? _GenerativeModelSender(modelName),
    );
  }

  Future<ReportDraft> createReportDraft({
    String? description,
    XFile? image,
  }) async {
    final trimmedDescription = description?.trim() ?? '';

    if (trimmedDescription.isEmpty && image == null) {
      throw const InvalidReportDraftInputException(
        'Nhập mô tả hoặc chọn ảnh trước khi phân tích.',
      );
    }

    final imageData = image == null ? null : await _readImage(image);
    final prompt = Content.multi([
      if (trimmedDescription.isNotEmpty) TextPart(trimmedDescription),
      if (imageData != null) InlineDataPart(imageData.$1, imageData.$2),
    ]);

    String? responseText;
    try {
      responseText = await _senderFor(_primaryModelName)
          .send(prompt)
          .timeout(requestTimeout);
    } on Object catch (error) {
      final mapped = _mapError(error);
      if (kDebugMode) {
        // Diagnosis only: surface the raw SDK error in debug builds so field
        // issues (App Check rejection, model name, quota) are visible in
        // logcat. Never log the prompt or image payload.
        debugPrint('ReportDraft request failed: $error');
      }
      if (mapped is! ReportDraftQuotaException) {
        throw mapped;
      }
      // Primary daily bucket exhausted: try the lite model once so the user
      // is not blocked for the rest of the day. Its quality is lower but the
      // free-tier daily quota is far larger.
      try {
        if (kDebugMode) {
          debugPrint(
            'ReportDraft: primary quota exhausted, trying fallback '
            '($_fallbackModelName)',
          );
        }
        responseText = await _senderFor(_fallbackModelName)
            .send(prompt)
            .timeout(requestTimeout);
      } on Object catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('ReportDraft fallback request failed: $fallbackError');
        }
        // The fallback quota error is the truthful outcome to report; other
        // fallback failures must not hide the original quota cause either.
        throw _mapError(fallbackError) is ReportDraftQuotaException
            ? mapped
            : _mapError(fallbackError);
      }
    }

    final draft = _parseDraft(responseText);
    return draft;
  }

  Future<(String, Uint8List)> _readImage(XFile image) async {
    final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } on Object {
      // Do not expose the local path or a platform exception to the UI/logs.
      throw const InvalidReportDraftInputException(
        'Ảnh không đọc được. Hãy chọn ảnh khác rồi thử lại.',
      );
    }
    if (bytes.isEmpty) {
      throw const InvalidReportDraftInputException(
        'Ảnh không đọc được. Hãy chọn ảnh khác rồi thử lại.',
      );
    }
    if (bytes.length > maxImageBytes) {
      throw const InvalidReportDraftInputException(
        'Ảnh vượt quá giới hạn 4 MiB để gửi phân tích. '
        'Hãy chọn ảnh nhỏ hơn hoặc chụp lại.',
      );
    }
    final mimeType = _imageMimeType(image, bytes);
    if (mimeType == null) {
      throw const InvalidReportDraftInputException(
        'Loại ảnh không được hỗ trợ. Hãy dùng ảnh JPEG, PNG hoặc WebP.',
      );
    }
    return (mimeType, bytes);
  }

  String? _imageMimeType(XFile image, Uint8List bytes) {
    final detected = _detectImageMimeType(bytes);
    final declared = image.mimeType?.split(';').first.trim().toLowerCase();

    if (declared == null || declared.isEmpty) return detected;
    if (declared == 'application/octet-stream') return detected;
    if (!_supportedInlineImageMimeTypes.contains(declared)) return null;

    // The file bytes are authoritative. Never send a supported MIME label
    // that disagrees with the detected image signature.
    return declared == detected ? declared : null;
  }

  String? _detectImageMimeType(Uint8List bytes) {
    if (bytes.length >= 33 &&
        _startsWith(bytes, const [
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
        ]) &&
        _startsWith(bytes.sublist(8), const [
          0x00,
          0x00,
          0x00,
          0x0d,
          0x49,
          0x48,
          0x44,
          0x52,
        ])) {
      return 'image/png';
    }
    if (_startsWith(bytes, const [0xff, 0xd8, 0xff])) return 'image/jpeg';
    if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  bool _startsWith(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  ReportDraft _parseDraft(String? responseText) {
    final text = responseText?.trim() ?? '';
    if (text.isEmpty) {
      throw const ReportDraftResponseException();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const ReportDraftResponseException();
    }

    try {
      return ReportDraft.fromJson(decoded);
    } on FormatException {
      throw const ReportDraftResponseException();
    } on ArgumentError {
      throw const ReportDraftResponseException();
    }
  }

  ReportDraftException _mapError(Object error) {
    switch (error) {
      case final TimeoutException _:
        return const ReportDraftTimeoutException();
      case final QuotaExceeded _:
        return const ReportDraftQuotaException();
      case final ServiceApiNotEnabled _:
      case final InvalidApiKey _:
      case final UnsupportedUserLocation _:
      case final FirebaseAISdkException _:
        return const ReportDraftConfigException();
      // App Check failures surface as the plugin's FirebaseException (for
      // example "[firebase_app_check/unknown] … 403 … App attestation
      // failed."), not as a FirebaseAIException from the AI SDK.
      case FirebaseException(plugin: final plugin, message: final message)
          when plugin.contains('app_check') || _mentionsAppCheck(message):
        return const ReportDraftAppCheckException();
      case FirebaseException _:
        return const ReportDraftServiceException();
      case FirebaseAIException(message: final message)
          when _mentionsAppCheck(message):
        return const ReportDraftAppCheckException();
      case FirebaseAIException(message: final message)
          when message.toLowerCase().contains('blocked'):
        return const ReportDraftResponseException();
      case FirebaseAIException _:
        return const ReportDraftServiceException();
      default:
        return const ReportDraftServiceException();
    }
  }

  bool _mentionsAppCheck(String? message) {
    if (message == null) return false;
    final normalized = message
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '');
    return normalized.contains('appcheck') ||
        normalized.contains('app check') ||
        normalized.contains('app attestation') ||
        normalized.contains('attestation failed');
  }
}

class _GenerativeModelSender implements ReportDraftRequestSender {
  _GenerativeModelSender(this.modelName);

  final String modelName;
  GenerativeModel? _model;

  @override
  Future<String?> send(Content prompt) async {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.text(reportDraftPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _reportDraftResponseSchema,
      ),
    );
    final response = await _model!.generateContent([prompt]);
    return response.text;
  }
}
