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
import 'services/app_check_initializer.dart';
import 'services/gemini_report_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bootstrap.dart';
import 'widgets/field_assistant_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppBootstrap(
      initialize: _initializeFirebase,
      appBuilder: (_) => const AiFieldAssistantApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  // A retry after App Check failure reuses the already initialized Firebase app.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await initializeAppCheck(
    isDebug: kDebugMode,
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    activate: ({required providerAndroid, providerWeb}) => FirebaseAppCheck
        .instance
        .activate(providerAndroid: providerAndroid, providerWeb: providerWeb),
  );
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
    return MaterialApp(
      title: 'AI Field Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            FieldAssistantLogo(size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Field Assistant'),
                  SizedBox(height: 2),
                  Text(
                    'TRỢ LÝ HIỆN TRƯỜNG',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 10,
                      height: 1.2,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
