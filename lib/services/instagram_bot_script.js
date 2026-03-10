(function() {
  function sendFlutter(videoUrl) {
    if (!videoUrl) return;
    // Bỏ qua nếu không phải link video hợp lệ
    if (!videoUrl.includes('.mp4') && !videoUrl.includes('.m3u8')) {
      return;
    }
    const fileName = "IG_Reel_" + Math.random().toString(36).substring(7);
    const message = JSON.stringify({ type: 'm3u8_captured', url: videoUrl, title: fileName });
    if (window.chrome && window.chrome.webview) {
      window.chrome.webview.postMessage(message);
    } else if (window.m3u8_captured) {
      window.m3u8_captured.postMessage(message);
    }
  }

  // Quét đệ quy object JSON để tìm link video
  function findVideosInJSON(obj) {
    if (typeof obj === 'string') {
      if (obj.startsWith('http') && (obj.includes('.mp4') || obj.includes('.m3u8'))) {
        sendFlutter(obj);
      }
    } else if (Array.isArray(obj)) {
      obj.forEach(item => findVideosInJSON(item));
    } else if (obj && typeof obj === 'object') {
      // Các key phổ biến của IG cho video
      if (obj.video_versions && Array.isArray(obj.video_versions)) {
        obj.video_versions.forEach(v => {
          if (v.url) sendFlutter(v.url);
        });
      }
      for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
          findVideosInJSON(obj[key]);
        }
      }
    }
  }

  // Intercept XHR responses để lấy được JSON graphql của Instagram
  const originalXHR = window.XMLHttpRequest;
  function newXHR() {
    const xhr = new originalXHR();
    xhr.addEventListener('load', function() {
      try {
        if (xhr.responseType === '' || xhr.responseType === 'text') {
          if (xhr.responseText.includes('video_versions') || xhr.responseText.includes('.mp4')) {
            const json = JSON.parse(xhr.responseText);
            findVideosInJSON(json);
          }
        }
      } catch (e) {}
    });
    return xhr;
  }
  window.XMLHttpRequest = newXHR;

  // Intercept Fetch API
  const originalFetch = window.fetch;
  window.fetch = async function(...args) {
    const response = await originalFetch.apply(this, args);
    try {
      const clone = response.clone();
      clone.text().then(text => {
        if (text.includes('video_versions') || text.includes('.mp4')) {
          try {
             const json = JSON.parse(text);
             findVideosInJSON(json);
          } catch(err) {
             // Nếu không phải JSON, thử regex tìm URL
             const urls = text.match(/https:\/\/[^"'\s]+\.(mp4|m3u8)[^"'\s]*/g);
             if (urls) urls.forEach(u => sendFlutter(u.replace(/\\u0026/g, '&')));
          }
        }
      }).catch(e => {});
    } catch(e) {}
    return response;
  };

  // Bot tính năng tự động lướt Reel (được kích hoạt nếu đang ở IG Reels)
  window.startAutoScrollBot = function(intervalParams) {
    let interval = intervalParams || 3000;
    if (window.igAutoScroller) clearInterval(window.igAutoScroller);
    window.igAutoScroller = setInterval(() => {
        // Mô phỏng lướt xuống như người dùng ở trang instagram reels
        window.scrollBy(0, window.innerHeight);
        // Nhấn nút mũi tên xuống (phổ biến trong trình phát reel)
        const event = new KeyboardEvent('keydown', { key: 'ArrowDown', code: 'ArrowDown', keyCode: 40, which: 40, bubbles: true });
        document.dispatchEvent(event);
    }, interval);
    console.log("IG Auto Scroll Bot Started! Every", interval, "ms");
  };
  
  window.stopAutoScrollBot = function() {
    if (window.igAutoScroller) {
       clearInterval(window.igAutoScroller);
       window.igAutoScroller = null;
    }
    console.log("IG Auto Scroll Bot Stopped!");
  };

})();
