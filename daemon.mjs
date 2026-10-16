import { readFileSync, writeFileSync, existsSync, readdirSync, createReadStream, statSync, watch } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServer } from 'node:http';
import { homedir } from 'node:os';
import { spawn } from 'node:child_process';

const HERE = dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = existsSync(join(homedir(), '.gemini/config/plugins/antigravity-550c'))
  ? join(homedir(), '.gemini/config/plugins/antigravity-550c')
  : join(HERE, 'plugins', 'antigravity-550c');

const CONTROLLER_DIR = join(PLUGIN_ROOT, 'sidecars', 'controller');
const SKINS_DIR = join(PLUGIN_ROOT, 'skins');
const CONFIG_FILE = join(CONTROLLER_DIR, 'wallpaper-config.json');
const BOOT_OVERLAY_PATH = join(CONTROLLER_DIR, 'assets', 'boot-overlay.js');

let bootOverlayCode = '';
try {
  if (existsSync(BOOT_OVERLAY_PATH)) {
    bootOverlayCode = readFileSync(BOOT_OVERLAY_PATH, 'utf8');
  }
} catch (e) {
  console.error('[550c-daemon] Error reading boot-overlay.js:', e);
}

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
    console.error('[550c-daemon] Failed to read config:', e);
  }
  return { ...DEFAULT_CONFIG };
}

function saveConfig(cfg) {
  try {
    writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2), 'utf8');
  } catch (e) {
    console.error('[550c-daemon] Failed to save config:', e);
  }
}

let currentConfig = loadConfig();

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
              skins.push(JSON.parse(readFileSync(skinJsonPath, 'utf8')));
            } catch (err) {}
          }
        }
      }
    }
  } catch (e) {
    console.error('[550c-daemon] Error reading skins directory:', e);
  }
  return skins;
}

function getSkinCss(skinId) {
  try {
    const cssPath = join(SKINS_DIR, skinId, 'skin.css');
    if (existsSync(cssPath)) {
      return readFileSync(cssPath, 'utf8');
    }
  } catch (e) {}
  try {
    const fallbackPath = join(SKINS_DIR, 'blue-fantasy', 'skin.css');
    if (existsSync(fallbackPath)) {
      return readFileSync(fallbackPath, 'utf8');
    }
  } catch (e) {}
  return '';
}

function generatePreloadScript(cfg) {
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

  return `
    (function() {
      if (window.self !== window.top) return;

      const fullCss = ${JSON.stringify(fullCss)};
      const videoSrc = ${JSON.stringify(videoSrc)};
      const isImg = ${isImage};
      const rate = ${rate};
      const sat = ${sat};
      const blur = ${blur};
      const scrimOpacity = ${scrimOpacity};
      const bootCode = ${JSON.stringify(bootOverlayCode)};
      const bootMode = ${JSON.stringify(cfg.bootMode || 'simple')};

      function injectStyle() {
        let style = document.getElementById('ag-video-style');
        if (!style) {
          style = document.createElement('style');
          style.id = 'ag-video-style';
          style.textContent = fullCss;
          (document.head || document.documentElement).appendChild(style);
        } else if (style.textContent !== fullCss) {
          style.textContent = fullCss;
        }
      }

      function injectMedia() {
        let vid = document.getElementById('ag-video-bg');
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
          vid.style.cssText = 'position:fixed;top:50%;left:50%;min-width:100vw;min-height:100vh;width:auto;height:auto;transform:translate3d(-50%,-50%,0);object-fit:cover;z-index:0;pointer-events:none;backface-visibility:hidden;-webkit-backface-visibility:hidden;contain:strict;will-change:transform;opacity:1;';
          if (document.body) {
            document.body.prepend(vid);
          } else {
            (document.documentElement || document).appendChild(vid);
          }
        }

        if (vid.src !== videoSrc) {
          vid.src = videoSrc;
          if (!isImg) {
            vid.load();
            vid.playbackRate = rate;
            vid.play().catch(() => {});
          }
        }
        vid.style.opacity = '1';
        vid.style.filter = 'saturate(' + sat + '%) contrast(105%) blur(' + (blur > 0 ? (blur * 0.15).toFixed(1) : 0) + 'px)';

        let scrim = document.getElementById('ag-wallpaper-scrim');
        if (!scrim) {
          scrim = document.createElement('div');
          scrim.id = 'ag-wallpaper-scrim';
          scrim.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;z-index:0;pointer-events:none;transform:translateZ(0);backface-visibility:hidden;-webkit-backface-visibility:hidden;contain:strict;';
          if (vid && vid.parentNode) vid.after(scrim);
        }
        if (scrim) {
          scrim.style.backgroundColor = 'rgba(10, 15, 28, ' + scrimOpacity + ')';
        }
      }

      // 1. Immediately inject style to skin the window
      injectStyle();

      // 2. Immediately inject media (dynamic live wallpaper)
      injectMedia();

      // 3. Keep as safeguard in case document was still in initial construction
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
          injectStyle();
          injectMedia();
        });
      }
    })();
  `;
}

