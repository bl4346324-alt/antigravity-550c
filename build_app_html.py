#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Builds the production 550c.html for the Antigravity 550C native launcher app.
- Full mode only (~16s)
- Amber CRT palette only
- Monospace CJK font stack & enhanced data textures
- Integrated with WebKit script message handlers (Esc / Click / Finish)
"""

import os

root_dir = os.path.dirname(os.path.abspath(__file__))
repo_dir = os.path.join(root_dir, 'repo-dsh-550c-boot')

with open(os.path.join(repo_dir, 'src/assets.js'), 'r', encoding='utf-8') as f:
    assets_js = f.read()

with open(os.path.join(repo_dir, 'src/show.js'), 'r', encoding='utf-8') as f:
    show_js = f.read()

with open(os.path.join(repo_dir, 'src/enhance.js'), 'r', encoding='utf-8') as f:
    enhance_js = f.read()

# Customize HUD texts specifically for Antigravity 中文版
assets_js = assets_js.replace(
    '550C CORE TERMINAL',
    '550C // ANTIGRAVITY 中文版核心终端'
).replace(
    'SWARM NODE MATRIX',
    '智能体集群阵列 / AGENT SWARM'
).replace(
    'TELEMETRY / C-RAN',
    '系统遥测 / ANTIGRAVITY HANS'
).replace(
    'SYSTEM IS REWRITTEN',
    'SYSTEM IS REWRITTEN · ANTIGRAVITY READY'
)

html_content = f"""<!DOCTYPE html>
<html lang="zh-CN" data-platform="darwin">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>550C // ANTIGRAVITY OVERRIDE</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; user-select: none; -webkit-user-select: none; }}
  html, body {{
    width: 100vw; height: 100vh; overflow: hidden; background: #050403;
    cursor: default; -webkit-app-region: drag;
  }}
  .dsh550c-host {{
    position: fixed; inset: 0; display: block; box-sizing: border-box;
    z-index: 1000; background: var(--bg, #050403);
    transition: opacity 420ms cubic-bezier(.4, 0, .2, 1) 150ms;
  }}
  .dsh550c-host.dsh550c-out {{
    opacity: 0; pointer-events: none;
  }}
  .dsh550c-host.dsh550c-out .dsh550c-stage {{
    opacity: 0; transition: opacity 200ms ease-out;
  }}

  /* Esc Skip Hint in bottom right */
  #esc-hint {{
    position: fixed; right: 24px; bottom: 12px; z-index: 9999;
    font-family: "SF Mono", Menlo, Monaco, Consolas, monospace;
    font-size: 11px; letter-spacing: 0.15em; color: rgba(232, 160, 32, 0.4);
    pointer-events: none; text-transform: uppercase;
    transition: opacity 0.3s;
  }}
  #esc-hint kbd {{
    background: rgba(232, 160, 32, 0.12);
    border: 1px solid rgba(232, 160, 32, 0.3);
    border-radius: 4px; padding: 2px 6px; color: rgba(232, 160, 32, 0.7);
  }}
</style>
</head>
<body>

<div id="esc-hint">按下 <kbd>ESC</kbd> 或点击跳过</div>

<script>
{assets_js}

{show_js}

{enhance_js}

const HOST_CSS = `
:host {{
  position: fixed; inset: 0; display: block; box-sizing: border-box;
  z-index: 2000; background: var(--bg, #050403);
  font-family: "Cascadia Mono", Menlo, Monaco, Consolas, "新宋体", NSimSun, monospace;
}}
:host(.dsh550c-out) {{ opacity: 0; transition: opacity 420ms cubic-bezier(.4, 0, .2, 1) 150ms; }}
:host(.dsh550c-out) .dsh550c-stage {{ opacity: 0; transition: opacity 200ms ease-out; }}
.dsh550c-stage {{ height: 100%; }}
`;

let hasFinished = false;

function notifyNative(action) {{
  if (hasFinished) return;
  hasFinished = true;
  try {{
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.splash) {{
      window.webkit.messageHandlers.splash.postMessage(action);
      return;
    }}
  }} catch(e) {{
    console.error('Native bridge error:', e);
  }}
  // Web fallback
  const host = document.querySelector('.dsh550c-host');
  if (host) host.classList.add('dsh550c-out');
}}

function start550C() {{
  const host = document.createElement('div');
  host.className = 'dsh550c-host';
  // Amber palette is default (no data-scheme attribute)
  host.dataset.mode = 'full';
  document.body.appendChild(host);

  const shadow = host.attachShadow({{ mode: 'open' }});
  const style = document.createElement('style');
  style.textContent = HOST_CSS + CSS_550C;
  shadow.appendChild(style);

  const stage = document.createElement('div');
  stage.className = 'dsh550c-stage';
  stage.innerHTML = BOOT_MARKUP + APP_MARKUP;
  shadow.appendChild(stage);

  const CANCELLED = Symbol('cancelled');
  const enhance = enhanceShow(stage, {{ mode: 'full' }});
  const show = createShow(stage, {{ mode: 'full', cancelled: CANCELLED }});

  // Skip handlers
  const handleSkip = () => {{
    show.cancel();
    notifyNative('skip');
  }};

  window.addEventListener('keydown', (e) => {{
    if (e.key === 'Escape' || e.code === 'Escape') {{
      handleSkip();
    }}
  }}, true);

  host.addEventListener('click', () => {{
    handleSkip();
  }});

  // Execute show
  show.start().then(() => {{
    notifyNative('finish');
  }}, () => {{
    notifyNative('finish');
  }});
}}

window.addEventListener('DOMContentLoaded', () => {{
  start550C();
}});
</script>
</body>
</html>
"""

output_path = os.path.join(root_dir, '550c.html')
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(html_content)

print(f"Generated 550c.html successfully! ({len(html_content)} bytes)")
