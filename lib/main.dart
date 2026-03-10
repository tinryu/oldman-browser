import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/main_screen.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Set mobile-like window size on Windows desktop
  if (Platform.isWindows) {
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
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
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
