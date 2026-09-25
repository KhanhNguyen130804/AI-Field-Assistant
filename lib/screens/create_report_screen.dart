import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key, this.imagePicker});

  @visibleForTesting
  final ImagePicker? imagePicker;

  static const maxImageBytes = 10 * 1024 * 1024;

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  late final TextEditingController _descriptionController;
  late final ImagePicker _imagePicker;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  XFile? _previousSelectedImage;
  Uint8List? _previousSelectedImageBytes;
  int _imageGeneration = 0;
  int? _handledDecodeErrorGeneration;
  String? _feedbackMessage;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _imagePicker = widget.imagePicker ?? ImagePicker();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_restoreLostPickerData());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _restoreLostPickerData() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (response.isEmpty) return;

      if (response.exception != null) {
        _showFeedback(_messageForPickerError(response.exception!, null));
        return;
      }

      final lostImages =
          response.files ?? [if (response.file != null) response.file!];
      if (lostImages.isNotEmpty) {
        await _applySelectedImage(lostImages.first);
      }
    } on PlatformException catch (error) {
      _showFeedback(_messageForPickerError(error, null));
    } on Exception {
      _showFeedback(
        'Không thể khôi phục ảnh đã chọn. Bạn có thể chọn lại ảnh.',
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
      _feedbackMessage = null;
    });

    try {
      if (!_imagePicker.supportsImageSource(source)) {
        _showFeedback(
          source == ImageSource.camera
              ? 'Thiết bị hoặc trình duyệt này không hỗ trợ chụp ảnh.'
              : 'Thiết bị hoặc trình duyệt này không hỗ trợ chọn ảnh.',
        );
        return;
      }

      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      // A null result means the user canceled. Keep existing text and photo.
      if (image == null || !mounted) return;
      await _applySelectedImage(image);
    } on PlatformException catch (error) {
      _showFeedback(_messageForPickerError(error, source));
    } on Exception {
      _showFeedback(
        source == ImageSource.camera
            ? 'Không thể mở camera. Bạn vẫn có thể nhập mô tả hoặc chọn ảnh.'
            : 'Không thể đọc ảnh đã chọn. Hãy thử ảnh khác.',
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _applySelectedImage(XFile image) async {
    try {
      final fileLength = await image.length();
      if (fileLength > CreateReportScreen.maxImageBytes) {
        _showFeedback(_imageTooLargeMessage);
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        _showFeedback(_unreadableImageMessage);
        return;
      }
      if (bytes.length > CreateReportScreen.maxImageBytes) {
        _showFeedback(_imageTooLargeMessage);
        return;
      }
      if (!_hasSupportedImageSignature(bytes)) {
        _showFeedback(_unreadableImageMessage);
        return;
      }

      if (!mounted) return;
      _imageGeneration++;
      setState(() {
        _previousSelectedImage = _selectedImage;
        _previousSelectedImageBytes = _selectedImageBytes;
        _selectedImage = image;
        _selectedImageBytes = bytes;
        _feedbackMessage = null;
      });
    } on Exception {
      _showFeedback(_unreadableImageMessage);
    }
  }

  String get _imageTooLargeMessage =>
      'Ảnh vượt quá giới hạn 10 MiB. Hãy chọn ảnh nhỏ hơn rồi thử lại.';

  String get _unreadableImageMessage => _selectedImage == null
      ? 'Không đọc được ảnh. Hãy thử chọn hoặc chụp ảnh khác.'
      : 'Ảnh mới không thể đọc được. Ảnh trước đó vẫn được giữ.';

  void _handleImageDecodeError(int generation) {
    if (_handledDecodeErrorGeneration == generation) return;
    _handledDecodeErrorGeneration = generation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _imageGeneration != generation) return;
      setState(() {
        _selectedImage = _previousSelectedImage;
        _selectedImageBytes = _previousSelectedImageBytes;
        _previousSelectedImage = null;
        _previousSelectedImageBytes = null;
        _imageGeneration++;
        _feedbackMessage = _selectedImage == null
            ? 'Ảnh không thể hiển thị. Hãy chọn ảnh khác.'
            : 'Ảnh mới không thể hiển thị. Ảnh trước đó vẫn được giữ.';
      });
    });
  }

  bool _hasSupportedImageSignature(Uint8List bytes) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      return true;
    }

    if (startsWith(const <int>[
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ])) {
      // Require the PNG signature and IHDR chunk before accepting the bytes.
      return bytes.length >= 33;
    }

    if (startsWith(const <int>[0xff, 0xd8, 0xff]) ||
        startsWith(const <int>[0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) ||
        startsWith(const <int>[0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) ||
        startsWith(const <int>[0x42, 0x4d])) {
      return true;
    }

    if (bytes.length >= 12 &&
        startsWith(const <int>[0x52, 0x49, 0x46, 0x46]) &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    if (bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      return const <String>{
        'heic',
        'heix',
        'hevc',
        'hevx',
        'mif1',
        'msf1',
        'avif',
        'avis',
      }.contains(brand);
    }

    return false;
  }

  String _messageForPickerError(PlatformException error, ImageSource? source) {
    final code = error.code.toLowerCase();
    if (code.contains('denied')) {
      final isCamera = source == ImageSource.camera || code.contains('camera');
      return isCamera
          ? 'Quyền camera bị từ chối. Hãy kiểm tra Cài đặt ứng dụng hoặc nhập mô tả/chọn ảnh.'
          : 'Quyền truy cập ảnh bị từ chối. Hãy kiểm tra Cài đặt ứng dụng hoặc tiếp tục với mô tả.';
    }

    if (source == ImageSource.camera || code.contains('camera')) {
      return 'Không thể mở camera. Bạn vẫn có thể nhập mô tả hoặc chọn ảnh.';
    }
    return 'Không thể mở thư viện ảnh. Mô tả của bạn vẫn được giữ nguyên.';
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    setState(() => _feedbackMessage = message);
  }

  Future<void> _reviewInput() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty && _selectedImage == null) {
      _showFeedback('Nhập mô tả hoặc chọn ảnh trước khi xem lại đầu vào.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _feedbackMessage = null);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem lại đầu vào',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      key: const Key('review-description'),
                      style: textTheme.bodyLarge,
                    )
                  else
                    Text(
                      'Chưa nhập mô tả.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (_selectedImageBytes case final imageBytes?) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        imageBytes,
                        key: const Key('review-image-preview'),
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _ImageReadError(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const _StatusNotice(
                    message: 'Đầu vào này chưa được gửi tới AI và chưa được lưu thành báo cáo.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Quay lại chỉnh sửa'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final previewGeneration = _imageGeneration;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ghi nhận sự cố',
                style: textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF17211F),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mô tả và thêm ảnh nếu có. Bạn có thể xem lại đầu vào trước khi tiếp tục.',
                style: textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF52615D),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('incident-description-field'),
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  if (_feedbackMessage != null) {
                    setState(() => _feedbackMessage = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Mô tả sự cố',
                  hintText:
                      'Ví dụ: Điều hòa tại khu vực lễ tân không hoạt động.',
                  alignLabelWithHint: true,
                  helperText: 'Không gửi thông tin cho AI trong bước này.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ảnh sự cố (không bắt buộc)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chọn một ảnh, tối đa 10 MiB sau xử lý.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('take-photo-button'),
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Chụp ảnh'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('choose-photo-button'),
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh'),
              ),
              if (_isPickingImage) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Đang mở trình chọn ảnh…'),
              ],
              if (_selectedImageBytes case final imageBytes?) ...[
                const SizedBox(height: 16),
                Semantics(
                  label: 'Ảnh sự cố đã chọn',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      imageBytes,
                      key: const Key('selected-image-preview'),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImageReadError(previewGeneration),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ảnh đã chọn. Chọn ảnh khác để thay thế.',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_feedbackMessage case final message?) ...[
                const SizedBox(height: 16),
                _StatusNotice(message: message, isError: true),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('review-input-button'),
                onPressed: _isPickingImage ? null : _reviewInput,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Xem lại đầu vào'),
              ),
              const SizedBox(height: 16),
              const _StatusNotice(
                message: 'Mô tả chỉ giữ tạm trong màn hình; ảnh dùng file tạm. AI và lưu báo cáo chưa được tích hợp.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageReadError(int generation) {
    _handleImageDecodeError(generation);
    return const _ImageReadError();
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.message, this.isError = false});

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

class _ImageReadError extends StatelessWidget {
  const _ImageReadError();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: const Color(0xFFEAF3F0),
      alignment: Alignment.center,
      child: const Text('Không thể hiển thị ảnh này. Hãy chọn ảnh khác.'),
    );
  }
}
