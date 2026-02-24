import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/browser/browser_modals.dart';
import '../widgets/speed_dial.dart';

import 'package:webview_windows/webview_windows.dart' as win;
import '../models/video_item.dart';
import '../models/browser_tab.dart';
import '../services/storage_service.dart';
import '../services/webview_service.dart';
import '../controllers/browser_tab_controller.dart';
import '../widgets/browser/address_bar.dart';
import '../widgets/browser/navigation_controls.dart';
import '../widgets/browser/tab_switcher.dart';

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

  // Tab & Browser Logic
  final BrowserTabController _tabController = BrowserTabController();
  final ScrollController _tabScrollController = ScrollController();
  final _textController = TextEditingController(text: 'https://www.google.com');
  final TextEditingController _tabSearchController = TextEditingController();

  String? _errorMessage;
  final List<VideoItem> _detectedVideos = [];
  List<Map<String, String>> _bookmarks = [];
  List<Map<String, String>> _history = [];
  String? _lastCandidateThumbnail;
  bool _showTabSwitcher = false;

  // Animation controllers
  late AnimationController _pageTransitionController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;

  late AnimationController _tabSwitcherController;
  late Animation<double> _tabSwitcherFadeAnimation;
  late Animation<double> _tabSwitcherScaleAnimation;
  late Animation<double> _contentScaleAnimation;

  // Helper getters
  BrowserTab? get _currentTab => _tabController.currentTab;
  win.WebviewController? get _winController => _currentTab?.winController;
  bool get _isInitialized => _currentTab?.isInitialized ?? false;
  String get _currentUrl => _currentTab?.url ?? 'https://www.google.com';
  double get _loadingProgress => _currentTab?.loadingProgress ?? 0;
  bool get _showHome => _currentTab?.showHome ?? true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Controllers
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

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

    _addNewTab();
    _pageTransitionController.forward();
  }

  Future<void> _loadInitialData() async {
    _bookmarks = await StorageService.loadBookmarks();
    _history = await StorageService.loadHistory();
    if (mounted) setState(() {});
  }

  void _toggleTabSwitcher() {
    setState(() => _showTabSwitcher = !_showTabSwitcher);
    _showTabSwitcher
        ? _tabSwitcherController.forward()
        : _tabSwitcherController.reverse();
  }

  void _addToHistory(String url, String title) {
    if (url == 'about:blank' || url.isEmpty) {
      return;
    }
    setState(() {
      _history.removeWhere((item) => item['url'] == url);
      _history.insert(0, {
        'url': url,
        'title': title.isEmpty ? url : title,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (_history.length > 100) {
        _history = _history.sublist(0, 100);
      }
    });
    StorageService.saveHistory(_history);
  }

  Future<void> _addBookmark() async {
    String title = _currentUrl;
    if (WebviewService.isWindows) {
      final jsTitle = await _winController?.executeScript('document.title');
      if (jsTitle != null) {
        String rawTitle = jsTitle.toString();
        if (rawTitle.startsWith('"') &&
            rawTitle.endsWith('"') &&
            rawTitle.length >= 2) {
          rawTitle = rawTitle.substring(1, rawTitle.length - 1);
        }
        if (rawTitle.isNotEmpty) title = rawTitle;
      }
    }

    if (!_bookmarks.any((b) => b['url'] == _currentUrl)) {
      setState(() => _bookmarks.add({'url': _currentUrl, 'title': title}));
      unawaited(StorageService.saveBookmarks(_bookmarks));
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

  void _removeBookmark(String url) {
    setState(() => _bookmarks.removeWhere((b) => b['url'] == url));
    StorageService.saveBookmarks(_bookmarks);
  }

  void _addNewTab({bool isIncognito = false}) {
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: 'https://www.google.com',
      title: isIncognito ? 'InPrivate Tab' : 'New Tab',
      isIncognito: isIncognito,
    );

    _tabController.addTab(newTab);
    _textController.text = newTab.url;
    _startInitialization();

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
    if (_tabController.tabs.length <= 1) {
      setState(() => _currentTab?.showHome = true);
      return;
    }
    _tabController.tabs[index].winController?.dispose();
    _tabController.closeTab(index);
    _textController.text = _currentTab?.url ?? '';
  }

  void _clearAllTabs() {
    for (var tab in _tabController.tabs) {
      tab.winController?.dispose();
    }
    _tabController.clearAllTabsExceptNew(
      BrowserTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: 'https://www.google.com',
        title: 'New Tab',
      ),
    );
    _startInitialization();
  }

  void _switchTab(int index) async {
    if (index == _tabController.currentTabIndex) {
      return;
    }
    await _pageTransitionController.reverse();
    _tabController.switchToTab(index);
    _textController.text = _currentTab?.url ?? '';
    await _pageTransitionController.forward();
  }

  void _startInitialization() {
    if (_currentTab == null) {
      return;
    }
    setState(() {
      _currentTab!.isInitialized = false;
      _errorMessage = null;
    });
    _initWindowsWebview();
  }

  Future<void> _initWindowsWebview() async {
    if (_currentTab == null) {
      return;
    }
    try {
      if (!_isEnvInitialized) {
        try {
          await win.WebviewController.initializeEnvironment();
        } catch (e) {
          if (!e.toString().contains('environment_already_initialized')) {
            rethrow;
          }
        }
        _isEnvInitialized = true;
      }

      final controller = win.WebviewController();
      await controller.initialize();
      await controller.addScriptToExecuteOnDocumentCreated(
        WebviewService.browserShieldScript,
      );

      if (_tabController.isDesktopMode) {
        await controller.addScriptToExecuteOnDocumentCreated('''
          Object.defineProperty(navigator, 'userAgent', { get: () => '${WebviewService.desktopUserAgent}' });
          Object.defineProperty(navigator, 'platform', { get: () => 'Win32' });
        ''');
      }

      await controller.addScriptToExecuteOnDocumentCreated(
        WebviewService.captureScript,
      );

      controller.webMessage.listen((message) {
        try {
          final data = (message is String)
              ? jsonDecode(message)
              : Map<String, dynamic>.from(message);
          if (data['type'] == 'm3u8_captured') {
            final url = data['url'] as String;
            if (!_detectedVideos.any((v) => v.url == url)) {
              if (mounted) {
                setState(
                  () => _detectedVideos.add(
                    VideoItem(
                      title: data['title'] ?? 'Captured Video',
                      url: url,
                      thumbnailUrl: _lastCandidateThumbnail,
                    ),
                  ),
                );
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
          _tabController.updateTabUrl(
            _tabController.tabs.indexOf(_currentTab!),
            url,
          );
          _textController.text = url;
        }
      });

      controller.loadingState.listen((state) async {
        if (_currentTab?.winController != controller) {
          return;
        }
        if (state == win.LoadingState.loading) {
          _lastCandidateThumbnail = null;
          if (mounted) {
            _tabController.updateTabLoadingProgress(
              _tabController.tabs.indexOf(_currentTab!),
              0.5,
            );
          }
        } else if (state == win.LoadingState.navigationCompleted) {
          if (mounted) {
            _tabController.updateTabLoadingProgress(
              _tabController.tabs.indexOf(_currentTab!),
              1.0,
            );
          }
          final jsTitle = await controller.executeScript('document.title');
          if (jsTitle != null) {
            final String title = jsTitle.toString().replaceAll('"', '');
            if (title.isNotEmpty) {
              _tabController.updateTabTitle(
                _tabController.tabs.indexOf(_currentTab!),
                title,
              );
              if (!(_currentTab?.isIncognito ?? false)) {
                _addToHistory(_currentTab!.url, title);
              }
            }
          }
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _tabController.updateTabLoadingProgress(
                _tabController.tabs.indexOf(_currentTab!),
                0,
              );
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
      if (mounted) {
        setState(
          () => _errorMessage =
              'Initialization Error: $e.\n\nPlease ensure Microsoft WebView2 Runtime is installed.',
        );
      }
    }
  }

  void _onUrlSubmitted(String value) {
    if (!_isInitialized || _currentTab == null) return;
    final String input = value.trim();
    if (input.isEmpty) return;

    setState(() => _currentTab!.showHome = false);

    String url = input;
    final bool isSearch =
        input.contains(' ') ||
        (!input.contains('.') && !input.startsWith('http'));
    if (isSearch) {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
    } else if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    _winController?.loadUrl(url);
  }

  void _goBack() => _winController?.goBack();
  void _goForward() => _winController?.goForward();
  void _reload() => _winController?.reload();
  void _goHome() {
    if (_currentTab != null) {
      setState(() => _currentTab!.showHome = true);
    }
  }

  @override
  void dispose() {
    for (final tab in _tabController.tabs) {
      tab.winController?.dispose();
    }
    _tabController.dispose();
    _textController.dispose();
    _tabScrollController.dispose();
    _tabSearchController.dispose();
    _pageTransitionController.dispose();
    _tabSwitcherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) return _buildErrorState();

    return Column(
      children: [
        Expanded(
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;

              if (event.logicalKey == LogicalKeyboardKey.f5) {
                _reload();
                return KeyEventResult.handled;
              }

              final isControl = HardwareKeyboard.instance.isControlPressed;
              final isAlt = HardwareKeyboard.instance.isAltPressed;

              if (isControl && event.logicalKey == LogicalKeyboardKey.keyR) {
                _reload();
                return KeyEventResult.handled;
              }

              if (isAlt && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _goBack();
                return KeyEventResult.handled;
              }

              if (isAlt && event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _goForward();
                return KeyEventResult.handled;
              }

              if (isControl && event.logicalKey == LogicalKeyboardKey.keyT) {
                _addNewTab();
                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: _currentTab == null
                ? const Center(child: Text('No tabs open'))
                : Stack(
                    children: [
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
                                : win.Webview(_winController!),
                          ),
                        ),
                      ),
                      if (_showHome)
                        SpeedDial(
                          bookmarks: _bookmarks,
                          onUrlSelected: (url) {
                            setState(() => _currentTab!.showHome = false);
                            _onUrlSubmitted(url);
                          },
                        ),
                      FadeTransition(
                        opacity: _tabSwitcherFadeAnimation,
                        child: ScaleTransition(
                          scale: _tabSwitcherScaleAnimation,
                          child:
                              _showTabSwitcher ||
                                  _tabSwitcherController.isAnimating
                              ? TabSwitcher(
                                  tabs: _tabController.tabs,
                                  currentTabIndex:
                                      _tabController.currentTabIndex,
                                  onTabSelected: (idx) {
                                    _switchTab(idx);
                                    _toggleTabSwitcher();
                                  },
                                  onTabClosed: _closeTab,
                                  onAddNewTab: _addNewTab,
                                  onAddCustomTab: ({required isIncognito}) =>
                                      _addNewTab(isIncognito: isIncognito),
                                  onClearAll: _clearAllTabs,
                                  onToggle: _toggleTabSwitcher,
                                  searchController: _tabSearchController,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        AddressBar(
          textController: _textController,
          onSubmitted: _onUrlSubmitted,
          onReload: _reload,
          onBookmark: _addBookmark,
          loadingProgress: _loadingProgress,
          isIncognito: _currentTab?.isIncognito ?? false,
          isInitialized: _isInitialized,
        ),
        BrowserNavigationControls(
          onHome: _goHome,
          onBack: _goBack,
          onForward: _goForward,
          onAddTab: _addNewTab,
          onToggleTabSwitcher: _toggleTabSwitcher,
          onMenu: () => _showSettingsModal(context),
          tabCount: _tabController.tabs.length,
          detectedVideosCount: _detectedVideos.length,
          isIncognito: _currentTab?.isIncognito ?? false,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.webhook_outlined, size: 64, color: Colors.orange),
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

  void _showSettingsModal(BuildContext context) {
    BrowserModals.showSettingsModal(
      context: context,
      isDesktopMode: _tabController.isDesktopMode,
      onGoHome: _goHome,
      onAddNewTab: _addNewTab,
      onClearAllData: () {
        _history.clear();
        _bookmarks.clear();
        StorageService.clearAllStorage();
        setState(() {});
      },
      bookmarks: _bookmarks,
      history: _history,
      detectedVideos: _detectedVideos,
      onlineVideos: widget.onlineVideos,
      onVideoCaptured: widget.onVideoCaptured,
      onVideoRemoved: widget.onVideoRemoved,
      onVideosUpdated: widget.onVideosUpdated,
      onTabRequested: widget.onTabRequested,
      onUrlSelected: _onUrlSubmitted,
      currentUrl: _currentUrl,
      onAddBookmark: _addBookmark,
      onRemoveBookmark: _removeBookmark,
    );
  }
}
