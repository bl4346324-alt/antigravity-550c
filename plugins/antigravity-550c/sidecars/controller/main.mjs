import { readFileSync, writeFileSync, existsSync, readdirSync, createReadStream, statSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { dirname, join, extname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createServer } from 'node:http';
import { homedir } from 'node:os';

const HERE = dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = join(HERE, '..', '..');
const SKINS_DIR = join(PLUGIN_ROOT, 'skins');
const CONFIG_FILE = join(HERE, 'wallpaper-config.json');
const BOOT_OVERLAY_PATH = join(HERE, 'assets', 'boot-overlay.js');
let bootOverlayCode = '';
try {
  if (existsSync(BOOT_OVERLAY_PATH)) {
    bootOverlayCode = readFileSync(BOOT_OVERLAY_PATH, 'utf8');
  }
} catch (e) {
  console.error('[550c-boot] Error reading boot-overlay.js:', e);
}

// Default Configuration (Aligned with DSH-Skins standards)
const DEFAULT_CONFIG = {
  enabled: true,
  activeSkin: 'blue-fantasy',
  currentPreset: 'kakashi-red-eyed-fury',
  videoUrl: 'http://127.0.0.1:5566/assets/kakashi.mp4',
  scrimOpacity: 0.25,
  backdropBlur: 14,
  sidebarAlpha: 0.22,
  composerFrost: 28,
  cardAlpha: 0.50,
  saturation: 130,
  playbackRate: 1.0,
  customVideoPath: '',
  playBootOnStartup: true,
  bootMode: 'simple'
};

function loadConfig() {
  try {
    if (existsSync(CONFIG_FILE)) {
      return { ...DEFAULT_CONFIG, ...JSON.parse(readFileSync(CONFIG_FILE, 'utf8')) };
    }
  } catch (e) {
    console.error('[dsh-skins] Failed to read config:', e);
  }
  return { ...DEFAULT_CONFIG };
}

function saveConfig(cfg) {
  try {
    writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2), 'utf8');
  } catch (e) {
    console.error('[dsh-skins] Failed to save config:', e);
  }
}

let currentConfig = loadConfig();

// Catalog scanner: finds all installed skins
function getAvailableSkins() {
  const skins = [];
  try {
    if (existsSync(SKINS_DIR)) {
      const entries = readdirSync(SKINS_DIR, { withFileTypes: true });
      for (const ent of entries) {
        if (ent.isDirectory()) {
          const skinJsonPath = join(SKINS_DIR, ent.name, 'skin.json');
          if (existsSync(skinJsonPath)) {
            try {
              const manifest = JSON.parse(readFileSync(skinJsonPath, 'utf8'));
              skins.push(manifest);
            } catch (err) {}
          }
        }
      }
    }
  } catch (e) {
    console.error('[dsh-skins] Error reading skins directory:', e);
  }
  return skins;
}

// Get CSS for a specific skin
function getSkinCss(skinId) {
  try {
    const cssPath = join(SKINS_DIR, skinId, 'skin.css');
    if (existsSync(cssPath)) {
      return readFileSync(cssPath, 'utf8');
    }
  } catch (e) {
    console.error(`[dsh-skins] Error reading skin.css for ${skinId}:`, e);
  }
  try {
    const fallbackPath = join(SKINS_DIR, 'blue-fantasy', 'skin.css');
    if (existsSync(fallbackPath)) {
      return readFileSync(fallbackPath, 'utf8');
    }
  } catch (e) {}
  return '';
}

// CDP Manager: Controls injection into Antigravity host window
class CdpSkinEngine {
  constructor() {
    this.ws = null;
    this.port = null;
    this.reconnectTimer = null;
    this.heartbeatTimer = null;
    this.lastInjectedCss = '';
    this.startTime = Date.now();
    this.isWallpaperReady = false;
  }

  async discoverDevTools() {
    const portFile = join(homedir(), 'Library/Application Support/Antigravity/DevToolsActivePort');
    if (!existsSync(portFile)) return null;
    try {
      const text = await readFile(portFile, 'utf8');
      const port = parseInt(text.trim().split('\n')[0], 10);
      if (!Number.isInteger(port)) return null;
      this.port = port;

      const res = await fetch(`http://127.0.0.1:${port}/json`);
      const targets = await res.json();
      const mainPage = targets.find(t => t.type === 'page');
      return mainPage ? mainPage.webSocketDebuggerUrl : null;
    } catch (e) {
      return null;
    }
  }

