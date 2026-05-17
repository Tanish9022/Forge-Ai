import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';

import 'core/config/api_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/chat/chat_cache_service.dart';
import 'core/notifications/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Protect app from screenshots for privacy
  try {
    await ScreenProtector.preventScreenshotOn();
  } catch (e) {
    debugPrint('Screen protection not supported on this platform');
  }
  
  final chatCache = ChatCacheService();
  await chatCache.init();
  
  // Try to initialize FCM
  final pushService = PushNotificationService();
  await pushService.init();
  
  // ApiConfig.baseUrl is read at compile time via --dart-define=API_BASE_URL=...
  debugPrint('Atmos API: ${ApiConfig.baseUrl}');
  runApp(const ProviderScope(child: AtmosApp()));
}

class AtmosApp extends ConsumerWidget {
  const AtmosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Atmos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
