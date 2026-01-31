import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:old_man_browser/widgets/history_modal.dart' show HistoryModal;
import 'package:old_man_browser/widgets/bookmarks_modal.dart';
import 'package:old_man_browser/widgets/captured_videos_modal.dart';
import 'package:old_man_browser/widgets/speed_dial.dart';

import 'package:webview_windows/webview_windows.dart' as win;
import 'package:webview_flutter/webview_flutter.dart' as mob;
import '../models/video_item.dart';
import '../models/menu_bottom_item.dart';
import '../models/browser_tab.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(VideoItem) onVideoCaptured;
  final Function(VideoItem) onVideoRemoved;
  final Function(List<VideoItem>) onVideosUpdated;
  final List<VideoItem> onlineVideos;
  final Function(int) onTabRequested;

  const HomeScreen({
    super.key,
    required this.onVideoCaptured,
    required this.onVideoRemoved,
    required this.onVideosUpdated,
    required this.onlineVideos,
    required this.onTabRequested,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static bool _isEnvInitialized = false;

  // Tab Management
  final List<BrowserTab> _tabs = [];
  int _currentTabIndex = 0;
  final ScrollController _tabScrollController = ScrollController();

  final _textController = TextEditingController(text: 'https://www.google.com');
  String? _errorMessage;
  final List<VideoItem> _detectedVideos = [];
  List<Map<String, String>> _bookmarks = [];
  List<Map<String, String>> _history = [];
  String? _lastCandidateThumbnail;
  bool _isDesktopMode = false;
  bool _showTabSwitcher = false;
  final TextEditingController _tabSearchController = TextEditingController();

  // Animation controllers for page transitions
  late AnimationController _pageTransitionController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;

  // Animation for Tab Switcher entry/exit
  late AnimationController _tabSwitcherController;
  late Animation<double> _tabSwitcherFadeAnimation;
  late Animation<double> _tabSwitcherScaleAnimation;
  late Animation<double> _contentScaleAnimation;

  // Getters for current tab
  BrowserTab? get _currentTab =>
      _tabs.isNotEmpty ? _tabs[_currentTabIndex] : null;
  win.WebviewController? get _winController => _currentTab?.winController;
  mob.WebViewController? get _mobController => _currentTab?.mobController;
  bool get _isInitialized => _currentTab?.isInitialized ?? false;
  String get _currentUrl => _currentTab?.url ?? 'https://www.google.com';
  double get _loadingProgress => _currentTab?.loadingProgress ?? 0;
  bool get _showHome => _currentTab?.showHome ?? true;

  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  // Script to mask webview identifiers that Google/X check
  static const String _browserShieldScript = r'''
    (function() {
      // Hide webdriver
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
      
      // Ensure languages are set
      Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
      
      // Spoof plugins to look like real Chrome
      Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });

      // Override userAgent if not already perfect
      const targetUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
      Object.defineProperty(navigator, 'userAgent', { get: () => targetUA });
      Object.defineProperty(navigator, 'platform', { get: () => 'Win32' });
    })();
  ''';

  static const String _captureScript = r'''
    (function() {
      function notifyFlutter(url) {
        if (url.includes('.m3u8')) {
          const fileName = url.split('/').pop().split('?')[0];
          const message = JSON.stringify({ type: 'm3u8_captured', url: url, title: fileName });
          window.chrome.webview.postMessage(message);
        } else if (url.match(/\.(jpg|jpeg|png|webp)(\?.*)?$/i)) {
          const message = JSON.stringify({ type: 'thumbnail_captured', url: url });
          window.chrome.webview.postMessage(message);
        }
      }

      // Hook Fetch API
      const originalFetch = window.fetch;
      window.fetch = function() {
        return originalFetch.apply(this, arguments).then(response => {
          notifyFlutter(response.url);
          return response;
        });
      };

      // Hook XMLHttpRequest
      const originalOpen = XMLHttpRequest.prototype.open;
      XMLHttpRequest.prototype.open = function(method, url) {
        notifyFlutter(url);
        return originalOpen.apply(this, arguments);
      };

      console.log("M3U8 Capture Hook Initialized");
    })();
  ''';

  bool get _isWindows => Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _loadHistory();

    // Initialize animation controller
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageTransitionController,
        curve: Curves.easeInOut,
      ),
    );

    _pageSlideAnimation =
        Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _pageTransitionController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Initialize Tab Switcher animations
    _tabSwitcherController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _tabSwitcherFadeAnimation = CurvedAnimation(
      parent: _tabSwitcherController,
      curve: Curves.easeInOut,
    );

    _tabSwitcherScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _tabSwitcherController,
        curve: Curves.easeOutBack,
      ),
    );

    _contentScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _tabSwitcherController,
        curve: Curves.easeInOutQuart,
      ),
    );

    _addNewTab(); // Create initial tab
    _pageTransitionController.forward(); // Start with animation visible
  }

  void _toggleTabSwitcher() {
    setState(() {
      _showTabSwitcher = !_showTabSwitcher;
    });

    if (_showTabSwitcher) {
      _tabSwitcherController.forward();
    } else {
      _tabSwitcherController.reverse();
    }
  }

  Future<File> get _bookmarksFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/bookmarks.json');
  }

  Future<File> get _historyFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/history.json');
  }

  Future<void> _loadBookmarks() async {
    try {
      final file = await _bookmarksFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> json = jsonDecode(content);
        setState(() {
          _bookmarks = json.map((e) => Map<String, String>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> _remoteAllFiles() async {
    try {
      final file = await _bookmarksFile;
      await file.delete();
      final historyFile = await _historyFile;
      await historyFile.delete();
    } catch (e) {
      debugPrint('Error removing all files: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final file = await _bookmarksFile;
      await file.writeAsString(jsonEncode(_bookmarks));
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final file = await _historyFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> json = jsonDecode(content);
        setState(() {
          _history = json.map((e) => Map<String, String>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final file = await _historyFile;
      await file.writeAsString(jsonEncode(_history));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  void _addToHistory(String url, String title) {
    if (url == 'about:blank' || url.isEmpty) return;

    setState(() {
      // Remove if already exists to move to top
      _history.removeWhere((item) => item['url'] == url);
      _history.insert(0, {
        'url': url,
        'title': title.isEmpty ? url : title,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only last 100 items
      if (_history.length > 100) {
        _history = _history.sublist(0, 100);
      }
    });
    _saveHistory();
  }

  void _removeAllHistory() {
    setState(() {
      _history.clear();
    });
    _saveHistory();
  }

  Future<void> _addBookmark() async {
    String title = _currentUrl;
    if (_isWindows) {
      final jsTitle = await _winController?.executeScript('document.title');
      if (jsTitle != null) {
        // executeScript might return a JSON string depending on implementation,
        // but typically returns the result. For webview_windows, it returns dynamic.
        // It often returns a quoted string like "\"Title\"" if it returns JSON.
        // Let's safe handle it.
        String rawTitle = jsTitle.toString();
        if (rawTitle.startsWith('"') &&
            rawTitle.endsWith('"') &&
            rawTitle.length >= 2) {
          rawTitle = rawTitle.substring(1, rawTitle.length - 1);
        }
        if (rawTitle.isNotEmpty) {
          title = rawTitle;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.greenAccent,
                content: Text('Bookmark added: $title'),
              ),
            );
          }
        }
      }
    } else {
      title = await _mobController?.getTitle() ?? _currentUrl;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.greenAccent,
            content: Text('Bookmark added: $title'),
          ),
        );
      }
    }

    if (!_bookmarks.any((b) => b['url'] == _currentUrl)) {
      setState(() {
        _bookmarks.add({'url': _currentUrl, 'title': title});
      });
      _saveBookmarks();
    }
  }

  void _removeBookmark(String url) {
    setState(() {
      _bookmarks.removeWhere((b) => b['url'] == url);
    });
    _saveBookmarks();
  }

  void _removeAllBookmarks() {
    setState(() {
      _bookmarks.clear();
    });
    _saveBookmarks();
  }

  void _addNewTab({bool isIncognito = false}) {
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: 'https://www.google.com',
      title: isIncognito ? 'InPrivate Tab' : 'New Tab',
      isIncognito: isIncognito,
    );

    setState(() {
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
      _errorMessage = null;
    });

    _textController.text = newTab.url;
    _startInitialization();

    // Scroll to the new tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabScrollController.hasClients) {
        _tabScrollController.animateTo(
          _tabScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close the last tab, just navigate home
      setState(() {
        _currentTab?.showHome = true;
      });
      return;
    }

    // Dispose controllers
    if (_isWindows) {
      _tabs[index].winController?.dispose();
    }

    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
      _textController.text = _currentTab?.url ?? '';
    });
  }

  void _clearAllTabs() {
    // Dispose all controllers
    for (var tab in _tabs) {
      if (_isWindows) {
        tab.winController?.dispose();
      }
    }

    setState(() {
      _tabs.clear();
      _currentTabIndex = 0;
    });

    // Add a default tab if all were cleared
    _addNewTab();
  }

  void _switchTab(int index) async {
    if (index == _currentTabIndex) return;

    // Fade out current tab
    await _pageTransitionController.reverse();

    setState(() {
      _currentTabIndex = index;
      _textController.text = _currentTab?.url ?? '';
    });

    // Fade in new tab
    await _pageTransitionController.forward();
  }

  void _startInitialization() {
    if (_currentTab == null) return;

    setState(() {
      _currentTab!.isInitialized = false;
      _errorMessage = null;
    });
    if (_isWindows) {
      _initWindowsWebview();
    } else {
      _initMobileWebview();
    }
  }

  Future<void> _initWindowsWebview() async {
    if (_currentTab == null) return;

    try {
      if (!_isEnvInitialized) {
        try {
          await win.WebviewController.initializeEnvironment();
        } catch (e) {
          if (e.toString().contains('environment_already_initialized')) {
            debugPrint('Webview environment already initialized.');
          } else {
            rethrow;
          }
        }
        _isEnvInitialized = true;
      }

      final controller = win.WebviewController();
      await controller.initialize();

      // Set browser shield and User-Agent
      await controller.addScriptToExecuteOnDocumentCreated(
        _browserShieldScript,
      );

      if (_isDesktopMode) {
        await controller.addScriptToExecuteOnDocumentCreated('''
          Object.defineProperty(navigator, 'userAgent', { get: () => '$_desktopUserAgent' });
          Object.defineProperty(navigator, 'platform', { get: () => 'Win32' });
        ''');
      }

      // Inject the capture script
      await controller.addScriptToExecuteOnDocumentCreated(_captureScript);

      // Listen for messages from the webvew
      controller.webMessage.listen((message) {
        try {
          final Map<String, dynamic> data;
          if (message is String) {
            data = jsonDecode(message);
          } else {
            data = Map<String, dynamic>.from(message);
          }

          if (data['type'] == 'm3u8_captured') {
            final url = data['url'] as String;
            final title = data['title'] as String? ?? 'Captured Video';

            if (!_detectedVideos.any((v) => v.url == url)) {
              if (mounted) {
                setState(() {
                  _detectedVideos.add(
                    VideoItem(
                      title: title,
                      url: url,
                      thumbnailUrl: _lastCandidateThumbnail,
                    ),
                  );
                });
              }
            }
          } else if (data['type'] == 'thumbnail_captured') {
            _lastCandidateThumbnail = data['url'];
          }
        } catch (e) {
          debugPrint('Error parsing web message: $e');
        }
      });

      controller.url.listen((url) {
        if (mounted && _currentTab?.winController == controller) {
          setState(() {
            _currentTab!.url = url;
            _textController.text = url;
          });
        }
      });

      controller.loadingState.listen((state) async {
        if (_currentTab?.winController != controller) return;

        if (state == win.LoadingState.loading) {
          _lastCandidateThumbnail = null;
          if (mounted) setState(() => _currentTab!.loadingProgress = 0.5);
        } else if (state == win.LoadingState.navigationCompleted) {
          if (mounted) setState(() => _currentTab!.loadingProgress = 1.0);

          // Fetch and update tab title
          try {
            final jsTitle = await controller.executeScript('document.title');
            if (jsTitle != null &&
                mounted &&
                _currentTab?.winController == controller) {
              String title = jsTitle.toString();
              // Remove quotes if present
              if (title.startsWith('"') &&
                  title.endsWith('"') &&
                  title.length >= 2) {
                title = title.substring(1, title.length - 1);
              }
              if (title.isNotEmpty) {
                setState(() {
                  _currentTab!.title = title;
                });

                // Record in history if not incognito
                if (!(_currentTab?.isIncognito ?? false)) {
                  _addToHistory(_currentTab!.url, title);
                }
              }
            }
          } catch (e) {
            debugPrint('Error fetching title: $e');
          }

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _currentTab?.winController == controller) {
              setState(() => _currentTab!.loadingProgress = 0);
            }
          });
        }
      });

      await controller.setBackgroundColor(Colors.transparent);
      await controller.setPopupWindowPolicy(win.WebviewPopupWindowPolicy.allow);
      await controller.loadUrl(_currentTab!.url);

      if (mounted) {
        setState(() {
          _currentTab!.winController = controller;
          _currentTab!.isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing Windows webview: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Initialization Error: $e.\n\nPlease ensure Microsoft WebView2 Runtime is installed for Windows support.';
        });
      }
    }
  }

  Future<void> _initMobileWebview() async {
    if (_currentTab == null) return;

    try {
      final controller = mob.WebViewController()
        ..setJavaScriptMode(mob.JavaScriptMode.unrestricted)
        ..setUserAgent(_desktopUserAgent);

      // Inject shield via JS on every page load
      controller.setNavigationDelegate(
        mob.NavigationDelegate(
          onProgress: (int progress) {
            if (mounted && _currentTab?.mobController == controller) {
              setState(() => _currentTab!.loadingProgress = progress / 100);
            }
          },
          onPageStarted: (String url) {
            controller.runJavaScript(_browserShieldScript);
            if (mounted && _currentTab?.mobController == controller) {
              setState(() {
                _currentTab!.url = url;
                _textController.text = url;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted && _currentTab?.mobController == controller) {
              setState(() => _currentTab!.loadingProgress = 0);

              // Fetch title and add to history
              try {
                final title = await controller.getTitle();
                if (title != null && title.isNotEmpty) {
                  setState(() => _currentTab!.title = title);
                  if (!(_currentTab?.isIncognito ?? false)) {
                    _addToHistory(url, title);
                  }
                }
              } catch (e) {
                debugPrint('Error getting mobile title: $e');
              }
            }
          },
          onWebResourceError: (mob.WebResourceError error) {
            debugPrint('Webview Error: ${error.description}');
          },
        ),
      );

      await controller.loadRequest(Uri.parse(_currentTab!.url));

      if (mounted) {
        setState(() {
          _currentTab!.mobController = controller;
          _currentTab!.isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Mobile Webview Error: $e';
        });
      }
    }
  }

  void _toggleDesktopMode() async {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
    });

    if (_isWindows) {
      if (_isDesktopMode) {
        await _winController?.addScriptToExecuteOnDocumentCreated('''
          Object.defineProperty(navigator, 'userAgent', { get: () => '$_desktopUserAgent' });
          Object.defineProperty(navigator, 'platform', { get: () => 'Win32' });
        ''');
      }
      // Note: Reverting desktop mode on Windows would require re-initializing the controller
      // as there's no native "removeScript" API in webview_windows yet.
      // But since Windows is already "Desktop", turning it ON just ensures a specific Chrome Desktop UA.
      await _winController?.reload();
    } else {
      if (_isDesktopMode) {
        await _mobController?.setUserAgent(_desktopUserAgent);
      } else {
        await _mobController?.setUserAgent(null); // Reset to default
      }
      await _mobController?.reload();
    }
  }

  void _onUrlSubmitted(String value) {
    if (!_isInitialized || _currentTab == null) return;
    String input = value.trim();
    if (input.isEmpty) return;

    setState(() {
      _currentTab!.showHome = false;
    });

    String url;
    // Simple logic to detect if it's a search query or a URL
    final bool isSearch =
        input.contains(' ') ||
        (!input.contains('.') && !input.startsWith('http'));

    if (isSearch) {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
    } else {
      url = input;
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
    }

    if (_isWindows) {
      _winController?.loadUrl(url);
    } else {
      _mobController?.loadRequest(Uri.parse(url));
    }
  }

  void _goBack() {
    if (_isWindows) {
      _winController?.goBack();
    } else {
      _mobController?.goBack();
    }
  }

  void _goForward() {
    if (_isWindows) {
      _winController?.goForward();
    } else {
      _mobController?.goForward();
    }
  }

  void _reload() {
    if (_isWindows) {
      _winController?.reload();
    } else {
      _mobController?.reload();
    }
  }

  void _goHome() {
    if (_currentTab == null) return;
    setState(() {
      _currentTab!.showHome = true;
    });
  }

  void _openInspect() {
    if (_isWindows) {
      _winController?.openDevTools();
    } else {
      // Inject Eruda for mobile debugging
      _mobController?.runJavaScript('''
        (function () { 
          var script = document.createElement('script'); 
          script.src="//cdn.jsdelivr.net/npm/eruda"; 
          document.body.appendChild(script); 
          script.onload = function () { 
            eruda.init(); 
            eruda.show();
          }; 
        })();
      ''');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile Inspector (Eruda) loading...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var tab in _tabs) {
      tab.winController?.dispose();
    }
    _textController.dispose();
    _tabScrollController.dispose();
    _tabSearchController.dispose();
    _pageTransitionController.dispose();
    _tabSwitcherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.webhook_outlined,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startInitialization,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Initialization'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_loadingProgress > 0 && _loadingProgress < 1)
          LinearProgressIndicator(value: _loadingProgress, minHeight: 2),
        Expanded(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.f5): _reload,
              const SingleActivator(LogicalKeyboardKey.keyR, control: true):
                  _reload,
              const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
                  _goBack,
              const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
                  _goForward,
              const SingleActivator(LogicalKeyboardKey.f12): _openInspect,
              const SingleActivator(
                LogicalKeyboardKey.keyI,
                control: true,
                shift: true,
              ): _openInspect,
              const SingleActivator(LogicalKeyboardKey.keyT, control: true):
                  _addNewTab,
            },
            child: Focus(
              autofocus: true,
              child: _currentTab == null
                  ? const Center(child: Text('No tabs open'))
                  : Stack(
                      children: [
                        // Main content with scaling effect when switcher is open
                        ScaleTransition(
                          scale: _contentScaleAnimation,
                          child: FadeTransition(
                            opacity: _pageFadeAnimation,
                            child: SlideTransition(
                              position: _pageSlideAnimation,
                              child: !_isInitialized
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _isWindows
                                  ? win.Webview(_winController!)
                                  : mob.WebViewWidget(
                                      controller: _mobController!,
                                    ),
                            ),
                          ),
                        ),
                        if (_showHome)
                          SpeedDial(
                            bookmarks: _bookmarks,
                            onUrlSelected: (url) {
                              setState(() {
                                _currentTab!.showHome = false;
                              });
                              _onUrlSubmitted(url);
                            },
                          ),
                        // Tab Switcher Overlay with smooth entry/exit
                        FadeTransition(
                          opacity: _tabSwitcherFadeAnimation,
                          child: ScaleTransition(
                            scale: _tabSwitcherScaleAnimation,
                            child:
                                _showTabSwitcher ||
                                    _tabSwitcherController.isAnimating
                                ? _buildTabSwitcher()
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        GestureDetector(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          controller: _textController,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search or enter URL',
                            hintStyle: const TextStyle(fontSize: 14),
                            isDense: true,
                            contentPadding: const EdgeInsets.only(left: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: _currentTab?.isIncognito ?? false
                                ? Colors.purple.withValues(alpha: 0.15)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                            prefixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _currentTab?.isIncognito ?? false
                                    ? Icons.security
                                    : Icons.bookmarks,
                                size: 18,
                                color: _currentTab?.isIncognito ?? false
                                    ? Colors.purple
                                    : null,
                              ),
                              onPressed: () => _addBookmark(),
                            ),
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: _reload,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          onSubmitted: _onUrlSubmitted,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        color: theme.colorScheme.onSurface,
                        icon: const Icon(Icons.home, size: 24),
                        onPressed: _goHome,
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        icon: const Icon(Icons.arrow_back, size: 24),
                        onPressed: _goBack,
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 24),
                        onPressed: _goForward,
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        icon: const Icon(Icons.add, size: 24),
                        onPressed: () {
                          _addNewTab();
                        },
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        icon: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _currentTab?.isIncognito ?? false
                                    ? Colors.purple.withValues(alpha: 0.2)
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _currentTab?.isIncognito ?? false
                                      ? Colors.purple
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.2,
                                        ),
                                ),
                              ),
                              child: Text(
                                _tabs.length.toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: _toggleTabSwitcher,
                        tooltip: 'Tab Switcher',
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        tooltip: 'Settings',
                        icon: Badge(
                          padding: const EdgeInsets.all(2),
                          offset: const Offset(10, -6),
                          label: Text(
                            _detectedVideos.length.toString(),
                            style: TextStyle(
                              color: _detectedVideos.isEmpty
                                  ? Colors.transparent
                                  : Colors.white,
                            ),
                          ),
                          backgroundColor: _detectedVideos.isEmpty
                              ? Colors.transparent
                              : Colors.redAccent,
                          child: Icon(
                            Icons.menu,
                            color: theme.colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                        onPressed: () {
                          _showSettingsModal(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    final filteredTabs = _tabs.where((tab) {
      final searchQuery = _tabSearchController.text.toLowerCase();
      return tab.title.toLowerCase().contains(searchQuery) ||
          tab.url.toLowerCase().contains(searchQuery);
    }).toList();

    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.98),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tab count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tabs.length.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.tab,
                          color: theme.colorScheme.onSurface,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    color: theme.colorScheme.onSurface,
                    onPressed: () => _clearAllTabs(),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _tabSearchController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search your tabs',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.05,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Add New Tab Buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.onPrimary),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _addNewTab();
                      },
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tab_rounded,
                            size: 24,
                            color: theme.colorScheme.onPrimary,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "New Tab",
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _addNewTab(isIncognito: true);
                      },
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_moon_outlined,
                            size: 24,
                            color: Colors.purple,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "Incognito",
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            // Tab Cards Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 800
                      ? 2
                      : 4,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredTabs.length,
                itemBuilder: (context, index) {
                  final tab = filteredTabs[index];
                  final tabIndex = _tabs.indexOf(tab);
                  final isActive = tabIndex == _currentTabIndex;

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeOutBack,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        _switchTab(tabIndex);
                        _toggleTabSwitcher();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: tab.isIncognito
                              ? (theme.brightness == Brightness.dark
                                    ? const Color(0xFF2B2B2B)
                                    : Colors.purple.shade50)
                              : theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? (tab.isIncognito
                                      ? Colors.purpleAccent
                                      : theme.colorScheme.onSurface)
                                : (tab.isIncognito
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface),
                            width: isActive ? 3 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color:
                                        (tab.isIncognito
                                                ? Colors.purpleAccent
                                                : theme.colorScheme.surface)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tab Header
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  // Favicon placeholder
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: tab.isIncognito
                                          ? Colors.purple.shade700
                                          : theme.colorScheme.onPrimary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      tab.isIncognito
                                          ? Icons.shield_moon_outlined
                                          : Icons.webhook_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tab.title.isEmpty ? 'New tab' : tab.title,
                                      style: TextStyle(
                                        color: tab.isIncognito
                                            ? Colors.purple.shade700
                                            : theme.colorScheme.onPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _closeTab(tabIndex);
                                      // if (_tabs.isEmpty) {
                                      //   _toggleTabSwitcher();
                                      // }
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Tab Preview (placeholder)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    tab.isIncognito
                                        ? Icons.shield_moon_outlined
                                        : Icons.tab_outlined,
                                    size: 48,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _singleMenuItem(),
              const Divider(),
              _gridMenu(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _singleMenuItem() {
    final items = [
      MenuBottomItem(Icons.star, "Favorites", Colors.white, () {
        Navigator.pop(context);
        _showBookmarksModal(context);
      }),
      MenuBottomItem(Icons.history, "History", Colors.white, () {
        Navigator.pop(context);
        _showHistoryModal(context);
      }),
      MenuBottomItem(Icons.download, "Downloads", Colors.white, () {
        Navigator.pop(context); // Close modal
        widget.onTabRequested(3); // Switch to "Offline" (Downloaded) tab
      }),
      MenuBottomItem(Icons.settings, "Settings", Colors.white, () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      }),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (item) => InkWell(
                onTap: item.onActions,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: Colors.white, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _gridMenu() {
    final items = [
      MenuBottomItem(Icons.home, "Home", Colors.white, () {
        Navigator.pop(context);
        _toggleTabSwitcher();
      }),
      MenuBottomItem(Icons.security, "InPrivate Tab", Colors.white, () {
        Navigator.pop(context);
        _addNewTab(isIncognito: true);
        _toggleTabSwitcher();
      }),
      MenuBottomItem(
        _isDesktopMode ? Icons.desktop_mac_rounded : Icons.mobile_friendly,
        _isDesktopMode ? "Desktop Mode" : "Mobile Mode",
        Colors.white,
        () {
          Navigator.pop(context);
          _toggleDesktopMode();
        },
      ),
      MenuBottomItem(
        Icons.cleaning_services,
        "Delete data",
        Colors.redAccent,
        () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete data"),
              content: const Text("Are you sure you want to delete all data?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    _removeAllHistory();
                    _removeAllBookmarks();
                    _remoteAllFiles();
                    Navigator.pop(context);
                  },
                  child: const Text("Delete"),
                ),
              ],
            ),
          );
        },
      ),
      MenuBottomItem(Icons.extension, "Extentions", Colors.white, () {
        Navigator.pop(context); // Close results from _showSettingsModal
        _showCapturedVideosModal(context);
      }),
      MenuBottomItem(Icons.share_outlined, "Share", Colors.white, () {}),
      MenuBottomItem(Icons.web, "Inspect Web", Colors.white, () {
        Navigator.pop(context); // Close results from _showSettingsModal
        _openInspect();
      }),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: MediaQuery.of(context).size.width > 500 ? 1.7 : 1.1,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: item.onActions,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 26),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: item.color, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => HistoryModal(
          history: _history,
          onUrlSelected: (url) {
            Navigator.pop(context);
            if (_currentTab != null) {
              setState(() {
                _currentTab!.showHome = false;
              });
            }
            if (_isWindows) {
              _winController?.loadUrl(url);
            } else {
              _mobController?.loadRequest(Uri.parse(url));
            }
          },
          onClearHistory: () {
            setState(() {
              _history.clear();
            });
            _saveHistory();
            setStateModal(() {});
          },
          onRemoveEntry: (index) {
            setState(() {
              _history.removeAt(index);
            });
            _saveHistory();
            setStateModal(() {});
          },
        ),
      ),
    );
  }

  void _showCapturedVideosModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CapturedVideosModal(
        videos: _detectedVideos,
        onlineVideos: widget.onlineVideos,
        onAdd: (video) {
          widget.onVideoCaptured(video);
        },
        onRemove: (video) {
          widget.onVideoRemoved(video);
        },
        onVideosUpdated: (newList) {
          widget.onVideosUpdated(newList);
        },
        onClear: () {
          setState(() {
            _detectedVideos.clear();
          });
          Navigator.pop(context);
        },
        onTabRequested: widget.onTabRequested,
      ),
    );
  }

  void _showBookmarksModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => BookmarksModal(
          bookmarks: _bookmarks,
          currentUrl: _currentUrl,
          onUrlSelected: (url) {
            Navigator.pop(context);
            if (_currentTab != null) {
              setState(() {
                _currentTab!.showHome = false;
              });
            }
            if (_isWindows) {
              _winController?.loadUrl(url);
            } else {
              _mobController?.loadRequest(Uri.parse(url));
            }
          },
          onAddBookmark: () async {
            await _addBookmark();
            setStateModal(() {});
          },
          onRemoveBookmark: (url) {
            _removeBookmark(url);
            setStateModal(() {});
          },
        ),
      ),
    );
  }
}
