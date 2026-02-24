import 'package:flutter/material.dart';
import '../models/browser_tab.dart';

class BrowserTabController extends ChangeNotifier {
  final List<BrowserTab> _tabs = [];
  int _currentTabIndex = 0;
  bool _isDesktopMode = false;

  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int get currentTabIndex => _currentTabIndex;
  bool get isDesktopMode => _isDesktopMode;

  BrowserTab? get currentTab =>
      _tabs.isNotEmpty &&
          _currentTabIndex >= 0 &&
          _currentTabIndex < _tabs.length
      ? _tabs[_currentTabIndex]
      : null;

  void addTab(BrowserTab tab) {
    _tabs.add(tab);
    _currentTabIndex = _tabs.length - 1;
    notifyListeners();
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) return;

    // Caller should handle controller disposal
    _tabs.removeAt(index);
    if (_currentTabIndex >= _tabs.length) {
      _currentTabIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void clearAllTabsExceptNew(BrowserTab placeholder) {
    // Caller should handle controller disposal
    _tabs.clear();
    _tabs.add(placeholder);
    _currentTabIndex = 0;
    notifyListeners();
  }

  void switchToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  void setDesktopMode(bool value) {
    _isDesktopMode = value;
    notifyListeners();
  }

  void updateTabUrl(int index, String url) {
    if (index >= 0 && index < _tabs.length) {
      _tabs[index].url = url;
      notifyListeners();
    }
  }

  void updateTabTitle(int index, String title) {
    if (index >= 0 && index < _tabs.length) {
      _tabs[index].title = title;
      notifyListeners();
    }
  }

  void updateTabLoadingProgress(int index, double progress) {
    if (index >= 0 && index < _tabs.length) {
      _tabs[index].loadingProgress = progress;
      notifyListeners();
    }
  }
}
