import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_draft.dart';
import 'report_draft_prompt.dart';

const _geminiModelName = 'gemini-3.8-flash';

const _defaultRequestTimeout = Duration(seconds: 60);

const _defaultMaxImageBytes = 4 * 1024 * 1024;

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
/// using Firebase AI Logic (`gemini-3.8-flash`) with JSON structured output.
///
/// The service never persists or edits the draft: the result is a proposal
/// for the user to review. Retry is manual — callers surface
/// [ReportDraftException.userMessage] and let the user trigger a new call.
class GeminiReportService {
  GeminiReportService({
    this.requestSender,
    this.modelFactory,
    this.requestTimeout = _defaultRequestTimeout,
    this.maxImageBytes = _defaultMaxImageBytes,
  });

  final ReportDraftRequestSender? requestSender;
  final GenerativeModel Function()? modelFactory;
  final Duration requestTimeout;
  final int maxImageBytes;

  ReportDraftRequestSender? _sender;

  ReportDraftRequestSender get _resolvedSender =>
      _sender ??= requestSender ?? _GenerativeModelSender(modelFactory);

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

    final String? responseText;
    try {
      responseText = await _resolvedSender.send(prompt).timeout(requestTimeout);
    } catch (error) {
      throw _mapError(error);
    }

    final draft = _parseDraft(responseText);
    return draft;
  }

  Future<(String, Uint8List)> _readImage(XFile image) async {
    final bytes = await image.readAsBytes();
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
        'Loại ảnh không được hỗ trợ. Hãy dùng ảnh JPEG, PNG, WebP, GIF hoặc HEIC.',
      );
    }
    return (mimeType, bytes);
  }

  String? _imageMimeType(XFile image, Uint8List bytes) {
    final declared = image.mimeType;
    if (declared != null && declared.startsWith('image/')) return declared;

    if (_startsWith(bytes, const [0x89, 0x50, 0x4e, 0x47])) return 'image/png';
    if (_startsWith(bytes, const [0xff, 0xd8, 0xff])) return 'image/jpeg';
    if (_startsWith(bytes, const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    if (_startsWith(bytes, const [0x42, 0x4d])) return 'image/bmp';
    if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 12 && bytes[4] == 0x66 && bytes[5] == 0x74) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      const heifBrands = {'heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'};
      if (heifBrands.contains(brand)) return 'image/heic';
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

  bool _mentionsAppCheck(String message) {
    final normalized = message.toLowerCase().replaceAll('-', '');
    return normalized.contains('appcheck') || normalized.contains('app check');
  }
}

class _GenerativeModelSender implements ReportDraftRequestSender {
  _GenerativeModelSender(this._modelFactory);

  final GenerativeModel Function()? _modelFactory;
  GenerativeModel? _model;

  @override
  Future<String?> send(Content prompt) async {
    _model ??= (_modelFactory ?? _defaultModelFactory)();
    final response = await _model!.generateContent([prompt]);
    return response.text;
  }

  static GenerativeModel _defaultModelFactory() {
    return FirebaseAI.googleAI().generativeModel(
      model: _geminiModelName,
      systemInstruction: Content.text(reportDraftPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _reportDraftResponseSchema,
      ),
    );
  }
}
