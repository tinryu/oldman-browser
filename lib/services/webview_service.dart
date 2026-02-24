import 'dart:io';

/// A service class that handles WebView-specific logic, including user agents and scripts.
class WebviewService {
  /// The user agent string used to spoof a desktop browser.
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  /// A JavaScript snippet that masks webview identifiers to avoid detection by websites.
  static const String browserShieldScript = r'''
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

  /// A JavaScript snippet that intercepts network requests to capture M3U8 URLs and images.
  static const String captureScript = r'''
    (function() {
      function notifyFlutter(url) {
        if (url.includes('.m3u8')) {
          const fileName = url.split('/').pop().split('?')[0];
          const message = JSON.stringify({ type: 'm3u8_captured', url: url, title: fileName });
          if (window.chrome && window.chrome.webview) {
            window.chrome.webview.postMessage(message);
          } else {
            // Mobile fallback if needed, though mobile uses different capture method usually
             // but keeping consistency
          }
        } else if (url.match(/\.(jpg|jpeg|png|webp)(\?.*)?$/i)) {
          const message = JSON.stringify({ type: 'thumbnail_captured', url: url });
          if (window.chrome && window.chrome.webview) {
            window.chrome.webview.postMessage(message);
          }
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

  /// Returns true if the current platform is Windows.
  static bool get isWindows => Platform.isWindows;

  /// Returns the desktop user agent string.
  static String getDesktopUA() => desktopUserAgent;
}
