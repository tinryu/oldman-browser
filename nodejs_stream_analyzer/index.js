var express = require('express');
var puppeteer = require('puppeteer');
var cors = require('cors');
var execSync = require('child_process').execSync;

// Handle CLI commands before starting the server
if (process.argv.includes('--install')) {
  console.log('Starting Puppeteer browser installation...');
  try {
    // We use the puppeteer-core or puppeteer CLI tools if available
    // For a packaged app, we might need to be clever.
    // However, simply running the command relative to node_modules (if we were in dev)
    // or assuming the environment can handle it.
    // Programmatic way is better:
    const { install } = require('@puppeteer/browsers');
    const path = require('path');
    
    async function doInstall() {
      console.log('Checking for required browser binaries...');
      // By default, puppeteer looks in ~/.cache/puppeteer
      // We can install it there.
      try {
        execSync('npx -y puppeteer browsers install chrome', { stdio: 'inherit' });
        console.log('Installation successful!');
      } catch (e) {
        console.error('Failed to install via npx. Trying internal method...');
        console.error(e.message);
      }
      process.exit(0);
    }
    
    doInstall();
    return; // Don't start the server
  } catch (err) {
    console.error('Installation error:', err.message);
    process.exit(1);
  }
}

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 3001;

// Health Check
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'stream-analyzer' });
});

// Media classification heuristics
const mediaPatterns = [
  { regex: /\.m3u8(\?.*)?$/i, type: 'HLS', format: 'm3u8' },
  { regex: /\.mpd(\?.*)?$/i,  type: 'DASH', format: 'mpd' },
  { regex: /\.mp4(\?.*)?$/i,  type: 'Progressive', format: 'mp4' },
  { regex: /\.webm(\?.*)?$/i, type: 'Progressive', format: 'webm' },
  { regex: /\.ts(\?.*)?$/i,   type: 'HLS', format: 'ts' },
  { regex: /\.flv(\?.*)?$/i,  type: 'Progressive', format: 'flv' },
  { regex: /\.mp3(\?.*)?$/i,  type: 'Progressive', format: 'mp3' },
  { regex: /\.m4a(\?.*)?$/i,  type: 'Progressive', format: 'm4a' },
  { regex: /\.m4s(\?.*)?$/i,  type: 'DASH', format: 'm4s' },
  { regex: /\.aac(\?.*)?$/i,  type: 'Progressive', format: 'aac' },
  { regex: /\.ogg(\?.*)?$/i,  type: 'Progressive', format: 'ogg' },   
  { regex: /\.mov(\?.*)?$/i,  type: 'Progressive', format: 'mov' },
  { regex: /\.mkv(\?.*)?$/i,  type: 'Progressive', format: 'mkv' }
];

const contentTypeMap = {
  'application/x-mpegurl': { type: 'HLS', format: 'm3u8' },
  'application/vnd.apple.mpegurl': { type: 'HLS', format: 'm3u8' },
  'application/dash+xml': { type: 'DASH', format: 'mpd' },
  'video/mp4': { type: 'Progressive', format: 'mp4' },
  'video/webm': { type: 'Progressive', format: 'webm' },
  'video/mp2t': { type: 'HLS', format: 'ts' },
  'audio/mpeg': { type: 'Progressive', format: 'mp3' },
  'audio/mp4': { type: 'Progressive', format: 'm4a' },
  'audio/aac': { type: 'Progressive', format: 'aac' }
};

const cdnPatterns = [
  { regex: /akamaized\.net|akamai/i, name: 'Akamai' },
  { regex: /cloudfront\.net/i, name: 'CloudFront (AWS)' },
  { regex: /googlevideo\.com/i, name: 'Google Video' },
  { regex: /fbcdn\.net|fbvideo/i, name: 'Facebook CDN' },
  { regex: /cdninstagram\.com/i, name: 'Instagram CDN' },
  { regex: /fastly/i, name: 'Fastly' },
  { regex: /cloudflare/i, name: 'Cloudflare' },
  { regex: /cdn\.jwplayer/i, name: 'JW Player CDN' },
  { regex: /bitmovin/i, name: 'Bitmovin' },
  { regex: /brightcove/i, name: 'Brightcove' },
  { regex: /mux\.com/i, name: 'Mux' },
  { regex: /vimeocdn\.com/i, name: 'Vimeo CDN' },
  { regex: /ytimg\.com/i, name: 'YouTube CDN' },
  { regex: /dailymotion/i, name: 'Dailymotion' },
  { regex: /limelight/i, name: 'Limelight' },
  { regex: /level3\.net/i, name: 'Level3' },
  { regex: /edgecast/i, name: 'Edgecast (Verizon)' },
  { regex: /azure.*cdn|azureedge/i, name: 'Azure CDN' },
  { regex: /stackpath/i, name: 'StackPath' }
];

