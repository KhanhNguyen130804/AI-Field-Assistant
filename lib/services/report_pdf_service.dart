import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report.dart';
import '../models/report_priority.dart';

abstract interface class ReportPdfGenerator {
  Future<Uint8List> generate({
    required Report report,
    Uint8List? photoBytes,
    bool photoOmissionConfirmed = false,
  });
}

class ReportPdfPhotoException implements Exception {
  const ReportPdfPhotoException(this.message);

  final String message;
}

class ReportPdfGenerationException implements Exception {
  const ReportPdfGenerationException();
}

/// Builds a self-contained PDF from a report that has already been confirmed.
class ReportPdfService implements ReportPdfGenerator {
  const ReportPdfService();

  static const _regularFontAsset = 'assets/fonts/roboto-regular.ttf';
  static const _boldFontAsset = 'assets/fonts/roboto-bold.ttf';

  @override
  Future<Uint8List> generate({
    required Report report,
    Uint8List? photoBytes,
    bool photoOmissionConfirmed = false,
  }) async {
    if (report.photoPath != null &&
        photoBytes == null &&
        !photoOmissionConfirmed) {
      throw const ReportPdfPhotoException(
        'Ảnh của báo cáo chưa sẵn sàng để đưa vào PDF.',
      );
    }

    final imageBytes = photoBytes == null ? null : _normalizePhoto(photoBytes);
    final regularFont = await _loadFont(_regularFontAsset);
    final boldFont = await _loadFont(_boldFontAsset);
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    final document = pw.Document(compress: false);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(38, 42, 38, 42),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFD9E2DF)),
            ),
          ),
          child: pw.Text(
            'AI FIELD ASSISTANT',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
              color: const PdfColor.fromInt(0xFF176B5B),
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColor.fromInt(0xFFD9E2DF)),
            ),
          ),
          child: pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF65736F),
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            'BÁO CÁO SỰ CỐ',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 21,
              color: const PdfColor.fromInt(0xFF17211F),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Mã báo cáo: ${report.id}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF65736F),
            ),
          ),
          pw.Text(
            'Thời gian tạo: ${_formatDateTime(report.createdAt)}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF65736F),
            ),
          ),
          pw.SizedBox(height: 18),
          _field(
            'Danh mục',
            _confirmedText(report, 'category', report.category),
          ),
          _field(
            'Địa điểm',
            _confirmedText(report, 'location', report.location),
          ),
          _field('Mức độ ưu tiên', _priorityText(report)),
          _field('Sự cố', report.issue),
          _field(
            'Hành động đề xuất',
            _confirmedText(report, 'suggested_action', report.suggestedAction),
            note: 'Đây là hành động đề xuất, chưa phải việc đã thực hiện.',
          ),
          _field('Tóm tắt', _confirmedText(report, 'summary', report.summary)),
          pw.SizedBox(height: 8),
          pw.Text(
            'MÔ TẢ GỐC',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            report.sourceDescription.isEmpty
                ? 'Không có mô tả gốc.'
                : report.sourceDescription,
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
          ),
          if (report.photoPath != null) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'ẢNH BÁO CÁO',
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
            pw.SizedBox(height: 8),
            if (imageBytes != null)
              pw.Center(
                child: pw.Container(
                  constraints: const pw.BoxConstraints(maxHeight: 300),
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              )
            else
              pw.Text(
                'Ảnh không được đính kèm theo lựa chọn của người dùng.',
                style: const pw.TextStyle(fontSize: 9),
              ),
          ],
        ],
      ),
    );

    try {
      return Uint8List.fromList(await document.save());
    } on Object {
      throw const ReportPdfGenerationException();
    }
  }

  Future<pw.Font> _loadFont(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      return pw.Font.ttf(data);
    } on Object {
      throw const ReportPdfGenerationException();
    }
  }

  Uint8List _normalizePhoto(Uint8List bytes) {
    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47;
    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw const FormatException('Invalid image.');
      if (isPng || isJpeg) return bytes;
      return Uint8List.fromList(img.encodePng(decoded));
    } on Object {
      // Report the same safe failure for malformed and unsupported image data.
    }
    throw const ReportPdfPhotoException(
      'Không thể đọc ảnh báo cáo để tạo PDF. Hãy tải lại ảnh hoặc xuất không kèm ảnh.',
    );
  }

  pw.Widget _field(String label, String value, {String? note}) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: const PdfColor.fromInt(0xFFE1E8E5)),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF176B5B),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10, lineSpacing: 3)),
        if (note != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            note,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF65736F),
            ),
          ),
        ],
      ],
    ),
  );

  String _confirmedText(Report report, String field, String value) =>
      report.confirmedAbsentFields.contains(field)
      ? 'Đã xác nhận không có thông tin'
      : value.isEmpty
      ? 'Không có dữ liệu'
      : value;

  String _priorityText(Report report) =>
      report.confirmedAbsentFields.contains('priority')
      ? 'Đã xác nhận chưa xác định'
      : switch (report.priority) {
          ReportPriority.low => 'Thấp',
          ReportPriority.medium => 'Trung bình',
          ReportPriority.high => 'Cao',
          null => 'Chưa xác định',
        };

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
