import 'dart:io';

/// A service class that handles WebView-specific logic, including user agents and scripts.
class WebviewService {
  /// The user agent string used to spoof a desktop browser.
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  /// The user agent string used to spoof a mobile browser (bypasses Google's blocking).
  static const String mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

  /// A JavaScript snippet that masks webview identifiers to avoid detection by websites.
  static String getBrowserShieldScript() {
    final String targetUA = Platform.isWindows
        ? desktopUserAgent
        : mobileUserAgent;
    final String platform = Platform.isWindows ? 'Win32' : 'Linux armv8l';

    return '''
    (function() {
      // Hide webdriver
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
      
      // Ensure languages are set
      Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
      
      // Spoof plugins to look like real Chrome
      Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });

      // Override userAgent to bypass "Disallowed UserAgent" errors
      const targetUA = '$targetUA';
      Object.defineProperty(navigator, 'userAgent', { get: () => targetUA });
      Object.defineProperty(navigator, 'platform', { get: () => '$platform' });
    })();
  ''';
  }

  /// A JavaScript snippet that intercepts network requests to capture M3U8/MP4 URLs and images.
  /// It also includes an auto-scroll bot designed for Instagram reels.
  static const String captureScript = r'''
    (function() {
      function notifyFlutter(url, customTitle) {
        if (!url) return;
        // Accept m3u8 or common video formats found on social media (mp4)
        if (url.includes('.m3u8') || url.includes('.mp4')) {
          const fileName = customTitle || url.split('/').pop().split('?')[0];
          const message = JSON.stringify({ type: 'm3u8_captured', url: url, title: fileName });
          if (window.chrome && window.chrome.webview) {
            window.chrome.webview.postMessage(message);
          } else if (window.m3u8_captured) {
            window.m3u8_captured.postMessage(message);
          }
        } else if (url.match(/\.(jpg|jpeg|png|webp)(\?.*)?$/i)) {
          const message = JSON.stringify({ type: 'thumbnail_captured', url: url });
          if (window.chrome && window.chrome.webview) {
            window.chrome.webview.postMessage(message);
          } else if (window.m3u8_captured) {
            window.m3u8_captured.postMessage(message);
          }
        }
      }

      // Check loaded video elements directly
      setInterval(() => {
        const videos = document.querySelectorAll('video');
        videos.forEach(v => {
          if (v.src && !v.dataset.captured) {
             v.dataset.captured = true;
             notifyFlutter(v.src, "HTML_Video_" + Math.random().toString(36).substring(7));
          }
        });
      }, 2000);

      // Deep scan JSON for video URLs (for GraphQL Instagram & Facebook responses)
      function scanVideoUrls(obj) {
        if (!obj) return;
        if (typeof obj === 'string') {
          if (obj.startsWith('http') && (obj.includes('.mp4') || obj.includes('.m3u8'))) {
            notifyFlutter(obj.replace(/\\u0026/g, '&').replace(/\\\//g, '/'), "Social_Video_" + Math.random().toString(36).substring(7));
          }
        } else if (Array.isArray(obj)) {
          obj.forEach(scanVideoUrls);
        } else if (typeof obj === 'object') {
          for (const key in obj) {
            if (key === 'video_versions' && Array.isArray(obj[key])) {
              obj[key].forEach(v => { if(v.url) notifyFlutter(v.url.replace(/\\u0026/g, '&').replace(/\\\//g, '/'), "IG_Reel_" + Math.random().toString(36).substring(7)); });
            } else if (key === 'video_url' && typeof obj[key] === 'string') {
              notifyFlutter(obj[key].replace(/\\u0026/g, '&').replace(/\\\//g, '/'), "IG_Video_" + Math.random().toString(36).substring(7));
            } else if ((key === 'playable_url' || key === 'playable_url_quality_hd' || key === 'browser_native_hd_url') && typeof obj[key] === 'string') {
              notifyFlutter(obj[key].replace(/\\u0026/g, '&').replace(/\\\//g, '/'), "FB_Video_" + Math.random().toString(36).substring(7));
            } else {
              scanVideoUrls(obj[key]);
            }
          }
        }
      }

      // Hook Fetch API
      const originalFetch = window.fetch;
      window.fetch = async function(...args) {
        const response = await originalFetch.apply(this, args);
        try {
          const clone = response.clone();
          clone.text().then(text => {
            // Send original URL first
            notifyFlutter(response.url);
            
            // Check response body for video URLs
            if (text.includes('video_versions') || text.includes('playable_url') || text.includes('.mp4')) {
               try {
                  const json = JSON.parse(text);
                  scanVideoUrls(json);
               } catch(e) {
                  // Fallback to regex
                  const urls = text.match(/https:\/\/[^"'\s\\]+\.(mp4|m3u8)[^"'\s\\]*/gi);
                  if (urls) urls.forEach(u => notifyFlutter(u.replace(/\\u0026/g, '&').replace(/\\\//g, '/'), "Regex_Video_" + Math.random().toString(36).substring(7)));
               }
            }
          }).catch(e => {});
        } catch(e) {}
        return response;
      };

      // Hook XMLHttpRequest
      const originalXHR = window.XMLHttpRequest;
      function newXHR() {
        const xhr = new originalXHR();
        xhr.addEventListener('load', function() {
          try {
            if (xhr.responseURL) notifyFlutter(xhr.responseURL);
            if (xhr.responseType === '' || xhr.responseType === 'text') {
              const text = xhr.responseText;
              if (text && (text.includes('video_versions') || text.includes('playable_url') || text.includes('.mp4'))) {
                 try {
                    const json = JSON.parse(text);
                    scanVideoUrls(json);
                 } catch(e) {
                    const urls = text.match(/https:\/\/[^"'\s\\]+\.(mp4|m3u8)[^"'\s\\]*/gi);
                    if (urls) urls.forEach(u => notifyFlutter(u.replace(/\\u0026/g, '&').replace(/\\\//g, '/'), "Regex_Video_" + Math.random().toString(36).substring(7)));
                 }
              }
            }
          } catch(e) {}
        });
        return xhr;
      }
      Object.assign(newXHR, originalXHR);
      newXHR.prototype = originalXHR.prototype;
      window.XMLHttpRequest = newXHR;

      // Auto-Bot Methods
      window.startAutoBot = function(intervalMs = 3000) {
        if (window.autoBotInterval) clearInterval(window.autoBotInterval);
        
        // Define scrolling strategy based on the current domain
        const isInstagram = window.location.href.includes('instagram.com');
        const isFacebook = window.location.href.includes('facebook.com');
        
        window.autoBotInterval = setInterval(() => {
          if (isInstagram || isFacebook) {
             // Simulate arrow down to scroll reels
             const event = new KeyboardEvent('keydown', { key: 'ArrowDown', code: 'ArrowDown', keyCode: 40, which: 40, bubbles: true });
             document.dispatchEvent(event);
             // Also try window scroll
             window.scrollBy({ top: window.innerHeight, behavior: 'smooth' });
          } else {
             // generic scroll down
             window.scrollBy({ top: window.innerHeight * 0.8, behavior: 'smooth' });
          }
        }, intervalMs);
        console.log("Auto bot started with interval: " + intervalMs);
      };

      window.stopAutoBot = function() {
        if (window.autoBotInterval) {
           clearInterval(window.autoBotInterval);
           window.autoBotInterval = null;
           console.log("Auto bot stopped");
        }
      };

      console.log("Capture & Bot Hook Initialized");
    })();
  ''';

  /// Returns true if the current platform is Windows.
  static bool get isWindows => Platform.isWindows;

  /// Returns the desktop user agent string.
  static String getDesktopUA() => desktopUserAgent;
}