// Global CDP Engine
class GlobalSkinEngine {
  constructor() {
    this.ws = null;
    this.port = null;
    this.lastScriptId = null;
    this.connecting = false;
    this.isWallpaperReady = false;
  }

  async discoverDevTools() {
    const portFile = join(homedir(), 'Library/Application Support/Antigravity/DevToolsActivePort');
    if (!existsSync(portFile)) return null;
    try {
      const text = await readFile(portFile, 'utf8');
      const port = parseInt(text.trim().split('\n')[0], 10);
      if (!Number.isInteger(port)) return null;

      // If port changed, Antigravity was restarted!
      if (this.port !== null && this.port !== port) {
        console.log(`[550c-daemon] Antigravity process changed: ${this.port} -> ${port}`);
        this.isWallpaperReady = false;
        if (this.ws) {
          try { this.ws.close(); } catch (e) {}
          this.ws = null;
        }
      }
      this.port = port;

      const res = await fetch(`http://127.0.0.1:${port}/json`);
      const targets = await res.json();
      const mainPage = targets.find(t => t.type === 'page');
      return mainPage ? mainPage.webSocketDebuggerUrl : null;
    } catch (e) {
      return null;
    }
  }

  async connectAndInject() {
    if (this.connecting || (this.ws && this.ws.readyState === WebSocket.OPEN)) {
      return;
    }

    const wsUrl = await this.discoverDevTools();
    if (!wsUrl) return;

    this.connecting = true;
    try {
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        this.connecting = false;
        console.log('[550c-daemon] Connected to Antigravity CDP host');
        this.send('Page.enable', {});

        // 1. Register script to evaluate on EVERY new document / navigation
        const scriptSource = generatePreloadScript(currentConfig);
        this.send('Page.addScriptToEvaluateOnNewDocument', { source: scriptSource }, (res) => {
          this.lastScriptId = res?.identifier;
        });

        // 2. Also immediately evaluate in the currently open document!
        this.send('Runtime.evaluate', { expression: scriptSource });
      };

      this.ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);
          // When a document loads, ensure styles & media are present
          if (msg.method === 'Page.loadEventFired' || msg.method === 'Page.domContentEventFired') {
            const scriptSource = generatePreloadScript(currentConfig);
            this.send('Runtime.evaluate', { expression: scriptSource });
          }
        } catch (e) {}
      };

      this.ws.onclose = () => {
        this.connecting = false;
        this.isWallpaperReady = false;
        this.ws = null;
        this.port = null;
      };

      this.ws.onerror = () => {
        this.connecting = false;
        this.isWallpaperReady = false;
        if (this.ws) {
          try { this.ws.close(); } catch (e) {}
        }
        this.ws = null;
      };
    } catch (e) {
      this.connecting = false;
    }
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
          sessionStorage.setItem('__ag_550c_boot_played', 'true');
          if (typeof window.__ag_playBootAnimation === 'function') {
            window.__ag_playBootAnimation(${JSON.stringify(mode)});
          }
        }
      })();
    `;
    this.send('Runtime.evaluate', { expression: injectCode });
  }

  updateConfig(newCfg) {
    currentConfig = { ...currentConfig, ...newCfg };
    saveConfig(currentConfig);
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      const scriptSource = generatePreloadScript(currentConfig);
      this.send('Page.addScriptToEvaluateOnNewDocument', { source: scriptSource });
      this.send('Runtime.evaluate', { expression: scriptSource });
    }
  }
}

const engine = new GlobalSkinEngine();

// HTTP Server on 5566
function handleHttpRequest(req, res) {
  const url = new URL(req.url, 'http://127.0.0.1');

  if (url.pathname === '/') {
    const indexPath = join(CONTROLLER_DIR, 'index.html');
    const html = existsSync(indexPath) ? readFileSync(indexPath, 'utf8') : '<h1>550C Daemon Active</h1>';
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
        engine.updateConfig({ activeSkin: currentConfig.activeSkin });
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, activeSkin: currentConfig.activeSkin }));
      } catch (e) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (url.pathname === '/api/config') {
    if (req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(currentConfig));
      return;
    }
    if (req.method === 'POST') {
      let body = '';
      req.on('data', chunk => body += chunk);
      req.on('end', () => {
        try {
          const update = JSON.parse(body);
          engine.updateConfig(update);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, config: currentConfig }));
        } catch (e) {
          res.writeHead(400);
          res.end(JSON.stringify({ error: e.message }));
        }
      });
      return;
    }
  }

  if ((url.pathname === '/api/boot/play' || url.pathname === '/api/play-boot') && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      let mode = currentConfig.bootMode || 'simple';
      try {
        if (body) {
          const data = JSON.parse(body);
          if (data.mode) mode = data.mode;
        }
      } catch (e) {}
      engine.playBootAnimation(mode, true);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: true, played: true, mode }));
    });
    return;
  }

  if (url.pathname === '/api/wallpaper-ready' && req.method === 'GET') {
    engine.checkWallpaperReadiness();
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-store'
    });
    res.end(JSON.stringify({
      ready: engine.isWallpaperReady,
      connected: !!(engine.ws && engine.ws.readyState === WebSocket.OPEN),
      videoUrl: currentConfig.videoUrl
    }));
    return;
  }

  // Assets handler
  if (url.pathname.startsWith('/assets/')) {
    const assetRel = url.pathname.slice('/assets/'.length);
    const filePath = join(CONTROLLER_DIR, 'assets', assetRel);

    if (existsSync(filePath) && statSync(filePath).isFile()) {
      const stat = statSync(filePath);
      const ext = assetRel.split('.').pop().toLowerCase();
      const contentType = ext === 'mp4' ? 'video/mp4'
        : ext === 'js' ? 'text/javascript'
        : ext === 'css' ? 'text/css'
        : ext === 'json' ? 'application/json'
        : ext === 'png' ? 'image/png'
        : ext === 'svg' ? 'image/svg+xml'
        : 'application/octet-stream';

      const range = req.headers.range;
      if (range) {
        const parts = range.replace(/bytes=/, '').split('-');
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

const server = createServer(handleHttpRequest);
let isListening = false;
server.on('listening', () => {
  isListening = true;
  console.log('[550c-daemon] HTTP service listening on http://127.0.0.1:5566');
});
server.on('error', (err) => {
  isListening = false;
  if (err.code === 'EADDRINUSE') {
    setTimeout(tryListen, 4000);
  } else {
    console.error('[550c-daemon] Server error:', err);
  }
});
function tryListen() {
  if (isListening) return;
  try {
    server.listen(5566, '127.0.0.1');
  } catch (e) {}
}
tryListen();

// Watch loop (checks every 200ms)
setInterval(() => {
  engine.connectAndInject();
  engine.checkWallpaperReadiness();
}, 200);

// Watch for file change on Antigravity user data dir for instant injection
const agDataDir = join(homedir(), 'Library/Application Support/Antigravity');
if (existsSync(agDataDir)) {
  try {
    watch(agDataDir, (eventType, filename) => {
      if (filename === 'DevToolsActivePort') {
        engine.connectAndInject();
      }
    });
  } catch (e) {}
}

// Heartbeat to keep video alive
setInterval(() => {
  if (engine.ws && engine.ws.readyState === WebSocket.OPEN) {
    engine.send('Runtime.evaluate', {
      expression: "!!document.getElementById('ag-video-bg')"
    }, (res) => {
      if (res?.result?.value === false && currentConfig.enabled) {
        const scriptSource = generatePreloadScript(currentConfig);
        engine.send('Runtime.evaluate', { expression: scriptSource });
      }
    });
  }
}, 3000);

// Native Launch Watcher Supervisor
let watcherProc = null;
function ensureNativeWatcher() {
  const watcherBin = '/Applications/Antigravity 550C.app/Contents/MacOS/Antigravity550C';
  if (!existsSync(watcherBin)) return;
  if (watcherProc && !watcherProc.killed) return;

  try {
    console.log('[550c-daemon] Spawning native launch watcher:', watcherBin);
    watcherProc = spawn(watcherBin, ['--watch'], {
      stdio: 'ignore'
    });
    watcherProc.on('exit', (code, signal) => {
      console.log(`[550c-daemon] Native watcher exited (${code}, ${signal}), restarting in 3s...`);
      watcherProc = null;
      setTimeout(ensureNativeWatcher, 3000);
    });
  } catch(e) {
    console.error('[550c-daemon] Failed to start native watcher:', e);
  }
}

ensureNativeWatcher();

process.on('SIGTERM', () => {
  if (watcherProc) {
    try { watcherProc.kill(); } catch (e) {}
  }
  process.exit(0);
});

process.on('SIGINT', () => {
  if (watcherProc) {
    try { watcherProc.kill(); } catch (e) {}
  }
  process.exit(0);
});

console.log('[550c-daemon] Antigravity 550C Global Daemon Started.');