  async connect() {
    if (this.ws && (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)) {
      return;
    }

    const wsUrl = await this.discoverDevTools();
    if (!wsUrl) {
      this.scheduleReconnect();
      return;
    }

    try {
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log('[dsh-skins] Connected to Antigravity CDP host');
        this.send('Page.enable', {});
        // Workspace sidecar only ensures wallpaper is present, never re-plays startup boot
        this.send('Runtime.evaluate', {
          expression: "window.__ag_boot_has_played = true; !!document.getElementById('ag-video-bg')"
        }, (res) => {
          if (!res?.result?.value) {
            this.applyToHost(currentConfig, false);
          }
        });
      };

      this.ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);
          // ONLY re-inject on FULL page reload event, NOT on internal SPA route changes (which caused flickering)
          if (msg.method === 'Page.loadEventFired') {
            setTimeout(() => {
              this.applyToHost(currentConfig, false);
            }, 400);
          }
        } catch (e) {}
      };

      this.ws.onclose = () => {
        this.ws = null;
        this.scheduleReconnect();
      };

      this.ws.onerror = () => {
        if (this.ws) {
          try { this.ws.close(); } catch (e) {}
        }
        this.ws = null;
        this.scheduleReconnect();
      };
    } catch (e) {
      this.scheduleReconnect();
    }
  }

  scheduleReconnect() {
    if (this.reconnectTimer) return;
    const isEarly = (Date.now() - this.startTime) < 20000;
    const delay = isEarly ? 400 : 2500;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, delay);
  }

  startHeartbeat() {
    if (this.heartbeatTimer) clearInterval(this.heartbeatTimer);
    this.heartbeatTimer = setInterval(() => {
      if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
        this.connect();
      } else {
        this.send('Runtime.evaluate', {
          expression: "!!document.getElementById('ag-video-bg')"
        }, (res) => {
          if (res?.result?.value === false && currentConfig.enabled) {
            this.applyToHost(currentConfig, true);
          }
        });
      }
    }, 5000);
  }

  send(method, params, callback) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
    const id = Math.floor(Math.random() * 1000000);
    if (callback) {
      const handler = (evt) => {
        try {
          const data = JSON.parse(evt.data);
          if (data.id === id) {
            this.ws.removeEventListener('message', handler);
            callback(data.result);
          }
        } catch (e) {}
      };
      this.ws.addEventListener('message', handler);
    }
    this.ws.send(JSON.stringify({ id, method, params }));
  }

  checkWallpaperReadiness() {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      this.isWallpaperReady = false;
      return;
    }
    const expr = `(function() {
      const vid = document.getElementById('ag-video-bg');
      const style = document.getElementById('ag-video-style');
      if (!vid || !style) return false;
      if (vid.tagName === 'VIDEO') {
        return vid.readyState >= 2 && !vid.paused && vid.currentTime > 0.05;
      }
      return vid.complete && vid.naturalWidth > 0;
    })()`;
    this.send('Runtime.evaluate', { expression: expr, returnByValue: true }, (res) => {
      if (res?.result?.value === true) {
        this.isWallpaperReady = true;
      }
    });
  }

  playBootAnimation(mode = 'simple', force = true) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
    const injectCode = `
      (function() {
        if (!window.__ag_playBootAnimation && ${JSON.stringify(bootOverlayCode)}) {
          try {
            eval(${JSON.stringify(bootOverlayCode)});
          } catch(err) {
            console.error('[550c-boot] Inlined eval error:', err);
          }
        }
        if (${force} || !window.__ag_boot_has_played) {
          window.__ag_boot_has_played = true;
          if (typeof window.__ag_playBootAnimation === 'function') {
            window.__ag_playBootAnimation(${JSON.stringify(mode)});
          }
        }
      })();
    `;
    this.send('Runtime.evaluate', { expression: injectCode });
  }

  applyToHost(cfg, forceReinject = false) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;

    if (!cfg.enabled) {
      const removeCode = `
        (function() {
          const v = document.getElementById('ag-video-bg');
          if (v) v.remove();
          const scrim = document.getElementById('ag-wallpaper-scrim');
          if (scrim) scrim.remove();
          const s = document.getElementById('ag-video-style');
          if (s) s.remove();
        })();
      `;
      this.send('Runtime.evaluate', { expression: removeCode });
      return;
    }

    const videoSrc = cfg.videoUrl;
    const scrimOpacity = cfg.scrimOpacity ?? 0.25;
    const blur = cfg.backdropBlur ?? 14;
    const sidebarAlpha = cfg.sidebarAlpha ?? 0.22;
    const composerFrost = cfg.composerFrost ?? 28;
    const cardAlpha = cfg.cardAlpha ?? 0.50;
    const sat = cfg.saturation ?? 130;
    const rate = cfg.playbackRate || 1.0;
    const skinId = cfg.activeSkin || 'blue-fantasy';

    const rawSkinCss = getSkinCss(skinId);
    const isImage = /\.(png|jpe?g|webp|gif)(\?.*)?$/i.test(videoSrc);

    // CSS variables & styles
    const fullCss = `
      :root {
        --dsh-sidebar-alpha: ${sidebarAlpha} !important;
        --dsh-card-alpha: ${cardAlpha} !important;
        --dsh-composer-frost: ${composerFrost}px !important;
        --dsh-backdrop-blur: ${blur}px !important;
      }
      #root, body > div:not(#ag-video-bg):not(#ag-wallpaper-scrim):not(#ag-boot-overlay) {
        position: relative !important;
        z-index: 1 !important;
      }
      ${rawSkinCss}
    `;

    // Only update styles if changed or forced, preventing style flicker on SPA navigation
    const shouldUpdateCss = forceReinject || (fullCss !== this.lastInjectedCss);
    this.lastInjectedCss = fullCss;

    const injectCode = `
      (function() {
        // 1. Hardware Isolated Video Element
        let vid = document.getElementById('ag-video-bg');
        const isImg = ${isImage};
        if (!vid || (isImg && vid.tagName !== 'IMG') || (!isImg && vid.tagName !== 'VIDEO')) {
          if (vid) vid.remove();
          vid = document.createElement(isImg ? 'img' : 'video');
          vid.id = 'ag-video-bg';
          if (!isImg) {
            vid.autoplay = true;
            vid.loop = true;
            vid.muted = true;
            vid.playsInline = true;
          }
          vid.style.cssText = 'position:fixed;top:50%;left:50%;min-width:100vw;min-height:100vh;width:auto;height:auto;transform:translate3d(-50%,-50%,0);object-fit:cover;z-index:0;pointer-events:none;backface-visibility:hidden;-webkit-backface-visibility:hidden;contain:strict;will-change:transform;';
          document.body.prepend(vid);
        }

        if (vid.src !== ${JSON.stringify(videoSrc)}) {
          vid.src = ${JSON.stringify(videoSrc)};
          if (!isImg) {
            vid.load();
            vid.playbackRate = ${rate};
            vid.play().catch(() => {});
          }
        }
        vid.style.opacity = '1';
        vid.style.filter = 'saturate(${sat}%) contrast(105%) blur(${blur > 0 ? (blur * 0.15).toFixed(1) : 0}px)';

        // 2. Hardware Isolated Scrim Element (NO backdrop-filter to prevent GPU stalls/flicker)
        let scrim = document.getElementById('ag-wallpaper-scrim');
        if (!scrim) {
          scrim = document.createElement('div');
          scrim.id = 'ag-wallpaper-scrim';
          scrim.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;z-index:0;pointer-events:none;transform:translateZ(0);backface-visibility:hidden;-webkit-backface-visibility:hidden;contain:strict;';
          vid.after(scrim);
        }
        scrim.style.backgroundColor = 'rgba(10, 15, 28, ${scrimOpacity})';

        // 3. Update Style Tag (Only if modified)
        ${shouldUpdateCss ? `
          let style = document.getElementById('ag-video-style');
          if (!style) {
            style = document.createElement('style');
            style.id = 'ag-video-style';
            document.head.appendChild(style);
          }
          if (style.textContent !== ${JSON.stringify(fullCss)}) {
            style.textContent = ${JSON.stringify(fullCss)};
          }
        ` : ''}
      })();
    `;

    this.send('Runtime.evaluate', { expression: injectCode });
  }
}

