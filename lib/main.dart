import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/database_service.dart';
import 'core/services/file_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Database Box Services
    await DatabaseService.instance.init();

    // Initialize File Service to cache application documents directory
    await FileService.instance.init();

    // Initialize Local Notification Engine
    final notificationService = NotificationService.instance;
    await notificationService.init();
    await notificationService.requestPermissions();
  } catch (e, stackTrace) {
    debugPrint('App initialization error: $e');
    debugPrint('Stacktrace: $stackTrace');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Hata Defteri',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Routing configuration
      routerConfig: AppRouter.router,
    );
  }
}
