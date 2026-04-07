import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/main_screen.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'config/configure_url_strategy.dart' if (dart.library.html) 'config/configure_url_strategy_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await dotenv.load(fileName: ".env");
  MediaKit.ensureInitialized();

  // Set mobile-like window size on Windows desktop
  if (!kIsWeb && Platform.isWindows) {
    try {
      await windowManager.ensureInitialized();
      const windowSize = Size(420, 780);
      const WindowOptions windowOptions = WindowOptions(
        size: windowSize,
        minimumSize: Size(360, 640),
        windowButtonVisibility: false,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('WindowManager init skipped: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: MultiProviderWrap(),
    ),
  );
}

class MultiProviderWrap extends StatelessWidget {
  const MultiProviderWrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'OldManBrowser',
      theme: AppTheme.getLightTheme(themeProvider.seedColor),
      darkTheme: AppTheme.getDarkTheme(themeProvider.seedColor),
      themeMode: themeProvider.themeMode,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
