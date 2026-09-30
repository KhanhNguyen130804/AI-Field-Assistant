import 'dart:typed_data';

import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:printing/printing.dart';

enum ReportPdfSaveResult { saved, cancelled }

abstract interface class ReportPdfActions {
  Future<ReportPdfSaveResult> save(Uint8List bytes, String fileName);

  Future<void> share(Uint8List bytes, String fileName);
}

class PlatformReportPdfActions implements ReportPdfActions {
  PlatformReportPdfActions({FlutterFileSaver? fileSaver})
    : _fileSaver = fileSaver ?? FlutterFileSaver();

  final FlutterFileSaver _fileSaver;

  @override
  Future<ReportPdfSaveResult> save(Uint8List bytes, String fileName) async {
    try {
      await _fileSaver.writeFileAsBytes(fileName: fileName, bytes: bytes);
      return ReportPdfSaveResult.saved;
    } on FileSaverCancelledException {
      return ReportPdfSaveResult.cancelled;
    }
  }

  @override
  Future<void> share(Uint8List bytes, String fileName) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);
}
