#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Builds sidecars/terminal/index.html for the Antigravity 550C Plugin.
Adapted for Antigravity's Auxiliary Pane / Sidecar UI:
- Interactive Replay and Skip controls
- Responsive layout for narrow auxiliary side panels
- Live terminal persistent mode after boot completion
"""

import os

root_dir = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(root_dir, '550c.html'), 'r', encoding='utf-8') as f:
    orig = f.read()

# Locate where JS logic is
split_marker = 'const HOST_CSS ='
split_pos = orig.find(split_marker)
if split_pos == -1:
    raise RuntimeError('Could not find split_marker in 550c.html')

base_assets = orig[:split_pos]

sidecar_tail = """
const RESPONSIVE_CSS = `
  /* ── 侧边栏/宽窄屏响应式适配 ── */
  @media (max-width: 820px) {
    #app {
      max-width: 100% !important;
      max-height: 100% !important;
      padding: 4px !important;
      gap: 4px !important;
    }
    #workspace {
      display: flex !important;
      flex-direction: column !important;
      overflow-y: auto !important;
      gap: 6px !important;
    }
    #w-tele, #w-main, #w-code, #w-node {
      min-height: 180px;
      flex: none;
    }
    #w-main {
      min-height: 240px;
    }
    .boot-stage svg {
      width: min(340px, 90vw) !important;
      max-height: 110px !important;
    }
    .win-popup {
      min-width: 260px !important;
      max-width: 92vw !important;
      left: 50% !important;
      top: 50% !important;
      transform: translate(-50%, -50%) !important;
    }
    #final {
      font-size: clamp(16px, 4vw, 24px) !important;
      padding: 14px 22px !important;
      white-space: normal !important;
    }
    #hud-top {
      font-size: 9px !important;
      gap: 6px !important;
      padding: 0 6px !important;
    }
    #hud-bot {
      font-size: 8px !important;
      gap: 6px !important;
    }
  }

  /* 浮动控制栏 */
  .terminal-controls {
    position: fixed;
    top: 8px;
    right: 14px;
    z-index: 3000;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .ctrl-btn {
    background: rgba(13, 10, 6, 0.92);
    border: 1px solid var(--amber-d, #8a5e10);
    color: var(--amber, #e8a020);
    font-family: inherit;
    font-size: 11px;
    letter-spacing: 0.12em;
    padding: 3px 10px;
    cursor: pointer;
    border-radius: 3px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.7);
    transition: all 0.2s;
    user-select: none;
    -webkit-user-select: none;
  }
  .ctrl-btn:hover {
    background: rgba(232, 160, 32, 0.2);
    border-color: var(--amber, #e8a020);
    color: var(--amber-b, #ffc043);
    box-shadow: 0 0 12px rgba(232, 160, 32, 0.4);
  }
  .ctrl-btn:active {
    transform: translateY(1px);
  }
  .ctrl-btn.hidden {
    display: none !important;
  }
`;

const HOST_CSS = `
:host {
  position: fixed; inset: 0; display: block; box-sizing: border-box;
  z-index: 1000; background: var(--bg, #050403);
  font-family: "Cascadia Mono", Menlo, Monaco, Consolas, "新宋体", NSimSun, monospace;
}
.dsh550c-stage { height: 100%; position: relative; }
`;

let currentDisposer = null;
let currentShow = null;

function start550C() {
  if (currentShow) {
    try { currentShow.cancel(); } catch(e){}
    currentShow = null;
  }
  if (currentDisposer) {
    try { currentDisposer(); } catch(e){}
    currentDisposer = null;
  }

  const oldHost = document.querySelector('.dsh550c-host');
  if (oldHost) oldHost.remove();

  const host = document.createElement('div');
  host.className = 'dsh550c-host';
  host.dataset.mode = 'full';
  document.body.appendChild(host);

  const shadow = host.attachShadow({ mode: 'open' });
  const style = document.createElement('style');
  style.textContent = HOST_CSS + CSS_550C + RESPONSIVE_CSS;
  shadow.appendChild(style);

  // Floating Controls
  const ctrlContainer = document.createElement('div');
  ctrlContainer.className = 'terminal-controls';
  ctrlContainer.innerHTML = `
    <button class="ctrl-btn" id="btn-skip" title="跳过开机动画直接进入终端">▶ 跳过动画</button>
    <button class="ctrl-btn" id="btn-replay" title="重新开始播放 550C 启动动画">↺ 重播序列</button>
  `;
  shadow.appendChild(ctrlContainer);

  const stage = document.createElement('div');
  stage.className = 'dsh550c-stage';
  stage.innerHTML = BOOT_MARKUP + APP_MARKUP;
  shadow.appendChild(stage);

  const skipBtn = ctrlContainer.querySelector('#btn-skip');
  const replayBtn = ctrlContainer.querySelector('#btn-replay');

  const CANCELLED = Symbol('cancelled');
  try {
    currentDisposer = enhanceShow(stage, { mode: 'full' });
  } catch(e) {
    console.warn('enhanceShow failed:', e);
  }

  const show = createShow(stage, { mode: 'full', cancelled: CANCELLED });
  currentShow = show;

  let isComplete = false;

  const onComplete = () => {
    if (isComplete) return;
    isComplete = true;
    if (skipBtn) skipBtn.classList.add('hidden');
    const finalEl = shadow.querySelector('#final');
    if (finalEl) {
      finalEl.classList.add('show');
      setTimeout(() => {
        finalEl.classList.remove('show');
      }, 2400);
    }
  };

  const handleSkip = () => {
    if (isComplete) return;
    show.cancel();
    const bootEl = shadow.querySelector('#boot');
    if (bootEl) bootEl.classList.add('fade');
    const appEl = shadow.querySelector('#app');
    if (appEl) appEl.classList.add('visible');
    // Close popups
    const popups = shadow.querySelectorAll('.win-popup');
    popups.forEach(p => p.classList.remove('show'));
    onComplete();
  };

  skipBtn.onclick = (e) => {
    e.stopPropagation();
    handleSkip();
  };

  replayBtn.onclick = (e) => {
    e.stopPropagation();
    start550C();
  };

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') handleSkip();
  });

  // Execute Show
  show.start().then(() => {
    onComplete();
  }, () => {
    // Cancelled / Skipped
    onComplete();
  });
}

window.addEventListener('DOMContentLoaded', () => {
  start550C();
});
</script>
</body>
</html>
"""

full_html = base_assets + sidecar_tail

# Write to plugin destination
plugin_dir = os.path.expanduser('~/.gemini/config/plugins/antigravity-550c/sidecars/terminal')
os.makedirs(plugin_dir, exist_ok=True)
dest_path = os.path.join(plugin_dir, 'index.html')

with open(dest_path, 'w', encoding='utf-8') as f:
    f.write(full_html)

print(f"Successfully generated sidecar UI at {dest_path} ({len(full_html)} bytes)")

# Also write to local project plugins directory
local_plugin_dir = os.path.join(root_dir, 'plugins/antigravity-550c/sidecars/terminal')
os.makedirs(local_plugin_dir, exist_ok=True)
with open(os.path.join(local_plugin_dir, 'index.html'), 'w', encoding='utf-8') as f:
    f.write(full_html)
print(f"Also synced to local project at {local_plugin_dir}/index.html")