const skinEngine = new CdpSkinEngine();

// HTTP Server
function handleHttpRequest(req, res) {
  const url = new URL(req.url, 'http://127.0.0.1');

  if (url.pathname === '/') {
    const html = readFileSync(join(HERE, 'index.html'), 'utf8');
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store'
    });
    res.end(html);
    return;
  }

  if (url.pathname === '/api/skins' && req.method === 'GET') {
    const skins = getAvailableSkins();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(skins));
    return;
  }

  if (url.pathname === '/api/skin' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const update = JSON.parse(body);
        if (update.skinId) currentConfig.activeSkin = update.skinId;
        saveConfig(currentConfig);
        skinEngine.applyToHost(currentConfig, true);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, activeSkin: currentConfig.activeSkin }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (url.pathname === '/api/config' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(currentConfig));
    return;
  }

  if (url.pathname === '/api/config' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const update = JSON.parse(body);
        currentConfig = { ...currentConfig, ...update };
        saveConfig(currentConfig);
        skinEngine.applyToHost(currentConfig);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, config: currentConfig }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (url.pathname === '/api/play-boot' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        const mode = payload.mode || currentConfig.bootMode || 'simple';
        skinEngine.playBootAnimation(mode);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, mode }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (url.pathname === '/api/wallpaper-ready' && req.method === 'GET') {
    skinEngine.checkWallpaperReadiness();
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-store'
    });
    res.end(JSON.stringify({
      ready: skinEngine.isWallpaperReady,
      connected: !!(skinEngine.ws && skinEngine.ws.readyState === WebSocket.OPEN),
      videoUrl: currentConfig.videoUrl
    }));
    return;
  }

  if (url.pathname.startsWith('/assets/') || url.pathname === '/api/local-video') {
    const filePath = url.pathname.startsWith('/assets/') 
      ? join(HERE, url.pathname)
      : url.searchParams.get('path');

    if (filePath && existsSync(filePath)) {
      const stat = statSync(filePath);
      const ext = extname(filePath).toLowerCase();
      const mimeTypes = {
        '.webm': 'video/webm',
        '.mp4': 'video/mp4',
        '.mov': 'video/quicktime',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.webp': 'image/webp',
        '.svg': 'image/svg+xml',
        '.css': 'text/css',
        '.js': 'text/javascript'
      };
      const contentType = mimeTypes[ext] || 'application/octet-stream';
      const range = req.headers.range;

      if (range && stat.size > 0) {
        const parts = range.replace(/bytes=/, "").split("-");
        const start = parseInt(parts[0], 10);
        const end = parts[1] ? parseInt(parts[1], 10) : stat.size - 1;
        const chunksize = (end - start) + 1;
        res.writeHead(206, {
          'Content-Range': `bytes ${start}-${end}/${stat.size}`,
          'Accept-Ranges': 'bytes',
          'Content-Length': chunksize,
          'Content-Type': contentType,
        });
        createReadStream(filePath, { start, end }).pipe(res);
        return;
      }

      res.writeHead(200, {
        'Content-Type': contentType,
        'Content-Length': stat.size,
        'Accept-Ranges': 'bytes'
      });
      createReadStream(filePath).pipe(res);
      return;
    }
  }

  res.writeHead(404);
  res.end('Not Found');
}

// Start Server
const port = 5566;
const server = createServer(handleHttpRequest);
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.log('[dsh-skin-engine] Port 5566 is already held by background daemon, running in client mode.');
    skinEngine.connect();
    skinEngine.startHeartbeat();
  } else {
    console.error('[dsh-skin-engine] Server error:', err);
  }
});
server.listen(port, '127.0.0.1', () => {
  console.log(`[dsh-skin-engine] listening on http://127.0.0.1:${port}`);
  skinEngine.connect();
  skinEngine.startHeartbeat();
});
