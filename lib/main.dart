import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_options.dart';
import 'repositories/report_repository.dart';
import 'repositories/report_repository_factory.dart';
import 'screens/create_report_screen.dart';
import 'screens/report_detail_screen.dart';
import 'screens/history_screen.dart';
import 'services/gemini_report_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    // Debug provider chỉ dùng cho local; token debug phải được đăng ký trong
    // Firebase Console (App Check → Apps → Manage debug tokens) trước khi
    // request được chấp nhận. Provider production thuộc bước phát hành.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerWeb: WebDebugProvider(),
    );
  }
  runApp(const AiFieldAssistantApp());
}

class AiFieldAssistantApp extends StatelessWidget {
  const AiFieldAssistantApp({
    super.key,
    this.imagePicker,
    this.reportService,
    this.reportRepository,
  });

  final ImagePicker? imagePicker;
  final GeminiReportService? reportService;
  final ReportRepository? reportRepository;

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF176B5B);

    return MaterialApp(
      title: 'AI Field Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brandColor),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF17211F),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: _HomeScreen(
        imagePicker: imagePicker,
        reportService: reportService,
        reportRepository: reportRepository,
      ),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen({
    this.imagePicker,
    this.reportService,
    this.reportRepository,
  });

  final ImagePicker? imagePicker;
  final GeminiReportService? reportService;
  final ReportRepository? reportRepository;

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _selectedIndex = 0;
  int _historyRefreshToken = 0;
  late final ReportRepository _reportRepository;

  @override
  void initState() {
    super.initState();
    _reportRepository = widget.reportRepository ?? createReportRepository();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Field Assistant')),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CreateReportScreen(
            imagePicker: widget.imagePicker,
            reportService: widget.reportService,
            reportRepository: _reportRepository,
            onReportSaved: _refreshHistory,
          ),
          HistoryScreen(
            repository: _reportRepository,
            isActive: _selectedIndex == 1,
            refreshToken: _historyRefreshToken,
            onReportSelected: _openReportDetail,
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 1) _historyRefreshToken++;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.note_add_outlined),
                  selectedIcon: Icon(Icons.note_add_rounded),
                  label: 'Tạo báo cáo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: 'Lịch sử',
                ),
              ],
            ),
    );
  }

  void _refreshHistory() {
    setState(() => _historyRefreshToken++);
  }

  Future<void> _openReportDetail(String reportId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ReportDetailScreen(
          repository: _reportRepository,
          reportId: reportId,
        ),
      ),
    );
  }
}
