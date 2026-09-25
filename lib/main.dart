import 'package:flutter/material.dart';

void main() {
  runApp(const AiFieldAssistantApp());
}

class AiFieldAssistantApp extends StatelessWidget {
  const AiFieldAssistantApp({super.key});

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
      home: const _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Field Assistant')),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [_CreateReportScreen(), _HistoryScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
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
}

class _CreateReportScreen extends StatelessWidget {
  const _CreateReportScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1ED),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'BẢN NỀN TẢNG',
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF14594D),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ghi nhận sự cố\ntại hiện trường',
                style: textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF17211F),
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'AI Field Assistant hướng tới giúp nhân viên hiện trường '
                'tạo báo cáo nhanh từ thông tin sự cố.',
                style: textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF52615D),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Quy trình dự kiến',
                style: textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF17211F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8ECEA)),
                ),
                child: const Column(
                  children: [
                    _WorkflowStep(
                      number: '01',
                      title: 'Ghi nhận thông tin',
                      description: 'Nhập mô tả, chụp hoặc chọn ảnh sự cố.',
                      icon: Icons.add_a_photo_outlined,
                    ),
                    Divider(height: 1, indent: 68, endIndent: 16),
                    _WorkflowStep(
                      number: '02',
                      title: 'Tạo bản nháp báo cáo',
                      description: 'AI đề xuất nội dung theo cấu trúc rõ ràng.',
                      icon: Icons.auto_awesome_outlined,
                    ),
                    Divider(height: 1, indent: 68, endIndent: 16),
                    _WorkflowStep(
                      number: '03',
                      title: 'Kiểm tra và lưu',
                      description: 'Xem lại thông tin trước khi lưu báo cáo.',
                      icon: Icons.fact_check_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF8A5A12)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đây mới là giao diện nền tảng. Nhập liệu, camera, '
                        'AI và lưu trữ chưa được tích hợp.',
                        style: TextStyle(
                          color: Color(0xFF684916),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String number;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF176B5B), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number  $title',
                  style: textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF17211F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF65716E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: Color(0xFF176B5B),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chưa có báo cáo',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF17211F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Các báo cáo đã lưu sẽ xuất hiện tại đây khi tính năng '
                'lưu trữ được tích hợp.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65716E),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
