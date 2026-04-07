import 'dart:io';
import 'package:flutter/foundation.dart';

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
    final bool isWindows = !kIsWeb && Platform.isWindows;
    final String targetUA = isWindows ? desktopUserAgent : mobileUserAgent;
    final String platform = isWindows ? 'Win32' : 'Linux armv8l';

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

  /// A JavaScript snippet that blocks common ads via CSS, DOM removal, and network interception.
  static const String adblockScript = r'''
    (function() {
      // 1. Hide Ad Elements via CSS
      const style = document.createElement('style');
      style.innerHTML = `
        .ad, .ads, .advert, .advertisement,
        [id^="ad-"], [class*=" ad "], [class*="-ad-"],
        .google-auto-placed, .adsbygoogle,
        div[id^="div-gpt-ad"], iframe[src*="ads"], iframe[src*="doubleclick"] {
          display: none !important;
          width: 0 !important;
          height: 0 !important;
        }
      `;
      document.head.appendChild(style);

      // 2. Remove Ad Elements actively
      function removeAds() {
        const adSelectors = [
          'iframe[src*="doubleclick.net"]',
          'iframe[src*="ads"]',
          '.adsbygoogle',
          '[id^="div-gpt-ad"]',
          'div[data-ad-unit]',
          'div[data-ad]',
          'a[href*="/ad/"]',
          '.ad-container'
        ];
        
        adSelectors.forEach(selector => {
          document.querySelectorAll(selector).forEach(el => el.remove());
        });
      }

      removeAds();
      setInterval(removeAds, 2000);

      // 3. Block Ad Requests
      const adDomains = [
        'doubleclick.net',
        'googlesyndication.com',
        'adsystem.com',
        'adnxs.com',
        'adsafeprotected.com',
        'criteo.com',
        'taboola.com',
        'outbrain.com',
        'popads.net',
        'popcash.net',
        'adsterra.com',
        'onclickads.net',
        'exoclick.com',
        'propellerads.com'
      ];

      function isAdUrl(url) {
        if (!url || typeof url !== 'string') return false;
        try {
           const urlObj = new URL(url, window.location.origin);
           return adDomains.some(domain => urlObj.hostname.includes(domain));
        } catch(e) {
           return false;
        }
      }

      // Hook Fetch for Ads
      const originalFetch = window.fetch;
      window.fetch = async function(...args) {
        const urlArgs = args[0];
        let reqUrl = '';
        if (typeof urlArgs === 'string') {
           reqUrl = urlArgs;
        } else if (urlArgs && urlArgs.url) {
           reqUrl = urlArgs.url;
        }

        if (isAdUrl(reqUrl)) {
          console.log("AdBlock: Blocked fetch request to " + reqUrl);
          // Return an empty success response for blocked ads
          return new Response(null, { status: 200, statusText: 'OK' });
        }
        return originalFetch.apply(this, args);
      };

      // Hook XHR for Ads
      const originalXHR = window.XMLHttpRequest;
      function newXHR() {
        const xhr = new originalXHR();
        const originalOpen = xhr.open;
        xhr.open = function(method, url) {
          if (isAdUrl(url)) {
            console.log("AdBlock: Blocked XHR request to " + url);
            this.send = function() {
               Object.defineProperty(this, 'readyState', { value: 4 });
               Object.defineProperty(this, 'status', { value: 200 });
               if (this.onload) this.onload();
            };
            return;
          }
          return originalOpen.apply(this, arguments);
        };
        return xhr;
      }
      Object.assign(newXHR, originalXHR);
      newXHR.prototype = originalXHR.prototype;
      window.XMLHttpRequest = newXHR;
      
      console.log("AdBlock Script Initialized");
    })();
  ''';

  /// A JavaScript snippet that intercepts network requests to capture M3U8/MP4 URLs and images.
  /// It also includes an auto-scroll bot designed for Instagram reels.
  static const String captureScript = r'''
    (function() {
      // Regex for matching common media file extensions
      const mediaRegex = /\.(mp4|m3u8|webm|ts|flv|avi|mkv|mov|mp3|m4a|aac|wav|ogg)(\?.*)?$/i;
      
      // Keep track of notified URLs to prevent spamming the same link
      const notifiedUrls = new Set();

      function notifyFlutter(url, customTitle) {
        if (!url || typeof url !== 'string' || url.startsWith('blob:') || url.startsWith('data:')) return;
        
        // Check if URL matches media extensions or known social media domains (if we parse them later)
        let isMedia = mediaRegex.test(url);
        
        // For non-extension URLs, we rely on the caller (like FB/IG JSON scanner)
        if (!isMedia && !customTitle) {
           return; 
        }

        // Clean URL
        const cleanUrl = url.replace(/\\u0026/g, '&').replace(/\\\//g, '/');
        if (notifiedUrls.has(cleanUrl)) return;
        
        notifiedUrls.add(cleanUrl);

        let fileName = customTitle;
        if (!fileName) {
           try {
             fileName = cleanUrl.split('/').pop().split('?')[0];
             if (!mediaRegex.test(fileName)) {
                fileName = "Media_" + Math.random().toString(36).substring(7);
             }
           } catch(e) {
             fileName = "Media_" + Math.random().toString(36).substring(7);
           }
        }

        const message = JSON.stringify({ type: 'm3u8_captured', url: cleanUrl, title: fileName });
        if (window.chrome && window.chrome.webview) {
          window.chrome.webview.postMessage(message);
        } else if (window.m3u8_captured) {
          window.m3u8_captured.postMessage(message);
        }
      }

      // 1. Check loaded video/audio elements directly (MutationObserver is better but interval is safer for IFrames/Dynamic)
      setInterval(() => {
        const mediaElements = document.querySelectorAll('video, audio, source');
        mediaElements.forEach(elem => {
          if (elem.src && !elem.dataset.idmCaptured) {
             elem.dataset.idmCaptured = true;
             notifyFlutter(elem.src, "HTML_Media_" + Math.random().toString(36).substring(7));
          }
        });
      }, 1500);

      // 2. Deep scan JSON for video URLs (for GraphQL Instagram & Facebook responses)
      function scanVideoUrls(obj) {
        if (!obj) return;
        if (typeof obj === 'string') {
          if (obj.startsWith('http') && mediaRegex.test(obj)) {
            notifyFlutter(obj, "Social_Media_" + Math.random().toString(36).substring(7));
          }
        } else if (Array.isArray(obj)) {
          obj.forEach(scanVideoUrls);
        } else if (typeof obj === 'object') {
          for (const key in obj) {
            if (key === 'video_versions' && Array.isArray(obj[key])) {
              obj[key].forEach(v => { if(v.url) notifyFlutter(v.url, "IG_Reel_" + Math.random().toString(36).substring(7)); });
            } else if (key === 'video_url' && typeof obj[key] === 'string') {
              notifyFlutter(obj[key], "IG_Video_" + Math.random().toString(36).substring(7));
            } else if ((key === 'playable_url' || key === 'playable_url_quality_hd' || key === 'browser_native_hd_url') && typeof obj[key] === 'string') {
              notifyFlutter(obj[key], "FB_Video_" + Math.random().toString(36).substring(7));
            } else {
              scanVideoUrls(obj[key]);
            }
          }
        }
      }

      // 3. Hook Fetch API to catch media requests
      const originalFetch = window.fetch;
      window.fetch = async function(...args) {
        const urlArgs = args[0];
        let reqUrl = '';
        if (typeof urlArgs === 'string') {
           reqUrl = urlArgs;
        } else if (urlArgs && urlArgs.url) {
           reqUrl = urlArgs.url;
        }

        // Catch direct media calls
        notifyFlutter(reqUrl);

        const response = await originalFetch.apply(this, args);
        try {
          const clone = response.clone();
          
          // Check header for media content type
          const contentType = clone.headers.get('content-type') || clone.headers.get('Content-Type');
          if (contentType && (contentType.includes('video/') || contentType.includes('audio/') || contentType.includes('application/x-mpegURL'))) {
             notifyFlutter(response.url, "Stream_" + Math.random().toString(36).substring(7));
          }

          clone.text().then(text => {
            // Check response body for video URLs
            if (text.includes('video_versions') || text.includes('playable_url') || text.includes('.mp4') || text.includes('.m3u8')) {
               try {
                  const json = JSON.parse(text);
                  scanVideoUrls(json);
               } catch(e) {
                  // Fallback to regex
                  const urls = text.match(/https:\/\/[^"'\s\\]+\.(mp4|m3u8|webm|ts|flv|avi)[^"'\s\\]*/gi);
                  if (urls) urls.forEach(u => notifyFlutter(u, "Regex_Media_" + Math.random().toString(36).substring(7)));
               }
            }
          }).catch(e => {});
        } catch(e) {}
        return response;
      };

      // 4. Hook XMLHttpRequest to catch media requests
      const originalXHR = window.XMLHttpRequest;
      function newXHR() {
        const xhr = new originalXHR();
        
        const originalOpen = xhr.open;
        xhr.open = function(method, url) {
           notifyFlutter(url);
           return originalOpen.apply(this, arguments);
        };

        xhr.addEventListener('load', function() {
          try {
            if (xhr.responseURL) notifyFlutter(xhr.responseURL);
            
            const contentType = xhr.getResponseHeader('Content-Type');
            if (contentType && (contentType.includes('video/') || contentType.includes('audio/') || contentType.includes('application/x-mpegURL'))) {
               notifyFlutter(xhr.responseURL, "Stream_" + Math.random().toString(36).substring(7));
            }

            if (xhr.responseType === '' || xhr.responseType === 'text') {
              const text = xhr.responseText;
              if (text && (text.includes('video_versions') || text.includes('playable_url') || text.includes('.mp4') || text.includes('.m3u8'))) {
                 try {
                    const json = JSON.parse(text);
                    scanVideoUrls(json);
                 } catch(e) {
                    const urls = text.match(/https:\/\/[^"'\s\\]+\.(mp4|m3u8|webm|ts|flv|avi)[^"'\s\\]*/gi);
                    if (urls) urls.forEach(u => notifyFlutter(u, "Regex_Media_" + Math.random().toString(36).substring(7)));
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

      // 5. Auto-bot for scrolling (FB/IG)
      window.startAutoBot = function(intervalMs = 3000) {
        if (window.autoBotInterval) clearInterval(window.autoBotInterval);
        const isInstagram = window.location.href.includes('instagram.com');
        const isFacebook = window.location.href.includes('facebook.com');
        
        window.autoBotInterval = setInterval(() => {
          if (isInstagram || isFacebook) {
             const event = new KeyboardEvent('keydown', { key: 'ArrowDown', code: 'ArrowDown', keyCode: 40, which: 40, bubbles: true });
             document.dispatchEvent(event);
             window.scrollBy({ top: window.innerHeight, behavior: 'smooth' });
          } else {
             window.scrollBy({ top: window.innerHeight * 0.8, behavior: 'smooth' });
          }
        }, intervalMs);
      };

      window.stopAutoBot = function() {
        if (window.autoBotInterval) {
           clearInterval(window.autoBotInterval);
           window.autoBotInterval = null;
        }
      };

      console.log("IDM-Style Media Sniffer & Bot Hook Initialized");
    })();
  ''';

  /// Returns true if the current platform is Windows.
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Returns the desktop user agent string.
  static String getDesktopUA() => desktopUserAgent;
}
