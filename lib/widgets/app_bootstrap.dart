import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keeps the application and its services closed until initialization succeeds.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    required this.initialize,
    required this.appBuilder,
  });

  final Future<void> Function() initialize;
  final WidgetBuilder appBuilder;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = Future<void>.sync(widget.initialize);
  }

  void _retry() {
    setState(() {
      _initialization = Future<void>.sync(widget.initialize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return widget.appBuilder(context);
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child:
                      snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Không thể khởi động ứng dụng. Kiểm tra kết nối '
                              'và thử lại. Nếu lỗi tiếp tục, hãy liên hệ '
                              'người cung cấp ứng dụng.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _retry,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Đang khởi động ứng dụng…'),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
