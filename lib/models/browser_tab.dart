import 'package:webview_windows/webview_windows.dart' as win;
import 'package:webview_flutter/webview_flutter.dart' as mob;

class BrowserTab {
  final String id;
  String url;
  String title;
  win.WebviewController? winController;
  mob.WebViewController? mobController;
  bool isInitialized;
  double loadingProgress;
  bool showHome;
  bool isIncognito;

  BrowserTab({
    required this.id,
    this.url = 'https://www.google.com',
    this.title = 'New Tab',
    this.winController,
    this.mobController,
    this.isInitialized = false,
    this.loadingProgress = 0,
    this.showHome = true,
    this.isIncognito = false,
  });
}