function classifyUrl(url, contentType) {
  if (!url || typeof url !== 'string') return null;
  if (url.startsWith('blob:') || url.startsWith('data:')) return null;

  if (url.includes('googlevideo.com/videoplayback')) {
    let format = 'mp4';
    if (url.includes('mime=audio')) format = 'm4a';
    else if (url.includes('mime=video%2Fwebm')) format = 'webm';
    return { type: 'DASH', format: format, contentType: contentType || 'video/mp4' };
  }

  if (url.includes('manifest') || url.includes('/manifest.mpd') || url.includes('/Manifest')) {
     return { type: 'DASH', format: 'mpd', contentType: contentType || 'application/dash+xml' };
  }

  if (contentType) {
    const ct = contentType.toLowerCase().split(';')[0].trim();
    if (contentTypeMap[ct]) {
      return { ...contentTypeMap[ct], contentType: ct };
    }
  }

  for (const pattern of mediaPatterns) {
    if (pattern.regex.test(url)) {
      return { type: pattern.type, format: pattern.format, contentType: contentType || null };
    }
  }

  return null;
}

app.post('/analyze', async (req, res) => {
  const targetUrl = req.body.url;
  console.log(`Received analysis request for URL: ${targetUrl}`);
  
  if (!targetUrl) return res.status(400).json({ error: 'url parameter missing' });

  var finalUrl = targetUrl;
  if (finalUrl.indexOf('http') !== 0) finalUrl = 'https://' + finalUrl;

  var report = {
    streams: [],
    usesHLS: false,
    usesDASH: false,
    usesProgressiveMP4: false,
    usesMSE: false,
    usesWebRTC: false,
    usesDRM: false,
    usesServiceWorker: false,
    techSummary: {},
    detectedCDNs: [],
    playerLibrary: null,
    pageTitle: ''
  };
  var seenUrls = new Set();
  
  function addStream(url, classification, source) {
    if (!classification || seenUrls.has(url)) return;
    seenUrls.add(url);

    cdnPatterns.forEach(function(p) {
      if (p.regex.test(url) && report.detectedCDNs.indexOf(p.name) === -1) {
        report.detectedCDNs.push(p.name);
      }
    });

    if (classification.type === 'HLS') report.usesHLS = true;
    if (classification.type === 'DASH') report.usesDASH = true;
    if (classification.type === 'Progressive') report.usesProgressiveMP4 = true;

    report.techSummary[classification.type] = (report.techSummary[classification.type] || 0) + 1;

    report.streams.push({
      url: url,
      type: classification.type,
      format: classification.format,
      contentType: classification.contentType || null,
      resolution: null,
      source: source
    });
  }

  let browser;
  try {
    browser = await puppeteer.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--disable-gpu'
      ]
    });
    
    const page = await browser.newPage();

    page.on('response', async (response) => {
      const url = response.url();
      const contentType = response.headers()['content-type'] || '';
      
      const cls = classifyUrl(url, contentType);
      if (cls) {
        addStream(url, cls, 'network');
      }

      if (contentType.includes('text') || contentType.includes('json') || contentType.includes('xml')) {
        try {
          const text = await response.text();
          if (text) {
             const urlRegex = /https?:\/\/[^\s"'<>\\]+\.(m3u8|mpd|mp4|webm|ts|flv|m4s|mp3|m4a)(\?[^\s"'<>\\]*)?/gi;
             const matches = text.match(urlRegex) || [];
             matches.forEach(m => {
               const c = classifyUrl(m, null);
               if (c) addStream(m, c, 'network-text');
             });
          }
        } catch (err) {}
      }
    });

    try {
      await page.goto(finalUrl, { waitUntil: 'networkidle2', timeout: 20000 });
    } catch(err) {
      console.log('Navigation error for ' + finalUrl + ': ' + err.message);
    }
    
    try {
      report.pageTitle = await page.title();
    } catch (e) {
      report.pageTitle = '';
    }
    
    // Use a string here to avoid pkg serialization issues with function blocks
    var evalString = "(" + function() {
        try {
            var info = {
               playerLibrary: null,
               usesMSE: false,
               usesWebRTC: false,
               usesDRM: false,
               usesServiceWorker: false,
               domStreams: []
            };
            
            if (window.Hls) info.playerLibrary = 'hls.js';
            else if (window.dashjs) info.playerLibrary = 'dash.js';
            else if (window.shaka && window.shaka.Player) info.playerLibrary = 'Shaka Player';
            else if (window.videojs) info.playerLibrary = 'Video.js';
            else if (window.jwplayer) info.playerLibrary = 'JW Player';
            else if (window.Clappr) info.playerLibrary = 'Clappr';
            else if (window.flowplayer) info.playerLibrary = 'Flowplayer';
            else if (window.bitmovin && window.bitmovin.player) info.playerLibrary = 'Bitmovin';
            else if (window.THEOplayer) info.playerLibrary = 'THEOplayer';
            else if (window.Plyr) info.playerLibrary = 'Plyr';
            else if (window.MediaElementPlayer) info.playerLibrary = 'MediaElement.js';
            else {
               var scripts = document.querySelectorAll('script[src]');
               for (var i = 0; i < scripts.length; i++) {
                 var s = scripts[i];
                 var src = s.src.toLowerCase();
                 if (src.indexOf('hls.js') !== -1 || src.indexOf('hls.min.js') !== -1) info.playerLibrary = 'hls.js';
                 else if (src.indexOf('dash.all') !== -1 || src.indexOf('dash.min') !== -1) info.playerLibrary = 'dash.js';
                 else if (src.indexOf('shaka-player') !== -1) info.playerLibrary = 'Shaka Player';
                 else if (src.indexOf('video.js') !== -1 || src.indexOf('video.min.js') !== -1) info.playerLibrary = 'Video.js';
                 else if (src.indexOf('jwplayer') !== -1) info.playerLibrary = 'JW Player';
               }
            }
            
            if (window.MediaSource || window.WebKitMediaSource) info.usesMSE = true;
            if (navigator.requestMediaKeySystemAccess) info.usesDRM = true;
            if (window.RTCPeerConnection || window.webkitRTCPeerConnection) info.usesWebRTC = true;
            if (navigator.serviceWorker && navigator.serviceWorker.controller) info.usesServiceWorker = true;
            
            var videoEls = document.querySelectorAll('video, audio, source');
            for (var j = 0; j < videoEls.length; j++) {
                var el = videoEls[j];
                var vsrc = el.src || el.getAttribute('data-src') || el.getAttribute('data-url');
                if (vsrc && vsrc.indexOf('blob:') !== 0 && vsrc.indexOf('data:') !== 0) {
                    info.domStreams.push(vsrc);
                }
            }

            var iframes = document.querySelectorAll('iframe');
            for (var k = 0; k < iframes.length; k++) {
                var iframe = iframes[k];
                var isrc = iframe.src;
                if (isrc) {
                   if (isrc.indexOf('youtube.com') !== -1 || isrc.indexOf('youtu.be') !== -1) info.domStreams.push(isrc + '#youtube');
                   else if (isrc.indexOf('vimeo.com') !== -1) info.domStreams.push(isrc + '#vimeo');
                   else if (isrc.indexOf('dailymotion.com') !== -1) info.domStreams.push(isrc + '#dailymotion');
                   else if (isrc.indexOf('facebook.com/plugins/video') !== -1 || isrc.indexOf('fb.watch') !== -1) info.domStreams.push(isrc + '#facebook');
                }
            }
            
            return info;
        } catch (e) {
            return { error: e.toString(), domStreams: [] };
        }
    } + ")()";

    var pageInfo = await page.evaluate(evalString);

    report.playerLibrary = pageInfo.playerLibrary;
    if (pageInfo.usesMSE) report.usesMSE = true;
    if (pageInfo.usesWebRTC) report.usesWebRTC = true;
    if (pageInfo.usesDRM) report.usesDRM = true;
    if (pageInfo.usesServiceWorker) report.usesServiceWorker = true;
    
    pageInfo.domStreams.forEach(src => {
        if (src.endsWith('#youtube')) addStream(src.replace('#youtube', ''), { type: 'HLS', format: 'embedded', contentType: 'youtube-embed' }, 'dom');
        else if (src.endsWith('#vimeo')) addStream(src.replace('#vimeo', ''), { type: 'HLS', format: 'embedded', contentType: 'vimeo-embed' }, 'dom');
        else if (src.endsWith('#dailymotion')) addStream(src.replace('#dailymotion', ''), { type: 'HLS', format: 'embedded', contentType: 'dailymotion-embed' }, 'dom');
        else if (src.endsWith('#facebook')) addStream(src.replace('#facebook', ''), { type: 'Progressive', format: 'embedded', contentType: 'facebook-embed' }, 'dom');
        else {
           const cls = classifyUrl(src, null);
           if (cls) addStream(src, cls, 'dom');
        }
    });

    res.json({ type: 'stream_analysis_report', data: report, isComplete: true });

  } catch (error) {
    console.error('Analysis error:', error);
    res.status(500).json({ 
      error: error.toString(),
      stack: error.stack
    });
  } finally {
    if (browser) await browser.close();
  }
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Stream Analyzer Node API running on http://127.0.0.1:${PORT}`);
});
